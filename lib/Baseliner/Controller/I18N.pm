package Baseliner::Controller::I18N;
use Moose;
BEGIN { extends 'Catalyst::Controller' };

use Baseliner::Utils;
use Baseliner::I18N;

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
    my $offset = ' ' x 4;
    my $text = Baseliner::I18N->parse_po($c->path_to('lib', 'Baseliner', 'I18N', $lang . '.po'), $offset );
    for my $feature ( $c->features->list ) {
        my $feature_text .= Baseliner::I18N->parse_po(_file($feature->lib, 'Baseliner', 'I18N', $lang . '.po'), $offset );
        if ($feature_text) {
            $text .= ",\n" if $text;
            $text .= $feature_text;
        }
    }
    $c->response->content_type('text/javascript; charset=utf-8');
    $c->stash->{po} = $text;
    $c->stash->{template} = '/site/i18n.js';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
