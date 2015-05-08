package Baseliner::Model::SystemMessages;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
extends qw/Catalyst::Model/;

with 'Baseliner::Role::Service';

register 'event.sms.new' => { name => 'New System Message', vars=>['username'] } ;
register 'event.sms.cancel' => { name => 'Canceled System Message', vars=>['username'] } ;
register 'event.sms.remove' => { name => 'Deleted System Message', vars=>['username'] } ;

sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};
    my $_id = $p->{_id} || _fail _loc 'Missing message id';
    if($action eq 'add'){
        model->Permissions->user_has_action( username=>$p->{username}, action=>'action.admin.sms' ) || _fail _loc 'Unauthorized';
        $self->sms_set_indexes;
        my $title = $p->{title} || _fail _loc 'Missing message title';
        my $text = $p->{text} || _fail _loc 'Missing message text';
        my $more = $p->{more} || '';
        my $username = $p->{username} || undef;
        my $from = $p->{from} || undef;
        
        my $exp = $p->{exp};
        
        my $ret = mdb->sms->update({ _id=>$_id },{ 
            '$set'=>{ title=>$title, text=>$text, more=>$more, from=>$from, username=>$username, ua=>$p->{user_agent}, expires=>"$exp" }, 
            '$currentDate'=>{ t=>boolean::true } },{upsert=>1}
        );
        event_new 'event.sms.new' => { username => $username } => sub {
            my $subject = _loc("System message %1 created", $title);
            { id => $_id, title=>$title, text=>$text, subject => $subject, more => $more, expire => $exp, from=> $from };
        };
    } elsif ( $action eq 'cancel') {
        my $username = $p->{username} || undef;
        mdb->sms->update({ _id=>mdb->oid($_id) },{ '$set'=>{ expires=>mdb->ts } });
        event_new 'event.sms.cancel' => { username => $username } => sub {
            my $subject = _loc("System message %1 canceled", $_id);
            { id => $_id, subject => $subject, username=>$username, ts=>$p->{ts}, ua => $p->{ua} };
        };
    } elsif ( $action eq 'del') {
        my $username = $p->{username} || undef;
        mdb->sms->remove({ _id=>mdb->oid($_id) });
        event_new 'event.sms.remove' => { username => $username } => sub {
            my $subject = _loc("System message %1 remove", $_id);
            { id => $_id, subject => $subject, username=>$username, ts=>$p->{ts}, ua => $p->{ua} };
        };
    }
}

sub sms_set_indexes {
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

sub sms_get {
    my ( $self, $id, $p ) = @_;

    my $msg = mdb->sms->find_and_modify({ 
        query=>{ _id=>mdb->oid($id) }, 
        update=>{ '$push'=>{ 'shown'=>{u=>$p->{username}, ts=>$p->{ts}, ua=>$p->{user_agent}, add=>$p->{address} } } },
        new=>1,
    });
    $$msg{_id} .= '';
    return $msg;
}

sub sms_list {
    my ( $self, $ts ) = @_;
    my @sms = map { 
        $$_{_id}.=''; 
        $$_{expired} = $$_{expires} gt $ts ? \0 : \1;
        $_ 
    } mdb->sms->find->fields({ t=>0 })->sort({ t=>-1 })->all;
    return @sms;
}

1;

