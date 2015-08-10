use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';
use TestEnv;

use JSON ();
use Baseliner::Role::CI;
use Baseliner::Core::Registry;
use BaselinerX::Type::Event;
use BaselinerX::Type::Statement;

TestEnv->setup;

$Clarive::_no_cache++;
$Baseliner::_no_cache++;

my $RE_ts = qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/;
my $RE_t  = qr/^\d+\.\d+$/;

use BaselinerX::Type::Event;

use_ok 'Baseliner::Model::Events';

subtest 'find_by_key: returns empty array ref when events not found' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_key('foo.bar');

    is_deeply $rv, [];
};

subtest 'find_by_key: returns events' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_key('event.topic.change_status');

    is scalar @$rv, 1;
    is $rv->[0]->{mid}, '1479';
    is $rv->[0]->{foo}, 'bar';
};

subtest 'find_by_mid: returns empty array ref when events not found' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_mid(999);

    is_deeply $rv, [];
};

subtest 'find_by_mid: returns empty array ref when event not registered' => sub {
    _setup();

    my $events = _build_model();

    my $rv = $events->find_by_mid(1479);

    is_deeply $rv, [];
};

subtest 'find_by_mid: returns mapped event' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.topic.change_status', { vars => ['foo'] } );

    my $events = _build_model();

    my $rv = $events->find_by_mid(1479);

    is_deeply $rv,
      [
        {
            'text'     => 'Event event.topic.change_status occurred',
            'ts'       => '2015-04-02 15:48:54',
            'foo'      => 'bar',
            'username' => 'clarive'
        }
      ];
};

subtest 'new_event: creates new event' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'BaselinerX::Type::Event', 'event.job.new', {} );

    my $events = _build_model();

    $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { } );

    my $event = mdb->event->find_one( { module => 'main' } );

    #is $event->{id            => $ev_id,
    like $event->{ts},      $RE_ts;
    like $event->{t},       $RE_t;
    is $event->{event_key}, 'event.job.new';

    #is $event->{event_data    => $event_data,
    is $event->{event_status}, 'new';
    is $event->{module},       'main';

    #is $event->{mid           => $ed->{mid},
    is $event->{username}, 'root';
};

subtest 'new_event: creates new activity' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'BaselinerX::Type::Event', 'event.job.new', {} );

    my $events = _build_model();

    $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { } );

    my $activity = mdb->event->find_one( { module => 'main' } );

    like $activity->{ts},         $RE_ts;
    like $activity->{t},          $RE_t;
    is $activity->{event_key},    'event.job.new';
    is $activity->{event_status}, 'new';
    is $activity->{module},       'main';
    is $activity->{username},     'root';
};

subtest 'new_event: creates log' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    my $events = _build_model();

    $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { } );

    my @logs = mdb->event_log->find->all;

    my $rule = mdb->rule->find_one;
    my $event = mdb->event->find_one( { module => 'main' } );

    like $logs[0]->{ts},     $RE_ts;
    like $logs[0]->{t},      $RE_t;
    is $logs[0]->{id_event}, $event->{id};
    is $logs[0]->{id_rule},  $rule->{id};
    is $logs[0]->{dsl},      'Clarive::RULE_' . $rule->{id};
};

subtest 'new_event: runs pre rules' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    _register_statements();

    _create_run_rule(
        id        => '2',
        rule_when => 'pre-online',
        code      => q/$stash->{foo} = 'bar'/
    );

    my $events = _build_model();

    my $data = $events->new_event( 'event.job.new' => { username => 'root', bl => '*', job_step => 'RUN' } => sub { } );

    is $data->{foo}, 'bar';
};

subtest 'new_event: runs post rules' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    _register_statements();

    _create_run_rule(
        id        => '2',
        rule_when => 'pre-online',
        code      => q/$stash->{foo} = 'bar'/
    );

    _create_run_rule(
        id        => '3',
        rule_when => 'post-online',
        code      => q/$stash->{foo} .= 'bar'/
    );

    my $events = _build_model();

    my $data = $events->new_event( 'event.job.new' => { username => 'root', bl => '*', job_step => 'RUN' } => sub { } );

    is $data->{foo}, 'barbar';
};

subtest 'new_event: runs hooks' => sub {
    _setup();

    my $hooks = '';

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );
    Baseliner::Core::Registry->add(
        'main',
        'event.job.new._hooks',
        {
            before => sub {
                my ($ev) = @_;
                $hooks .= 'before';
                return { before => 'foo' };
            },
            after => sub {
                my ($ev) = @_;
                $hooks .= 'after';
                return { after => $ev->{data}->{before} . 'bar' };
            }
        }
    );

    my $events = _build_model();

    my $data = $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { } );

    is $hooks, 'beforeafter';

    is $data->{before}, 'foo';
    is $data->{after},  'foobar';
};

subtest 'new_event: runs code block' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    my $events = _build_model();

    my $here;
    $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { $here++ } );

    is $here, 1;
};

subtest 'new_event: merges code block results into data' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    my $events = _build_model();

    my $data = $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { { foo => 'bar' } } );

    is $data->{foo}, 'bar';
};

subtest 'new_event: runs catch block on error' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    my $events = _build_model();

    my $here;
    $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { die 'here' }, sub { $here++ } );

    is $here, 1;
};

subtest 'new_event: rethrows error if catch block not provided' => sub {
    _setup();

    Baseliner::Core::Registry->add( 'main', 'event.job.new', {} );

    my $events = _build_model();

    like exception {
        $events->new_event( 'event.job.new' => { username => 'root', bl => '*' } => sub { die 'here' } )
    }, qr/here/;
};

sub _setup {
    Baseliner::Core::Registry->clear;

    Baseliner::Core::Registry->add_class(undef, 'event' => 'BaselinerX::Type::Event');

    mdb->rule->drop;
    mdb->event->drop;
    mdb->event_log->drop;
    mdb->activity->drop;

    mdb->event->insert(
        {
            "event_data"   => "---\nfoo: bar",
            "event_key"    => "event.topic.change_status",
            "event_status" => "ok",
            "ts"           => "2015-04-02 15:48:54",
            "username"     => "clarive",
            "mid"          => "1479",
            "id"           => "3626",
            "t"            => 1427982534.315101,
            "module"       => "Baseliner::Model::Topic"
        }
    );

    _create_rule();
}

sub _register_statements {
    Baseliner::Core::Registry->add_class( undef, 'statement' => 'BaselinerX::Type::Statement' );

    Baseliner::Core::Registry->add(
        'main',
        'statement.step' => {
            dsl => sub {
                my ( $self, $n, %p ) = @_;
                sprintf(
                    q{
            if( $stash->{job_step} eq q{%s} ) {
                %s
            }
        }, $n->{text}, $self->dsl_build( $n->{children}, %p )
                );
            }
        }
    );

    Baseliner::Core::Registry->add(
        'main',
        'statement.perl.code' => {
            data => { code => '' },
            dsl  => sub {
                my ( $self, $n, %p ) = @_;
                sprintf( q{ %s; }, $n->{code} // '' );
            },
        }
    );
}

sub _create_run_rule {
    my (%params) = @_;

    my $code = delete $params{code} // '';

    _create_rule(
        rule_tree => [
            {
                "attributes" => {
                    "text" => "RUN",
                    "key"  => "statement.step",
                },
                "children" => [
                    {
                        "attributes" => {
                            "key"  => "statement.perl.code",
                            "data" => { "code" => "$code" },
                        },
                        "children" => []
                    }
                ]
            },
        ],
        %params
    );
}

sub _create_rule {
    my (%params) = @_;

    my $rule_tree = delete $params{rule_tree};

    if ( $rule_tree && ref $rule_tree ) {
        $rule_tree = JSON::encode_json($rule_tree);
    }

    mdb->rule->insert(
        {
            id                => '1',
            "rule_active"     => "1",
            "wsdl"            => "",
            "rule_type"       => "event",
            "rule_desc"       => "",
            "authtype"        => "required",
            "rule_name"       => "test",
            "ts"              => "2015-06-30 13:44:11",
            "username"        => "root",
            "rule_seq"        => 1,
            "rule_event"      => 'event.job.new',
            "rule_when"       => "pre-online",
            "subtype"         => "-",
            "detected_errors" => "",
            "rule_tree"       => $rule_tree,
            %params
        }
    );
}

sub _build_model {
    return Baseliner::Model::Events->new();
}

done_testing;
