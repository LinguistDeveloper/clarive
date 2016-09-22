package Baseliner::Controller::Message;
use Moose;
BEGIN {  extends 'Catalyst::Controller' }

use Try::Tiny;
use Baseliner::Model::Permissions;
use Baseliner::Model::Messaging;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

sub detail : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $message = $c->model('Messaging')->get( id => $p->{id} );
    mdb->message->update({'queue.id' => 0 + $p->{id}}, {'$set' => {'queue.$.swreaded' => '1'}});
    $c->stash->{json} = { data => [ $message ] };
    $c->forward('View::JSON');
}

sub body : Local {
    my ($self,$c, $id) = @_;
    my $message = mdb->message->find({_id => mdb->oid($id)})->next;
    my $body = $message->{body};
    #$body = Encode::decode_utf8( $body );
    #Encode::from_to( $body, 'utf-8', 'iso-8859-1' );
    $c->response->body( $body );
}

# only for im, with read after check
sub im_json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    return unless $c->user;
    $c->stash->{messages} = $c->model('Messaging')->inbox(username=>$c->username || $c->user->id, carrier=>'instant', deliver_notify_adminw=>1 );
    $c->forward('/message/json');
}

# all messages for the user
sub inbox_json : Local {
    my ($self,$c) = @_;

    my $p = $c->request->parameters;

    my ($start, $limit, $query, $query_id, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query query_id dir sort/}, 0 );
    $sort ||= 'sent';
    $dir ||= 'DESC';

    my $permissions = Baseliner::Model::Permissions->new;

    my $username = $p->{username}
      && $permissions->user_has_action( $c->username, 'action.admin.users' ) ? $p->{username} : $c->username;

    $c->stash->{messages} = Baseliner::Model::Messaging->new->inbox(
            all      => 1,
            username => $username,
            query    => $query,
            sort     => $sort,
            dir      => $dir,
            start    => $start,
            limit    => $limit,
            query_id => $query_id || undef
    );

    $c->stash->{username} = $username;
    $c->forward('/message/json');
}

sub json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @rows;
    my $cnt = 1;
    foreach my $message ( _array( $c->stash->{messages}->{data} ) ) {
        # produce the grid
        push @rows,
             {
                 id         => $message->{id} ,
                 id_message => $message->{_id},
                 sender     => $message->{sender},
                 subject    => $message->{subject},
                 received    => $message->{received},
                 body    => substr( $message->{body}, 0, 100 ),
                 sent       => $message->{sent},
                 created    =>  $message->{created},
                 schedule_time  =>  $message->{schedule_time},
                 swreaded    => $message->{swreaded}
             }
    }
    $c->stash->{json} = { totalCount=>$c->stash->{messages}->{total}, data => \@rows };
    $c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {

        $c->model('Messaging')->delete( id_queue=>$p->{id_queue}, id_message =>  $p->{id_message});
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the message ").$@  };
    } else {
        $c->stash->{json} = { success => \1, msg => _loc("Message '%1' deleted", $p->{name} ) };
    }
    $c->forward('View::JSON');
}

sub delete_all : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        _log _dump $p->{username};
        $c->model('Messaging')->delete_all( username=>$p->{username});
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the message ").$@  };
    } else {
        $c->stash->{json} = { success => \1, msg => _loc("All Messages deleted" ) };
    }
    $c->forward('View::JSON');
}


sub inbox : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{username} = $p->{username} || $c->username;
    $c->stash->{query_id} = $p->{query};
    $c->stash->{template} = '/comp/message_grid.js';
}

sub to_and_cc : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my $query = quotemeta($p->{query} // '');
    my $deny_email = $p->{denyEmail};
    try {
        my @data;
        #my $id = 1;
        @data = map {
            my $id = $_->{mid} // $_->{id};
            my $ns = $_->{username} ? "user/".$id : "role/".$id;
            +{
                type => $_->{username} ? 'User' : 'Role',
                name => $_->{username} || $_->{role} || '',
                long => $_->{description} || $_->{realname} || '',
                id => $id,
                ns => $ns,
            }
        } ci->user->find()->all, mdb->role->find()->all;
        if( $query ) {
            my $re = qr/$p->{query}/i;
            @data = grep { join( ',',values(%$_) ) =~ $re } @data ;
            if(!$deny_email){
                push @data, { type=>'Email', name=>$_, long=>'', id=>$_, ns=>$_ } for split /\|/, $query;
            }
        }
        $c->stash->{json} = { success => \1, data=>\@data, totalCount=>scalar(@data) };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub test_message : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $config = Baseliner->model('ConfigStore')->get('config.comm.email');

        my $now = mdb->ts;
        my $test_user = _trim "$now".'test@clarive.com';
        #my @users_list = ($test_user);
        my @users_list = ('root');
        my $to = [ _unique(@users_list) ];

        Baseliner->model('Messaging')->notify(
            to => { users => $to },
            subject => "Envio de correo desde Clarive: $now",
            sender => $config->{from},
            carrier => 'email',
            template => 'email/generic.html',
            template_engine => 'mason',
            vars => {
                subject => "Prueba de envio de correo desde Clarive",
                message =>'Has recibido este correo porque estamos ejecutando una prueba de envio desde Clarive'
            }
        );
        my $_id = mdb->message->find({subject => "Envio de correo desde Clarive: $now", sender => $config->{from}})->next->{_id};

        my %query;
        $query{where} = {_id => $_id, 'queue.username' => $test_user};
        my @queue = Baseliner->model('Messaging')->transform(%query);
        my ($q) = @queue;

        $c->stash->{json} = { success => \1, msg => "Message created with _id $_id. MessageQueue inserted with id: $q->{id}. Email sent succesfully. " };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

1;
