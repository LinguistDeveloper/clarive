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

{
    my $job = $m->create( bl=>'TEST', contents=>[ { ns=>'/' } ], job_type=>'normal', step=>'PRE', username=>'root' );
    is $job->id, 1, 'job created';
    is $job->name, 'N.TEST-00000001', 'job name ok';

    # check component js
    try {
        require JE;
        my $res = request GET '/job/monitor', Cookie=>$cookie;
        my $js = $res->decoded_content;
        my $parsed = JE->new->parse( $js );
        is( ref($parsed), 'JE::Code', 'monitor grid component parsed' );
        #my $rv = $parsed->execute;
    } catch {
        skip 'Module JE not installed. Javascript tests skipped.', 1;
    };
}
SKIP: {

    # check DOM and JS
    try {
        require HTML::DOM;
        require HTML::Entities; # to decode 
    } catch {
        skip 'HTML::DOM or HTML::Entities not installed. Test skipped.', 1;
    };

    {
        my $res = request GET '/job/create', Cookie=>$cookie;
        my $html = $res->decoded_content;
        my $tree = HTML::DOM->new;
        $tree->write( $html );
        $tree->close;
        #$tree->getElementByID('
        my $js = HTML::Entities::decode_entities $tree->getElementsByTagName('script')->[0]->innerHTML;
        my $parsed = JE->new(html_mode=>1)->parse( $js );
        is( ref($parsed), 'JE::Code', 'job_new form component parsed' );
        #warn _dump( $tree );
        #is( ref($parsed), 'JE::Code', 'create component parsed' );
    }
    {
    my $res = GET '/job/monitor_json', Cookie=>$cookie;
    #warn $res->decoded_content;
    ok( $res, 'monitor json' );
    }

    #my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Baseliner');
    #$mech->get_ok('/login', { login=>'local/root', password=>'admin' }, 'login');
    #$mech->get_ok('/job/monitor_json');
}
{
    my $cm = Baseliner->model('Baseliner::BaliChain');
    my $chain = $cm->create({ name=>'Global Chain', description=>'Global Testing Chain' });
    $chain->bali_chained_services->create({ seq=>100, key=>'service.job.dummy', step=>'PRE'  });
    $chain->bali_chained_services->create({ seq=>200, key=>'service.job.dummy', step=>'RUN'  });
    is( $cm->search->first->name, 'Global Chain', 'chain 1 created' );

}
{
    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>1, step=>'PRE'  } );
    Baseliner->model('Services')->launch( 'service.job.run', data=>{ jobid=>1, step=>'RUN' } );
    my $job = Baseliner->model('Jobs')->get( 1 );
    is( $job->status, 'READY', 'ready for run' );
    is( $job->step, 'POST', 'step is post' );
}
done_testing;

