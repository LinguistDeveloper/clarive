package Baseliner::Controller::Message;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

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
    return unless $c->user || $p->{test};
    $c->stash->{messages} = $c->model('Messaging')->inbox(
            all      => 1,
            username => $p->{username} || $c->username || $c->user->id,
            query    => $query,
            sort     => $sort,
            dir      => $dir,
            start    => $start,
            limit    => $limit,
            query_id => $query_id || undef
    );
    
    $c->stash->{username} = $p->{username} || $c->username || $c->user->id;
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
                 swreaded	=> $message->{swreaded}
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
    try {
        my @data;
        #my $id = 1;
        @data = map {
            my $id = $_->{mid} // $_->{id};
            my $ns = $_->{username} ? "user/".$id : "role/".$id;
            +{
                type => $_->{username} ? 'User' : 'Role',
                name => $_->{username} || $_->{role},
                long => $_->{description} || $_->{realname} || '',
                id => $id,
                ns => $ns,
            }
        } ci->user->find()->all, mdb->role->find()->all;
        if( $p->{query} ) {
            my $re = qr/$p->{query}/i;
            @data = grep { join( ',',values(%$_) ) =~ $re } @data ;
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

# System messages
register 'action.admin.sms' =>  { name=>'System Messages' };
register 'menu.admin.sms' => { label => 'System Messages', icon=>'/static/images/icons/sms.gif', actions=>['action.admin.sms'], url_eval=>'/comp/sms.js', index=>1000 };

sub sms_create : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        model->Permissions->user_has_action( username=>$c->username, action=>'action.admin.sms' ) || _fail _loc 'Unauthorized';
        $self->sms_set_indexes;
        my $title = $p->{title} || _fail _loc 'Missing message title';
        my $text = $p->{text} || _fail _loc 'Missing message text';
        my $more = $p->{more} || '';
        my $username = $p->{username} || undef;
        my $_id = mdb->oid;
        my $exp = Class::Date->now + ( $p->{expires} || '1D' );
        
        my $ret = mdb->sms->update({ _id=>$_id },{ 
            '$set'=>{ title=>$title, text=>$text, more=>$more, from=>$c->username, username=>$username, ua=>$c->req->user_agent, expires=>"$exp" }, 
            '$currentDate'=>{ t=>boolean::true } },{upsert=>1}
        );
        $c->stash->{json} = { success => \1, msg=>$ret, _id=>"$_id" };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_set_indexes : Private {
    my $expire_secs = 2_764_800;  # 32 days, 1 day above max system message of 30 days
    if( scalar mdb->sms->get_indexes < 4 ) {   # works if the collection does not exist or missing indexes
        mdb->sms->drop_indexes;
        Util->_debug( 'Creating mongo sms indexes. Expire seconds=' . $expire_secs ); 
        my $coll = mdb->db->get_collection('sms');
        $coll->ensure_index($_,{ background=>1 }) for ({ _id=>1 }, { username=>1 },{ expires=>1 });
        $coll->ensure_index({ t=>1 },{ expire_after_seconds=>$expire_secs }); # 1 month max
    }
    else {
        # reconfigure expire seconds
        mdb->db->run_command([ collMod=>"sms", index=>{keyPattern=>{t=>1}, expireAfterSeconds=>$expire_secs }]);
    }
}

sub sms_del : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $_id = $p->{_id} || _fail _loc 'Missing message id';
        my $action = $p->{action} || 'del'; 
        if( $action eq 'cancel' ) {
            mdb->sms->update({ _id=>mdb->oid($_id) },{ '$set'=>{ expires=>mdb->ts } });
        } else{
            mdb->sms->remove({ _id=>mdb->oid($_id) });
        }
        $c->stash->{json} = { success => \1, _id=>"$_id" };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_get : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $_id = $p->{_id};
        my $msg = mdb->sms->find_and_modify({ 
            query=>{ _id=>mdb->oid($_id) }, 
            update=>{ '$push'=>{ 'shown'=>{u=>$c->username, ts=>mdb->ts, ua=>$c->req->user_agent, add=>$c->req->address } } },
            new=>1,
        });
        $$msg{_id} .= '';
        $c->stash->{no_system_messages} = 1;
        $c->stash->{json} = { success => \1, msg=>$msg };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_ack : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        if( my $_id = $p->{_id} ) {
            mdb->sms->update({ _id=>mdb->oid($_id) },{ '$push'=>{ 'read'=>{u=>$c->username, ts=>mdb->ts, ua=>$c->req->user_agent, add=>$c->req->address } } });
        }
        $c->stash->{json} = { success => \1 };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $ts = mdb->ts;
        my @sms = map { 
            $$_{_id}.=''; 
            $$_{expired} = $$_{expires} gt $ts ? \0 : \1;
            $_ 
        } mdb->sms->find->fields({ t=>0 })->sort({ t=>-1 })->all;
        $c->stash->{json} = { success => \1, data=>\@sms, totalCount=>scalar @sms };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_wipe : Local {
    my ( $self, $c ) = @_;
    mdb->sms->remove({});
    $c->forward('View::JSON');
}

1;

