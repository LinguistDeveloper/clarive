package Clarive::Role::Baseliner;
use v5.10;
use Moo::Role;

sub setup_baseliner {
    my ($self)=@_;
    
    $ENV{BASELINER_HOME} = $self->home;

    # TRACE
    if( $self->trace // $ENV{BASELINER_TRACE} ) {
        $ENV{BASELINER_TRACE} = 1;
        $ENV{BASELINER_TRACE_MODULE} //= "-d:Trace::More" 
    }
    
    # DEBUG?
    if( $self->debug ) {
        $ENV{BASELINER_DEBUG} = 1;
    } else {
        $ENV{BASELINER_DEBUG} = 0;
    }
    
    # ENV
    exists $ENV{BALI_ENV} and $ENV{BASELINER_CONFIG_LOCAL_SUFFIX}=$ENV{BALI_ENV};
    $ENV{BASELINER_CONFIG_LOCAL_SUFFIX} ||= $self->env;
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} ||= $ENV{BASELINER_CONFIG_LOCAL_SUFFIX};

    $ENV{BASELINER_PERL_OPTS} = ''; # XXX 
}

sub bali_service {
    my ($self,$service_name,%opts) = @_;
    require Baseliner::Cmd;
    require Baseliner; 
    my $c = Baseliner::Cmd->new;
    Baseliner->app( $c );
    $opts{ arg_list } = { map { $_ => () } keys %opts }; # so that we can differentiate between defaults and user-fed data
    $opts{ args } = \%opts;
    my $logger = $c->model('Services')->launch($service_name, %opts, data=>\%opts, c=>$c );
    exit ref $logger ? $logger->rc : $logger;
}

1;

