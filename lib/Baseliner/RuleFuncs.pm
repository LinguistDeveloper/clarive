package Baseliner::RuleFuncs;
use strict;
use warnings;

use Try::Tiny;
use Baseliner::Utils qw(:logging parse_vars _array _get_dotted_keys _clone is_number _pointer);
use Baseliner::Sugar qw(event_new);
use Baseliner::Core::Registry;
use Clarive::ci;
use Clarive::queue;
use Clarive::Code;

use Exporter::Tidy default => [
    qw(
      changeset_projects
      current_task
      cut_nature_items
      error_trap
      include_rule
      launch
      merge_data
      merge_into_stash
      parallel_run
      wait_for_children
      project_changes
      semaphore
      stash_has_nature
      variables_for_bl
      eval_code
      condition_check
      )
];

our $DATA;

sub parallel_run {
    my ( $name, $mode, $stash, $code ) = @_;

    # Save stash completely, so that parent does not
    # destroy something by the time fork() child is ready
    my $stash_child = _clone($stash);

    my $chi_pid = fork;

    # Could not fork
    if ( !defined $chi_pid ) {

        require Proc::ProcessTable;

        my @children;
        for my $p ( _array( Proc::ProcessTable->new->table ) ) {
            push @children, $p->pid if $p->ppid == $$;
        }

        my $msg = _loc( "Children, number=%1, list=%2", scalar(@children), join( ',', @children ) );
        _fail( _loc( 'Could not fork child from parent pid %1. Check max processes available with `ulimit -u`.', $$ ),
            data => $msg );
    }

    # Parent
    elsif ($chi_pid) {
        _log _loc('Forked child task %1 with pid %2', $name, $chi_pid);

        if ( $mode eq 'fork' ) {

            # fork and wait..
            $DATA->{_forked_pids}{$chi_pid} = $name;
        }

        return $chi_pid;
    }

    # Child
    else {
        mdb->disconnect;    # will reconnect later

        my ( $ret, $err );
        my $orig_stash = $stash;
        $stash = $stash_child;

        try {
            $ret = $code->();
        }
        catch {
            $err = shift;
            _error( _loc( 'Detected error in child %1 (%2): %3', $$, $mode, $err ) );
        };

        if ( $mode eq 'fork' ) {

            # fork and wait.., communicate results to parent
            my $res = { ret => $ret, err => $err, stash => $orig_stash };
            queue->push( msg => "rule:child:results:$$", data => $res );
        }

        exit 0;    # cannot update stash, because it would override the parent run copy
    }
}

sub wait_for_children {
    my ($stash, %p ) = @_;

    my $config     = $p{config};
    my $errors     = $config->{errors} || 'fail';
    my $stash_keys = $config->{parallel_stash_keys} || [];
    my $results    = [];

    my $chi_pids = $DATA->{_forked_pids};
    if( my @pids = keys %$chi_pids ) {
        _info( _loc('Waiting for return code from children pids: %1', join(',', @pids ) ) );
        my @failed;
        my @oks;

        for my $pid ( @pids ) {
            waitpid $pid, 0;
            delete $chi_pids->{$pid};
            if( my $res = queue->pop( msg=>"rule:child:results:$pid" ) ) {
                if( $res->{err} ) {
                    _error( $res->{err} );
                    push @failed, {pid => $pid, err => $res->{err}};
                } else {
                    push @oks, $pid;
                }

                my $fork_stash = {ret => $res->{ret}, err => $res->{err}};
                foreach my $stash_key (@$stash_keys) {
                    $fork_stash->{$stash_key} = $res->{stash}->{$stash_key};
                }

                push @$results, $fork_stash;
            }
        }
        if( @failed ) {
            my $error_msg = _loc( 'Error detected in children, pids failed: %1. Ok: %2',
                join( ',', map { $_->{pid} } @failed ),
                join( ',', @oks )
            );

            $error_msg .= "\nErrors:\n";
            $error_msg .= join "\n", map { $_->{pid} . ': ' . $_->{err} } @failed;

            if ($errors eq 'fail') {
                _fail( $error_msg );
            }
            elsif ($errors eq 'warn') {
                _warn( $error_msg );
            }
        } else {
            _info( _loc('Done waiting for return code from children pids: %1', join(',',@pids ) ) );
        }
    } else {
#        _debug( _loc('No children to wait for.') );
    }

    return $results;
}

sub error_trap {
    my (%params) = @_;

    my $stash               = $params{stash};
    my $trap_timeout        = $params{trap_timeout};
    my $trap_timeout_action = $params{trap_timeout_action};
    my $trap_max_retry      = $params{trap_max_retry};
    my $trap_rollback       = $params{trap_rollback};
    my $mode                = $params{mode};
    my $code                = $params{code};

    my %timeouts = $params{timeouts} // ();
    $timeouts{initial_timeout}  //= $timeouts{default_timeout} // 4;
    $timeouts{pause_timeout}    //= $timeouts{default_timeout} // 5;
    $timeouts{interval_timeout} //= $timeouts{default_timeout} // 10;
    $timeouts{zero_timeout}     //= $timeouts{default_timeout} // 5;

    my $no_retry_limit = !$trap_max_retry;

    RETRY_TRAP:
    try {
        $code->();
    } catch {
        my $err = shift;

        my $job = $stash->{job};

        if( !$job ) { # we're in a event rule, not a job
            _error( _loc( "Error ignored in rule: %1", $err ) );
            return;
        }

        if ( $job->rollback && !$trap_rollback ) {
            $job->logger->info( _loc("Ignoring trap errors in rollback.  Aborting task", $err ) );
            _fail($err);
        }

        if( $mode eq 'ignore' ) {
            $job->logger->info( _loc("Ignored error trapped in rule: %1", $err ) );
            return;
        };

        $job->logger->error( _loc("Error trapped in rule: %1", $err ) );
        $job->update( status=>'TRAPPED' );

        ## Avoid error if . in stash keys
        my @keys = _get_dotted_keys( $stash, '$stash');

        if ( @keys ) {
            my @complete_keys;
            for my $key ( @keys ) {
                push @complete_keys, $key->{parent}.'->{'.$key->{key}.'}';
                my $parent = eval($key->{parent});
                delete $parent->{$key->{key}};
            }
            _debug("Stash contains variables with '.' removed to avoid errors:\n\n". join(", ", @complete_keys));
        };

        my @projects = map { $_->{mid} } _array( $job->projects );
        event_new 'event.job.trapped' =>
            { notify => { project => \@projects }, username => 'internal', stash => $stash, output => $err } =>
            sub { } => sub {
            my $err = shift;
            _warn( _loc( 'Could not store event for trapped error: %1', $err ) );
            };

        my $last_status = 'TRAPPED';
        my $timeout = $trap_timeout;

        LOOP:
        sleep $timeouts{initial_timeout};
        while (1) {
            if ( $last_status eq 'TRAPPED_PAUSED' ) {
                sleep $timeouts{pause_timeout};
            }
            else {
                if ( !$trap_timeout || $trap_timeout eq '0' ) {
                    sleep $timeouts{zero_timeout};
                }
                else {
                    sleep $timeouts{interval_timeout};
                    # WE SLEEP HERE AT LEAST 14 SECONDS NO MATTER WHAT trap_timeout IS
                    $timeout = $timeout - $timeouts{interval_timeout};
                    if ( $timeout gt 0 ) {
                        $job->logger->warn(
                            _loc(
                                "%1 seconds remaining to cancel trap with action %2",
                                $timeout,
                                $trap_timeout_action
                            )
                        );
                    }
                    else {
                        $job->trap_action(
                            {   action   => $trap_timeout_action,
                                comments => _loc(
                                    "Trap timeout expired.  Action configured: %1",
                                    $trap_timeout_action
                                )
                            }
                        );
                    }
                }
            }
            $last_status = $job->load->{status};
            if ( $last_status !~ /TRAPPED/ ) {
                last;
            }
        }
        if ( $last_status eq 'RETRYING' ) {
            $stash->{_last_trap_action} = 'retry';
            if ($no_retry_limit || $trap_max_retry > 0){
                $job->logger->info( _loc( "Retrying task: %1", $err ) );
                $trap_max_retry-- unless $no_retry_limit;
                goto RETRY_TRAP;
            } else {
                $job->logger->info( _loc( "Cannot retry. Max retries reached: %1", $err ) );
                _fail(_loc("Cannot retry. Max retries reached: %1", $err));
            }
        }
        elsif ( $last_status eq 'SKIPPING' ) {
            $stash->{_last_trap_action} = 'skip';
            $job->logger->info( _loc( "Skipping task: %1", $err ) );
            return;
        }
        elsif ( $last_status eq 'ERROR' ) {
            $job->logger->info( _loc( "Aborting task: %1", $err ) );
            _fail($err);
        }
        else {
            goto LOOP;
        }

    };
}

sub semaphore {
    my ($data, $stash)=@_;
    require Baseliner::Sem;
    parse_vars( $data, $stash );
    my $sem = Baseliner::Sem->new( $data );
    _info( _loc('Semaphore queued for %1', $data->{key} ) );
    return $sem;
}

sub merge_data {
    my ($dest,@hashes)=@_;
    $dest = {} unless ref $dest eq 'HASH';
    for my $hash ( @hashes ) {
        next unless ref $hash eq 'HASH';
        for my $k ( keys %$hash ) {
            $dest->{$k} = $hash->{$k};
        }
    }
    parse_vars( $dest, $dest );
}

sub project_changes {
    my ($stash)=@_;
    if( !$stash->{project_changes} ) {
        _warn _loc('No project changes detected');
        return ();
    } else {
        return map {
            my $p = $_->{project};
            if( Util->_blessed( $p )  ) {
                $p;
            } else {
                if( $p->can('mid') ) {
                    ci->new( $p->mid );
                } else {
                    ci->new( $p );  # is a number then, or try my luck
                }
            }
        } _array( $stash->{project_changes} );
    }
}

sub current_task {
    my ( $stash, %params ) = @_;

    my $id_rule   = $params{id_rule};
    my $rule_name = $params{rule_name};
    my $name      = $params{name};
    my $code      = $params{code};
    my $level     = $params{level};

    $name = parse_vars( $name, $stash );   # so we can have vars in task names

    $Baseliner::_rule_current_id   = $id_rule;
    $Baseliner::_rule_current_name = $rule_name;

    $stash->{current_rule_id}   = $id_rule;
    $stash->{current_rule_name} = $rule_name;
    $stash->{current_task_name} = $name;

    if ( my $job = $stash->{job} ) {
        my $is_job_canceled = mdb->rule_status->find_and_modify(
            {   query => {
                    id     => $job->jobid,
                    type   => 'job',
                    status => "CANCEL_REQUESTED"
                },
                update => { '$set' => { status => "CANCELLED" } }
            }
        );
        if ($is_job_canceled) {
            _fail _loc( 'Job cancelled by user %1',
                $is_job_canceled->{username} );
        }
        else {
            $job->start_task($name, $level);
        }
    }

    $code->() if $code;
}


sub cut_nature_items {
    my ($stash,$tail)=@_;
    my @items = _array( $stash->{nature_items} );
    # items to write
    my @items_write = grep { $_->status ne 'D' } @items;
    my @paths_write = grep { length } map { $_->path_tail( $tail ) } @items_write;
    # items deleted
    my @items_del   = grep { $_->status eq 'D' } @items;
    my @paths_del   = grep { length } map { $_->path_tail( $tail ) } @items_del;

    _fail _loc('Could not find any paths in nature items that match cut path `%1`', $tail)
        unless ( @paths_write + @paths_del );
    return ( \@paths_write, \@paths_del );
}

# launch runs service, merge return into stash and returns what the service returns
sub launch {
    my ($key, $task, $stash, $config, $data_key )=@_;

    $task = parse_vars( $task, $stash );

    my $reg = Baseliner::Core::Registry->get_instance( $key );
    _fail _loc("Cound not find '$key' in registry") unless $reg;

    #_log "running container for $key";
    my $return_data = try {
        $reg->run_container( $stash, $config );
    } catch {
        my $err = shift;
        die _loc( 'Error running task * %1 *: %2', $task, $err ) . "\n"; # there's another catch later, so no need to _fail here
    };
    # TODO milestone for service
    #_debug $ret;
    my $refr = ref $return_data;
    my $mergeable = $refr eq 'HASH' || Scalar::Util::blessed($return_data);
    if( $mergeable || $refr eq 'ARRAY' || !$refr ) {
        # merge into stash
        merge_into_stash( $stash, ( $data_key eq '=' && $mergeable ? $return_data : { $data_key => $return_data } ) ) if length $data_key;
        return $return_data;
    } else {
        return {};
    }
}

sub merge_into_stash {
    my ($stash, $data) = @_;
    return unless ref $data eq 'HASH';
    while( my($k,$v) = each %$data ) {
        $stash->{$k} = $v;
    }
    return $stash
}

sub stash_has_nature {
    my ($nature,$stash) = @_;
    $nature = ci->new( $nature ) unless ref $nature;
    my $nature_items = $nature->filter_items( items=>$stash->{items} ); # save => 1 ??
    return $nature_items;
}

sub changeset_projects {
    my $stash = shift;

    # for each changeset, get project and group changesets
    my %projects;
    for my $cs ( _array( $stash->{changesets} ) ) {
        $cs = ci->new($cs) unless ref $cs;
        for my $project ( $cs->related( does => 'Project' ) ) {
            $projects{ $project->mid } = $project;
        }
    }

    return values %projects;
}

#sub project_changed {
#    my $stash = shift;
#    # for each changeset, get project and group changesets
#    my %projects;
#    for my $project ( _array( $stash->{project_changes} ) ) {
#        $cs = ci->new( $cs ) unless ref $cs;
#        for my $project ( $cs->related( does=>'Project' ) ) {
#            $projects{ $project->mid } = $project;
#        }
#    }
#    #my $project = ci->new( 6901 );  # TEF
#    return values %projects;
#}

sub variables_for_bl {
    my ($ci, $bl) = @_;
    my $vars = $ci->variables // { _no_vars=>1 };
    my $vars_common_bl = $vars->{'*'} // {};
    my $vars_for_bl = $vars->{$bl} // { _no_vars_for_bl=>$bl } if length $bl && $bl ne '*';
    $vars_for_bl //= {};
    +{ %$vars_common_bl, %$vars_for_bl };
}

sub eval_code {
    my ($lang, $code, $stash) = @_;

    Clarive::Code->new->eval_code($code, lang => $lang, stash => $stash);
}

sub condition_check {
    my ( $stash, $when, $conditions ) = @_;

    my @values;
    foreach my $condition (@$conditions) {
        my $operand_a = _pointer $condition->{operand_a}, $stash;
        my $operator  = $condition->{operator};
        my $options   = $condition->{options};
        my $operand_b = Util->parse_vars( $condition->{operand_b}, $stash );

        my $value = !!_condition_check( $operand_a, $operator, $options, $operand_b );

        if ( $when eq 'all' ) {
            return 0 unless $value;
        }
        elsif ( $when eq 'any' ) {
            return 1 if $value;
        }
        elsif ( $when eq 'none' ) {
            return 0 if $value;
        }
    }

    if ( $when eq 'all' ) {
        return 1;
    }
    elsif ( $when eq 'any' ) {
        return 0;
    }
    elsif ( $when eq 'none' ) {
        return 1;
    }
}

sub _condition_check {
    my ( $operand_a, $operator, $options, $operand_b ) = @_;

    $operand_a //= '';
    $operand_b //= '';

    if ( $operator eq 'is_true' || $operator eq 'is_false' ) {
        my $ret = Util->_any( sub { $_ }, Util->_array($operand_a) );

        return $operator eq 'is_true' ? $ret : !$ret;
    }
    elsif ( $operator eq 'is_empty' || $operator eq 'not_empty' ) {
        my @values = Util->_array($operand_a);

        my $ret;
        if (@values) {
            $ret = 0;
            foreach my $value (@values) {
                if ( ref $value ) {
                    if ( ref $value eq 'HASH' ) {
                        $ret = !%$value;
                    }
                }
                else {
                    $ret = !length $value;
                }

                last if $ret;
            }
        }
        else {
            $ret = 1;
        }

        return $operator eq 'is_empty' ? $ret : !$ret;
    }
    elsif ( $operator eq 'eq' || $operator eq 'not_eq' ) {
        if ( $options->{ignore_case} ) {
            $operand_a = lc($operand_a);
            $operand_b = lc($operand_b);
        }

        my $ret = $options->{numeric} ? $operand_a == $operand_b : $operand_a eq $operand_b;

        return $operator eq 'eq' ? $ret : !$ret;
    }
    elsif ( $operator eq 'ge' ) {
        if ( $options->{ignore_case} ) {
            $operand_a = lc($operand_a);
            $operand_b = lc($operand_b);
        }

        return $options->{numeric} ? $operand_a >= $operand_b : $operand_a ge $operand_b;
    }
    elsif ( $operator eq 'gt' ) {
        if ( $options->{ignore_case} ) {
            $operand_a = lc($operand_a);
            $operand_b = lc($operand_b);
        }

        return $options->{numeric} ? $operand_a > $operand_b : $operand_a gt $operand_b;
    }
    elsif ( $operator eq 'le' ) {
        if ( $options->{ignore_case} ) {
            $operand_a = lc($operand_a);
            $operand_b = lc($operand_b);
        }

        return $options->{numeric} ? $operand_a <= $operand_b : $operand_a le $operand_b;
    }
    elsif ( $operator eq 'lt' ) {
        if ( $options->{ignore_case} ) {
            $operand_a = lc($operand_a);
            $operand_b = lc($operand_b);
        }

        return $options->{numeric} ? $operand_a < $operand_b : $operand_a lt $operand_b;
    }
    elsif ( $operator eq 'like' ) {
        return $operand_a =~ ( $options->{ignore_case} ? qr{$operand_b}i : qr{$operand_b} );
    }
    elsif ( $operator eq 'not_like' ) {
        return $operand_a !~ ( $options->{ignore_case} ? qr{$operand_b}i : qr{$operand_b} );
    }
    elsif ( $operator eq 'in' || $operator eq 'not_in' ) {
        my $var_val = $operand_a;
        my $ret     = Util->_any(
            sub {
                $options->{ignore_case}
                  ? lc($var_val) eq lc($_)
                  : $var_val eq $_;
            },
            Util->_array( ref $operand_b eq 'HASH' ? %$operand_b : $operand_b )
        );

        return $operator eq 'in' ? $ret : !$ret;
    }
    elsif ( $operator eq 'has' || $operator eq 'not_has' ) {
        my $var_val = $operand_a;
        my $ret     = Util->_any(
            sub {
                $options->{ignore_case}
                  ? lc($operand_b) eq lc($_)
                  : $operand_b eq $_;
            },
            Util->_array( ref $var_val eq 'HASH' ? %{$var_val} : $var_val )
        );

        return $operator eq 'has' ? $ret : !$ret;
    }
    else {
        _fail "Unknown operator '$operator'";
    }
}

1;
