package Baseliner::Controller::CGit;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Path::Class;

BEGIN { extends 'Catalyst::Controller::WrapCGI' }

#register 'menu.tools.cgit' => {
#    label    => 'CGit',
#    url      => '/cgit.cgi',
#    title    => 'CGit',
#    icon     => '/gitweb/images/icons/git.png',
#    actions  => [ 'action.git.cgit_view_repo' ]
#};

sub cgit : Path('/cgit.cgi') {
    my ($self,$c) = @_;
    $self->cgi_to_response($c, sub {
        my $cgi = '/tmp/cgit/cgit';
        $ENV{CGIT_CONFIG} = '/tmp/cgit/cgitrc';
        $ENV{CACHE_ROOT} = '/tmp/cgit/cache';
        system $cgi;
        if ($? == -1) {
            die "failed to execute CGI '$cgi': $!";
        }
        elsif ($? & 127) {
            die sprintf "CGI '$cgi' died with signal %d, %s coredump",
                ($? & 127),  ($? & 128) ? 'with' : 'without';
        }
        else {
            my $exit_code = $? >> 8;

            return 0 if $exit_code == 0;

            die "CGI '$cgi' exited non-zero with: $exit_code";
        }
        
        #my $q = CGI->new;
        #print $q->header, $q->start_html('Hello'), $q->h1('Catalyst Rocks!'), $q->end_html;
    });
    my $html = $c->res->body; 
    $html =~ s{<html.*?>}{}gs;
    $html =~ s{</html.*?>}{}gs;
    $html =~ s{\<head\>.*\</head\>}{}gs;
    $html =~ s{\<body\>}{}gs;
    $html =~ s{\<\/body\>}{}gs;
    $c->res->body( $html ); 
}

sub cgit_data : Path('/cgit-data') {
    my ($self,$c) = @_;
    $c->res->body('nay');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

