#!/usr/bin/perl
use strict;
use warnings;
use Carp qw/carp croak/;
use JSON::Any;
use HTTP::Request;
use LWP::UserAgent;
use URI;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Baseliner::Utils;

sub request {
    my $url  = shift;
    my $args = _get_args(@_);
    my $uri  = URI->new($url);
    $uri->query_form($args);
    my $request = HTTP::Request->new( GET => $uri, );
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;

    my $response = $ua->request($request);

    croak sprintf qq/HTTP request failed: %s/, $response->status_line
      unless $response->is_success;

    my $content = $response->content;
    my $json    = JSON::Any->new();
    return $json->decode($content);

    #return bless $self, $class;
}

sub _get_args {
    my %args;
    if ( scalar(@_) > 1 ) {
        if ( @_ % 2 ) {
            croak "odd number of parameters";
        }
        %args = @_;
    }
    elsif ( ref $_[0] ) {
        unless ( eval { local $SIG{'__DIE__'}; %{ $_[0] } || 1 } ) {
            croak "not a hashref in args";
        }
        %args = %{ $_[0] };
    }
    else {
        %args = ( 'q' => shift );
    }

    return {%args};
}

# turns option=>[]  into option=>''
#    required for sending emptyness over an http request
sub clean_empty_arrays {
    my %opts = @_;
    for( %opts ) {
        if( ref $opts{$_} eq 'ARRAY' ) {
            $opts{$_} = '' if @{$opts{$_}} == 0;
        }
    }
    return %opts;
}

package main;

my $server = $ENV{BASELINER_SERVER} || $ENV{CATALYST_SERVER} || 'localhost';
my $port   = $ENV{BASELINER_PORT}   || $ENV{CATALYST_PORT}   || 3000;

my $service = shift @ARGV;
my %opts    = _get_options(@ARGV);
%opts = clean_empty_arrays( %opts );
# check if there's any STDIN
use IO::Select;
my $s = IO::Select->new();
$s->add(\*STDIN);
if( $s->can_read(.1) ) {
    $opts{STDIN} = join '',<STDIN>;
}
my $res     = request(
    "http://$server:$port/service/rest",
    api_key => $ENV{BASELINER_API_KEY},
    service => $service || 'service.job.dummy',
    %opts
);

#print _dump( $res );
#print _dump( \%opts );

if ( ! defined $res ) {
    print STDERR "***REST Error: " . $!;
    exit 99;
} else {
    print $res->{output};
    if ( $res->{rc} > 0 ) {
        print STDERR $res->{msg};
    }
    else {
        print $res->{msg} if 0;
    }
    exit $res->{rc};
}

exit 0;

