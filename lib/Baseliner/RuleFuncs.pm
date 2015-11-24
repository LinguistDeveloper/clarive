package Baseliner::RuleFuncs;
use strict;
use warnings;

use Try::Tiny;
use Baseliner::Utils qw(:logging parse_vars _array _get_dotted_keys _clone);
use Baseliner::Sugar qw(event_new);
use Baseliner::Core::Registry;
use Clarive::ci;
use Clarive::queue;

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
        _log _loc 'Forked child task %1 with pid %2', $name, $chi_pid;

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
                    push @failed, $pid;
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
            my $error_msg = _loc('Error detected in children, pids failed: %1. Ok: %2', join(',',@failed ), join(',',@oks) );

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
    my ($stash, $trap_timeout,$trap_timeout_action, $trap_rollback, $mode, $code)= @_;

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
            $job->logger->info( _loc "Ignoring trap errors in rollback.  Aborting task", $err );
            _fail($err);
        }

        if( $mode eq 'ignore' ) {
            $job->logger->debug( _loc "Ignored error trapped in rule: %1", $err );    
            return;
        };

        $job->logger->error( _loc "Error trapped in rule: %1", $err );    
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

        event_new 'event.rule.trap' => { username=>'internal', stash=>$stash, output=>$err } => sub {} => sub{
            # catch and ignore
            my $err = shift;
            _warn( _loc('Could not store event for trapped error: %1', $err ) );
        }; 

        my $last_status = 'TRAPPED';
        my $timeout = $trap_timeout;

        LOOP:
        sleep 4;
        while( 1 ) {
            if ( $last_status eq 'TRAPPED_PAUSED' ) {
                sleep 5;
            } else {
                if ( !$trap_timeout || $trap_timeout eq '0' ) {
                    sleep 5;
                } else {
                    sleep 10;

                    # WE SLEEP HERE AT LEAST 14 SECONDS NO MATTER WHAT trap_timeout IS
                    $timeout = $timeout - 10;
                    if ( $timeout gt 0 ) {
                        $job->logger->warn( _loc("%1 seconds remaining to cancel trap with action %2", $timeout, $trap_timeout_action) );
                    } else {
                        $job->trap_action({ action => $trap_timeout_action, comments => _loc("Trap timeout expired.  Action configured: %1", $trap_timeout_action)});

                        # WHAT TO DO HERE?
                    }
                }
            }
            $last_status = $job->load->{status};
            if ( $last_status !~ /TRAPPED/ ) {
                last;
            }
        }

        if( $last_status eq 'RETRYING' ) {
            $job->logger->info( _loc "Retrying task", $err );    
            goto RETRY_TRAP;
        } elsif( $last_status eq 'SKIPPING' ) {
            $job->logger->info( _loc "Skipping task", $err );    
            return;
        } elsif( $last_status eq 'ERROR' ) { # ERROR
            $job->logger->info( _loc "Aborting task", $err );    
            _fail( $err );
        } else {
           goto LOOP; 
        }
    };
}

sub semaphore {
    my ($data, $stash)=@_;
    require Baseliner::Sem;
    parse_vars( $data, $stash );
    my $sem = Baseliner::Sem->new( $data );
    _info( _loc 'Semaphore queued for %1', $data->{key} );
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
    my ($stash,$id_rule, $rule_name, $name, $code)=@_;

    $name = parse_vars( $name, $stash );  # so we can have vars in task names

    $Baseliner::_rule_current_id = $id_rule;
    $Baseliner::_rule_current_name = $rule_name;

    $stash->{current_rule_id} = $id_rule;
    $stash->{current_rule_name} = $rule_name;
    $stash->{current_task_name} = $name;

    if( my $job = $stash->{job} ) {
        $job->start_task( $name );
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
    
    _fail _loc 'Could not find any paths in nature items that match cut path `%1`', $tail 
        unless ( @paths_write + @paths_del );
    return ( \@paths_write, \@paths_del );
}

# launch runs service, merge return into stash and returns what the service returns
sub launch {  
    my ($key, $task, $stash, $config, $data_key )=@_;
    
    $task = parse_vars( $task, $stash );

    my $reg = Baseliner::Core::Registry->get_instance( $key );
    _fail _loc "Cound not find '$key' in registry" unless $reg;

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

1;
