package Baseliner::Model::Rules;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;

BEGIN { extends 'Catalyst::Model' }

with 'Baseliner::Role::Service';

has tidy_up => qw(is rw isa Bool default 1);

register 'event.rule.failed' => {
    description => 'Rule failed',
    vars => ['dsl', 'rc', 'ret', 'rule', 'rule_name', 'stash', 'output']
};

register 'event.rule.trap' => {
    description => 'Rule error trapped',
    vars => ['stash', 'output']
};

sub init_job_tasks {
    my ($self)=@_;
    return map { +{ text=>$_, key=>'statement.step', icon=>'/static/images/icons/job.png', 
            children=>[], leaf=>\0, expanded=>\1 } 
    } qw(CHECK INIT PRE RUN POST);
}

sub parallel_run {
    my ($name, $mode, $stash, $code)= @_;
    my $job = $stash->{job};
     
    if( my $chi_pid = fork ) {
        # parent
        mdb->disconnect;    # will reconnect later
        _log _loc 'Forked child task %1 with pid %2', $name, $chi_pid; 
        if( $mode eq 'fork' ) {
            # fork and wait..
            $stash->{_forked_pids}{ $chi_pid } = $name;
        }
    } else {
        # child
        mdb->disconnect;    # will reconnect later
        my ( $ret, $err );
        try {
            $ret = $code->();
        }
        catch {
            $err = shift;
            _error( _loc( 'Detected error in child %1 (%2): %3', $$, $mode, $err ) );
        };
        if ( $mode eq 'fork' ) {
            # fork and wait.., communicate results to parent
            my $res = { ret => $ret, err => $err };
            queue->push( msg => "rule:child:results:$$", data => $res );
        }
        exit 0;    # cannot update stash, because it would override the parent run copy
    }
}

sub error_trap {
    my ($stash, $code)= @_;
    my $job = $stash->{job};
    RETRY_TRAP:
    try {
        $code->();
    } catch {
        my $err = shift;
        $job->logger->error( _loc "Error trapped in rule: %1", $err );    
        $job->status('TRAPPED');
        event_new 'event.rule.trap' => { username=>'internal', stash=>$stash, output=>$err } => sub {};
        $job->save;
        my $last_status;
        while( ($last_status = $job->load->{status} ) eq 'TRAPPED' ) {
            sleep 5;
        }
        if( $last_status eq 'RETRYING' ) {
            $job->logger->info( _loc "Retrying task", $err );    
            goto RETRY_TRAP;
        } 
        elsif( $last_status eq 'SKIPPING' ) {
            $job->logger->info( _loc "Skipping task", $err );    
            return;
        } else { # ERROR
            $job->logger->info( _loc "Aborting task", $err );    
            _fail( $err );
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

sub tree_format {
    my ($self, @tree_in)=@_;
    my @tree_out;
    for my $n ( @tree_in ) {
        my $chi = delete $n->{children};
        $n = $n->{attributes} if $n->{attributes};
        $chi = delete $n->{children} unless ref $chi eq 'ARRAY' && @$chi;
        delete $n->{attributes};
        delete $n->{disabled};
        delete $n->{id};
        $n->{active} //= 1;
        $n->{disabled} = $n->{active} ? \0 : \1;
        my @chi = $self->tree_format( _array($chi) );
        #$n->{children} = \@chi;
        if( @chi ) {
            $n->{children} = \@chi;
            $n->{leaf} = \0;
            $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
        } elsif( ! ${$n->{leaf} // \1} ) {  # may be a folder with no children
            $n->{children} = []; 
            $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
        }
        delete $n->{loader};  
        delete $n->{isTarget};  # otherwise you cannot drag-drop around a node
        #_log $n;
        push @tree_out, $n;
    }
    return @tree_out;
}

sub build_tree {
    my ($self, $id_rule, $parent, %p) = @_;
    # TODO run query just once and work with a hash ->hash_for( id_parent )
    my $rule = DB->BaliRule->find( $id_rule );
    my $rule_tree_json = $rule->rule_tree;
    if( $rule_tree_json ) {
        my $rule_tree = Util->_decode_json( $rule_tree_json );
        _fail _loc 'Invalid rule tree json data: not an array' unless ref $rule_tree eq 'ARRAY';
        return $self->tree_format( @$rule_tree );
        return @$rule_tree;
    } else {
        # no json rule_tree, look for legacy data
        my @tree;
        my @rows = DB->BaliRuleStatement->search( { id_rule => $id_rule, id_parent => $parent }, # XXX legacy, deprecated
            { order_by=>{ -asc=>'id' } } )->hashref->all;
        if( !defined $parent ) {
            my $rule_type = $rule->rule_type;
            if( !@rows && $rule_type eq 'chain' ) {
                push @tree, $self->init_job_tasks;
            }
        }
        for my $row ( @rows ) {
            my $n = { text=>$row->{stmt_text} };
            $row->{stmt_attr} = _load( $row->{stmt_attr} );
            $n = { active=>1, %$n, %{ $row->{stmt_attr} } } if length $row->{stmt_attr};
            delete $n->{disabled};
            delete $n->{id};
            $n->{active} //= 1;
            $n->{disabled} = $n->{active} ? \0 : \1;
            my @chi = $self->build_tree( $id_rule, $row->{id} );
            if(  @chi ) {
                $n->{children} = \@chi;
                $n->{leaf} = \0;
                $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
            } elsif( ! ${$n->{leaf} // \1} ) {  # may be a folder with no children
                $n->{children} = []; 
                $n->{expanded} = $n->{expanded} eq 'false' ? \0 : \1;
            }
            delete $n->{loader};  
            delete $n->{isTarget};  # otherwise you cannot drag-drop around a node
            #_log $n;
            push @tree, $n;
        }
        return @tree;
    }
}

sub _is_true { 
    my($self,$v) = @_; 
    return (ref $v eq 'SCALAR' && !${$v}) || $v eq 'false' || !$v;
}

sub dsl_build_and_test {
    my ($self,$stmts, %p )=@_;
    my $dsl = $self->dsl_build( $stmts, %p ); 
    my $stash = {};
    eval "sub{ $dsl }";
    die $@ if $@; 
    return $dsl;
}

sub dsl_build {
    my ($self,$stmts, %p )=@_;
    return '' if !$stmts || ( ref $stmts eq 'HASH' && !%$stmts );
    #_debug $stmts;
    my @dsl;
    require Data::Dumper;
    my $spaces = sub { '   ' x $_[0] };
    my $level = 0;
    my $stash = $p{stash};
    my $is_rollback = $stash->{rollback};
    local $Data::Dumper::Terse = 1;
    for my $s ( _array $stmts ) {
        local $p{no_tidy} = 1; # just one tidy is enough
        my $children = $s->{children} || {};
        my $attr = defined $s->{attributes} ? $s->{attributes} : $s;  # attributes is for a json treepanel
        # is active ?
        next if defined $attr->{active} && !$attr->{active}; 
        #next if (ref $attr->{disabled} eq 'SCALAR' && ${$attr->{disabled}} ) || $attr->{disabled} eq 'true' || $attr->{disabled};
        delete $attr->{loader} ; # node cruft
        delete $attr->{events} ; # node cruft
        #_debug $attr;
        my $name = _strip_html( $attr->{text} );
        my $name_id = Util->_name_to_id( $name );
        my $data = $attr->{data} || {};
        
        my $run_forward = _bool($attr->{run_forward},1);  # if !defined, default is true
        my $run_rollback = _bool($attr->{run_rollback},1); 
        my $error_trap = $attr->{error_trap} && $attr->{error_trap} eq 'trap';
        my $needs_rollback_mode = $data->{needs_rollback_mode} // 'none'; 
        my $needs_rollback_key  = $data->{needs_rollback_key} // $name_id;
        my $parallel_mode = length $attr->{parallel_mode} && $attr->{parallel_mode} ne 'none' ? $attr->{parallel_mode} : '';

        if( my $semaphore_key = $attr->{semaphore_key} ) {
            # consider using a hash: $stash->{_sem}{ $semaphore_key } = ...
            push @dsl, sprintf( 'local $stash->{_sem} = semaphore({ key=>q{%s}, who=>q{%s} }, $stash)->take;', $semaphore_key, $name ) . "\n"; 
        }
        my $timeout = $attr->{timeout};
        do{ _debug _loc("*Skipped* task %1 in run forward", $name); next; } if !$is_rollback && !$run_forward;
        do{ _debug _loc("*Skipped* task %1 in run rollback", $name); next; } if $is_rollback && !$run_rollback;
        my ($data_key) = $attr->{data_key} =~ /^\s*(\S+)\s*$/ if $attr->{data_key};
        my $closure = $attr->{closure};
        push @dsl, sprintf( '# task: %s', $name ) . "\n"; 
        if( $closure ) {
            push @dsl, sprintf( 'current_task($stash, q{%s}, sub{', $name )."\n";
        } elsif( ! $attr->{nested} ) {
            push @dsl, sprintf( 'current_task($stash, q{%s});', $name )."\n";
        }
        if( defined $timeout && $timeout > 0 ) {
            push @dsl, sprintf( 'alarm %s;', $timeout )."\n";
        }
        push @dsl, sprintf( '_debug(q{=====| Current Rule Task: %s} );', $name)."\n" if $p{verbose}; 
        if( length $attr->{key} ) {
            push @dsl, sprintf('$stash->{needs_rollback}{q{%s}} = 1;', $needs_rollback_key) if $needs_rollback_mode eq 'nb_always';
            push @dsl, sprintf('parallel_run(q{%s},q{%s},$stash,sub{', $name, $parallel_mode) if $parallel_mode;
            push @dsl, sprintf( 'error_trap($stash, sub {') if $error_trap; 
            my $key = $attr->{key};
            my $reg = Baseliner->registry->get( $key );
            if( $reg->isa( 'BaselinerX::Type::Service' ) ) {
                push @dsl, $spaces->($level) . '{';
                push @dsl, $spaces->($level) . sprintf(q{   my $config = parse_vars %s, $stash;}, Data::Dumper::Dumper( $data ) );
                push @dsl, $spaces->($level) . sprintf(q{   launch( "%s", q{%s}, $stash, $config => '%s' );}, $key, $name, $data_key );
                push @dsl, $spaces->($level) . '}';
                #push @dsl, $spaces->($level) . sprintf('merge_data($stash, $ret );', Data::Dumper::Dumper( $data ) );
            } else {
                push @dsl, _array( $reg->{dsl}->($self, { %$attr, %$data, children=>$children, data_key=>$data_key }, %p ) );
            }
            push @dsl, '});' if $error_trap; # current_task close
            push @dsl, '});' if $parallel_mode; # current_task close
            push @dsl, '});' if $closure; # current_task close
            push @dsl, sprintf( '$stash->{_sem}->release if $stash->{_sem};') if $attr->{semaphore_key};
        } else {
            _debug $s;
            _fail _loc 'Missing dsl/service key for node %1', $name;
        }
    }

    my $dsl = join "\n", @dsl;
    if( $self->tidy_up && !$p{no_tidy} ) {
        require Perl::Tidy;
        require Capture::Tiny;
        my $tidied = '';
        Capture::Tiny::capture(sub{
            Perl::Tidy::perltidy( argv => '--maximum-line-length=160 ', source => \$dsl, destination => \$tidied );
        });
        return $tidied;
    } else {
        return $dsl;
    }
}

sub wait_for_children {
    my ($self, $stash, %p ) = @_;
    if( my $chi_pids = $stash->{_forked_pids} ) {
        _info( _loc('Waiting for return code from children pids: %1', join(',',keys $chi_pids ) ) );
        my @failed;
        my @pids = keys $chi_pids;
        for my $pid ( keys $chi_pids ) {
            waitpid $pid, 0;
            delete $chi_pids->{$pid};
            if( my $res = queue->pop( msg=>"rule:child:results:$pid" ) ) {
                if( $res->{err} ) {
                    _error( $res->{err} );
                    push @failed, $pid;
                }
            }
        }
        if( @failed ) {
            _fail( _loc('Error detected in children: %1', join(',',@failed ) ) );
        } else {
            _info( _loc('Done waiting for return code from children pids: %1', join(',',@pids ) ) );
        }
    }
}

sub dsl_run {
    my ($self, %p ) = @_;
    my $dsl = $p{dsl};
    local $@;
    my $ret;
    my $stash = $p{stash} // {};
    
    local $SIG{ALRM} = sub { die "Timeout running rule\n" };
    alarm 0;
    
    merge_into_stash( $stash, BaselinerX::CI::variable->default_hash ); 
    ## local $Baseliner::Utils::caller_level = 3;
    ############################## EVAL DSL Tasks
    $ret = eval $dsl;
    my $err = $@;
    ##############################
    alarm 0;
    
    # wait for children to finish
    $self->wait_for_children( $stash );
    
    # reset log reporting to "Core"
    if( my $job = $stash->{job} ) {
        $job->back_to_core;
    }

    if( length $err ) {
        if( $p{simple_error} ) {
            _error( _loc("Error during DSL Execution: %1", $err) ) unless $p{simple_error} > 1;
            _fail $err;
        } else {
            _fail( _loc("Error during DSL Execution: %1", $err) );
        }
    }
    return $stash;
}

# used by events
sub run_rules {
    my ($self, %p) = @_;
    my $when = $p{when};
    local $Baseliner::_no_cache = 1;
    my @rules = 
        $p{id_rule} 
            ? ( +{ DB->BaliRule->find( $p{id_rule} )->get_columns } )
            : DB->BaliRule->search(
                { rule_event => $p{event}, rule_type => ($p{rule_type} // 'event'), rule_when => $when, rule_active => 1 },
                { order_by   => [          { -asc    => 'rule_seq' }, { -asc    => 'id' } ] }
              )->hashref->all;
    my $stash = $p{stash};
    my @rule_log;
    local $ENV{BASELINER_LOGCOLOR} = 0;
    
    my $mid = $stash->{mid} if $stash;
    my $sem;
    if( defined $mid && @rules ) {
        require Baseliner::Sem;
        $sem = Baseliner::Sem->new( key=>'event:'.$stash->{mid}, who=>"rules:$when", internal=>1 );
        $sem->take;
    }

    for my $rule ( @rules ) {
        my ($runner_output, $rc, $dsl, $ret,$err);
        try {
            my @tree = $self->build_tree( $rule->{id}, undef );
            $dsl = try {
                $self->dsl_build( \@tree, %p ); 
            } catch {
                _fail( _loc("Error building DSL for rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
            };
            ################### RUN THE RULE DSL ######################
            require Capture::Tiny;
            ($runner_output) = Capture::Tiny::tee_merged(sub{
                try {
                    $ret = $self->dsl_run( dsl=>$dsl, stash=>$stash, simple_error=>$p{simple_error} );
                } catch {
                    $err = shift // _loc('Unknown error running rule: %1', $rule->{id} ); 
                };
            });
            # report controlled errors
            if( $err ) {
                if ( $rule->{rule_when} !~ /online/ ) {
                    event_new 'event.rule.failed' => { username => 'internal', dsl => $dsl, rule => $rule->{id}, rule_name => $rule->{rule_name}, stash => $stash, output => $runner_output } => sub {};
                }           
                if( $p{simple_error} ) {
                    _error( _loc("Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, $err ) ) unless $p{simple_error} > 1; 
                    _fail $err; 
                } else {
                    _fail( _loc("Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, $err ) ); 
                }
            }
        } catch {
            my $err_global = shift;
            $rc = 1;
            if( ref $p{onerror} eq 'CODE') {
                if ( $rule->{rule_when} !~ /online/ ) {
                    event_new 'event.rule.failed' => { username => 'internal', dsl => $dsl, rc => $rc, ret => $ret, rule => $rule->{id}, rule_name => $rule->{rule_name}, stash => $stash, output => $runner_output } => sub {};
                }
                $p{onerror}->( { err=>$err_global, ret=>$ret, id=>$rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc } );
            } elsif( ! $p{onerror} ) {
                _fail $err_global;
            }
        };
        push @rule_log, { ret=>$ret, id => $rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc };
    }
    if( $sem ) {
        $sem->release;
    }
    return { stash=>$stash, rule_log=>\@rule_log }; 
}

# used by job_chain
sub run_single_rule {
    my ($self, %p ) = @_;
    local $Baseliner::_no_cache = 1;
    $p{stash} //= {};
    my $rule = DB->BaliRule->find( $p{id_rule} );
    _fail _loc 'Rule with id `%1` not found', $p{id_rule} unless $rule;
    my @tree = $self->build_tree( $p{id_rule}, undef );
    #local $self->{tidy_up} = 0;
    my $dsl = try {
        $self->dsl_build( \@tree, no_tidy=>0, %p ); 
    } catch {
        _fail( _loc("Error building DSL for rule '%1' (%2): %3", $rule->rule_name, $rule->rule_when, shift() ) ); 
    };
    my $ret = try {
        ################### RUN THE RULE DSL ######################
        $self->dsl_run( dsl=>$dsl, stash=>$p{stash}, %p );
        _debug "DSL:\n",  $self->dsl_listing( $dsl ) if $p{logging};
    } catch {
        _debug "DSL:\n",  $self->dsl_listing( $dsl );
        _fail( _loc("Error running rule '%1': %2", $rule->rule_name, shift() ) ); 
    };
    return { ret=>$ret, dsl=>$dsl };
}

sub dsl_listing {
    my ($self,$dsl)=@_;
    my $lin = 1;
    return join '', map { $lin++.": ".$_."\n" } split /\n/, $dsl;
}

######################################## GLOBAL SUBS

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
    my ($stash,$name, $code)=@_;
    $name = parse_vars( $name, $stash );  # so we can have vars in task names
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
    my $reg = Baseliner->registry->get( $key );
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
        $cs = ci->new( $cs ) unless ref $cs;
        for my $project ( $cs->related( does=>'Project' ) ) {
            $projects{ $project->mid } = $project;
        }
    }
    #my $project = ci->new( 6901 );  # TEF
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
    +{ %$vars_common_bl, %$vars_for_bl };
}

############################## STATEMENTS

register 'statement.if.var' => {
    text => 'IF var THEN',
    type => 'if',
    form => '/forms/variable_value.js',
    data => { variable=>'', value=>'' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( $stash->{'%s'} eq '%s' ) {
                %s
            }
            
        }, $n->{variable}, $n->{value} , $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if_not.var' => {
    text => 'IF var ne value THEN',
    type => 'if',
    form => '/forms/variable_value.js',
    data => { variable=>'', value=>'' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( $stash->{'%s'} ne '%s' ) {
                %s
            }
            
        }, $n->{variable}, $n->{value} , $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if.condition' => {
    text => 'IF condition THEN',
    type => 'if',
    data => { condition =>'1' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( %s ) {
                %s
            }
            
        }, $n->{condition}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if.else' => {
    text => 'ELSE',
    type => 'if',
    nested => 1,   # avoids a "current_task" before
    data => {},
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            else {
                %s
            }
            
        }, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if.elsif' => {
    text => 'ELSIF condition THEN',
    type => 'if',
    nested => 1,
    data => { condition =>'1' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            elsif( %s ) {
                %s
            }
            
        }, $n->{condition}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if.var.list' => {
    text => 'IF var in LIST THEN',
    type => 'if',
    form => '/forms/variable_values.js',
    data => { variable=>'', values=>'' },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        my @conditions;
        my $complete_condition;
        my @values = split /,/,$n->{values};

        for ( @values ) {
            push @conditions, sprintf(q{$stash->{'%s'} eq '%s'},$n->{variable},$_);
        }
        $complete_condition = join " || ", @conditions;

        sprintf(q/
            if( %s ) {
                %s
            }
    
        /, $complete_condition, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.try' => {
    text => 'TRY statement', 
    type => 'if',
    data => { },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            try {
                %s
            };
            
        }, $self->dsl_build( $n->{children}, %p) );
    },
};

register 'statement.let.merge' => {
    text => 'MERGE value INTO stash', 
    type => 'let',
    holds_children => 0, 
    data => { value=>{} },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
           merge_data( $stash, %s );
        }, Data::Dumper::Dumper($n->{value}), $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.delete.key' => {
    text => 'DELETE hashkey', 
    type => 'if',
    holds_children => 0, 
    data => { key=>'' },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
           delete $stash->{ '%s' } ;
        }, $n->{key}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.parallel.wait' => {
    text => 'WAIT for children',
    data => { variable=>'stash_var', local_var=>'value' },
    icon => '/static/images/icons/time.png',
    holds_children => 0, 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            $self->wait_for_children( $stash );
        });
    },
};

register 'statement.foreach' => {
    text => 'FOREACH stash[ variable ]',
    type => 'loop',
    data => { variable=>'stash_var', local_var=>'value' },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            foreach my $item ( _array( $stash->{'%s'} ) ) {
                local $stash->{'%s'} = $item;
                %s
            }
            
        }, $n->{variable}, $n->{local_var} // 'value', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.foreach.ci' => {
    text => 'FOREACH CI',
    type => 'loop',
    data => { variable=>'stash_var', local_var=>'value' },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            foreach my $ci ( map { ci->new($_) } Util->_array_or_commas( $stash->{'%s'} ) ) {
                local $stash->{'%s'} = $ci;
                %s
            }
            
        }, $n->{variable}, $n->{local_var} // 'value', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.foreach.split' => {
    text => 'FOREACH SPLIT /re/', 
    type => 'loop',
    data => { split=>',', variable=>'stash_var', local_var=>'value' },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            foreach my $item ( split _regex('%s'), $stash->{'%s'} ) {
                local $stash->{'%s'} = $item;
                %s
            }
            
        }, $n->{split} // ',', $n->{variable}, $n->{local_var} // 'value', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.step' => {
    text => 'JOB STEP',
    description=> 'a job step section: PRE,RUN,POST...',
    icon => '/static/images/icons/job.png',
    dsl=>sub{
        my ($self, $n, %p ) = @_;
        sprintf(q{
            if( $stash->{job_step} eq q{%s} ) {
                %s
            }
        }, $n->{text}, $self->dsl_build( $n->{children}, %p ) );
    }
};

register 'statement.fail' => {
    text => 'FAIL',
    data => { msg => 'abort here' },
    icon => '/static/images/icons/delete.gif',
    dsl=>sub{
        my ($self, $n, %p ) = @_;
        sprintf(q{
            Util->_fail( q{%s} );
        }, $n->{msg}, $self->dsl_build( $n->{children}, %p ) );
    }
};

register 'service.echo' => {
    data => { msg => '', args=>{}, arr=>[] },
    handler=>sub{
        my ($self, $c, $data ) = @_;
        $data->{hello} = $data->{msg} || 'world';
        _log _loc "Loggin echo: %1", $data->{hello};
        $data;
    }
};

register 'service.fail' => {
    data => { msg => 'dummy fail' },
    handler=>sub{
        my ($self, $c, $data ) = @_;
        Baseliner::Utils::_fail( $data->{msg} || 'dummy fail' );
    }
};

register 'event.rule.tester' => {
    text => '%1 posted a comment on %2: %3',
    description => 'Dummy Event to Test a Rule',
    vars => ['hello'],
};

register 'statement.var.set' => {
    text => 'SET VAR', data => {},
    type => 'let',
    holds_children => 0, 
    form => '/forms/set_var.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            $stash->{'%s'} = parse_vars( q{%s}, $stash ); 
        }, $n->{variable}, $n->{value}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.var.set_to_ci' => {
    text => 'SET VAR to CI', data => {},
    type => 'let',
    holds_children => 0, 
    data => { variable=>'my_varname', from_code=>'', prepend=>'' },
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            $stash->{'%s'} = ci->new( '%s' . parse_vars( %s, $stash ) ); 
        }, $n->{variable}, $n->{prepend}, $n->{from_code} || sprintf(q{$stash->{'%s'}},$n->{variable}) );
    },
};

register 'statement.nature.block' => {
    text => 'APPLY NATURE', data => { nature=>'' },
    type => 'loop',
    form => '/forms/nature_block.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                # check if nature applies 
                my $nature = ci->new( '%s' );
                if( my $nature_items = stash_has_nature( $nature, $stash) ) {
                    # load natures config
                    my $variables = $nature->variables->{ $stash->{bl} // '*' } // {};
                    merge_data $variables, $stash, variables_for_bl( $nature, $stash->{bl} ), { _ctx => 'nature' }; 
                    $stash->{nature_items} = $nature_items;
                    
                    %s
                }
            }
        }, $n->{nature}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.stash.local' => {
    text => 'STASH LOCAL', data => {},
    type => 'loop',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                local $stash = { %$stash };
                
                %s    
            }
        }, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.project.block' => {
    text => 'APPLY PROJECT', data => { project=>'' },
    type => 'loop',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                my $project = '%s';
                my $variables = $stash->{$project}->variables->{ $stash->{bl} // '*' } // {};
                merge_data $stash, $variables, { _ctx => 'apply_variables' }; 
                
                %s    
            }
        }, $n->{project} // 'project', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.perl.eval' => {
    text => 'EVAL', data => { code=>'' },
    form => '/forms/stmt_eval.js', 
    icon => '/static/images/icons/cog.png', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                $stash->{'%s'} = eval { %s };
                if($@) {
                    _fail "ERROR in EVAL: $@";
                }
            }
        }, $n->{data_key}, $n->{code} // '', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.perl.do' => {
    text => 'DO', data => { code=>'' },
    icon => '/static/images/icons/cog.png', 
    form => '/forms/stmt_eval.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                my $dk = '%s';
                my $ret = do { %s };
                $stash->{$dk} = $ret if length $dk;
            }
        }, $n->{data_key} // '', $n->{code} // '', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.perl.for' => {
    text => 'FOR eval', data => { varname=>'x', code=>'()' },
    type => 'loop',
    icon => '/static/images/icons/cog.png', 
    form => '/forms/stmt_for.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            for( %s ) {
                local $stash->{'%s'} = $_;
                %s;
            }
        }, $n->{code} // '()', $n->{varname} // 'x',  $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.js.code' => {
    text => 'EVAL JavaScript', data => { code=>'' },
    type => 'loop',
    icon => '/static/images/icons/javascript.png', 
    form => '/forms/stmt_for.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            require JE;
            my $je = JE->new;
            my $jstash = Util->_clone($stash);
            Util->_unbless($jstash);
            $je->new_function( stash => sub { defined $_[1] ? $jstash->{$_[0]} = $_[1]->value : $jstash->{$_[0]} } );
            $je->eval(q{%s});
            do { $stash->{$_} = $jstash->{$_} if !exists $stash->{$_} } for keys $jstash;
        }, $n->{code} // '()',  $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.perl.code' => {
    text => 'CODE', data => { code=>'' },
    type => 'loop',
    icon => '/static/images/icons/cog.png',
    holds_children => 0,
    form => '/forms/stmt_eval.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            %s;
        }, $n->{code} // '' );
    },
};

register 'statement.project.loop' => {
    text => 'FOR projects with changes DO', data => { },
    type => 'loop',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            for my $project ( project_changes( $stash ) ) { 
                $stash->{project} = $project->name;
                $stash->{project_mid} = $project->mid;
                $stash->{project_lc} = lc $project->name;
                $stash->{project_uc} = uc $project->name;
                my $vars = variables_for_bl( $project, $stash->{bl} );
                $stash->{job}->logger->info( _loc('Current project *%1* (%2)', $project->name, $stash->{bl} ), $vars );

                merge_data $stash, $vars, { _ctx => 'project_loop' }; 
                
                %s
            }
        }, $self->dsl_build( $n->{children}, %p ) );
    },
};

# needs the changeset.nature service to fill the stash with natures (create a dependency check?)
register 'statement.if.nature' => {
    text => 'IF EXISTS nature THEN',
    form => '/forms/if_nature.js',
    type => 'if',
    data => { nature=>'', },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        my ($nature) = _array($n->{nature});  # in case we accidently get an array of natures
        sprintf(q{
            if( my $nature = $stash->{natures}{'%s'} ) {
                NAT: {  
                    $stash->{current_nature} = $nature;
                    local $stash->{nature_items} = $stash->{project_items}{ $project->mid }{natures}{ $nature->mid };
                    last NAT if !_array( $stash->{nature_items} );
                    my ($nat_paths, $nat_paths_del) = cut_nature_items( $stash, parse_vars(q{%s},$stash) );
                    local $stash->{ nature_item_paths } = $nat_paths;
                    local $stash->{ nature_item_paths_del } = $nat_paths_del;
                    local $stash->{ nature_items_comma } = join(',', @$nat_paths );
                    local $stash->{ nature_items_quote } = "'" . join("' '", @$nat_paths ) . "'";
                    $stash->{job}->logger->info( _loc('Nature Detected *%1*', $nature->name ), 
                        +{ map { $_=>$stash->{$_} } qw/nature_items nature_item_paths nature_items_comma nature_items_quote/ } );

                    %s
                };
            }
        }, $nature, $n->{cut_path} , $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.if.any_nature' => {
    text => 'IF ANY nature THEN',
    form => '/forms/if_any_nature.js',
    type => 'if',
    data => { natures=>'', },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( _any { exists $stash->{natures}{$_} } split /,/, '%s' ) {
                %s
            }
        }, join(',',_array($n->{natures})), $self->dsl_build( $n->{children}, %p ) );
    },
};


register 'statement.if.rollback' => {
    text => 'IF ROLLBACK',
    type => 'if',
    data => { rollback=>'1', },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( $stash->{rollback} eq '%s' ) {
                %s
            }
        }, $n->{rollback}, $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.include' => {
    text => 'INCLUDE rule',
    icon => '/static/images/icons/cog.png', 
    data => { id_rule=>'', },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        my $dsl = $self->include_rule( $n->{id_rule}, %p );
        sprintf(q{
                %s;
        }, $dsl );
    },
};

sub include_rule {
    my ($self, $id_rule, %p) = @_;
    my @tree = $self->build_tree( $id_rule, undef );
    my $dsl = try {
        $self->dsl_build( \@tree, %p ); 
    } catch {
        _fail( _loc("Error building DSL for rule '%1': %2", $id_rule, shift() ) ); 
    };
    return $dsl;
}

1;
