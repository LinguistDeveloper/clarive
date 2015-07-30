package Baseliner::Controller::I18N;
use Moose;
BEGIN { extends 'Catalyst::Controller' };

use Baseliner::Utils;

use Try::Tiny;

sub default : Path {
    my ($self,$c,$lang) = @_;
    #my $lang = $c->req->params->{lang};
    my $file = $c->path_to('lib', 'Baseliner', 'I18N', $lang . '.po');
    try {
        $c->serve_static_file( $file );
    } catch {	
        $c->res->body( "" );
    };
}

sub js : Local {
    my ($self,$c,$lang) = @_;
    my $p = $c->req->parameters;
    # set the language here if possible
    my @languages = $c->user_languages;
    $c->languages([ @languages ]); 
    $lang ||= $c->language;
    my $text = $self->parse_po($c, $c->path_to('lib', 'Baseliner', 'I18N', $lang . '.po') );
    for my $feature ( $c->features->list ) {
        $text .= $self->parse_po($c, _file($feature->lib, 'Baseliner', 'I18N', $lang . '.po') );
    }
    $text .= ' "" : "" ';  # finish up
    $c->response->content_type('text/javascript; charset=utf-8');
    $c->stash->{po} = $text;
    $c->stash->{template} = '/site/i18n.js';
}

sub parse_po {
    my ($self,$c,$file) = @_;
    return try {
        open my $fh,'<:encoding(UTF-8)',$file or die $@;
        my ($key,$val,@po);
        while( <$fh> ) {
            s{\r|\n}{}g;
            if( /^msgid (.*)$/ ) {
                $key = $1	
            }
            elsif( /^msgstr (.*)/ ) {
                my $val = $1;
                next unless $val;
                next unless $val ne '""';
                push @po, "$key : $val";
            }
        }
        close $fh;
        my ($relpath) = $file =~ m{^.*(/[^/]+/lib/.*)$};
        return ( Clarive->debug ? "\n /* From po file '$relpath': */ \n\n" : "\n/**************/\n\n" ) . join( ",\n",@po ) . ",\n";
    } catch {
        #return "\n /* Error reading po file '$file': \n\n" . shift() . " */ \n\n";
        return '';
    };
}

1;
