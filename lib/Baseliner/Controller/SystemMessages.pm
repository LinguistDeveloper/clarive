package Baseliner::Controller::SystemMessages;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

# System messages
register 'action.admin.sms' =>  { name=> 'System Messages' };
register 'menu.admin.sms' => { label => 'System Messages', icon=>'/static/images/icons/sms.png', actions=>['action.admin.sms'], url_eval=>'/comp/sms.js', index=>1000 };

sub sms_create : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        model->Permissions->user_has_action( username=>$c->username, action=>'action.admin.sms' ) || _fail _loc 'Unauthorized';
        $p->{ua} = $c->req->user_agent;
        $p->{username} = $c->username;
        $p->{_id} = mdb->oid;
        $p->{exp} = Class::Date->now + ( $p->{expires} || '1D' );
        $p->{action} = "add";
        my $ret = model->SystemMessages->update($p);
        $c->stash->{json} = { success => \1, msg=>$ret, _id=>$p->{_id} };
    } catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_del : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $_id = $p->{_id} || _fail _loc 'Missing message id';
        $p->{username} = $c->username;
        $p->{ts} = _now;
        $p->{ua} = $c->req->user_agent;
        model->SystemMessages->update($p);
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
        my $msg = model->SystemMessages->sms_get($_id, $p);
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
        my @sms = model->SystemMessages->sms_list($ts);
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

