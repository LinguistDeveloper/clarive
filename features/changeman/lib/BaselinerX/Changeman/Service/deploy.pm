package BaselinerX::Changeman::Service::deploy;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::Dist::Utils;
use BaselinerX::Comm::Balix;
use Data::Dumper;
use Try::Tiny;

with 'Baseliner::Role::Service';

register 'service.changeman.deploy' => {
  name   => 'Execute job in changeman',
  config  => 'config.changeman.connection',
  handler => \&main
};

register 'service.changeman.finalize' => {
  name   => 'Finish job in changeman',
  config  => 'config.changeman.connection',
  handler => \&finalize
};

register 'service.changeman.job_elements' => {
   name   =>_loc('Fill job_elements'),
   config  => 'config.changeman.connection',
   handler =>  \&job_elements,
};

sub main {
   my ($self, $c, $config) = @_;
   my $job      = $c->stash->{job};
   my $log      = $job->logger;
   my $job_stash = $job->job_stash;
   my $contents  = $job_stash->{ contents };
   my $bl      = $job->job_data->{bl};


   # my $runner = BaselinerX::Job::Service::Runner->new_from_id( jobid=>$job->jobid, same_exec=>1, exec=>'last', silent=>1 );
   # my $jobRow=bali_rs('Job')->search( {id=>$job->jobid} )->first;
   # $runner->{job_row} = $jobRow;
   # $runner->{job_data} = $jobRow->{_column_data};

   $self->execute({config=>$config, job=>$job});
   }

sub execute {
   my ($self, $p) = @_;
   my $config     = $p->{config};
   my $job        = $p->{job};
   my $log        = $job->logger;
   my $job_stash  = _load bali_rs('Job')->find( $job->jobid )->stash;
   my $isCHM=undef;

   if ( $job_stash->{origin} eq 'changeman' && ! $p->{finalize} ) {
      $job->suspend (status=>'WAITING', message=>_loc("Waiting for JES spool outputs"), level=>'info');
      return 0;
   }

   my $chm = BaselinerX::Changeman->new( host=>$config->{host}, port=>$config->{port}, key=>$config->{key} );

   foreach my $package (_array $job_stash->{contents}) {
      my $ns = ns_get( $package->{item} );
      next if $ns->{provider} ne "namespace.changeman.package";

      if ($package->{returncode}) {
         _throw ('Error during changeman execution') if $package->{returncode} !~ m{ok}i;
      } elsif ( $job->{origin} ne 'changeman' ) {
         my $ret=undef;
         my $sitename = $config->{siteMap}->{$job->bl}->{PromotionSite};
         my $name     = $config->{siteMap}->{$job->bl}->{PromotionName};
         my $level    = $config->{siteMap}->{$job->bl}->{PromotionLevel};
         my $date     = parse_date ('YYYY-MM-DD',$job->{job_data}->{schedtime})->ymd('');

         if ( $job->bl eq 'PROD' && $job->{job_data}->{type} eq 'promote') {
            $log->debug( _loc( qq{Execute package <b>%1</b> type <b>%2</b> to site <b>%3</b>},$ns->{ns_name}, 'install', $ns->{ns_data}->{site} ));
         } elsif ( $job->bl eq 'PROD' && $job->{job_data}->{type} eq 'demote') {
            $log->debug( _loc( qq{Execute package <b>%1</b> type <b>%2</b> to site <b>%3</b>},$ns->{ns_name}, 'backout', $ns->{ns_data}->{site} ));
         } elsif ( $job->bl ne 'PROD' && $job->{job_data}->{type} eq 'promote') {
            $log->debug( _loc( qq{Execute package <b>%1</b> type <b>%2</b> to site <b>%3</b>},$ns->{ns_name}, 'promote', $ns->{ns_data}->{site} ));
         } elsif ( $job->bl ne 'PROD' && $job->{job_data}->{type} eq 'demote') {
            $log->debug( _loc( qq{Execute package <b>%1</b> type <b>%2</b> to site <b>%3</b>},$ns->{ns_name}, 'demote', $ns->{ns_data}->{site} ));
         } else {
            _throw _loc( "Invalid job for Changeman");
         }

         $ret = $chm->xml_runPackageInJob(
             job       =>$job->{name},
             'package' =>$ns->ns_name,
             job_type  =>$job->{job_data}->{type} =~ m{PROMOTE}i?'P':'M',
             bl        =>$job->{job_data}->{bl},
         );
         if ( $ret->{ReturnCode} !~ m{^00$|^0$} ) {
             $log->error (_loc("Can't execute changeman package %1", $ns->{ns_name}), _dump $ret);
             _throw _loc('Error during changeman execution');
         } else {
            $log->info(_loc("Execution for changeman package %1 correctly submitted", $ns->{ns_name}), _dump $ret);
            $job->suspend (status=>'WAITING', message=>_loc("Waiting for JES spool outputs"), level=>'info');
            return 0;
         }
      }
   }

   ## En PROD si el pase tiene activo el refresco de Linklist realizar la llamada al rexx de refresco.
   if ($job->{job_data}->{bl} eq 'PROD' && $job_stash->{chm_linked_list} ) {
      #_debug "JOB STASH CONTENTS=" . _dump $job_stash->{contents};
      my @sites=map{ $_->{data}->{site}=~s{ }{}; split /,/,$_->{data}->{site} } _array $job_stash->{contents};
      if( !@sites ) {  # job stash lost? Go for the ns
         for my $nsid (  _array $job_stash->{contents} ) {
             my $ns = Baseliner->model('Namespaces')->get( $nsid );
             my @s = map { s/ //; $_ } split /,/, $ns->{ns_data}->{site};
             push @sites, @s;
         }
      }
      @sites = _unique( @sites );
      #_log qq{my ret = chm->xml_refreshLLA(join (', ',@sites))};
      my $data = join (', ',@sites);
      if( ! length $data ) {
        _fail _loc "Empty xml data from changeman";
      }

      my $ret = $chm->xml_refreshLLA( sites=>$data );

      if ($ret->{ReturnCode} ne '00') {
         $log->error (_loc("Can't execute Linklist refresh"), $ret->{Message});
         _throw ( _loc('Error during changeman execution') );
      } else {
         $log->info(_loc("Linklist refresh correctly submitted"));
      }
   }

   if ($job->{origin} ne 'changeman') {
      my @pkgs;
      foreach my $package (_array $job_stash->{contents}) {  ## Desasociamos los paquetes del pase.
         my $ns = ns_get( $package->{item} );
         push @pkgs, $package->{item} if $ns->{provider} ne "namespace.changeman.package";
      }
      my $ret= $chm->xml_cancelJob(job=>$job->{name}, items=>\@pkgs) ;
   }

        Baseliner->model('Jobs')->resume(id=>$job->jobid, silent=>1) if $p->{finalize};
}

sub finalize {
   my ($self, $p) = @_;
   my $runner     = $p->{runner};
   my $pkg        = $p->{pkg};
   my $rc         = $p->{rc};
   my $config     = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );

   my $job_stash=_load bali_rs('Job')->find( $runner->jobid )->stash;
   foreach my $package (_array $job_stash->{contents}) {
      next if $package->{item} !~ m{$pkg$};
      $package->{returncode}=$rc;
   }
   bali_rs('Job')->find( $runner->jobid )->stash(_dump $job_stash);
   $runner->job_stash($job_stash);
   $self->execute({config=>$config, job=>$runner, finalize=>1});
}

sub job_elements {
   my ($self, $c, $cfgChangeman ) = @_;
   my $job = $c->stash->{job};
   my $log = $job->logger;
   my $stash = $job->job_stash;
   # my $stash = _load $job->job_stash->stash;
   my $bl = $job->bl;
   # my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
   my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port}, key=>$cfgChangeman->{key} );
   my @elems;
   my @list;

   $log->debug( "Changeman package list elements", _dump  $stash );

   for my $item ( _array $stash->{contents} ) {
      next if $item->{item} =~ 'nature/.*';
      my $ns = ns_get $item->{item};
      my $application = $1 if $ns->{ns_name}=~m{^(....).*};
      next unless $ns->provider eq 'namespace.changeman.package';

# TODO .- Añadir installDate y fromInstallTime agrupado por site a la información del paquete.
#      if ( $job->bl eq 'PROD' ) {
#         my $rr = Baseliner->model('Baseliner::BaliRepo')->search( { ns=>$item->{item} } )->first;
#         my $data=_load $rr->data;
#         foreach (_array $data->{ns_data}->{site}) {
#           my $strdate=qq{$_->{installDate}$_->{fromInstallTime}};
#           $strdate="$1/$2/$3 $4:$5" if $strdate =~ m/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
#           $log->info( _loc( "<b>Changeman</b> package %1 will not be installed in site <b>%2</b> until <b>%3</b> ", $ns->{ns_name},  $_->{siteName}, $strdate) );
#         }
#      }

      my $xml = $chm->xml_components( package=>$ns->{ns_name} );
      @list=();  ## Vaciamos el array de elementos

      if ( scalar _array $xml->{result} ) {
         push @list, sprintf("%-10s%-42s","ELEMENTO","TIPO");
         push @list, sprintf("%-10s%-42s","=========","==========================================");
      }

      foreach ( _array $xml->{result} ) {
         push @elems,{ name=>$_->{component}, type=>$cfgChangeman->{typedef}->{$_->{componentType}}, path=>qq{/$application/ZOS/}.$_->{component} };
         push @list,sprintf("%-10s%-42s",$_->{component},$cfgChangeman->{typedef}->{$_->{componentType}});
      }

      $log->info( _loc( "<b>Changeman</b> Job Elements from package %1", $ns->{ns_name} ), data=>join"\n",@list );
      @elems = map {
         BaselinerX::ChangemanComponent->new( name=>$_->{name}, type=>$_->{type}, path=>$_->{path} );
      } @elems;

      my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
      $e->push_elements( @elems );
      $job->job_stash->{elements} = $e;
   }
}

package BaselinerX::ChangemanComponent;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has 'mask' => ( is=>'rw', isa=>'Str', default=>'/application/nature');
has 'path' => ( is=>'rw', isa=>'Str');

1;
