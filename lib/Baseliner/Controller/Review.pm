package Baseliner::Controller::Review;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

with 'Baseliner::Role::ControllerValidator';

use BaselinerX::CI::review;
use Baseliner::Utils qw(_loc _array _ci);
use Baseliner::Sugar;

sub add : Local {
    my ( $self, $c ) = @_;

    return
      unless my $params = $self->validate_params(
        $c,
        repo_mid => { isa => 'ExistingCI' },
        rev_num  => { isa => 'Str' },
        branch   => { isa => 'Str', default => undef },
        file     => { isa => 'Str' },
        line     => { isa => 'PositiveInt' },
        text     => { isa => 'Str' },
        action   => { isa => 'Str', default => undef },
      );

    my $repo_mid = $params->{repo_mid};
    my $rev_num  = $params->{rev_num};
    my $branch   = $params->{branch};
    my $file     = $params->{file};
    my $line     = $params->{line};
    my $text     = $params->{text};
    my $action   = $params->{action};

    my $repo = ci->new($repo_mid);

    my $rev = ci->GitRevision->search_ci( sha => $rev_num );
    if ( !$rev ) {
        $rev = ci->GitRevision->new( repo => $repo, sha => $rev_num );
        $rev->save;
    }

    my $branch_rev = ci->GitRevision->find_one( { sha => $branch } );

    my $data = {
        repo       => $repo_mid,
        rev        => $rev->{mid},
        file       => $file,
        line       => $line,
        created_by => $c->username,
        action     => $action,
    };
    my $review = BaselinerX::CI::review->new(%$data);
    $review->save;

    $review->put_data($text);

    my %users_to_notify;

    my @rels = mdb->master_rel->find_values( from_mid => { to_mid => mdb->in( $rev->{mid}, $branch_rev->{mid} ) } );
    if (@rels) {
        my @topics = mdb->topic->find( { mid => mdb->in(@rels) } )->all;

        foreach my $topic (@topics) {
            my $friends = $self->_topic_friends( $c, $topic );

            $users_to_notify{$_}++ for @$friends;
        }
    }

    my @projects = $repo->related(
        where     => { collection => 'project' },
        docs_only => 1
    );

    my @other_reviews_users = map { $_->{created_by} } $rev->related(
        where     => { collection => 'review', mid => {'$ne' => $review->mid} },
        docs_only => 1
    );
    $users_to_notify{$_}++ for @other_reviews_users;

    my $subject = _loc( "@%1 created a review for %2", $c->username, $rev->sha );
    my $notify = {
        mid     => $review->mid,
        project => [ map { $_->{mid} } @projects ],
    };

    event_new 'event.review.create' => {
        username => $c->username,
        mid      => $review->mid,
        text     => $review->text,
        subject  => $subject,
        project  => [ map { $_->{name} } @projects ],

        notify_default => [ keys %users_to_notify ],
        notify         => $notify
    };

    $c->stash->{json} = {
        success => \1,
        msg     => 'ok',
        data    => {
            %$data,
            created_on => $review->created_on,
            text       => $text
        }
    };

    $c->forward('View::JSON');
}

sub list : Local {
    my ( $self, $c ) = @_;

    return
      unless my $params = $self->validate_params(
        $c,
        repo_mid => { isa => 'ExistingCI' },
        rev_num  => { isa => 'Str' },
      );

    my $repo_mid = $params->{repo_mid};
    my $rev_num  = $params->{rev_num};

    my $repo = ci->new($repo_mid);
    my $rev = ci->GitRevision->find_one( { sha => $rev_num } );

    my @reviews = BaselinerX::CI::review->find(
        {
            repo => $repo->mid,
            rev  => $rev->{mid},
        }
    )->all;

    my %reviews_by_file;
    foreach my $review (@reviews) {
        push @{ $reviews_by_file{ $review->{file} } }, { %$review, text => ci->new( $review->{mid} )->text };
    }

    $c->stash->{json} = { success => \1, msg => 'ok', data => \%reviews_by_file };

    $c->forward('View::JSON');
}

sub _topic_friends {
    my $self = shift;
    my ( $c, $topic_row, $review ) = @_;

    my $topic_mid = $topic_row->{mid};

    # notification data
    my @projects = mdb->master_rel->find_values( to_mid => { from_mid => "$topic_mid", rel_type => 'topic_project' } );
    my @users = Baseliner->model("Topic")->get_users_friend(
        mid         => $topic_mid,
        id_category => $topic_row->{category}{id},
        id_status   => $topic_row->{category_status}{id},
        projects    => \@projects
    );

    return \@users;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
