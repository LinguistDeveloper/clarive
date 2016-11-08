package Baseliner::RuleCompiler;
use Moose;

use Try::Tiny;
use Module::Loaded qw();
use Class::Unload;
use Digest::MD5 ();
use Baseliner::Model::Rules;
use Baseliner::Utils qw(:logging _now _md5);

has dsl        => qw(is ro isa Str),        default => '';
has id_rule    => qw(is ro isa Maybe[Str]), default => '';
has version_id => qw(is ro isa Maybe[Str]), default => '';
has is_compiled   => qw(is rw isa Bool default 0);
has all_warnings  => qw(is rw isa ArrayRef lazy 1), default => sub { [] };
has warnings_mode => qw(is rw isa Str default no);                           # no,use,print
has compile_time  => qw(is rw isa Any);
has compile_error => qw(is rw isa Any);
has runtime_error => qw(is rw isa Any);
has return_value  => qw(is rw isa Any);
has compile_status => qw(is rw isa Str), default => 'none';
has ts => qw(is rw isa Maybe[Str]), default => sub { mdb->ts };

has
  package => qw(is ro isa Str lazy 1),
  default => sub {
    my $self = shift;

    my $suffix = '';
    if ( $self->id_rule ) {
        $suffix .= $self->id_rule;

        if ( $self->version_id ) {
            $suffix .= '_' . $self->version_id;
        }
    }
    else {
        my $str = _now . rand() . $$;
        $suffix .= Digest::MD5::md5_hex($str);
    }

    return 'Clarive::RULE_' . $suffix;
  };

sub is_temp_rule {
    my $self = shift;

    return 1 unless $self->id_rule;
    return 0;
}

sub errors {
    my ($self) = @_;
    return $self->compile_error if $self->compile_error;
    return $self->runtime_error if $self->runtime_error;
    return '';
}

sub warnings {
    my ($self) = @_;
    return join '', @{ $self->all_warnings };
}

sub is_loaded {
    my ($self) = @_;
    my $pkg = $self->package;
    return Module::Loaded::is_loaded($pkg);
}

sub compile {
    my $self = shift;

    my $ts = $self->ts;

    my $pkg = $self->package;
    if ( $self->is_loaded ) {
        if ($self->id_rule) {
            my $id_rule = '' . $self->id_rule;
            my $rule     = mdb->rule->find_one(
                { '$or' => [  { _id     => mdb->oid($id_rule) }, { id => "$id_rule" }, { rule_name => $id_rule } ] },
                { _id   => 0, ts => 1 } );

            if ($rule && $rule->{ts} eq $pkg->ts ) {
                _debug("Cached rule $id_rule is fresh, no need to recompile");

                $self->compile_status('fresh');
                $self->ts( $rule->{ts} );

                return { err => '', t => '' };
            }
        }

        _debug("Recompiling loaded rule $pkg...");
        $self->compile_status('recompiling');
        $self->unload;
    }
    else {
        _debug("Compiling and loading rule $pkg...");
        $self->compile_status('compiling');
    }

    my $dsl = $self->dsl;
    if ($dsl eq '' && (my $id_rule = $self->id_rule)) {
        my $rule = mdb->rule->find_one(
            { '$or' => [ { _id => mdb->oid($id_rule) }, { id => "$id_rule" }, { rule_name => $id_rule } ] } );

        if ( my $grid = mdb->grid->find_one( { id_rule => $id_rule } ) ) {
            if ( $grid->info->{ts} && $grid->info->{ts} eq $rule->{ts} ) {
                _debug("DSL not changed. Loading cached version $pkg...");
            }
            else {
                _debug("DSL has changed. Removing cached version $pkg...");
                mdb->grid->remove( { id_rule => $id_rule } );
            }
        }

        if ( !length $dsl ) {
            $dsl = $self->_build_dsl_from_rule( $id_rule, $rule );

            _debug("Caching DSL $pkg...");
            mdb->grid_insert( $dsl, id_rule => $id_rule, ts => $rule->{ts} );
        }
    }

    my $warnings_str =
      $self->warnings_mode eq 'no'
      ? 'no warnings;'
      : 'use warnings;';    # TODO consider using SIG{__WARN__} for elegant warn trapping
    my $t0 = [Time::HiRes::gettimeofday];
    {
        local $@;
        local $SIG{__WARN__} = sub {
            my $t = shift;
            warn $t if $self->warnings_mode eq 'print';
            push @{ $self->all_warnings }, $t;
        };
        eval qq{
            {
                package $pkg;
                use Moose;
                use v5.10;
                use Baseliner::RuleFuncs;
                use Baseliner::Utils;
                use Baseliner::Sugar;
                use Try::Tiny;
                $warnings_str
                our \$DATA = {};
                sub data { \$DATA }
                sub ts { '$ts' }
                sub run {
                    my (\$self,\$stash)=\@_;
                    $dsl
                };
                sub call {
                    shift if ref \$_[0] || \$_[0] eq __PACKAGE__;
                    my (\$id_rule, \$stash)=\@_;

                    my \$rule_runner = Baseliner::RuleRunner->new;
                    my \$ret = \$rule_runner->find_and_run_rule(id_rule => \$id_rule, stash => \$stash);

                    return \$ret->{ret};
                }
                1;
            }
        };
        my $compile_err = $@;

        $self->compile_time( Time::HiRes::tv_interval($t0) );
        $self->compile_error($compile_err);

        if ( !$compile_err ) {
            $self->is_compiled(1);

            # fix recompiles which do not show as loaded
            Module::Loaded::mark_as_loaded($pkg) unless $self->is_loaded;
        }
    }

    _debug("Done loading rule $pkg (t=" . $self->compile_time . ")" );

    return { err => $self->compile_error, t => $self->compile_time };
}

sub run {
    my ( $self, %p ) = @_;

    my $stash = $p{stash} // _throw('Missing parameter stash');

    return if $self->compile_error;

    my $err = '';

    my $pkg;

    my $t0  = [Time::HiRes::gettimeofday];
    my $ret = try {
        $pkg = $self->package;
        $pkg->run($stash);
    }
    catch {
        $err = shift;
    };

    $self->return_value($ret);
    $self->runtime_error($err);

    # Let's wait for any not captured forks just in case
    if ($pkg) {
        my $chi_pids = $pkg->data->{_forked_pids};
        for my $pid ( keys %$chi_pids ) {
            waitpid $pid, 0;
        }
    }

    # reset log reporting to "Core"
    if ( my $job = $stash->{job} ) {
        $job->back_to_core;
    }

    $$stash{_rule_compile} = $self->compile_time if $self->compile_time;
    $$stash{_rule_elapsed} = Time::HiRes::tv_interval($t0);
    $$stash{_rule_err}     = $err;

    return { ret => $ret, err => $err };
}

sub unload {
    my ($self) = @_;

    Class::Unload->unload( $self->package );
}

sub DESTROY {
    my ($self) = @_;

    if ( $self->is_temp_rule ) {
        _debug( 'Destroying temporary rule: ' . $self->package );
        $self->unload;
    }
}

sub _build_dsl_from_rule {
    my $self = shift;
    my ($id_rule, $rule) = @_;

    my $rules_model = Baseliner::Model::Rules->new;
    my @tree = $rules_model->build_tree( $rule, undef );

    my $dsl = try {
        $rules_model->dsl_build( \@tree, no_tidy => 0, id_rule => $id_rule, rule_name => $rule->{name} );
    }
    catch {
        my $error = shift;

        _fail( _loc( "Error building DSL for rule `%1`: %2", $id_rule, $error ) );
    };

    return $dsl;
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_destructor => 0 );

1;
