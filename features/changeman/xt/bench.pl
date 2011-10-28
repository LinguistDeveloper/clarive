use v5.10;
require Baseliner;
use Baseliner::Utils;
use Baseliner::Sugar;
use Benchmark qw/timethis/;
use MVS::USS;

#my $req = Baseliner->model('Semaphores')->create( sem=>'changeman.semaphore' );

sub run {
    my $i = shift;
    say ">>>> $i START";
    my $host = 'prue';
    my $user = 'vpchm';
    my $timeout = 120;
    my $prompt;
    my $port = 24;
    my $agent_port = 58765;

    # critical section
    #my $sem = Baseliner->model('Semaphores')->wait_for( sem=>'changeman.semaphore', who=>'changeman benchmark' );
        my $bx = new BaselinerX::Comm::Balix(
           key=>config_get( 'config.harax' )->{$agent_port},
           host => 'expsv011',
           port => $agent_port,
        );

        my $ret = $bx->executeas( 'vpchm', 'racxtk 01 vpchm batchp prue' );
        my $pw = [split( /\n/, $ret->{ret} )]->[1];

        my $uss = MVS::USS->new( host=>$host, port=>$port||623, user=>$user, password=>$pw,
                Timeout => $timeout || 20,
                Prompt  => $prompt || '/\$/',
        );
    #$sem->release;
    # *,p|m,PRE|FORM|PROD,CAM1 CAM2
    # *,p,PROD,XXX SCT
    my $filter = '*' ; #'177';
    my $job_type = 'p';
    my $to = 'PREP';
    my @apps = qw/SCT XXX SCTT/;
    my $apps = join ' ',@apps;
    my $cmd = '/u/aps/chm/rexxpru3' . ' ' . join(',', $filter, $job_type, $to, $apps ) ;
    $ret = join '', $uss->cmd( $cmd );
    say  "$i >>>>>> " . $ret . "<<<<<<<<<<";
    say ">>>> $i FINISHED";
}

say ">>>>>>> forking started...."; 

for my $i ( 1..10 ) {
    sleep 3;
    fork and next;
    timethis 1 => sub {
        run($i);
    };
    exit 0;
}

timethis 1 => sub {
    say "Waiting for processes to finish...";
    while( wait != -1 ) {}
    say "Done";
};
