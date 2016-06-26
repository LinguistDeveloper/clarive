use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';

use_ok 'Baseliner::Controller::Review';

use Baseliner::Utils qw(_load);

subtest 'add: creates review' => sub {
    _setup();

    my $controller = _build_controller();

    my $repo = TestUtils->create_ci('GitRepository');
    my $rev = TestUtils->create_ci( 'GitRevision', sha => '123' );

    my $c = _build_c(
        username => 'user',
        req      => {
            params => {
                repo_mid => $repo->mid,
                rev_num  => '123',
                branch   => '',
                text     => 'hello',
                file     => 'some/file.txt',
                line     => 15,
                action   => 'add'
            }
        },
    );

    $controller->add($c);

    my $review = ci->review->find_one();

    is $review->{repo}, $repo->mid;
    is $review->{rev},  $rev->mid;

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'ok',
            data    => {
                'text'       => 'hello',
                'rev'        => ignore(),
                'created_by' => 'user',
                'created_on' => ignore(),
                'file'       => 'some/file.txt',
                'line'       => 15,
                'action'     => 'add',
                'repo'       => ignore()
            }
        }
      };
};

subtest 'add: creates correct event' => sub {
    _setup();

    my $controller = _build_controller();

    my $repo = TestUtils->create_ci('GitRepository');
    my $rev = TestUtils->create_ci( 'GitRevision', sha => '123' );
    my $project = TestUtils->create_ci('project', name => 'Project', repositories => [$repo->mid]);

    my $review1 = TestUtils->create_ci(
        'review',
        repo       => $repo->mid,
        rev        => $rev->mid,
        created_by => 'user1',
        file       => 'file1.txt',
        line       => 1
    );

    my $c = _build_c(
        username => 'user',
        req      => {
            params => {
                repo_mid => $repo->mid,
                rev_num  => '123',
                branch   => '',
                text     => 'hello',
                file     => 'some/file.txt',
                line     => 15,
                action   => 'add'
            }
        },
    );

    $controller->add($c);

    my $event = mdb->event->find_one({event_key => 'event.review.create'});

    my $event_data = _load $event->{event_data};

    cmp_deeply $event_data,
      superhashof(
        {
            subject        => '@user created a review for 123',
            project        => ['Project'],
            notify_default => ['user1']
        }
      );
};

subtest 'list: returns reviews grouped by files' => sub {
    _setup();

    my $controller = _build_controller();

    my $repo = TestUtils->create_ci('GitRepository');
    my $rev = TestUtils->create_ci( 'GitRevision', sha => '123' );

    my $review1 = TestUtils->create_ci(
        'review',
        repo       => $repo->mid,
        rev        => $rev->mid,
        created_by => 'user1',
        file       => 'file1.txt',
        line       => 1
    );
    $review1->put_data('good');

    my $review2 = TestUtils->create_ci(
        'review',
        repo       => $repo->mid,
        rev        => $rev->mid,
        created_by => 'user2',
        file       => 'file1.txt',
        line       => 3
    );
    $review2->put_data('bad');

    my $review3 = TestUtils->create_ci(
        'review',
        repo       => $repo->mid,
        rev        => $rev->mid,
        created_by => 'user3',
        file       => 'file2.txt',
        line       => 5
    );
    $review3->put_data('so so');

    my $c = _build_c(
        req => {
            params => {
                repo_mid => $repo->mid,
                rev_num  => '123',
            }
        },
    );

    $controller->list($c);

    cmp_deeply $c->stash,
      {
        json => {
            success => \1,
            msg     => 'ok',
            data    => {
                'file1.txt' => [ superhashof( { text => 'good' } ), superhashof( { text => 'bad' } ), ],
                'file2.txt' => [ superhashof( { text => 'so so' } ), ]
            }
        }
      };
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'BaselinerX::CI::review' );

    TestUtils->cleanup_cis;

    mdb->event->drop;
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::Review->new( application => '' );
}
