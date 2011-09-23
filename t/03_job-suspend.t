use strict;
use warnings;
use Test::More;
use Try::Tiny;

BEGIN { use_ok 'Catalyst::Test', 'Baseliner' }
#BEGIN { use_ok 'Baseliner::Controller::JSON' }
#BEGIN { use_ok 'Test::WWW::Mechanize::Catalyst' }
use HTTP::Request::Common;

my $m = Baseliner->model('Jobs');

# login
my $res = request POST '/login', [ login=>'local/root', password=>'admin' ];
my $cookie = $res->header('Set-Cookie');
my $jobid;
our $value;
{
    package BaselinerX::Services::Testing;
    use Baseliner::Plug;
    use Baseliner::Utils;
    with 'Baseliner::Role::Service';
    register 'service.test.pre' => { 
        handler=>sub{ 
            my ($self,$c,$config)=@_;
            $c->stash->{job}->job_stash->{test_data} = { value=>999 };
        }
    };
    register 'service.test.sum' => { 
        handler=>sub{ 
            my ($self,$c,$config)=@_;
            _log ">>>> Sum one on PRE";
            $c->stash->{job}->job_stash->{test_data}->{value} ++;
        }
    };
    register 'service.test.sumrun' => { 
        handler=>sub{ 
            my ($self,$c,$config)=@_;
            _log ">>>> Sum one on RUN";
            $c->stash->{job}->job_stash->{test_data}->{value} ++;
        }
    };
    register 'service.test.post' => { 
        handler=>sub{ 
            my ($self,$c,$config)=@_;
            my $data = $c->stash->{job}->job_stash->{test_data};
            _log ">>>> Stash value: " . $data->{value};
            $main::value = $data->{value};
        }
    };
}
{
    # create job chain
    my $cm = Baseliner->model('Baseliner::BaliChain');
    my $chain = $cm->find(1);
    $chain = $cm->create({ name=>'Global Chain', description=>'Global Testing Chain' }) unless defined $chain;

    $chain->bali_chained_services->create({ seq=>100, key=>'service.test.pre', step=>'PRE'  });
    $chain->bali_chained_services->create({ seq=>200, key=>'service.manual.deploy', step=>'PRE'  });
    $chain->bali_chained_services->create({ seq=>300, key=>'service.test.sum', step=>'PRE'  });
    $chain->bali_chained_services->create({ seq=>400, key=>'service.test.sumrun', step=>'RUN'  });
    $chain->bali_chained_services->create({ seq=>500, key=>'service.test.post', step=>'POST'  });

    # create job
    my $job = $m->create( bl=>'TEST', contents=>[ { ns=>'/' } ], job_type=>'normal', username=>'root' );
    $jobid= $job->id;
}
{
    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>$jobid, step=>'PRE' } );
    #Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>$jobid, step=>'RUN' } );
    my $job = Baseliner->model('Jobs')->get( $jobid );
    is( $job->step, 'PRE', 'job suspended in PRE');
    is( $job->status, 'SUSPENDED', 'job SUSPENDED status');

    Baseliner->model('Jobs')->resume( id=>$jobid, username=>'root' );
    $job = $job->get_from_storage;  # reload row
    is( $job->status, 'READY', 'job READY status after resume');
    is( $job->step, 'PRE', 'job resumed in PRE');

    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>$jobid, step=>'PRE' } );
    $job = $job->get_from_storage;  # reload row
    is( $job->step, 'RUN', 'job finished PRE, now RUN');

    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>$jobid }, step=>'RUN' );
    $job = $job->get_from_storage;  # reload row
    is( $job->step, 'POST', 'job finished RUN, now POST');

    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>$jobid }, step=>'POST' );
    $job = $job->get_from_storage;  # reload row
    is( $main::value, 1001, "stash recovered ok" );
    is( $job->status, 'FINISHED', 'job finished');
}
done_testing;

