package BaselinerX::Service::CIServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.ci.invoke' => {
    name => 'Invoke CI methods',
    form => '/forms/ci_invoke.js',
    icon => '/static/images/icons/class.gif',
    job_service  => 1,
    handler => \&ci_invoke,
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

1;
