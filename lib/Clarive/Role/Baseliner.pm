package Clarive::Role::Baseliner;
use v5.10;
use Mouse::Role;

has nls_lang   => qw(is ro default) => sub { 'AMERICAN_AMERICA.UTF8' };

with 'Clarive::Role::TempDir';

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
    $ENV{BALI_ENV} ||= $self->env;
    $ENV{BASELINER_ENV} ||= $ENV{BALI_ENV};
    $ENV{BASELINER_CONFIG_LOCAL_SUFFIX} ||= $ENV{BASELINER_ENV};
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} ||= $ENV{BASELINER_CONFIG_LOCAL_SUFFIX};

    $ENV{BASELINER_LANG} = $self->lang;
    $ENV{BASELINER_NLS_LANG} = $self->nls_lang;
    $ENV{NLS_LANG} = $self->nls_lang;
    $ENV{BASELINER_TEMP} = $self->tmp_dir;
    $ENV{BASELINER_TMPHOME} = $self->tmp_dir;
    $ENV{BASELINER_LOGHOME} = $self->log_dir;
    $ENV{BASELINER_JOBHOME} = $self->job_dir;
    $ENV{BASELINER_PIDHOME} = $self->pid_dir;
    $ENV{CLARIVE_MIGRATE_NOW} = $self->app->migrate;
    $ENV{BASELINER_PERL_OPTS} = ''; # XXX 
    $ENV{BASELINER_DEBUG} = $self->debug; 
    $ENV{BASELINER_LOGCOLOR} = 1; # force colorize even in log files
    
    # TLC
    $Baseliner::TLC = $Clarive::TLC;
    $Baseliner::TLC_STATUS = $Clarive::TLC_STATUS;
    $Baseliner::TLC_MSG = $Clarive::TLC_MSG;
    
    # CONFIG
    my $baseliner_config = $self->app->opts->{baseliner} // {};
    $baseliner_config->{mongo} //= $self->app->config->{mongo};
    $baseliner_config->{redis} //= $self->app->config->{redis};
    
    $Baseliner::BASE_OPTS = $baseliner_config; 
}

sub bali_service {
    my ($self,$service_name,%opts) = @_;
    $ENV{BALI_CMD} = 1;
    require Baseliner; 
    require Baseliner::Standalone;
    my $c = Baseliner::Standalone->new;
    Baseliner->app( $c );
    $opts{ arg_list } = { map { $_ => 1 } keys %opts }; # so that we can differentiate between defaults and user-fed data
    $opts{ args } = \%opts;
    my $logger = Baseliner->model('Services')->launch($service_name, %opts, data=>\%opts, c=>$c );
    #_log _dump $logger;
    # exit ref $logger ? $logger->rc : $logger;
    exit $logger->rc;
}

sub bali_conf_file {
    my ($self) = @_;
    return sprintf '%s/baseliner_%s.conf', $self->home, $self->env;
}

sub bali_utils {
    require Baseliner::Utils;
    return 'Util';
}

sub bali_config {
    my ($self) = @_;
    # load config 
    require Config::General;
    my $cfg      = Config::General->new( $self->bali_conf_file );
    my $config = { $cfg->getall };
}

1;

