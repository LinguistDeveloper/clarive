package Baseliner::Controller::TopicWS;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }

# skip authentication for this controller:
sub begin : Private {
    my ( $self, $c ) = @_;
    $c->stash->{auth_skip} = 1;
    $c->forward( '/begin' );
}

sub list_topics : Path('/openapi/list_topics') {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $category = 'Test';

    my $where = {};
    $where->{"categories.name"} = $category if $category;

    my @rs =
        Baseliner->model( 'Baseliner::BaliTopic' )
        ->search( $where, {select => 'me.mid', prefetch => [ 'categories' ]} )
        ->hashref->all;

    my $meta     = Baseliner::Model::Topic->get_meta( $rs[ 0 ]->{id_category} ) if @rs;
    my $ret      = {};
    my $ret_temp = {};

    for ( @rs ) {
        $ret = {};
        $ret = Baseliner::Model::Topic->get_data( $meta, $_->{mid} );
        $ret_temp->{"topic_" . $ret->{topic_mid}} = $ret;
        $ret = $ret_temp;
    } ## end for ( @rs )

    $self->return( $c, {ret => $ret, list_type => "Topics", format => $p->{format}} );
} ## end sub list_topics :

sub return {
    my ( $self, $c, $p ) = @_;

    my $ret       = $p->{ret};
    my $list_type = $p->{list_type};

    if ( $p->{format} && $p->{format} eq 'xml' ) {
        my $x = XML::Simple->new;
        my $xml = $x->XMLout( $ret, XMLDecl => 1, NoAttr => 1, RootName => "$list_type" );
        $c->res->content_type( 'text/plain' );
        $c->res->body( $xml );
    } elsif ( $p->{format} && $p->{format} eq 'yaml' ) {
        $c->res->content_type( 'text/plain' );
        $c->res->body( _dump $ret );
    } else {
        $c->stash->{json} = $ret;
        $c->forward( 'View::JSON' );
    }
} ## end sub return

1;
