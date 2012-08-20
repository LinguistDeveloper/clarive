package BaselinerX::Job::Model::Report;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;

sub conn {
  Baseliner->model('Baseliner::BaliJobReport');
}

1;