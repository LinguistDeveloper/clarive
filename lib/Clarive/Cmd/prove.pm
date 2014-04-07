package Clarive::Cmd::prove;
use Mouse;
use Path::Class;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'run system tests and check';
with 'Clarive::Role::Baseliner';

has type          => qw(is rw isa Str default server);
has test_url      => qw(is rw isa Str), default => sub {
    my ($self)=@_;
    return $self->app->config->{baseliner}{web_url};
};
has test_user     => qw(is rw isa Str default local/root);
has test_password => qw(is rw isa Str default admin);
has case  => qw(is rw isa Str default *);

sub run {
    my ( $self, %opts ) = @_;
    
    require Time::HiRes;
    require Term::ANSIColor;
    require Clarive::Test;
    
    $Clarive::Test::base_url = $self->test_url;
    $Clarive::Test::user = $self->test_user;
    $Clarive::Test::password = $self->test_password;
    
    my $grc=0;

    my @tc = glob join '/', $self->home, 't', $self->type, $self->case . '*';
    for my $tc ( @tc ) {
        my $pid;
        unless ( $pid = fork ) {
            say "====> [start] $tc" ;
            my $t0 = [gettimeofday]; 
            do $tc;  # this returns 1 always... or whatever, unusable
            my $rc = $@;  # catch errors here
            my $inter = sprintf( "%.04fs", tv_interval( $t0 ) );
            say Term::ANSIColor::color('red'),"====> [error] $tc:\n" . $@, Term::ANSIColor::color('reset') if $@;
            say "====> [end] $tc [$inter]" ;
            exit !!$rc;
        }
        waitpid $pid,0;
        my $rc = $? >> 8;
        $grc += $rc;
    }
    exit $grc;
}

sub run_startup {
    my ( $self ) = @_;
    $self->setup_baseliner;
    $SIG{__WARN__} = sub {};
    $ENV{BASELINER_DEBUG}=0;
    say "Starting system test...";
    eval {
        require Baseliner;
    };
    if( $@ ) {
        die "Clarive: error during system prove: $@\n";
    } else {
        say "Clarive: all systems ready.";
    }
    exit 0;
}


1;
