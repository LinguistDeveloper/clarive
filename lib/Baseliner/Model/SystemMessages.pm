package Baseliner::Model::SystemMessages;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Baseliner::Model::Users;
extends qw/Catalyst::Model/;

with 'Baseliner::Role::Service';

register 'event.sms.new' => {
    name        => 'New System Message',
    description => _locl('New System Message'),
    vars        => ['username']
};

register 'event.sms.cancel' => {
    name        => 'Canceled System Message',
    description => _locl('Canceled System Message'),
    vars        => ['username']
};

register 'event.sms.remove' => {
    name        => 'Deleted System Message',
    description => _locl('Deleted System Message'),
    vars        => ['username']
};

sub create {
    my ( $self, $p ) = @_;

    my $username = $p->{username} || undef;
    Baseliner::Model::Permissions->new->user_has_action( username=>$p->{username}, action=>'action.admin.sms' ) || _fail _loc('Unauthorized');

    $self->sms_set_indexes;

    my $_id = mdb->oid;
    my $title = $p->{title} || _fail _loc('Missing message title');
    my $text = $p->{text} || _fail _loc('Missing message text');
    my $more = $p->{more} || '';
    my $exp = $p->{exp} || Class::Date->now + "1D";
    my @users = Baseliner::Model::Users->new->get_usernames_from_user_mids($p);
    my $sms_data = {
        title    => $title,
        text     => $text,
        more     => $more,
        username => $username,
        ua       => $p->{ua},
        expires  => "$exp",
        users    => \@users,
        ts       => _now
   };

    mdb->sms->update( { _id => $_id }, { '$set' => $sms_data }, { upsert => 1 } );
    event_new 'event.sms.new' => { username => $username } => sub {
    my $subject = _loc( "System message %1 created", $title );
        {   id      => $_id,
            title   => $title,
            text    => $text,
            subject => $subject,
            more    => $more,
            expire  => $exp
        };
    };
    $sms_data->{id} = $_id;
    return $sms_data;
}

sub cancel {
    my ( $self, $p ) = @_;

    my $_id = $p->{id};
    _fail _loc('Missing message id') unless $_id;

    my $username = $p->{username} || undef;
    mdb->sms->update( { _id => mdb->oid($_id) },
        { '$set' => { expires => mdb->ts } } );

    event_new 'event.sms.cancel' => { username => $username } => sub {
        my $subject = _loc( "System message %1 canceled", $_id );
        {   id       => $_id,
            subject  => $subject,
            username => $username,
            ts       => $p->{ts},
            ua       => $p->{ua}
        };
    };

}

sub delete : method {
    my ( $self, $p ) = @_;
    my $_id = $p->{id};
    _fail _loc('Missing message id') unless $_id;
    my $username = $p->{username} || undef;
    mdb->sms->remove({ _id=>mdb->oid($_id) });
    event_new 'event.sms.remove' => { username => $username } => sub {
        my $subject = _loc( "System message %1 remove", $_id );
        {   id       => $_id,
            subject  => $subject,
            username => $username,
            ts       => $p->{ts},
            ua       => $p->{ua}
        };
    };

}

sub sms_set_indexes {
    # 32 days, 1 day above max system message of 30 days
    my $expire_secs = 2_764_800;
    # works if the collection does not exist or missing indexes
    if ( scalar mdb->sms->get_indexes < 4 ) {
        mdb->sms->drop_indexes;
        Util->_debug( 'Creating mongo sms indexes. Expire seconds=' . $expire_secs );
        my $coll = mdb->db->get_collection('sms');
        $coll->ensure_index( $_, { background => 1 } ) for ( { _id => 1 }, { username => 1 }, { expires => 1 } );
        $coll->ensure_index( { t => 1 }, { expire_after_seconds => $expire_secs } );
    } else {
        mdb->db->run_command(
            [   collMod => "sms",
                index   => {
                    keyPattern         => { t => 1 },
                    expireAfterSeconds => $expire_secs
                }
            ]
        );
    }
}

sub sms_get {
    my ( $self, $p ) = @_;
    my $id = $p->{id};
    _fail _loc('Missing message id') unless $id;
    my $username = $p->{username};
    _fail _loc('Missing username') unless $username;
    my $msg = mdb->sms->find_and_modify(
        {   query  => { _id => mdb->oid( $id ) },
            update => {
                '$push' => {
                    'shown' => {
                        u   => $username,
                        ts  => mdb->ts,
                        ua  => $p->{ua} || '',
                        add => $p->{add} || ''
                    }
                }
            },
            new => 1,
        }
    );

    $$msg{_id} .= '';
    return $msg;
}

sub sms_list {
    my ( $self, $ts ) = @_;
    $ts = $ts ||  mdb->ts;
    my @sms = map {
        $$_{_id} .= '';
        $$_{expired} = $$_{expires} gt $ts ? \0 : \1;
        $_
    } mdb->sms->find->fields( { t => 0 } )->sort( { t => -1 } )->all;
    return @sms;
}

1;
