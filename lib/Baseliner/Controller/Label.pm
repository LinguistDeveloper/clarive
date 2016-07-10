package Baseliner::Controller::Label;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Try::Tiny;
use v5.10;

use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils qw(_loc _error _array _fail _locl );
use Baseliner::Sugar;
use Baseliner::Model::Permissions;
use Baseliner::Model::Topic;

register 'action.admin.labels' => { name => _locl('Admin labels') };

register 'menu.admin.labels' => {
    label    => _locl('Labels'),
    title    => _locl('Labels'),
    action   => 'action.admin.labels',
    url_comp => '/label/grid',
    icon     => '/static/images/icons/flag_white.svg',
    tab_icon => '/static/images/icons/flag_white.svg'
};

with 'Baseliner::Role::ControllerValidator';

sub grid : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;
    $c->stash->{query_id} = $p->{query};
    $c->stash->{template} = '/comp/label_admin.js';
}

sub list : Local {
    my ( $self, $c ) = @_;

    my $p = $c->request->parameters;
    my ( $dir, $sort, $cnt ) = ( @{$p}{qw/dir sort/}, 0 );
    $dir = $dir && lc $dir eq 'desc' ? -1 : 1;
    $sort ||= 'name';

    my @rows;
    my $rs = mdb->label->find->sort( { $sort => $dir } );
    while ( my $r = $rs->next ) {
        push @rows,
            {
            id    => $r->{id},
            name => _loc( $r->{name} ),
            color => $r->{color},
            seq   => $r->{seq}
            };
    }

    $c->stash->{json} = { data => \@rows, totalCount => scalar @rows };
    $c->forward('View::JSON');
}

sub attach : Local {
    my ( $self, $c ) = @_;

    my $p                 = $c->req->params;
    my $topic_mid         = $p->{topic_mid};
    my @ids         = _array( $p->{ids} );
    my $attach_permission =
      Baseliner::Model::Permissions->user_has_action( $c->username, 'action.labels.attach_labels' );
    try {
        if ( !$attach_permission ) {
            _fail _loc(
                'User (%1) does not have permissions to attach a label',
                $c->username );
        }
        if (my $doc = mdb->topic->find_one(
                { mid    => "$topic_mid" },
                { labels => 1, category => 1, category_status => 1 }
            )
            )
        {
            mdb->topic->update( { mid => "$topic_mid" },
                { '$set' => { labels => \@ids } } );
            my $subject = _loc('Labels assigned');
            my $event   = 'event.file.labels';
            $self->_notify_topic_friends( $c, $topic_mid, $subject,
                $doc, $event );
        }
        else {
            _fail _loc( 'Topic not found: %1', $topic_mid );
        }
        $c->stash->{json}
            = { msg => _loc('Labels assigned'), success => \1 };
        cache->remove( { mid => "$topic_mid" } )
            if length $topic_mid;
    }
    catch {
        my $err = shift;
        my $msg = _loc( 'Error assigning Labels: %1', $err );
        _error($msg);
        $c->stash->{json} = { msg => $msg, success => \0 }
    };

    $c->forward('View::JSON');
}

sub detach : Local {
    my ( $self, $c, $topic_mid, $id ) = @_;

    my $detach_permission =
      Baseliner::Model::Permissions->user_has_action( $c->username, 'action.labels.remove_labels' );

    try {
        if ( !$detach_permission ) {
            _fail _loc(
                'User (%1) does not have permissions to detach a label',
                $c->username );
        }
        cache->remove( { mid => "$topic_mid" } ) if length $topic_mid;
        my $doc = mdb->topic->find_one( { mid => "$topic_mid" } );
        mdb->topic->update(
            { mid      => "$topic_mid" },
            { '$pull'  => { labels => $id } },
            { multiple => 1 }
        );
        my $subject = _loc('Labels deleted');
        my $event   = 'event.file.labels_remove';
        $self->_notify_topic_friends( $c, $topic_mid, $subject,
            $doc, $event );

        $c->stash->{json} = {
            msg     => _loc('Label deleted'),
            success => \1
        };
    }
    catch {
        $c->stash->{json} = {
            msg     => _loc( 'Error deleting label: %1', shift() ),
            success => \0
        };
    };

    $c->forward('View::JSON');
}

sub update : Local {
    my ( $self, $c ) = @_;

    my $username = $c->username;

    cache->remove({ d=>qr/^topic:/ });

    my $action = $c->req->param('action');
    if ( $action eq 'add' ) {
        return
          unless my $p = $self->validate_params(
            $c,
            name  => { isa => 'Str' },
            seq   => { isa => 'Num', default => 0 },
            color => { isa => 'Str', default => '#000000' },
          );

        my $row = mdb->label->find_one( { name => $p->{name} } );

        if ( !$row ) {
            mdb->label->insert( { id => mdb->seq('label'), %$p } );

            $c->stash->{json} = { success => \1, msg => _loc('Label added') };
        }
        else {
            $c->stash->{json} = {
                msg    => _loc('Validation failed'),
                errors => {
                    name => _loc( 'Label name already exists' )
                },
                success => \0
            };
        }
    }
    elsif ( $action eq 'update' ) {
        return
          unless my $p = $self->validate_params(
            $c,
            id    => { isa => 'Str' },
            name  => { isa => 'Str' },
            color => { isa => 'Str' },
            seq   => { isa => 'Num' },
          );

        my $id = delete $p->{id};

        my $row = mdb->label->find_one( { id => $id } );
        if ( !$row ) {
            $c->stash->{json} = {
                msg     => _loc( 'Label does not exist' ),
                success => \0
            };
        }
        else {
            my $label_with_same_name = mdb->label->find_one( { name => $p->{name} } );

            if ($label_with_same_name && $label_with_same_name->{id} ne $id) {
                $c->stash->{json} = {
                    msg     => _loc('Validation failed'),
                    errors  => { name => _loc('Label name already exists') },
                    success => \0
                };
            }
            else {
                mdb->label->update( { id => $id }, { '$set' => $p } );

                $c->stash->{json} = { success => \1, msg => _loc('Label modified') };
            }
        }
    }

    $c->forward('View::JSON');
}

sub delete : Local {
    my ( $self, $c ) = @_;

    my $p = $c->req->params;

    cache->remove_like(qr/^topic:/);
    my $ids = $p->{ids};

    try {
        my @ids = _array $ids;
        if (@ids) {
            mdb->label->remove( { id => mdb->in(@ids) }, { multiple => 1 } );

            # errors like "cannot $pull/pullAll..." is due to labels=>N
            mdb->topic->update(
                {},
                { '$pull'  => { labels => mdb->in(@ids) } },
                { multiple => 1 }
            );    # mongo rocks!
        }

        $c->stash->{json}
            = { success => \1, msg => _loc('Labels deleted') };
    }
    catch {
        my $err = shift;
        _error($err);
        $c->stash->{json} = {
            success => \0,
            msg     => _loc('Error deleting Labels') . ': ' . $err
        };
    };

    $c->forward('View::JSON');
}

sub _notify_topic_friends : Local {
    my ( $self, $c, $topic_mid, $subject, $doc, $event ) = @_;

    my @projects = mdb->master_rel->find_values(
        to_mid => { from_mid => "$topic_mid", rel_type => 'topic_project' } );
    my @users = Baseliner::Model::Topic->get_users_friend(
        mid         => $topic_mid,
        id_category => $doc->{category}{id},
        id_status   => $doc->{category_status}{id},
        projects    => \@projects
    );
    event_new "$event" => {
        username       => $c->username,
        mid            => $topic_mid,
        notify_default => \@users,
        subject        => $subject
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
