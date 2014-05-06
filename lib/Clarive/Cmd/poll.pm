=head1 NAME

poll - check if processes are started

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

has url_web       => qw(is rw isa Any);
has url_nginx     => qw(is rw isa Any);
has api_key       => qw(is rw isa Any);
has pid_filter    => qw(is rw isa Any);
has web           => qw(is rw isa Any default 1);
has act_nginx     => qw(is rw isa Any default 1);
has act_mongo     => qw(is rw isa Any default 1);
has act_redis     => qw(is rw isa Any default 0);
has timeout_web   => qw(is rw isa Num default 5);
has error_rc      => qw(is rw isa Num default 10);

our $CAPTION = 'monitoring tool';

=head1 Clarive Poll Monitoring

Usage:
  cla poll

Options:

  -h                      this help
  --url_web               clarive web url
  --url_nginx             nginx web url
  --api_key               api key to login to clarive
  --web                   1=try clarive web connection, 0=skip
  --act_nginx                 1=try nginx connection, 0=skip nginx
  --act_mongo                 1=try mongo connection, 0=skip mongo
  --act_redis                 1=try redis connection, 0=skip redis status
  --timeout_web           seconds to wait for clarive/nginx web response, 0=no timeout
  --error_rc              return code for fatal errors
  --pid_filter            regular expression to filter in pid files

=cut

sub sayts { print DateTime->now( time_zone=>'CET' ), ' - ', @_, "\n" }
sub errts { print STDERR DateTime->now( time_zone=>'CET' ), ' - ', @_, "\n" }

sub _find_pid {
    my ($self, $pidfile, $cnt )  = @_;
    $pidfile = $pidfile . ($cnt ? $cnt : '' );
    my $clean_pid = sub { $_[0] =~ /^([0-9]+)/ ? $1 : $_[0] };
    if( defined $self->opts->{pid} ) {
        $clean_pid->( $self->opts->{pid} );
    } 
    if( -e $pidfile ) {
        open(my $pf, '<', $pidfile ) or die "Could not open pidfile: $!";
        my $pid = join '',<$pf>;
        close $pf;
        return $clean_pid->( $pid );
    }
}

sub run {
    my ($self,%opts) = @_;

    my $rc = 0;

    my $pid_filter = $self->pid_filter;
    $pid_filter = qr/$pid_filter/i if $pid_filter;
    
    for my $pidfile ( glob(file($self->pid_dir,'*.pid')), glob(file($self->app->base,'data','mongo','*.lock')) ) { 
        next if $pid_filter && $pidfile !~ $pid_filter;
        sayts "pid_file=$pidfile";
        my $pid = $self->_find_pid( $pidfile );
        next if( length $self->opts->{pid} && $self->opts->{pid} != $pid );
        sayts "checking pid exists=$pid";
        if( ! pexists($pid) ) {
            errts "KO: pid $pid not found.";
            $rc = $self->error_rc;
        } else {
            sayts "OK: pid exists=$pid";
        }
    }

    if( $self->web ) {
        sayts "connecting to Clarive Web Server...";
        $rc += $self->call_web( %opts, url=>$self->url_web );
    }
    
    if( $self->act_nginx  && $self->url_nginx) {
        sayts "connecting to Nginx...";
        $rc += $self->call_web( %opts, url=>$self->url_nginx ) if $self->act_nginx;  
    }
    
    if( $self->act_mongo ) {
        require MongoDB;
        try {
            sayts "connecting to MongoDB...";
            my $m = MongoDB::MongoClient->new( $self->app->config->{mongo}{client});
            my $db_name = $self->app->config->{mongo}{dbname} // 'clarive';
            my $db = $m->get_database( $db_name ); 
            sayts "OK: connected to Mongo database $db_name";
        } catch {
            my $err = shift;
            errts( "KO: could not connect to mongo: " . $err );
            $rc += $self->error_rc;
        };
    }
    
    if( $self->act_redis ) {
        require Redis;
        try {
            sayts "connecting to Redis...";
            my $s = $self->app->config->{redis} // { server=>'localhost:6379' };
            my $r = Redis->new( %$s );
            sayts "OK: connected to Redis: " . $s->{server};
        } catch {
            my $err = shift;
            errts( "KO: could not connect to Redis: " . $err );
            $rc += $self->error_rc;
        };
    }
    
    $rc = $self->error_rc if $rc > $self->error_rc;
    sayts "poll finished. RC = $rc";
    exit $rc;
}

sub call_web {
    my ($self, %opts) =@_;
    
    require LWP::UserAgent;
    require HTTP::Request;
    require Encode;
    
    my $url = $opts{url} || sprintf "http://%s:%s", $opts{host} // 'localhost', $opts{port} // 3000;
    sayts "checking web server at url $url";
    my $uri = URI->new( $url );
    $uri->query_form({ api_key=>$self->api_key });
    my $request = HTTP::Request->new( 'GET' => $uri );
    my $ua = LWP::UserAgent->new();
    $ua->timeout( $self->timeout_web ) if $self->timeout_web;
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
