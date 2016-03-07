package Baseliner::CompiledRule;
use Moose;

use Try::Tiny;
use Module::Loaded qw();
use Class::Unload;
use Digest::MD5 ();
use Baseliner::Utils qw(:logging _now);
use Baseliner::Model::Rules;

has id_rule      => qw(is ro isa Maybe[Str]);
has rule_version => qw(is ro isa Any);
has rule_name    => qw(is ro isa Str), default => 'none';
has dsl          => qw(is ro isa Any), default => '';

has
  package => qw(is ro isa Str lazy 1),
  default => sub {
    my ($self) = @_;

    my $suffix = '';

    if ( $self->id_rule ) {
        $suffix = $self->id_rule;

        if ( $self->rule_version ) {
            $suffix .= '_' . $self->rule_version;
        }
    }
    else {
        my $str = _now . rand() . $$;
        $suffix = Digest::MD5::md5_hex($str);
    }

    return 'Clarive::RULE_' . $suffix;
  };

has is_compiled   => qw(is rw isa Bool default 0);
has is_temp_rule  => qw(is rw isa Bool default 0);
has all_warnings  => qw(is rw isa ArrayRef lazy 1), default => sub { [] };
has warnings_mode => qw(is rw isa Str default no);                           # no,use,print
has compile_time  => qw(is rw isa Any);
has compile_error => qw(is rw isa Any);
has runtime_error => qw(is rw isa Any);
has return_value  => qw(is rw isa Any);
has compile_status => qw(is rw isa Str), default => 'none';

sub BUILD {
    my $self = shift;

    if ( my $id_rule = $self->id_rule ) {
        my $rule = mdb->rule->find_one( { id => "$id_rule" }, { _id => 1 } );
        _fail 'rule not found' unless $rule;
    }
    elsif ( $self->dsl ) {
        $self->is_temp_rule(1);
    }
    else {
        _fail 'id_rule or dsl is required';
    }
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

    my $ts = mdb->ts;

    if ( !$self->is_temp_rule ) {
        my $doc = mdb->rule->find_one( { id => $self->id_rule }, { _id => 0, ts => 1 } );
        _fail 'rule not found' unless $doc;

        $ts = $doc->{ts};

        if ( $self->is_loaded && $doc->{ts} eq $self->package->ts ) {
            return { err => '', t => '' };
        }
    }

    my $dsl = $self->_build_dsl;

    my $pkg = $self->package;
    if ( $self->is_loaded ) {
        _debug("Recompiling loaded rule $pkg...");
        $self->compile_status('recompiling');
        $self->unload;
    }
    else {
        _debug("Compiling and loading rule $pkg...");
        $self->compile_status('compiling');
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
                #extends 'Baseliner::Model::Rules';
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
                    my (\$id_rule, \$stash)=\@_;

                    my \$rule = Baseliner::CompiledRule->new(id_rule => "\$id_rule");
                    \$rule->compile;
                    return \$rule->run(stash => \$stash)->{ret};
                }
                1;
            }
        };
        my $compile_err = $@;
        $self->compile_time( Time::HiRes::tv_interval($t0) );
        $self->compile_error($compile_err);
        if ( !$compile_err ) {
            $self->is_compiled(1);
            Module::Loaded::mark_as_loaded($pkg) unless $self->is_loaded;   # fix recompiles which do not show as loaded
        }
    }

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

sub _build_dsl {
    my $self = shift;

    return $self->dsl if $self->is_temp_rule;

    my $rules_model = Baseliner::Model::Rules->new;

    my $rule = mdb->rule->find_one( { id => $self->id_rule }, { id => 1, rule_tree => 1 } );
    _fail 'Rule not found' unless $rule;

    if ( my $version = $self->rule_version ) {
        $rule = mdb->rule_version->find_one( { _id => mdb->oid( $self->rule_version ) }, { rule_tree => 1 } );
        _fail 'Rule version not found' unless $rule;
    }

    my @tree = $rules_model->build_tree( $rule, undef );

    my $dsl = try {
        $rules_model->dsl_build( \@tree, no_tidy => 0, id_rule => $self->id_rule, rule_name => $self->rule_name );
    }
    catch {
        _fail( _loc( "Error building DSL for rule `%1`: %2", $self->id_rule, shift() ) );
    };

    return $dsl;
}

no Moose;
__PACKAGE__->meta->make_immutable( inline_destructor => 0 );

1;
