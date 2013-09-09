package Baseliner::Model::Rules;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;
BEGIN { extends 'Catalyst::Model' }

with 'Baseliner::Role::Service';

has tidy_up => qw(is rw isa Bool default 1);

sub build_tree {
    my ($self, $id_rule, $parent, %p) = @_;
    my @tree;
    # TODO run query just once and work with a hash ->hash_for( id_parent )
    my @rows = DB->BaliRuleStatement->search( { id_rule => $id_rule, id_parent => $parent },
        { order_by=>{ -asc=>'id' } } )->hashref->all;
    if( !defined $parent ) {
        my $rule = DB->BaliRule->find( $id_rule );
        my $rule_type = $rule->rule_type;
        if( !@rows && $rule_type eq 'chain' ) {
            push @tree, { text=>$_, key=>'statement.step', icon=>'/static/images/icons/job.png', 
                    children=>[], leaf=>\0, expanded=>\1 } 
                for qw(CHECK INIT PRE RUN POST);
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
            $n->{expanded} = \1;
        } elsif( ! ${$n->{leaf} // \1} ) {  # may be a folder with no children
            $n->{children} = []; 
            $n->{expanded} = \1;
        }
        delete $n->{loader};  
        delete $n->{isTarget};  # otherwise you cannot drag-drop around a node
        #_log $n;
        push @tree, $n;
    }
    return @tree;
}

sub _is_true { 
    my($self,$v) = @_; 
    return (ref $v eq 'SCALAR' && !${$v}) || $v eq 'false' || !$v;
}

sub dsl_build {
    my ($self,$stmts, %p )=@_;
    #_debug $stmts;
    my @dsl = (
        #'my $stash = {};',
        #'my $ret;',
    );
    require Data::Dumper;
    my $spaces = sub { '   ' x $_[0] };
    my $level = 0;
    local $Data::Dumper::Terse = 1;
    for my $s ( _array $stmts ) {
        #_debug( $s );
        my $children = $s->{children} || {};
        my $attr = defined $s->{attributes} ? $s->{attributes} : $s;  # attributes is for a json treepanel
        # is active ?
        next if defined $attr->{active} && !$attr->{active}; 
        #next if (ref $attr->{disabled} eq 'SCALAR' && ${$attr->{disabled}} ) || $attr->{disabled} eq 'true' || $attr->{disabled};
        delete $attr->{loader} ; # node cruft
        delete $attr->{events} ; # node cruft
        #_debug $attr;
        my $name = _strip_html( $attr->{text} );
        my $data_key = length $attr->{data_key} ? $attr->{data_key} : _name_to_id( $name );
        push @dsl, sprintf( '# statement: %s', $name ) . "\n"; 
        push @dsl, sprintf( '_debug(q{Current Rule Statement: %s} );', $name)."\n" if $p{logging}; 
        my $data = $attr->{data} || {};
        if( length $attr->{key} ) {
            my $key = $attr->{key};
            my $reg = Baseliner->registry->get( $key );
            if( $reg->isa( 'BaselinerX::Type::Service' ) ) {
                push @dsl, $spaces->($level) . sprintf(q{my $config = parse_vars %s, $stash;}, Data::Dumper::Dumper( $data ) );
                push @dsl, $spaces->($level) . sprintf(q{launch( "%s", $stash, $config => '%s' );}, $key, $data_key );
                #push @dsl, $spaces->($level) . sprintf('merge_data($stash, $ret );', Data::Dumper::Dumper( $data ) );
            } else {
                push @dsl, _array( $reg->{dsl}->($self, { %$attr, %$data, children=>$children, data_key=>$data_key }, %p ) );
            }
        } else {
            _fail _loc 'Missing dsl/service key for node %1', $name;
        }
    }
    #push @dsl, sprintf '$stash;';

    my $dsl = join "\n", @dsl;
    if( $self->tidy_up && !$p{no_tidy} ) {
        require Perl::Tidy;
        require Capture::Tiny;
        my $tidied = '';
        Capture::Tiny::capture(sub{
            Perl::Tidy::perltidy( argv => ' ', source => \$dsl, destination => \$tidied );
        });
        return $tidied;
    } else {
        return $dsl;
    }
}

sub dsl_run {
    my ($self, %p ) = @_;
    my $dsl = $p{dsl};
    local $@;
    my $ret;
    our $stash = $p{stash} // {};
    
    ############################## EVAL DSL STATEMENTS
    $ret = eval $dsl;
    ##############################

    _fail( _loc("Error during DSL Execution: %1", $@) ) if $@;
    return $stash;
}

sub run_rules {
    my ($self, %p) = @_;
    local $Baseliner::_no_cache = 1;
    my @rules = 
        $p{id_rule} 
            ? ( +{ DB->find( $p{id_rule} )->get_columns } )
            : DB->BaliRule->search(
                { rule_event => $p{event}, rule_type => ($p{rule_type} // 'event'), rule_when => $p{when} },
                { order_by   => [          { -asc    => 'rule_seq' }, { -asc    => 'id' } ] }
              )->hashref->all;
    my $stash = $p{stash};
    my @rule_log;
    for my $rule ( @rules ) {
        my ($runner_output, $rc, $dsl, $ret);
        try {
            my @tree = $self->build_tree( $rule->{id}, undef );
            $dsl = try {
                $self->dsl_build( \@tree, %p ); 
            } catch {
                _fail( _loc("Error building DSL for rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
            };
            $ret = try {
                ################### RUN THE RULE DSL ######################
                IO::CaptureOutput::capture( sub {
                    $self->dsl_run( dsl=>$dsl, stash=>$stash );
                }, \$runner_output, \$runner_output );
            } catch {
                _fail( _loc("Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
            };
        } catch {
            my $err = shift;
            $rc = 1;
            if( ref $p{onerror} eq 'CODE') {
                $p{onerror}->( { err=>$err, ret=>$ret, id=>$rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc } );
            } elsif( ! $p{onerror} ) {
                _fail $err;
            }
        };
        push @rule_log, { ret=>$ret, id => $rule->{id}, dsl=>$dsl, stash=>$stash, output=>$runner_output, rc=>$rc };
    }
    return { stash=>$stash, rule_log=>\@rule_log }; 
}

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
        _fail( _loc("Error building DSL for rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, shift() ) ); 
    };
    my $ret = try {
        ################### RUN THE RULE DSL ######################
        $self->dsl_run( dsl=>$dsl, stash=>$p{stash}, %p );
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

# launch runs service, merge return into stash and returns what the service returns
sub launch {  
    my ($key, $stash, $config, $data_key )=@_;
    
    #my $ret = Baseliner->launch( $key, data=>$stash );  # comes with a dummy job
    my $reg = Baseliner->registry->get( $key );
    my $return_data = $reg->run_container( $stash, $config ); 
    # TODO milestone for service
    #_debug $ret;
    my $refr = ref $return_data;
    $return_data = $refr eq 'HASH' || Scalar::Util::blessed($return_data) 
        ? $return_data 
        : {}; #!$refr || $refr eq 'ARRAY' ? { service_return=>$return_data } : {} ;
    # merge into stash
    merge_into_stash( $stash, ( length $data_key ? { $data_key => $return_data } : $return_data ) );
    return $return_data;
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
    $nature = _ci( $nature ) unless ref $nature;
    my $nature_items = $nature->filter_items( items=>$stash->{items} ); # save => 1 ??  
    return $nature_items; 
}

sub changeset_projects {
    my $stash = shift;
    # for each changeset, get project and group changesets
    my %projects;
    for my $cs ( _array( $stash->{changesets} ) ) {
        $cs = _ci( $cs ) unless ref $cs;
        for my $project ( $cs->related( does=>'Project' ) ) {
            $projects{ $project->mid } = $project;
        }
    }
    #my $project = _ci( 6901 );  # TEF
    return values %projects;
}

#sub project_changed {
#    my $stash = shift;
#    # for each changeset, get project and group changesets
#    my %projects;
#    for my $project ( _array( $stash->{project_changes} ) ) {
#        $cs = _ci( $cs ) unless ref $cs;
#        for my $project ( $cs->related( does=>'Project' ) ) {
#            $projects{ $project->mid } = $project;
#        }
#    }
#    #my $project = _ci( 6901 );  # TEF
#    return values %projects;
#}

sub variables_for_bl {
    my ($ci, $bl) = @_; 
    my $vars = $ci->variables // { _no_vars=>1 }; 
    $vars->{ $bl // '*' } // { _no_vars_for_bl=>1 };
}

############################## STATEMENTS

register 'statement.if.var' => {
    text => 'IF var THEN',
    type => 'if',
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

register 'statement.let.key_value' => {
    text => 'LET key => value', 
    type => 'let',
    holds_children => 0, 
    data => { key=>'', value=>'' },
    dsl => sub { 
        my ($self, $n, %p) = @_;
        sprintf(q{
           $stash->{ '%s' } = '%s';
        }, $n->{key}, $n->{value}, $self->dsl_build( $n->{children}, %p ) );
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

register 'statement.foreach' => {
    text => 'FOREACH stash[ variable ]', type => 'for', data => { variable=>'' },
    type => 'loop',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            foreach my $item ( _array( $stash->{'%s'} ) ) {
                %s
            }
            
        }, $n->{variable}, $self->dsl_build( $n->{children}, %p ) );
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

register 'statement.nature.block' => {
    text => 'APPLY NATURE', data => { nature=>'' },
    type => 'loop',
    form => '/forms/nature_block.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                # check if nature applies 
                my $nature = _ci( '%s' );
                if( stash_has_nature( $nature, $stash) ) {
                    # load natures config
                    my $variables = $nature->variables->{ $stash->{bl} // '*' } // {};
                    merge_data $variables, $stash, variables_for_bl( $nature, $stash->{bl} ), { _ctx => 'nature' }; 
                    
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
    type => 'loop',
    form => '/forms/stmt_eval.js', 
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            {
                $stash->{'%s'} = eval %s;
                if($@) {
                    _error $@;
                }
            }
        }, $n->{data_key}, $n->{code} // '', $self->dsl_build( $n->{children}, %p ) );
    },
};

register 'statement.project.loop' => {
    text => 'FOR projects with changes DO', data => { },
    type => 'loop',
    dsl => sub { 
        my ($self, $n, %p ) = @_;
        sprintf(q{
            for my $project ( map { _ci($_->{project}->mid) } _array( $stash->{project_changes} ) ) {
                $stash->{project} = $project->name;
                my $vars = variables_for_bl( $project, $stash->{bl} );
                $stash->{job}->logger->info( _loc('Current project *%1* (%2)', $project->name, $stash->{bl} ), $vars );

                merge_data $stash, $vars, { _ctx => 'project_loop' }; 
                
                %s
            }
        }, $self->dsl_build( $n->{children}, %p ) );
    },
};

# needs the changeset.nature service to fill the stash with natures
register 'statement.if.nature' => {
    text => 'IF EXISTS nature THEN',
    form => '/forms/if_nature.js',
    type => 'if',
    data => { nature=>'', },
    dsl => sub { 
        my ($self, $n , %p) = @_;
        sprintf(q{
            if( my $nature = $stash->{natures}{'%s'} ) {
                $stash->{current_nature} = $nature;
                $stash->{job}->logger->info( _loc('Nature Detected *%1*', $nature->name ) );

                %s
            }
        }, $n->{nature} , $self->dsl_build( $n->{children}, %p ) );
    },
};

1;
