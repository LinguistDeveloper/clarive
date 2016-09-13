package Baseliner::Controller::Notification;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Model::Notification;
use Try::Tiny;
use v5.10;
use experimental 'switch';

BEGIN {  extends 'Catalyst::Controller' }

sub list_notifications : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my ( $start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= '_id';
    $dir  ||= 'desc';
    if ( $dir eq 'desc' ) {
        $dir = -1;
    }
    else {
        $dir = 1;
    }

    $start ||= 0;
    $limit ||= 30;

    my $page = to_pages( start => $start, limit => $limit );

    my $where = {};

    if ($query) {
        $where = mdb->query_build(
            query  => $query,
            fields => [
                qw(
                id
                event_key
                data.recipients
                data.recipients.TO
                data.recipients.TO.Fields
                data.recipients.TO.Users
                data.recipients.TO.Users.mid
                data.recipients.TO.Users.name
                data.recipients.TO.Roles.mid
                data.recipients.TO.Roles.name
                data.recipients.TO.Actions
                data.recipients.TO.Owner
                data.recipients.TO.Emails
                data.recipients.BCC.Fields
                data.recipients.BCC.Users
                data.recipients.BCC.Users.mid
                data.recipients.BCC.Users.name
                data.recipients.BCC.Roles.mid
                data.recipients.BCC.Roles.name
                data.recipients.BCC.Actions
                data.recipients.BCC.Owner
                data.recipients.BCC.Emails
                data.recipients.CC
                data.recipients.CC.Fields
                data.recipients.CC.Users
                data.recipients.CC.Users.mid
                data.recipients.CC.Users.name
                data.recipients.CC.Roles.mid
                data.recipients.CC.Roles.name
                data.recipients.CC.Actions
                data.recipients.CC.Owner
                data.recipients.CC.Emails
                data.scopes.category.name
                data.scopes.category_status.name
                data.scopes.project.name
                data.scopes.bl.name
                data.scopes.status.name
                data.scopes.step.name
                data.scopes.field
                username
                template_path
                subject
                digest_time
                digest_date
                digest_freq)

            ]
        );
    }

    my $rs = mdb->notification->find($where);
    $rs->skip($start);
    $rs->limit($limit) unless $limit eq '-1';
    $rs->sort( { $sort => $dir } );

    my @rows;
    while ( my $r = $rs->next ) {
        my $data = Baseliner::Model::Notification->new->encode_data( $r->{data} );
        push @rows,
            {
            id            => $r->{_id}->{value},
            event_key     => $r->{event_key},
            data          => $data,
            action        => $r->{action},
            is_active     => $r->{is_active},
            template_path => $r->{template_path},
            subject       => $r->{subject},
            };
    }
    $cnt = mdb->notification->count();
    $c->stash->{json} = { data => \@rows, totalCount => $cnt };
    $c->forward("View::JSON");
}


sub list_events : Local {
    my ( $self, $c ) = @_;
    my @events = map {
        my $key = $_;
        my $event = $c->registry->get($_);
        my ($kind) = $key =~ /^event\.([^.]+)\./ ? $1 : 'event';
        +{
            key => $key,
            kind=>$kind,
            description=> _loc ($event->description ) // $_
         }
     } sort $c->registry->starts_with('event.');

    $c->stash->{json} = \@events;
    $c->forward('View::JSON');
}

sub list_status_end : Local {
    my ( $self, $c ) = @_;

    my @status = ( 'REJECTED', 'CANCELLED', 'TRAPPED', 'TRAPPED_PAUSED', 'ERROR', 'FINISHED', 'KILLED', 'EXPIRED' );

    my @names_status = map { +{ name => $_ } } @status;

    $c->stash->{json} = { data => \@names_status };
    $c->forward('View::JSON');
}

sub list_actions : Local {
    my ( $self, $c ) = @_;
    my @actions = map {+{action => $_,  checked => $_ eq 'SEND' ? \1: \0}} $c->model('Notification')->get_actions;

    $c->stash->{json} = \@actions;
    $c->forward('View::JSON');
}

sub list_carriers : Local {
    my ( $self, $c ) = @_;
    my @carriers = map {+{carrier => $_}} $c->model('Notification')->get_carriers;

    $c->stash->{json} = \@carriers;
    $c->forward('View::JSON');
}

sub list_type_recipients : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    my @type_recipients = Baseliner::Model::Notification->new->get_type_recipients;
    if ( $p->{action} && $p->{action} eq 'SEND' ) {
        @type_recipients = grep { $_ ne 'Default' } @type_recipients;
    }

    my @recipients = map { +{ id => $_, type_recipient => _loc($_) } } @type_recipients;

    $c->stash->{json} = \@recipients;
    $c->forward('View::JSON');
}

sub get_recipients : Local {
    my ( $self, $c, $type ) = @_;

    try {
        my $recipients = Baseliner::Model::Notification->new->get_recipients($type);
        my $field_type;

        if ( $type && $type eq 'Default' ) {
            $field_type = 'none';
        }
        elsif ( $type && $type eq 'Emails' ) {
            $field_type = 'textfield';
        }
        else {
            $field_type = 'combo';
        }

        $c->stash->{json} = { data => $recipients, field_type => $field_type, success => \1 };
    }
    catch {
        $c->stash->{json} = { msg => _loc('Se ha producido un error'), success => \0 };
    };
    $c->forward('View::JSON');
}

sub get_scope : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    try{
        my $scope;
        if (Baseliner->registry->get( $p->{key} )->notify){
            $scope =  Baseliner->registry->get( $p->{key} )->notify->{scope};
        }
        $c->stash->{json} = { data => $scope, success=>\1 };
    }catch{
        $c->stash->{json} = { msg=> _loc('Se ha producido un error'), success=>\0 };
    };

    $c->forward('View::JSON');
}

sub save_notification : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my %scope;
    my $recipient;
    my $data;

    try {
        if ( $p->{event} ) {
            if ( Baseliner::Core::Registry->get( $p->{event} )->notify ) {
                my $scope = Baseliner::Core::Registry->get( $p->{event} )->notify->{scope};
                my @scopes = grep { exists $p->{$_} && $p->{$_} ne '' } _array $scope;
                foreach my $key (@scopes) {
                    if ( $p->{$key} eq 'on' ) {
                        $scope{$key} = { '*' => _loc('All') };
                    }
                    else {
                        $scope{$key} = _decode_json( $p->{ $key . '_names' } );
                    }
                }
            }
        }

        $data->{scopes}     = \%scope;
        $data->{recipients} = _decode_json( $p->{recipients} );

        $data = Baseliner::Model::Notification->new->decode_data( _dump $data);
        my $id_notification = $p->{notification_id} eq '-1' ? '' : $p->{notification_id};
        my $notification = mdb->notification->update(
            { _id => mdb->oid($id_notification) },
            {   event_key     => $p->{event},
                action        => $p->{action},
                data          => $data,
                is_active     => '1',
                template_path => $p->{template},
                subject       => $p->{subject},
            },
            { 'upsert' => 1 }
        );

        if ( $p->{notification_id} eq '-1' ) {
            $c->stash->{json} = {
                success         => \1,
                msg             => _loc('Notification added'),
                notification_id => $notification->{upserted}->{value}
            };
        }
        else {
            $c->stash->{json}
                = { success => \1, msg => _loc('Notification updated'), notification_id => $p->{notification_id} };
        }
    }
    catch {
        my $err = shift;
        _error($err);
        $c->stash->{json} = { success => \0, msg => _loc( 'Error adding notification: %1', $err ) };
    };
    $c->forward('View::JSON');
}

sub remove_notifications : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $ids_notification = $p->{ids_notification};

    try{
        my @ids_notification;
        foreach my $id_notification (_array $ids_notification){
            push @ids_notification, $id_notification;
        }

        map {$_ = mdb->oid($_)} @ids_notification;

        mdb->notification->remove({_id => {'$in' => \@ids_notification }});

        $c->stash->{json} = { success => \1, msg=>_loc('Notifications deleted') };
    }
    catch{
        $c->stash->{json} = { success => \0, msg=>_loc('Error deleting notifications') };
    };
    $c->forward('View::JSON');
}

sub change_active : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my @ids_notifications = _array $p->{ids_notification};
    my $action = $p->{action};
    my $msg_active = $action eq 'active' ? 'activated' : 'deactivated';

    try{
        map {$_ = mdb->oid($_)} @ids_notifications;
        my @notifications = mdb->notification->find({_id => {'$in' => \@ids_notifications }})->all;
        foreach my $not (@notifications){
            mdb->notification->update({_id => $not->{_id} }, {'$set' => {is_active => $action eq 'active' ? '1' : '0' }});
        }
        $c->stash->{json} = { success => \1, msg => "Notifications $msg_active" };
    }
    catch{
        $c->stash->{json} = { success => \0, msg => 'Error modifying the notification' };
    };

    $c->forward('View::JSON');
}


sub get_templates : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    try{

        my @templates_dirs = map { $_->root } Baseliner->features->list;
        push @templates_dirs, $c->path_to( 'root' );
        my @templates;

        for my $template_dir ( @templates_dirs ) {
            push @templates, map { ( _file $_)->basename } <$template_dir/email/*>;
        }

        @templates = map { +{name => $_, path => "/email/$_" }}  @templates;

        $c->stash->{json} = { data => \@templates, success=>\1 };

    }catch{
        $c->stash->{json} = { data => {}, msg=> _loc('Se ha producido un error'), success=>\0 };
    };

     $c->forward('View::JSON');
}


sub export : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    try{
        $p->{id_notify} or _fail( _loc('Missing parameter id') );
        my $export;
        my @notifies;
        for my $id (  _array( $p->{id_notify} ) ) {
            my $notify = mdb->notification->find({_id => mdb->oid($id)})->next;
            _fail _loc('Notify not found for id %1', $id) unless $notify;
            push @notifies, $notify;
        }
        if( @notifies > 1 ) {
            my $yaml = _dump( \@notifies );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };
        } else {
            my $yaml = _dump( $notifies[0] );
            utf8::decode( $yaml );
            $c->stash->{json} = { success => \1, yaml=>$yaml };
        }
    }
    catch{
        $c->stash->{json} = { success => \0, msg => _loc('Error exporting: %1', shift()) };
    };
    $c->forward('View::JSON');
}

sub import_notification : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    cache->remove({ d=>'notify' }); # qr/^notify:/;
    $c->registry->reload_all;
    try{
        mdb->txn( sub {
            my $yaml = $p->{yaml} or _fail _loc('Missing parameter yaml');
            my $import = _load( $yaml );
            $import = [ $import ] unless ref $import eq 'ARRAY';
            for my $data ( _array( $import ) ) {
                next if !defined $data;
                my $is_new;
                my $notify;
                my $id = delete $data->{_id};
                push @log => "----------------| Notify: $data->{event_key} |----------------";
                #$notify = DB->BaliNotification->search({ event_key=>$data->{event_key} })->first;
                #$is_new = !$notify;
                #if( $is_new ) {
                    $notify = mdb->notification->insert($data);
                    push @log => _loc('Created notify %1', $data->{event_key} );
                #} else {
                #    $notify->update( $data );
                #    push @log => _loc('Updated notify %1', $data->{event_key} );
                #}

                #push @log => $is_new
                #    ? _loc('Notify created with id %1 and event_key %2:', $notify->id, $notify->event_key)
                #    : _loc('Notify %1 updated', $notify->event_key) ;

                push @log, _loc('Notify created with id %1 and event_key: %2', $id, $data->{event_key}) ;
            }
        });   # txn end

        $c->stash->{json} = { success => \1, log=>\@log, msg=>_loc('finished') };
    }
    catch{
        $c->stash->{json} = { success => \0, log=>\@log, msg => _loc('Error importing: %1', shift()) };
    };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
