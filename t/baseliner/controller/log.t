use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use TestEnv;
BEGIN { TestEnv->setup; }
use TestUtils ':catalyst';
use TestSetup;
use Compress::Zlib qw(compress);
use Encode ();
use Digest::MD5 qw(md5_base64);

use Capture::Tiny qw(capture);

use_ok 'Baseliner::Controller::Log';

subtest 'log_data: throws no log found' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    like exception { $controller->log_data( $c, 123 ) }, qr/Log row not found/;
};

subtest 'log_data: returns job log data' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $id_asset = mdb->grid_add(
        'foobarbaz',
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_data( $c, $id_job );

    is $c->res->body, '<pre>foobarbaz</pre>';
};

subtest 'log_data: returns job log data unicode' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $id_asset = mdb->grid_add(
        Encode::encode( 'UTF-8', "\x{1F61C}" ),
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_data( $c, $id_job );

    is $c->res->body, "<pre>\x{1F61C}</pre>";
};

subtest 'log_data: returns job log data uncompressed' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $id_asset = mdb->grid_add(
        Baseliner::Utils::compress('foobarbaz'),
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_data( $c, $id_job );

    is $c->res->body, '<pre>foobarbaz</pre>';
};

subtest 'log_data: returns job log data html escaped' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $id_asset = mdb->grid_add(
        '<script>alert("HELLO!")</scrtip>',
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_data( $c, $id_job );

    is $c->res->body, '<pre>&lt;script&gt;alert("HELLO!")&lt;/scrtip&gt;</pre>';
};


subtest 'log_data: returns job log data html escaped' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $id_asset = mdb->grid_add(
        '<script>alert("HELLO!")</scrtip>',
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_data( $c, $id_job );

    is $c->res->body, '<pre>&lt;script&gt;alert("HELLO!")&lt;/scrtip&gt;</pre>';
};

subtest 'logs_list: returns message error then log does not exist' => sub {
    _setup();

    my $fake_mid = '1111111';

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { mid => $fake_mid } } );

    $controller->logs_list($c);

    cmp_deeply $c->stash->{json},
        {
        success => \0,
        msg     => 'The log does not exist'
        };
};

subtest 'log_highlight: returns job log hightlighted' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job } );

    my $data     = 'hello';
    my $id_asset = mdb->grid_add(
        $data,
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset, data_length => length $data } } );

    my $controller = _build_controller();

    my $c = _build_c();

    $controller->log_highlight( $c, $id_job );

    cmp_deeply $c->stash,
      {
        'style'    => 'golden',
        'class'    => 'spool',
        'template' => '/site/highlight.html',
        'data'     => 'hello'
      };
};

subtest 'log_file: returns job log for download' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $_id = mdb->job_log->insert( { id => $id_job, mid => 'job_log-1' } );

    my $data     = "\x{1F62E}";
    my $id_asset = mdb->grid_add(
        Encode::encode( 'UTF-8', $data ),
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $_id,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset, data_length => length $data } } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $id_job } } );

    $controller->log_file($c);

    cmp_deeply $c->stash,
      {
        'serve_filename' => "job_log-1-$id_job-attachment.txt",
        'serve_body'     => Encode::encode( 'UTF-8', "\x{1F62E}" )
      };
};

subtest 'log_file: returns job log for download on binary files' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    my $id_log = mdb->job_log->insert( { id => $id_job, mid => 'job_log-1' } );

    open my $ff, '>', 'test.txt';
    print $ff Encode::encode( 'UTF-8', "some contents \x{1F62E}\n" );
    close $ff;

    my $cmd = "tar -czvf test.tar.gz test.txt 2>&1";
    system($cmd);

    open my $ft, '<', 'test.tar.gz';
    my $data = join '', <$ft>;
    close $ft;

    compress($data);

    my $id_asset = mdb->grid_add(
        $data,
        filename          => 'logdata',
        parent_collection => 'log',
        id_log            => $id_log,
        parent            => $id_job,
        parent_mid        => 123,
    );

    mdb->job_log->update( { id => $id_job }, { '$set' => { data => $id_asset, data_length => length $data } } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $id_job } } );

    $controller->log_file($c);

    open my $fn, '>', 'new_test.tar.gz';
    print $fn $c->stash->{serve_body};
    close $fn;

    open( HANDLE, "<", 'test.tar.gz' );
    my $cksum1 = md5_base64(<HANDLE>);
    open( HANDLE, "<", 'new_test.tar.gz' );
    my $cksum2 = md5_base64(<HANDLE>);

    $cmd = "rm test.txt test.tar.gz new_test.tar.gz";
    system($cmd);

    is $cksum1, $cksum2;
};

subtest 'logs_json: returns job log as json' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    mdb->rule->insert(
        {
            id        => '1',
            rule_type => 'pipeline',
            rule_when => 'promote',
        }
    );

    my $job = BaselinerX::CI::job->new( changesets => [$changeset] );

    my $id_job;
    capture {
        $id_job = $job->save;
        $job->start_task( 'some_task', 123 )
    };

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { mid => $id_job } } );

    $controller->logs_json($c);

    cmp_deeply $c->stash,
      {
        json => {
            job        => ignore(),
            totalCount => re(qr/^\d+$/),
            data       => ignore(),
            job_key    => $job->job_key
        }
      };
};

subtest 'logs_json: returns job log as json filtered' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    mdb->rule->insert(
        {
            id        => '1',
            rule_type => 'pipeline',
            rule_when => 'promote',
        }
    );

    my $job = BaselinerX::CI::job->new( changesets => [$changeset] );

    my $id_job;
    capture {
        $id_job = $job->save;
        $job->start_task( 'some_task', 123 )
    };

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { mid => $id_job, filter => JSON::encode_json({name => '123'}) } } );

    $controller->logs_json($c);

    is $c->stash->{json}->{totalCount}, 0;
};

subtest 'auto_refresh: returns the latest job log info' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    mdb->rule->insert(
        {
            id        => '1',
            rule_type => 'pipeline',
            rule_when => 'promote',
        }
    );

    my $job = BaselinerX::CI::job->new( changesets => [$changeset] );

    my $id_job;
    capture {
        $id_job = $job->save;
        $job->start_task( 'some_task', 123 )
    };

    my $controller = _build_controller();

    #my $c = _build_c( req => { params => { mid => $id_job, filter => JSON::encode_json({name => '123'}) } } );
    my $c = _build_c( req => { params => { mid => $id_job } } );

    $controller->auto_refresh($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'count'    => ignore(),
            'stop_now' => \1,
            'top_id'   => ignore()
        }
      };
};

subtest 'auto_refresh: returns the latest job log info filtered' => sub {
    _setup();

    my $project = TestUtils->create_ci_project();
    my $id_role = TestSetup->create_role();
    my $user    = TestSetup->create_user( id_role => $id_role, project => $project );

    my $changeset = TestSetup->create_topic( is_changeset => 1, username => $user->name );

    mdb->rule->insert(
        {
            id        => '1',
            rule_type => 'pipeline',
            rule_when => 'promote',
        }
    );

    my $job = BaselinerX::CI::job->new( changesets => [$changeset] );

    my $id_job;
    capture {
        $id_job = $job->save;
        $job->start_task( 'some_task', 123 )
    };

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { mid => $id_job, filter => JSON::encode_json({name => '123'}) } } );

    $controller->auto_refresh($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'count'    => 0,
            'stop_now' => \1,
            'top_id'   => undef
        }
      };
};

subtest 'auto_refresh: returns empty refresh when no job found' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { } } );

    $controller->auto_refresh($c);

    cmp_deeply $c->stash,
      {
        'json' => {
            'count'    => 0,
            'stop_now' => \1,
            'top_id'   => undef
        }
      };
};

subtest 'log_stream: returns error when stream file not available' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    mdb->job_log->insert( { id => $id_job } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $id_job } } );

    $controller->log_stream($c);

    like $c->res->body, qr/no stream available/i;
};

subtest 'log_stream: returns streaming js' => sub {
    _setup();

    my $path = File::Temp->new;
    TestUtils->write_file('something', $path->filename);

    my $id_job = 0 + mdb->seq('job_log_id');
    mdb->job_log->insert( { id => $id_job, stream => $path->filename } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $id_job } } );

    $controller->log_stream($c);

    like $c->res->body, qr/xhr/;
};

subtest 'log_stream_events: throws error when stream file not available' => sub {
    _setup();

    my $id_job = 0 + mdb->seq('job_log_id');
    mdb->job_log->insert( { id => $id_job } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => $id_job } } );

    like exception { $controller->log_stream_events($c) }, qr/no stream available/i;
};

done_testing;

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    Baseliner::Controller::Log->new( application => '' );
}

sub _setup {
    TestUtils->setup_registry(
        'BaselinerX::CI',
        'BaselinerX::Type::Action',
        'BaselinerX::Type::Event',
        'BaselinerX::Type::Fieldlet',
        'BaselinerX::Type::Statement',
        'BaselinerX::Type::Service',
        'BaselinerX::Fieldlets',
        'Baseliner::Model::Topic',
        'Baseliner::Model::Rules',
        'Baseliner::Model::Jobs',
    );

    TestUtils->cleanup_cis();

    mdb->role->drop;
    mdb->rule->drop;
    mdb->job_log->drop;
}
