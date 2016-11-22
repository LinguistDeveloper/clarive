package Baseliner::RuleRunner;
use Baseliner::Moose;

use Time::HiRes ();
use Try::Tiny;
use Baseliner::Sugar;
use Baseliner::Sem;
use BaselinerX::CI::variable;
use Baseliner::Model::Rules;
use Baseliner::RuleCompiler;
use Baseliner::Utils qw(_fail _loc _debug _error);
use Capture::Tiny qw(tee_merged);

has tidy_up => qw(is ro), default => sub { 1 };

sub run_rules {
    my $self = shift;
    my (%p) = @_;

    local $Baseliner::_no_cache = 0;
    local $ENV{BASELINER_LOGCOLOR} = 0;

    my $when          = $p{when};
    my $stash         = $p{stash} // {};
    my $event         = $p{event};
    my $type          = $p{type} // 'event';
    my $onerror       = $p{onerror};
    my $simple_error  = $p{simple_error};
    my $use_semaphore = $p{use_semaphore};
    my $id_rule       = $p{id_rule};

    my @rules =
        $id_rule
      ? $self->_find_rule_by_id_or_name($id_rule)
      : mdb->rule->find(
        {
            rule_event  => $event,
            rule_type   => $type,
            rule_when   => $when,
            rule_active => mdb->true
        }
      )->sort( mdb->ixhash( rule_seq => 1, id => 1 ) )->all;

    my $mid = $stash->{mid};
    my $sem;
    if ( defined $mid && @rules && $use_semaphore ) {
        $sem = Baseliner::Sem->new( key => "event:$mid", who => "rules:$when", internal => 1 );
        $sem->take;
    }

    my @rule_log;

    my $throw_error;

    $stash->{rules_exec}{$event}{$when} = 0;
    for my $rule (@rules) {
        $stash->{rules_exec}{$event}{$when}++;
        my ( $runner_output, $rc, $ret, $err );
        my $id_rule = $rule->{id};
        try {
            ($runner_output) = tee_merged(
                sub {
                    try {
                        $ret = $self->_dsl_run( rule => $rule, stash => $stash, simple_error => $simple_error );
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
            my $error = shift;

            $rc = 1;
            if ( ref $onerror eq 'CODE' ) {
                try {
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
                            err    => $error,
                            ret    => $ret->{stash},
                            id     => $id_rule,
                            dsl    => $ret->{dsl},
                            stash  => $stash,
                            output => $runner_output,
                            rc     => $rc
                        }
                    );
                } catch {
                    my $error = shift;

                    _error "Error during event onerror: $error";
                };
            }
            elsif ( !$onerror ) {
                $throw_error = "(rule $id_rule): " . $error;
            }
        };

        last if defined $throw_error;

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

    _fail $throw_error if defined $throw_error;

    return { stash => $stash, rule_log => \@rule_log };
}

method compile_rule(:$rule, :$logging = 0, :$simple_error = 0) {
    my $id_rule = $rule->{id};

    #my $dsl = $self->_build_dsl_from_rule($id_rule, $rule);

    my $compiler = $self->_build_rule_compiler(
        #dsl          => $dsl,
        ts           => $rule->{ts},
        id_rule      => $rule->{id},
        version_id   => '' . $rule->{_id},
        simple_error => $simple_error,
        logging      => $logging,
    );
    $compiler->compile;

    return $compiler;
}

method find_and_run_rule(:$id_rule, :$version_id = '', :$version_tag = '', :$stash = {}, :$logging = 0, :$simple_error = 0) {
    my $rule = $self->_resolve_rule(
        id_rule      => $id_rule,
        version_id   => $version_id,
        version_tag  => $version_tag
    );

    return $self->run_rule(
        rule         => $rule,
        stash        => $stash,
        logging      => $logging,
        simple_error => $simple_error
    );
}

method run_rule(:$rule, :$stash = {}, :$logging = 0, :$simple_error = 0) {
    local $Baseliner::_no_cache = 0;

    merge_into_stash( $stash, BaselinerX::CI::variable->default_hash );

    my $compiler = $self->compile_rule(
        rule         => $rule,
        logging      => $logging,
        simple_error => $simple_error
    );

    my $ret = try {
        $compiler->run( stash => $stash );

        my $rules_model = Baseliner::Model::Rules->new;
        if ( my $err = $compiler->errors ) {
            if ($simple_error) {
                _error( _loc( "Error during DSL Execution: %1", $err ) ) unless $simple_error > 1;
                _fail $err;
            }
            else {
                _fail( _loc( "Error during DSL Execution: %1", $err ) );
            }
            _debug "DSL:\n", $rules_model->dsl_listing( $compiler->dsl );
        }
        else {
            _debug "DSL:\n", $rules_model->dsl_listing( $compiler->dsl ) if $logging;
        }

        { stash => $stash }
    }
    catch {
        my $error = shift;

        _fail( _loc( "Error running rule '%1': %2", $rule->{id}, $error ) );
    };

    return {
        ret  => $ret,
        rule => { id => $rule->{id}, version_id => '' . $rule->{_id}, version_tag => $rule->{version_tag} }
    };
}

sub run_dsl {
    my $self = shift;
    my (%params) = @_;

    my $dsl = $params{dsl} or _fail 'dsl required';
    my $stash = $params{stash} // {};

    merge_into_stash( $stash, BaselinerX::CI::variable->default_hash );

    my $rule = $self->_build_rule_compiler( dsl => $dsl );
    $rule->compile;

    local $Baseliner::no_log_color = 1;
    my ($output) = tee_merged( sub { $rule->run( stash => $stash ) } );

    if ( my $err = $rule->errors ) {
        _fail $err;
    }

    return { output => $output };
}

sub dsl_build_and_test {
    my $self = shift;
    my ( $stmts, %p ) = @_;

    my $id_rule = $p{id_rule};
    my $ts      = $p{ts};

    my $rules_model = Baseliner::Model::Rules->new;
    my $dsl = $rules_model->dsl_build( $stmts, id_rule => $id_rule );

    # send ts so its stored as this rule save timestamp
    my $rule = $self->_build_rule_compiler( id_rule => $id_rule, dsl => $dsl, ts => $ts );

    $rule->compile;

    die $rule->errors if $rule->errors;

    return $dsl;
}

sub _dsl_run {
    my ( $self, %p ) = @_;

    my $rule         = $p{rule};
    my $simple_error = $p{simple_error};
    my $stash        = $p{stash} // {};
    my $include_dsl  = $p{include_dsl} // {};

    merge_into_stash( $stash, BaselinerX::CI::variable->default_hash );

    my $compiler = $self->compile_rule(
        rule         => $rule,
        simple_error => $simple_error
    );

    my $rules_model = Baseliner::Model::Rules->new;

    my $ret = try {
        $compiler->run( stash => $stash );

        if ( my $err = $compiler->errors ) {
            if ( $p{simple_error} ) {
                _error( _loc( "Error during DSL Execution: %1", $err ) ) unless $p{simple_error} > 1;
                _fail $err;
            }
            else {
                _fail( _loc( "Error during DSL Execution: %1", $err ) );
            }
            _debug "DSL:\n", $rules_model->dsl_listing( $compiler->dsl );
        }
        else {
            _debug "DSL:\n", $rules_model->dsl_listing( $compiler->dsl ) if $p{logging};
        }

        my $dsl = $include_dsl ? $compiler->dsl : $compiler->package;

        { stash => $stash, dsl => $dsl }
    }
    catch {
        my $error = shift;

        _fail( _loc( "Error running rule '%1': %2", $rule->{id}, $error ) );
    };

    return $ret;
}

sub merge_into_stash {
    my ( $stash, $data ) = @_;
    return unless ref $data eq 'HASH';
    while ( my ( $k, $v ) = each %$data ) {
        $stash->{$k} = $v unless exists $stash->{$k};
    }
    return $stash;
}

method _resolve_rule(:$id_rule, :$version_id, :$version_tag) {
    my $rule = $self->_find_rule_by_id_or_name($id_rule);
    _fail _loc( 'Rule with id or name `%1` not found', $id_rule ) unless $rule;

    $id_rule = $rule->{id};

    if ($version_id) {
        $rule = mdb->rule_version->find_one( { id_rule => $rule->{id}, _id => mdb->oid($version_id) } );
        _fail _loc( 'Version `%1` of rule `%2` not found', $version_id, $id_rule ) unless $rule;
    }
    elsif ($version_tag) {
        $rule = mdb->rule_version->find_one( { id_rule => $rule->{id}, version_tag => $version_tag } );
        _fail _loc( 'Version tag `%1` of rule `%2` not found', $version_tag, $id_rule ) unless $rule;
    }

    return $rule;
}

sub _find_rule_by_id_or_name {
    my $self = shift;
    my ($param) = @_;

    return mdb->rule->find_one( { '$or' => [ { id => "$param" }, { rule_name => "$param" } ] } );
}

sub _build_rule_compiler {
    my $self = shift;

    return Baseliner::RuleCompiler->new(@_);
}

1;
