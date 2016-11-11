package BaselinerX::Service::CIServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.ci.invoke' => {
    name => _locl('Invoke CI methods'),
    form => '/forms/ci_invoke.js',
    icon => '/static/images/icons/class.svg',
    job_service  => 1,
    handler => \&ci_invoke,
};

register 'service.ci.create' => {
    name => _locl('Create CI'),
    form => '/forms/ci_create.js',
    icon => '/static/images/icons/class.svg',
    handler => \&ci_create,
};

register 'service.ci.load_related' => {
    name => _locl('Load related CIs'),
    form => '/forms/ci_related.js',
    icon => '/static/images/icons/class.svg',
    handler => \&ci_related,
};

sub ci_invoke {
    my ($self, $c, $config ) = @_;

    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;

    my $named = $config->{named} || {};
    my $positional = $config->{positional} || [];
    my $ci_class =  Util->to_ci_class( $config->{ci_class} );
    my $ci_method = $config->{ci_method};
    my $ci_mid = $config->{ci_mid};

    my $ci = length $ci_mid ? ci->new($ci_mid) : $ci_class;
    my @args;
    if( @$positional ) {
        push @args, map { $_->{value} } @$positional;
    }
    if( %$named ) {
        push @args, map { substr($_,1) => $named->{$_} } keys %$named;   # need to strip the '$' or '@' from the front
    }
    my @ret = $ci->$ci_method( @args );

    return @ret==0 ? undef : @ret==1 ? $ret[0] : \@ret;

    # sort map { _loc(Util->to_base_class($_)) } packages_that_do('Baseliner::Role::CI');
    # my $cl = 'BaselinerX::CI::job';
    # sort grep !/^(_|TO_JSON)/, $cl->meta->get_method_list;
    # Function::Parameters::info( $cl.'::'.'write_to_logfile' );
}

sub ci_create {
    my ( $self, $c, $config ) = @_;

    my ($class_name) = _array($config->{classname});
    my $data = $config->{attributes};

    my $ci_class =  Util->to_ci_class( $class_name );

    my $ci = $ci_class->new($data);

    $ci->save;

    return $ci;

}

sub ci_related {
    my ( $self, $c, $config ) = @_;

    my $mid = $config->{mid} // die _loc("Missing mid");

    my ($collection) = _array $config->{classname};
    $collection =~ s{^BaselinerX::CI::}{} if $collection;

    my $depth = $config->{depth} // 1;

    my $query_type = $config->{query_type} // 'children';
    if ( !grep { $query_type eq $_ } qw/children parents related/ ) {
        die 'Unknown query type';
    }

    my $single     = $config->{single};
    my $mids_only  = $config->{mids_only};

    my $ci = ci->new($mid);

    my @related = $ci->$query_type(
        $collection ? (where => { collection => $collection }) : (),
        $mids_only ? ( mids_only => 1 ) : ( docs_only => 1 ), depth => $depth
    );

    if ($mids_only) {
        @related = map { $_->{mid} } @related;
    }

    if ($single) {
        return $related[0];
    }

    return \@related;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
