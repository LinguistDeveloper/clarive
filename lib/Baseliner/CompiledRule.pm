package Baseliner::CompiledRule;
use Mouse;
use strict;
use warnings;
use Baseliner::Utils qw(:logging);
use Try::Tiny;
use Module::Loaded qw();

has id_rule => qw(is rw isa Maybe[Str] lazy 1), default=>sub{ 
    my $self = shift;
    $self->is_temp_rule(1);
    return Util->_md5;
};
has dsl          => qw(is rw isa Any), default => '';
has package => qw(is rw isa Str lazy 1),
    default => sub {
    my ($self) = @_;
    return 'Clarive::RULE_' . $self->id_rule;
};
has ts => qw(is rw isa Maybe[Str] lazy 1), default => sub { mdb->ts };

has is_compiled  => qw(is rw isa Bool default 0);
has is_temp_rule => qw(is rw isa Bool default 0);
has all_warnings   => qw(is rw isa ArrayRef lazy 1), default=>sub{[]};
has warnings_mode   => qw(is rw isa Str default no);  # no,use,print
has compile_time   => qw(is rw isa Any);
has compile_error  => qw(is rw isa Any);
has runtime_error  => qw(is rw isa Any);
has return_value   => qw(is rw isa Any);
has compile_status => qw(is rw isa Str), default=>'none';
has rule_name      => qw(is rw isa Str), default=>'none';
has doc            => qw(is rw isa Any lazy 1), default=>sub{ 
    my $self = shift;
    my $id_rule = ''.$self->id_rule;
    mdb->rule->find_one({ '$or'=>[{id=>"$id_rule"},{rule_name=>$id_rule}]  },{ _id=>0, rule_tree=>0 });
};

sub errors {
    my ($self)=@_;
    return $self->compile_error if $self->compile_error;
    return $self->runtime_error if $self->runtime_error;
    return '';
}

sub warnings {
    my ($self)=@_;
    return join '', @{ $self->all_warnings }; 
}

sub is_loaded {
    my ($self)=@_;
    my $pkg = $self->package;
    return Module::Loaded::is_loaded( $pkg );
}

sub dsl_build { 
    my ($self, %p)=@_;
    return if $self->is_temp_rule;
    my @tree = model->Rules->build_tree( $self->id_rule, undef );
    return unless @tree;
    my $dsl = try {
        model->Rules->dsl_build( \@tree, no_tidy=>0, %p ); 
    } catch {
        _fail( _loc("Error building DSL for rule `%1`: %2", $self->id_rule, shift() ) ); 
    };
    mdb->grid_insert( $dsl ,id_rule=>''.$self->id_rule );
    return $dsl;
}

sub compile {
    my ($self, %p) =@_;
    
    _throw('Missing parameter id_rule or a dsl') unless $self->id_rule // $self->dsl;

    my $id_rule = $self->id_rule;
    my $pkg = $self->package;
    
    # is it compiled and up-to-date?
    # don't do this for ad-hoc rule test or try, only saved rules
    if( !$self->is_temp_rule && $self->is_loaded ) {
        my $doc = $self->doc;
        if( $doc && $doc->{ts} eq $pkg->ts ) {
            _debug("Cached rule $id_rule is fresh, no need to recompile");
            $self->compile_status('fresh');
            $self->ts( $doc->{ts} );
            return { err=>'', t=>'' };
        }
    }
    
    # provided or get dsl ourselves?
    my $dsl = $self->dsl;
    if( !$dsl ) {
        my $doc = $self->doc // mdb->rule->find_one({ '$or'=>[{id=>"$id_rule"},{rule_name=>$id_rule}] },{ ts=>1 }) // _fail( _loc('Rule %1 not found', $self->id_rule) );
        $self->ts( $doc->{ts} );
        _debug('Loaded ts=' . $self->ts . ',' . $self->id_rule );
        $dsl = mdb->grid_slurp({ id_rule=>"$id_rule" });
        $dsl = $self->dsl_build || 'do{};';
        $self->dsl( $dsl );
    }
    _fail(_loc('Missing rule dsl')) if !$dsl; 
 
    if( $self->is_loaded ) {
        _debug("Recompiling loaded rule $pkg...");
        $self->compile_status('recompiling');
        $self->unload;
    } else {
        _debug("Compiling and loading rule $pkg...");
        $self->compile_status('compiling');
    }

    my $ts = $self->ts;
    my $warnings_str = $self->warnings_mode eq 'no' ? 'no warnings;' : 'use warnings;';  # TODO consider using SIG{__WARN__} for elegant warn trapping
    my $t0=[Time::HiRes::gettimeofday];
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
                use Baseliner::Model::Rules;
                use Baseliner::Utils;
                use Baseliner::Sugar;
                $warnings_str
                sub ts { '$ts' }
                sub run { 
                    my (\$self,\$stash)=\@_;
                    $dsl 
                };
                1;
            }
        };
        my $compile_err = $@;
        $self->compile_time( Time::HiRes::tv_interval( $t0 ) );
        $self->compile_error( $compile_err );
        if( !$compile_err ) {
            $self->is_compiled(1);
            Module::Loaded::mark_as_loaded( $pkg ) unless $self->is_loaded; # fix recompiles which do not show as loaded
        }
    }
    
    return { err=>$self->compile_error, t=>$self->compile_time };
}

sub run {
    my ($self,%p) = @_;
    my $stash = $p{stash} // _throw('Missing parameter stash');
    
    return if $self->compile_error;
    
    local $SIG{ALRM} = sub { die "Timeout running rule\n" };
    alarm 0;
    my $err = '';
    
    my $t0=[Time::HiRes::gettimeofday];
    my $ret = try { 
        my $pkg = $self->package;
        $pkg->run($stash);
    } catch {
        $err = shift;
    };
    alarm 0;
    
    $self->return_value( $ret );
    $self->runtime_error( $err );

    # wait for children to finish
    Baseliner::Model::Rules->wait_for_children( $stash );
    
    # reset log reporting to "Core"
    if( my $job = $stash->{job} ) {
        $job->back_to_core;
    }

    $$stash{_rule_compile} = $self->compile_time if $self->compile_time;
    $$stash{_rule_elapsed} = Time::HiRes::tv_interval( $t0 );
    $$stash{_rule_err} = $err;
    return { ret=>$ret, err=>$err };
}

sub unload {
    my ($self) = @_;
    require Class::Unload;
    Class::Unload->unload( $self->package );
}

sub DESTROY {
    my ($self) = @_;
    if( $self->is_temp_rule ) {
        # this is a temporary rule, unload 
        _debug( 'Destroying temporary rule: ' . $self->package );
        $self->unload;
    }
}

1;
