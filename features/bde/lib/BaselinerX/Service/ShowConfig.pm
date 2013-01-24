package BaselinerX::Service::ShowConfig;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.baseliner.bde.view.config' => { name => 'Baseliner config settings' , handler => \&run };

sub run {
   my ($self, $c, $config) = @_;
   my $job      = $c->stash->{job};
   my $log      = $job->logger;

   my $rs = $c->model('Baseliner::BaliConfig')->search( { value => { '!=', undef } }, { orderby => [' bl,ns '] } ); #solo variables con valor
   #rs_hashref($rs);
   my $count = $rs->count;
   my @config;
   while ( my $r = $rs->next ) {
      push @config, $r->key . " -> " . $r->value;    #if $r->value
   }
  
   $log->debug("Variables de configuracion($count): ", data=>\@config);

   return;
}

1;
