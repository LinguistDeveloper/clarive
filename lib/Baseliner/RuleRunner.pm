package Baseliner::RuleRunner;
use Moose;

use Time::HiRes ();
use Try::Tiny;
use Capture::Tiny qw(tee_merged);
use Baseliner::Sugar;
use Baseliner::Sem;
use BaselinerX::CI::variable;
use Baseliner::Utils qw(_fail _loc _debug _error);
use Baseliner::Model::Rules;

has tidy_up => qw(is ro), default => sub { 1 };

sub run_rules {
    my $self = shift;
    my (%p) = @_;

    local $Baseliner::_no_cache = 0;
    local $ENV{BASELINER_LOGCOLOR} = 0;

    my $when         = $p{when};
    my $stash        = $p{stash} // {};
    my $event        = $p{event};
    my $rule_type    = $p{rule_type} // 'event';
    my $onerror      = $p{onerror};
    my $simple_error = $p{simple_error};

    my @rules =
        $p{id_rule}
      ? $self->_find_rule_by_id_or_name( $p{id_rule} )
      : mdb->rule->find(
        {
            rule_event  => $event,
            rule_type   => $rule_type,
            rule_when   => $when,
            rule_active => mdb->true
        }
      )->sort( mdb->ixhash( rule_seq => 1, id => 1 ) )->all;

    my $mid = $stash->{mid};
    my $sem;
    if ( defined $mid && @rules && $p{use_semaphore} ) {
        $sem = Baseliner::Sem->new( key => 'event:' . $mid, who => "rules:$when", internal => 1 );
        $sem->take;
    }

    my @rule_log;

    $stash->{rules_exec}{$event}{$when} = 0;
    for my $rule (@rules) {
        $stash->{rules_exec}{$event}{$when}++;
        my ( $runner_output, $rc, $ret, $err );
        my $id_rule = $rule->{id};
        try {
            ($runner_output) = tee_merged(
                sub {
                    try {
                        $ret = $self->dsl_run( id_rule => $id_rule, stash => $stash, simple_error => $simple_error );
                    }
                    catch {
                        $err = shift // _loc( 'Unknown error running rule: %1', $id_rule );
                    };
                }
            );

            # report controlled errors
            if ($err) {
                if ( $rule->{rule_when} !~ /online/ ) {
                    event_new 'event.rule.failed' => {
                        username  => 'internal',
                        dsl       => $ret->{dsl},
                        rule      => $id_rule,
                        rule_name => $rule->{rule_name},
                        stash     => $stash,
                        output    => $runner_output
                    } => sub { };
                }
                if ($simple_error) {
                    _error( _loc( "Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, $err ) )
                      unless $simple_error > 1;
                    _fail $err;
                }
                else {
                    _fail( _loc( "Error running rule '%1' (%2): %3", $rule->{rule_name}, $rule->{rule_when}, $err ) );
                }
            }
        }
        catch {
            my $err_global = shift;
            $rc = 1;
            if ( ref $onerror eq 'CODE' ) {
                if ( $rule->{rule_when} !~ /online/ ) {
                    event_new 'event.rule.failed' => {
                        username  => 'internal',
                        dsl       => $ret->{dsl},
                        rc        => $rc,
                        ret       => $ret->{stash},
                        rule      => $id_rule,
                        rule_name => $rule->{rule_name},
                        stash     => $stash,
                        output    => $runner_output
                    } => sub { };
                }
                $onerror->(
                    {
                        err    => $err_global,
                        ret    => $ret->{stash},
                        id     => $id_rule,
                        dsl    => $ret->{dsl},
                        stash  => $stash,
                        output => $runner_output,
                        rc     => $rc
                    }
                );
            }
            elsif ( !$onerror ) {
                _fail "(rule $id_rule): " . $err_global;
            }
        };
        push @rule_log,
          {
            ret    => $ret->{stash},
            id     => $id_rule,
            dsl    => $ret->{dsl},
            stash  => $stash,
            output => $runner_output,
            rc     => $rc
          };
    }

    if ($sem) {
        $sem->release;
    }

    return { stash => $stash, rule_log => \@rule_log };
}

sub run_single_rule {
    my ( $self, %p ) = @_;

    local $Baseliner::_no_cache = 0;

    my $id_rule = $p{id_rule} or _fail 'id_rule required';
    my $stash = $p{stash} // {};

    my $rule = $self->_find_rule_by_id_or_name($id_rule);
    _fail _loc 'Rule with id `%1` not found', $id_rule unless $rule;

    my $rules_model = Baseliner::Model::Rules->new;
    my @tree = $rules_model->build_tree( $rule->{id}, undef );

    my $ret = try {
        $self->dsl_run( id_rule => $rule->{id}, stash => $stash, %p );
    }
    catch {
        _fail( _loc( "Error running rule '%1': %2", $rule->{rule_name}, shift() ) );
    };

    return { ret => $ret, dsl => '' };
}

sub run_dsl {
    my $self = shift;
    my (%params) = @_;

    my $dsl = $params{dsl} or _fail 'dsl required';
    my $stash = $params{stash} // {};

    my $default_vars = BaselinerX::CI::variable->default_hash;
    foreach my $default_var ( keys %$default_vars ) {
        $stash->{$default_var} = $default_vars->{$default_var}
          unless exists $stash->{$default_var};
    }

    my $rule = Baseliner::CompiledRule->new( dsl => $dsl );
    $rule->compile;

    local $Baseliner::no_log_color = 1;
    my ($output) = tee_merged( sub { $rule->run( stash => $stash ) } );

    if ( my $err = $rule->errors ) {
        _fail $err;
    }

    return { output => $output };
}

sub dsl_build_and_test {
    my ($self,$stmts, %p )=@_;

    my $rules_model = Baseliner::Model::Rules->new;

    my $dsl = $rules_model->dsl_build( $stmts, id_rule=>$p{id_rule}, %p ); 

    my $rule = Baseliner::CompiledRule->new( id_rule=>$p{id_rule}, dsl=>$dsl, ts=>$p{ts} ); # send ts so its stored as this rule save timestamp
    $rule->compile;

    die $rule->errors if $rule->errors;

    return $dsl;
}

sub dsl_run {
    my ( $self, %p ) = @_;
    my $id_rule = $p{id_rule};
    local $@;
    my $ret;
    my $stash = $p{stash} // {};

    merge_into_stash( $stash, BaselinerX::CI::variable->default_hash );

    ## local $Baseliner::Utils::caller_level = 3;
    ############################## EVAL DSL Tasks
    my $rule = Baseliner::CompiledRule->new( ( $id_rule ? ( id_rule => $id_rule ) : () ), dsl => $p{dsl} );
    $rule->compile;
    $rule->run( stash => $stash );    # if there's a compile error it wont run
    ##############################

    my $rules_model = Baseliner::Model::Rules->new;

    if ( my $err = $rule->errors ) {
        if ( $p{simple_error} ) {
            _error( _loc( "Error during DSL Execution: %1", $err ) ) unless $p{simple_error} > 1;
            _fail $err;
        }
        else {
            _fail( _loc( "Error during DSL Execution: %1", $err ) );
        }
        _debug "DSL:\n", $rules_model->dsl_listing( $rule->dsl );
    }
    else {
        _debug "DSL:\n", $rules_model->dsl_listing( $rule->dsl ) if $p{logging};
    }
    return {
        stash => $stash,
        dsl   => ( $rule->dsl || $rule->package )
    };    # TODO storing dsl everywhere maybe a waste of space
}

sub merge_into_stash {
    my ( $stash, $data ) = @_;
    return unless ref $data eq 'HASH';
    while ( my ( $k, $v ) = each %$data ) {
        $stash->{$k} = $v;
    }
    return $stash;
}

sub _find_rule_by_id_or_name {
    my $self = shift;
    my ($param) = @_;

    return mdb->rule->find_one( { '$or' => [ { id => "$param" }, { rule_name => "$param" } ] } );
}

1;
