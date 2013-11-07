=head1 NAME

poll - check if processes are started, start if not

=cut

package Clarive::Cmd::poll;
use Mouse;

use v5.10;
use strict;
use Proc::Exists qw( pexists);
use Try::Tiny;
use List::Util qw/max/;
use Proc::ProcessTable;
use Path::Class;
use DateTime;

extends 'Clarive::Cmd';
with 'Clarive::Role::TempDir';

has url_web   => qw(is rw isa Any);
has url_nginx => qw(is rw isa Any);
has api_key   => qw(is rw isa Any);
has timeout   => qw(is rw isa Num default 5);

our $CAPTION = 'monitoring tool';

sub _help {
    print << 'EOF';
Usage:
  cla poll

Options:
  -h                      : this help

EOF
}

sub sayts { print DateTime->now( time_zone=>'CET' ), ' - ', @_, "\n" }
sub errts { print STDERR DateTime->now( time_zone=>'CET' ), ' - ', @_, "\n" }

sub _find_pid {
    my ($self, $pidfile, $cnt )  = @_;
    my $pidfile = $pidfile . ($cnt ? $cnt : '' );
    my $clean_pid = sub { $_[0] =~ /^([0-9]+)/ ? $1 : $_[0] };
    if( defined $self->opts->{pid} ) {
        return $clean_pid->( $self->opts->{pid} );
    } elsif( -e $pidfile ) {
        open(my $pf, '<', $pidfile ) or die "Could not open pidfile: $!";
        my $pid = join '',<$pf>;
        close $pf;
        return $clean_pid->( $pid );
    }
}

sub run {
    my ($self,%opts) = @_;

    my $rc = 0;

    for my $pidfile ( glob file($self->pid_dir,'*.pid') ) { 
        sayts "pid_file=$pidfile";
        my $pid = $self->_find_pid( $pidfile );
        sayts "checking pid exists=$pid";
        if( ! pexists($pid) ) {
            errts "KO: pid $pid not found.";
            $rc = 10;
        } else {
            sayts "OK: pid exists=$pid";
        }
    }

    $rc += $self->call_web( %opts ); 
    
    sayts "poll finished with rc=$rc";
    exit $rc;
}

sub call_web {
    my ($self, %opts) =@_;
    
    require LWP::UserAgent;
    require HTTP::Request;
    require Encode;
    
    my $url = $self->url_web || sprintf "http://%s:%s", $opts{host} // 'localhost', $opts{port} // 3000;
    sayts "checking web server at url $url";
    my $uri = URI->new( $url );
    $uri->query_form({ api_key=>$self->api_key });
    my $request = HTTP::Request->new( 'GET' => $uri );
    my $ua = LWP::UserAgent->new();
    $ua->timeout( $self->timeout ) if $self->timeout;
    #for my $k ( keys %$headers ) {
    #    $ua->default_header( $k => $headers->{$k} );
    #}
    $ua->env_proxy;
    try {
        my $response = $ua->request( $request );
        my $content = $response->decoded_content;
        if( $response->code == 200 ) {
            sayts sprintf "OK: STATUS=%s, web call url=%s", $response->code, $url;
        } elsif( $response->code == 401 ) {
            sayts sprintf "WARN: STATUS=%s, web call url=%s. Please set poll/api_key for correct web reporting", $response->code, $url;
            return 1;  # a warning
        } else {
            $content =~ s/\n|\r//g;
            errts sprintf "KO: STATUS=%s, web call url=%s: %s", $response->code, $url, substr( $content, 0, 40) . '...';
            return 2;
        }
        return 0;
    } catch {
        my $err = shift;
        errts "error connecting to url $url: $err";
        return 2 if $err =~ /timeout/; 
        return 4;
    };
}

1;
