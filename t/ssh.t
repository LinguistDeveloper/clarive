use strict;
use lib '../lib';
use Baseliner;
use BaselinerX::Comm::SSH;
use Baseliner::Core::Filesys;

my $h = Baseliner::Core::Filesys->new(home=>'ssh://instala@172.26.206.19:53255=/temporal');
$h->put(from=>'/opt/ca/tmp/N.DESA-00001426/GBP.0083/J2EE/build/tarfile_dist_24044.tar' ,
        to=>'/temporal/tarfile_dist_24044.tar');


