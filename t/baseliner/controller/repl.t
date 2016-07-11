use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Test::MonkeyMock;
use Test::TempDir::Tiny;

use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst', 'mock_time';

use JSON ();
use Baseliner::Utils qw(_dump _load _slurp);

use_ok 'Baseliner::Controller::REPL';

subtest 'eval: executes code and returns correct results' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "yaml",
                show    => "cons",
                lang    => 'perl',
                code    => 'print "output"; my $x = 123;',
                as_json => 1,
            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message1) = $fh->mocked_call_args( 'write', 0 );
    my ($message2) = $fh->mocked_call_args( 'write', 1 );

    my ($length1, $json1) = split "\n", $message1;
    my ($length2, $json2) = split "\n", $message2;

    ok $length1;
    is_deeply JSON::decode_json($json1),
      {
        type => 'output',
        data => 'output'
      };
    ok $length2;
    cmp_deeply JSON::decode_json($json2),
      {
        type => 'result',
        data => {
            result  => "--- 123\n",
            error   => '',
            elapsed => ignore(),
            stdout  => 'output',
            stderr  => '',
        }
      };

    ok $fh->mocked_called('close');
};

subtest 'eval: returns result as json' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "json",
                show    => "cons",
                lang    => 'perl',
                code    => '{foo => "bar"}',
                as_json => 1,
            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message2) = $fh->mocked_call_args( 'write', 0 );
    my ($length2, $json2) = split "\n", $message2;

    is JSON::decode_json($json2)->{data}->{result}, qq/{\n   "foo" : "bar"\n}\n/;
};

subtest 'eval: returns correct results with exceptions' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "yaml",
                show    => "cons",
                lang    => 'perl',
                code    => 'die "error"',
                as_json => 1,
            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message1) = $fh->mocked_call_args( 'write', 0 );

    my ($length1, $json1) = split "\n", $message1;

    cmp_deeply JSON::decode_json($json1),
      {
        type => 'result',
        data => {
            result  => "--- ~\n",
            error   => re(qr/error/),
            elapsed => ignore(),
            stdout  => '',
            stderr  => '',
        }
      };

    ok $fh->mocked_called('close');
};

subtest 'eval: returns result value as json' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "json",
                show    => "cons",
                lang    => 'perl',
                code    => 'print "output"; my $x = {foo => "bar"};',
                as_json => 1,
            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message) = $fh->mocked_call_args( 'write', 1 );

    my ($length, $json) = split "\n", $message;

    cmp_deeply JSON::decode_json($json),
      {
        type => 'result',
        data => {
            result  => qq/{\n   "foo" : "bar"\n}\n/,
            error   => '',
            elapsed => ignore(),
            stdout  => 'output',
            stderr  => '',
        }
      };

    ok $fh->mocked_called('close');
};

subtest 'eval: javascript code executed' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "yaml",
                show    => "cons",
                lang    => 'js-server',
                code    => 'var x = 123; x',
                as_json => 1,

            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message) = $fh->mocked_call_args( 'write', 1 );

    my ($length, $json) = split "\n", $message;

    cmp_deeply JSON::decode_json($json),
      {
        type => 'result',
        data => {
            result  => "--- '123'\n",
            error   => '',
            elapsed => ignore(),
            stdout  => ignore(),
            stderr  => '',
        }
      };

    ok $fh->mocked_called('close');
};

subtest 'eval: correctly decodes unicode' => sub {
    _setup();

    my $controller = _build_controller();

    my $fh = _mock_fh();

    my $c = _build_c(
        req => {
            params => {
                eval    => 1,
                dump    => "yaml",
                show    => "cons",
                lang    => 'perl',
                code    => qq{print "\x{1F627}"; "привет"},
                as_json => 1,
            }
        },
        res => FakeResponse->new( write_fh => $fh )
    );

    $controller->eval($c);

    my ($message1) = $fh->mocked_call_args( 'write', 0 );
    my ($message2) = $fh->mocked_call_args( 'write', 1 );

    my ($length1, $json1) = split "\n", $message1;
    my ($length2, $json2) = split "\n", $message2;

    ok $length1;
    is_deeply JSON::decode_json($json1),
      {
        type => 'output',
        data => "\x{1F627}"
      };
    ok $length2;
    cmp_deeply JSON::decode_json($json2),
      {
        type => 'result',
        data => {
            result  => "--- привет\n",
            error   => '',
            elapsed => ignore(),
            stdout  => "\x{1F627}",
            stderr  => '',
        }
      };
};

subtest 'tree_hist: returns history' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c(
        req => {
            params => {
                lang => 'js-server',
                code => 'var x = 123; x',
            }
        }
    );

    $controller->eval($c);

    $controller->tree_hist($c);

    cmp_deeply $c->stash->{json},
      [
        {
            'data' => {
                'text' => ignore(),
            },
            'text'      => re(qr/.*? \(js-server\): var x = 123; x/),
            'iconCls'   => 'default_folders',
            'url_click' => '/repl/load_hist',
            'leaf'      => \1
        }
      ];
};

subtest 'tree_hist: returns history by query' => sub {
    _setup();

    my $controller = _build_controller();

    my $c;

    mock_time '2016-01-01 00:00:00', sub {
        $c = _build_c(
            req => {
                params => {
                    lang => 'js-server',
                    code => 'var x = 123; x',
                }
            }
        );
        $controller->eval($c);
    };

    mock_time '2016-01-01 00:01:00', sub {
        $c = _build_c(
            session => $c->session,
            req     => {
                params => {
                    lang => 'js-server',
                    code => '[1, 2, 3]',
                }
            }
        );
        $controller->eval($c);
    };

    $c = _build_c(
        session => $c->session,
        req     => {
            params => {
                query => 'var x'
            }
        }
    );

    $controller->tree_hist($c);

    cmp_deeply $c->stash->{json},
      [
        {
            'data' => {
                'text' => ignore(),
            },
            'text'      => re(qr/.*? \(js-server\): var x = 123; x/),
            'iconCls'   => 'default_folders',
            'url_click' => '/repl/load_hist',
            'leaf'      => \1
        }
      ];
};

subtest 'tidy: tidies code' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                code    => "if(1){\n22;}",
                as_json => 1,
            }
        }
    );

    $controller->tidy($c);

    my $lines = scalar split /\n/, $c->stash->{json}{code};
    is $lines, 3;
};

subtest 'save: returns successful response' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                id   => 'foo',
                text => 'bar'
            }
        }
    );

    $controller->save($c);

    cmp_deeply $c->stash, { json => { success => \1 } };
};

subtest 'save: saves code' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        username => 'tester',
        req      => {
            params => {
                id   => 'foo',
                text => 'bar'
            }
        }
    );

    $controller->save($c);

    my $repl = mdb->repl->find_one;

    cmp_deeply $repl, { _id => 'foo', id => 'foo', text => 'bar', username => 'tester' };
};

subtest 'save: overwrites existing id' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        username => 'tester',
        req      => {
            params => {
                id   => 'foo',
                text => 'baz'
            }
        }
    );

    $controller->save($c);

    my $repl = mdb->repl->find_one;

    cmp_deeply $repl, { _id => 'foo', id => 'foo', text => 'baz', username => 'tester' };
};

subtest 'load: throws when no entry found' => sub {
    _setup();

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                id => 'unknown'
            }
        }
    );

    like exception { $controller->load($c) }, qr/REPL entry not found: unknown/;
};

subtest 'load: returns history' => sub {
    _setup();

    mdb->repl->insert( { _id => 'foo', id => 'foo', text => 'bar' } );

    my $controller = _build_controller();
    my $c          = _build_c(
        req => {
            params => {
                id => 'foo'
            }
        }
    );

    $controller->load($c);

    is_deeply $c->stash,
      {
        'json' => {
            'id'   => 'foo',
            'text' => 'bar',
            '_id'  => 'foo'
        }
      };
};

subtest 'delete: throws when unknown id' => sub {
    _setup();

    my $controller = _build_controller();

    my $c = _build_c();

    like exception { $controller->delete($c) }, qr/Missing REPL id/;
};

subtest 'delete: deletes repl history' => sub {
    _setup();

    mdb->repl->insert( { _id => 'foo', id => 'foo', text => 'bar' } );

    my $controller = _build_controller();

    my $c = _build_c( req => { params => { id => 'foo' } } );

    $controller->delete($c);

    ok !mdb->repl->find_one;

    cmp_deeply $c->stash, { json => { success => \1 } };
};

subtest 'save_to_file: deletes colons in filenames' => sub {
    _setup();

    mdb->repl->insert( { _id => 'title', id => 'foo:title', code => 'bar', output => 'output' } );

    my $tempdir    = tempdir();
    my $controller = _build_controller();
    my $c          = _build_c( path_to => $tempdir );

    $controller->save_to_file($c);

    ok -f "$tempdir/etc/repl/footitle.t";
};

subtest 'save_to_file: replaces whitespaces by dashes in filenames' => sub {
    _setup();

    mdb->repl->insert( { _id => 'title', id => 'foo new title', code => 'bar', output => 'output' } );

    my $tempdir    = tempdir();
    my $controller = _build_controller();
    my $c          = _build_c( path_to => $tempdir );

    $controller->save_to_file($c);

    ok -f "$tempdir/etc/repl/foo-new-title.t";
};

subtest 'save_to_file: writes the code and the output in files' => sub {
    _setup();

    mdb->repl->insert( { _id => 'foo', id => 'foo', code => 'bar', output => 'output' } );

    my $tempdir    = tempdir();
    my $controller = _build_controller();
    my $c          = _build_c( path_to => $tempdir );

    $controller->save_to_file($c);

    my @file_array;
    my $filename = $c->path_to( 'etc', 'repl', "foo.t" );
    my $file = _slurp($filename);

    is $file, "bar\n__END__\noutput\n";
};

subtest 'save_to_file: shows an error when try to create the unknown folder' => sub {
    _setup();

    mdb->repl->insert( { _id => 'foo', id => 'foo', code => 'bar', output => 'bar' } );

    my $tempdir    = tempdir();
    my $controller = _build_controller();
    my $c          = _build_c( path_to => '/unknown/folder' );

    $controller->save_to_file($c);

    cmp_deeply $c->stash,
        {
        json => {
            msg     => re(qr/Cannot save: mkdir \/unknown/),
            success => \0
        }
        };
};

done_testing;

sub _setup {
    TestUtils->setup_registry( 'BaselinerX::Type::Event', 'BaselinerX::CI' );

    TestUtils->cleanup_cis;

    mdb->repl->drop;
}

sub _mock_fh {
    my $fh = FakeResponseFileHandle->new;
    $fh = Test::MonkeyMock->new($fh);
    $fh->mock('write');
    $fh->mock('close');
    return $fh;
}

sub _build_c {
    mock_catalyst_c(@_);
}

sub _build_controller {
    my (%params) = @_;

    return Baseliner::Controller::REPL->new( application => '' );
}
