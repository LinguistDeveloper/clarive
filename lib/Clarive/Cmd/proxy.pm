=head1 NAME

proxy - utilities for proxying web requests to/from Clarive

=cut
package Clarive::Cmd::proxy;
use Mouse;
use strict;
use v5.14;
use Try::Tiny;
use HTTP::Daemon;
use LWP::UserAgent;

extends 'Clarive::Cmd';

has listen    => qw(is rw isa Str default localhost:8089);
has host      => qw(is rw isa Str);
has port      => qw(is rw isa Str);
has unpack    => qw(is rw isa Bool default 1);

sub run {
    my ($self, %opts)=@_;
    my $ua = LWP::UserAgent->new();
    my %http_opts;
    # use listen only if no host or port
    $http_opts{LocalAddr} = $self->listen if $self->listen && !length $self->app->args->{port} && !$self->app->args->{host};
    $http_opts{LocalHost} = $self->host if $self->app->args->{host};
    $http_opts{LocalPort} = $self->port if length $self->app->args->{port};
    my $d = HTTP::Daemon->new( 
        ReuseAddr => 1,
        %http_opts,
    ) || die "$!: ".(join ',',%http_opts)."\n";
    print "[Proxy URL:", $d->url, "]\n";

    # Avoid dying from browser cancel
    $SIG{PIPE} = 'IGNORE';

    # Dirty pre-fork implementation
    fork(); fork(); fork();  # 2^3 = 8 processes
    say "Started pid=$$";

    while (my $c = $d->accept) {
        while (my $request = $c->get_request) {

            print $request->as_string =~ s/\n/\n\t--> /gr;

            print $c->sockhost . ": " . $request->uri->as_string . "\n";

            $request->push_header( Via => "1.1 ". $c->sockhost );
            my $response = $ua->simple_request( $request );
            
            my $resas = $response->as_string;
            if( $self->unpack ) {
                for( split /\n/, $resas ) {
                    my $hh = unpack( 'H*', $_ );
                    print "\t<-- $_ [$hh]\n"; 
                }
            } else {
                print "$resas" =~ s/\n/\n\t<-- /gr;
            }
        
            $c->send_response( $response );

            # Save the response content into file
            if( ($request->method eq "GET" || $request->method eq "POST") 
                && $response->is_success && length($response->content) > 10 )
            {
                my $uri = $request->uri->as_string;
                $uri =~ s#/#_#g;
                open(F, ">$uri") || print "Cannot write $uri\n";;
                print F $response->content;
                close F;
            }
        }
        $c->close;
        undef($c);
    }
}

=head1 Proxy Utility

Usage:

  cla proxy

Options:

  -h                      this help
  --listen                <host>:<port> or just :<port>
  --port                  listen port
  --host                  listen host
  --unpack                shows hex block for each line of incoming

=cut

1;
