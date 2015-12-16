use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;
use Capture::Tiny qw(capture);

use TestEnv;
BEGIN { TestEnv->setup; }

use TestUtils;
use TestGit;

use BaselinerX::CI::project;

use_ok 'BaselinerX::CI::GitRevision';

subtest 'items: returns added items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: returns modified items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );
    my $sha2 = TestGit->commit($repo);

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns deleted items' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, action => 'git rm README' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'D';
    is $item->mask,   undef;
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns added items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit( $repo, action => 'git rm README' );
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns modified items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'M';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/README';
};

subtest 'items: returns deleted items when demoting' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );
    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( type => 'demote', bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'D';
    is $item->mask,   undef;
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: returns items referenced by branch' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    TestGit->tag( $repo, tag => 'TEST' );

    my $sha2 = TestGit->commit( $repo, file => 'NEW_FILE' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => 'HEAD' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my @items = $rev->items( bl => 'TEST', tag => 'TEST' );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $sha2;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: throws when redeploying without changesets' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/No changesets for this sha/;
};

subtest 'items: throws when redeploying when sha is in several changesets' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $topic2 = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic2->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/This sha is contained in more than one changeset/;
};

subtest 'items: cannot redeploy when no last job detected' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci('topic');
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    like exception { $rev->items( bl => 'TEST', tag => 'TEST' ) }, qr/No last job detected.*Cannot redeploy/;
};

subtest 'items: cannot redeploy when last job detected but without bl_original' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $project =
      TestUtils->create_ci( 'project', name => 'project', moniker => 'project', repositories => [ $repo->mid ] );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
        );
    };

    like exception { $rev->items( bl => 'TEST', tag => 'TEST', project => $project ) }, qr/No last job detected/;
};

subtest 'items: cannot redeploy when last job detected but with invalid bl_original' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', tags_mode => 'project', revision_mode => 'diff' );

    my $project =
      TestUtils->create_ci( 'project', name => 'project', moniker => 'project', repositories => [ $repo->mid ] );

    my $sha  = TestGit->commit($repo);
    my $sha2 = TestGit->commit($repo);

    TestGit->tag( $repo, tag => 'TEST' );

    my $rev = TestUtils->create_ci( 'GitRevision', repo => $repo, sha => $sha2 );
    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        'SomeThingElese' => {
                            current => 'Yeah'
                        }
                    }
                }
            }
        );
    };

    like exception { $rev->items( bl => 'TEST', tag => 'TEST', project => $project ) }, qr/No last job detected/;
};

subtest 'items: redeploy with tags_mode project' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', tags_mode => 'project', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $top_sha);

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current => $top_rev,
                            previous => $rev
                        }
                    }
                }
            }
        );
    };

    my @items = $top_rev->items( bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_rev->sha;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: redeploy' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $top_sha);

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        '*' => {
                            current => $top_rev,
                            previous => $rev
                        }
                    }
                }
            }
        );
    };

    my @items = $top_rev->items( bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_rev->sha;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: redeploy with branch as a revision' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => 'master');

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        '*' => {
                            current => $top_rev,
                            previous => $rev
                        }
                    }
                }
            }
        );
    };

    my @items = $top_rev->items( bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_sha;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: redeploy with tag as a revision' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    TestGit->tag($repo, tag => 'master#123-foo');
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => 'master#123-foo');

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        '*' => {
                            current => $top_rev,
                            previous => $rev
                        }
                    }
                }
            }
        );
    };

    my @items = $top_rev->items( bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_sha;
    is $item->path,   '/NEW_FILE';
};

subtest 'items: redeploy after redeploy' => sub {
    _setup();

    my $repo = TestUtils->create_ci_GitRepository( name => 'repo', tags_mode => 'project', revision_mode => 'diff' );

    my $sha = TestGit->commit($repo);
    my $rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $sha);

    my $top_sha = TestGit->commit( $repo, file => 'NEW_FILE' );
    my $top_rev = TestUtils->create_ci('GitRevision', repo => $repo, sha => $top_sha);

    TestGit->tag( $repo, tag => 'TEST' );

    TestUtils->create_ci( 'bl', bl => 'TEST' );

    my $topic = TestUtils->create_ci( 'topic', is_changeset => 1, _doc => {} );
    mdb->master_rel->insert(
        { from_mid => $topic->mid, to_mid => $top_rev->mid, rel_type => 'topic_revision', rel_field => 'revisions' } );

    my $project = TestUtils->create_ci( 'project', name => 'Project' );

    mdb->rule->insert( { id => '1', rule_when => 'promote' } );

    capture {
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            endtime      => '2015-01-01 00:00:00',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $top_rev,
                            previous => $rev
                        }
                    }
                }
            }
        );
        TestUtils->create_ci(
            'job',
            final_status => 'FINISHED',
            changesets   => [$topic],
            bl           => 'TEST',
            endtime      => '2015-01-01 00:00:01',
            stash_init   => {
                bl_original => {
                    $repo->mid => {
                        $project->mid => {
                            current  => $top_rev,
                            previous => $top_rev
                        }
                    }
                }
            }
        );
    };

    my @items = $top_rev->items( bl => 'TEST', tag => 'TEST', project => $project );
    is scalar @items, 1;

    my $item = $items[0];
    is $item->status, 'A';
    is $item->mask,   '644';
    is $item->repo,   $repo;
    is $item->sha,    $top_rev->sha;
    is $item->path,   '/NEW_FILE';
};

done_testing;

sub _setup {
    TestUtils->cleanup_cis;

    mdb->rule->drop;
    mdb->topic->drop;
    mdb->category->drop;

    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI', 'Baseliner::Model::Jobs' );
}
