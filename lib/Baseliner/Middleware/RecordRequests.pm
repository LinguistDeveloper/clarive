package Baseliner::Middleware::RecordRequests;
use strict;
use warnings;
use parent 'Plack::Middleware';

use Time::HiRes qw(time);
use Plack::Util::Accessor qw(file);
use Plack::Request;
use Plack::Response;
use Scalar::Util qw(blessed);
use Baseliner::Utils qw(_dump);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    die 'file required' unless $self->file;

    open my $fh, '>', $self->file or die sprintf "Can't open file '%s' for recording: %s\n", $self->file, $!;
    close $fh;

    return $self;
}

sub call {
    my $self = shift;
    my ($env) = @_;

    open my $fh, '>>', $self->file or die $!;

    print $fh sprintf "*** %s ***\n", time;

    my $req   = Plack::Request->new($env);
    my $entry = {
        request => {
            env  => $env,
            body => $req->content
        }
    };

    my $res = $self->app->($env);

    return Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;

            my $body = $res->[2];
            my $content_type = Plack::Util::header_get( $res->[1], 'Content-Type' );

            if ( $content_type && $content_type =~ m{text/html} ) {
                $body = ['*** HTML ***'];
            }

            $entry->{response} = {
                status  => $res->[0],
                headers => $res->[1],
                body    => $self->_read_body($body)
            };

            print $fh _dump $entry;

            close $fh;
        }
    );
}

sub _read_body {
    my $self = shift;
    my ($body) = @_;

    my $content = '';
    foreach my $part (@$body) {
        if (ref $part) {
            while (my $line = $part->getline) {
                $content .= $line;
            }
        }
        else {
            $content .= $part;
        }
    }

    return $content;
}

1;
