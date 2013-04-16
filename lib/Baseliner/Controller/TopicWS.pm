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

sub topic_details : Path('/api/topic_details') {
    my ( $self, $c ) = @_;
    my $p         = $c->request->parameters;
    my $topic_mid = $p->{id};

    my $ret = {};
    my $row = DB->BaliTopic->find( $topic_mid );
    if ( $row ) {
        my $meta = Baseliner::Model::Topic->get_meta( $topic_mid );
        $ret = Baseliner::Model::Topic->get_data( $meta, $topic_mid );
        my $ret_temp = {};
        my $mid      = delete $ret->{$topic_mid};

        $ret_temp->{"topic_" . $topic_mid} = $ret;
        $ret = $ret_temp;
    } ## end if ( $row )

    $self->return( $c, {ret => $ret, list_type => "Topics", format => $p->{format}} );
} ## end sub topic_details :

sub list_topics : Path('/api/list_topics') {
    my ( $self, $c ) = @_;
    my $p        = $c->request->parameters;
    my $category = $p->{category} || '';
    my $status   = $p->{status} || '';

    my $where = {};
    $where->{"categories.name"} = $category if $category;
    $where->{"status.name"}     = $status   if $status;

    my @rs =
        Baseliner->model( 'Baseliner::BaliTopic' )
        ->search( $where, {select => 'me.mid', prefetch => [ 'status', 'categories' ]} )
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

sub topic_change_status : Path('/api/topic_change_status') {
    my ( $self, $c ) = @_;
    my $p         = $c->request->parameters;
    my $topic_mid = $p->{id};
    my $status    = $p->{status};
    my $force     = $p->{force};

    my $ret = {};

    my $topic = DB->BaliTopic->find( $topic_mid, { prefetch => 'status'} );

    if ( !$topic ) {
        $ret->{status} = 'ERROR';
        $ret->{msg} = _loc( 'Topic %1 does not exist', $topic_mid );
    } else {
        if ( !$force || $force == 0 ) {
            my @statuses = $c->model( 'Topic' )->next_status_for_user(
                id_category    => $topic->id_category,
                id_status_from => $topic->id_category_status
            );
            my $found = 0;
            for ( @statuses ) {
                if ( $status eq $_->{status_name} ) {
                    $found = 1;
                }
            }
            if ( !$found ) {
                $ret->{status} = 'ERROR';
                $ret->{msg} = _loc( 'Can\'t change status of topic %1 to %2', $topic_mid, $status );
            } ## end if ( !$found )
        } ## end if ( !$force || $force...)
        my $new_status = DB->BaliTopicCategoriesStatus->search( { "status.name" => $status }, { prefetch => ['status'] } )->hashref->first;
        if ( $new_status ) {
            event_new 'event.topic.change_status' => { username => 'root', status => $status, old_status => $topic->status->name } => sub {
                $topic->id_category_status($new_status->{"id_status"});
                $topic->update;
                $ret->{status} = 'SUCCESS';
                $ret->{msg} = _loc( 'Status of topic %1 changed to %2', $topic_mid, $status );
                return { mid => $topic_mid, topic => $topic->title };
            } 
            => sub {
                $ret->{status} = 'ERROR';
                $ret->{msg} = _loc( 'Error changing status of topic %1 to %2: %3', $topic_mid, $status, $_ );
            };
        } else {

        }
    } ## end else [ if ( !$topic ) ]

    $self->return( $c, {ret => $ret, list_type => "Result", format => $p->{format}} );

} ## end sub topic_change_status :

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
