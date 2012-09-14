package Baseliner::Controller::TopicWS;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

# skip authentication for this controller:
sub begin : Private {
    my ($self,$c) = @_;
    $c->stash->{auth_skip} = 1;
    $c->forward('/begin');
}

sub topic_details : Path('/api/topic_details') {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{id};
        
    my $ret = {};
    my $row = DB->BaliTopic->find( $topic_mid );
    if ( $row ) {
        my $meta = Baseliner::Model::Topic->get_meta( $topic_mid );
        $ret = Baseliner::Controller::Topic->get_data( $meta, $topic_mid );
        my $ret_temp = {};
        my $mid = delete $ret->{$topic_mid};

        $ret_temp->{ "topic_".$topic_mid } = $ret;
        $ret = $ret_temp;
    }

    $self->return_list( $c, { ret => $ret, format => $p->{format} } );
}

sub list_topics : Path('/api/list_topics') {
    my ($self,$c)=@_;
    my $p = $c->request->parameters;
    my $category = $p->{category} || '';
    my $status = $p->{status} || '';
    
    my $where = {};
    $where->{"categories.name"} = $category if $category;
    $where->{"status.name"} = $status if $status;

    my @rs = Baseliner->model('Baseliner::BaliTopic')
    ->search( $where, { select => 'me.mid', prefetch => [ 'status', 'categories' ] } )
    ->hashref->all;

    my $meta = Baseliner::Model::Topic->get_meta( $rs[0]->{id_category} ) if @rs;
    my $ret = {};
    my $ret_temp = {};
    
    for ( @rs ) {
        $ret = {};
        $ret = Baseliner::Controller::Topic->get_data( $meta, $_->{mid} );
        $ret_temp->{ "topic_".$ret->{topic_mid} } = $ret;
        $ret = $ret_temp;
    }

    $self->return_list( $c, { ret => $ret, format => $p->{format} } );
}

sub topic_change_status : Path('/api/topic_change_status') {
    my ($self, $c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid};
            
    my $ret = {};
    
    my $meta = Baseliner::Model::Topic->get_meta( $topic_mid );
    $ret->{topic_meta} = $meta;
    $ret->{topic_data} = $self->get_data( $meta, $topic_mid );
    $c->stash->{json} = $ret;
    
    $c->forward('View::JSON');
}

sub return_list {
    my ($self, $c, $p) = @_;

    my $ret = $p->{ret};

    if ( $p->{format} && $p->{format} eq 'xml') {
        my $x = XML::Simple->new;
        my $xml = $x->XMLout( $ret, XMLDecl => 1, NoAttr => 1, RootName => "Topics", KeyAttr => { topic => 'topic_mid'});
        $c->res->content_type('text/plain');
        $c->res->body( $xml );
    } elsif ( $p->{format} && $p->{format} eq 'yaml') {    
        $c->res->content_type('text/plain');
        $c->res->body( _dump $ret );
    } else {
        $c->stash->{json} = $ret;
        $c->forward('View::JSON');        
    }
}

1;
