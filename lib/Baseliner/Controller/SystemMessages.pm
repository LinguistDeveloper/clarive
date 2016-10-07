package Baseliner::Controller::SystemMessages;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;

register 'action.admin.sms' => { name => _locl('System Messages') };
register 'menu.admin.sms' => {
    label    => _locl('System Messages'),
    icon     => '/static/images/icons/sms.svg',
    actions  => ['action.admin.sms'],
    url_eval => '/comp/sms.js',
    index    => 1000
};

sub sms_create : Local : Does('ACL') : ACL('action.admin.sms') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;

    try {
        my $system_message;
        $system_message->{ua}       = $c->req->user_agent;
        $system_message->{username} = $c->username;
        $system_message->{_id}      = mdb->oid;
        $system_message->{exp}      = Class::Date->now + ( $p->{expires} || '1D' );
        $system_message->{title}    = $p->{title};
        $system_message->{text}     = $p->{text};
        $system_message->{more}     = $p->{more};
        $system_message->{users}    = $p->{users};

        my $ret = Baseliner::Model::SystemMessages->new->create($system_message);
        $c->stash->{json} = { success => \1, msg => $ret, _id => "$ret->{id}" };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_del : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try {
        my $params;
        _fail _loc('Missing message id') unless $p->{_id};
        _fail _loc('Missing action') unless $p->{action};
        $params->{id} = $p->{_id};
        $params->{username} = $c->username;
        $params->{ts}       = _now;
        $params->{ua}       = $c->req->user_agent;
        if ( $p->{action} eq 'del' ) {
            Baseliner::Model::SystemMessages->new->delete($params);
        }
        elsif ( $p->{action} eq 'cancel' ) {
            Baseliner::Model::SystemMessages->new->cancel($params);
        }

        $c->stash->{json} = { success => \1, _id => $p->{_id} };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_get : Local {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    try {
        my $msg = Baseliner::Model::SystemMessages->new->sms_get(
            {   id        => $req->params->{_id},
                ua        => $req->user_agent,
                add       => $req->address,
                username  => $c->username
            }
        );
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
    my $_id = $p->{_id};
    try {
        my $updated_sms = mdb->sms->update(
            { _id => mdb->oid($_id) },
            {   '$push' => {
                    'read' => {
                        u   => $c->username,
                        ts  => mdb->ts,
                        ua  => $c->req->user_agent || '',
                        add => $c->req->address || ''
                    }
                }
            }
        )->{n};
        my $success = $updated_sms ? \1 : \0;
        $c->stash->{json} = { success => $success };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

sub sms_list : Local {
    my ( $self, $c ) = @_;
    try {
        my $ts  = mdb->ts;
        my @sms = model->SystemMessages->sms_list($ts);
        $c->stash->{json} = { success => \1, data => \@sms, totalCount => scalar @sms };
    }
    catch {
        my $err = shift;
        $c->stash->{json} = { success => \0, msg => $err };
    };
    $c->forward('View::JSON');
}

1;
