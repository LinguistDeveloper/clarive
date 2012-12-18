package BaselinerX::Service::AddMailJUData;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use BaselinerX::Dist::Utils;
use Baseliner::Sugar;

use utf8;

with 'Baseliner::Role::Service';

register 'service.add.mail-ju.data' => {name    => 'Add JU mail notificacion data',
                                        handler => \&main};

sub main {
  my ($self, $c, $config) = @_;
  
  # Prerequisites.
  my $job      = $c->stash->{job};
  my $log      = $job->logger;
  my @elements = @{$job->job_stash->{elements}->{elements}};
  my @contents = @{$job->job_stash->{contents}};
  my $username = $job->job_data->{username};

  my @camlist  =  map { _pathxs $_->{fullpath}, 1 } @elements;
  my %camlist=map { substr ((ns_split($_->{item}))[1], 0,3) => $_->{item} =~ m{^nature}?1:0 } @contents;
  for (keys %camlist) {
    push @camlist, $_ unless $camlist{$_}; 
  }
  @camlist = _unique @camlist;

  $username=~s{vpchm|desconocido}{Pase lanzado desde Changeman}ig;
 
  if ( $job->job_data->{bl} ne 'DESA' ){ 

      my $urgent          = $job->job_stash->{approval_needed}->{reason}=~m{pase urgente}i?1:0;
      my $linklistRefresh = $job->job_stash->{chm_linked_list};
      for (@{ $job->job_stash->{contents}}) {
          $urgent = $urgent || ( $_->{data}->{urgente} eq 'S' || 0 ); 
          $linklistRefresh = $linklistRefresh || ( ( $_->{data}->{urgente} eq 'S' && $_->{data}->{linklist} eq 'SI' ) || 0 )
      }

      # Set data.
      my $data = {
        job_id       => $job->{jobid},
        environment  => $job->job_data->{bl},
        job_name     => $job->job_data->{name},
        status       => $job->job_data->{status} eq 'RUNNING'?$job->job_data->{rollback}?_loc('FINISHED DOING ROLLBACK CORRECTLY'):_loc('FINISHED CORRECTLY'):$job->job_data->{rollback}?_loc('FINISHED WITH ERROR DURING ROLLBACK'):_loc('FINISHED WITH ERROR'),
        username     => $username,
        start_time   => $job->job_data->{starttime},
        end_time     => $job->job_data->{endtime},
        cam_list     => [@camlist],
        node_list    => $job->job_data->{bl} eq 'PROD'?$job->job_stash->{procSites}:[],
        nature_list  => [get_job_natures $job->{jobid}],
        package_list => [ map { $self->message($_) } @contents ],
        subapps_list => [get_job_subapps $job->{jobid}],
        urgent       => $linklistRefresh?_loc("Linklist refresh forced"):$urgent?_loc("Urgent"):_loc("Normal"),
      };
      # Turn it to utf8.
      # Encode::from_to($_, 'iso-8859-1', 'utf8') for values %$data;
      
      # Calculate date so we can identify ns allowing for faster search results.
      my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
      $Year  += 1900;
      $Month += 1;
      $Month = '0' . $Month if $Month < 10;
      $Day   = '0' . $Day if $Day < 10;
      
      # Set data in Baseliner Repository.
      my $repo = Baseliner->model('Repository');
      my $provider = 'informepase.ju_email';
      my $cnt = (scalar Baseliner->model('Repository')->list(provider => $provider)) + 2;
      my $ns = "$provider/$Year$Month$Day#$cnt";
      _log "ns -> $ns";
      $repo->set(ns => $ns, data => $data);
  }
}

sub message {
    my ($self, $p) = @_;
    my $name = (ns_split($p->{item}))[1];
    my $tipo = undef;
    my $codigo = undef;
    if ( $p->{provider} eq 'namespace.changeman.package') { 
        $tipo=$p->{data}->{motivo} eq 'PRO'?'<b>Proyecto      :</b> ':$_->{data}->{motivo} eq 'PET'?'<b>Peticion      :</b>':$_->{data}->{motivo} eq 'MTO'?'<b>Mantenimiento :</b>':$_->{data}->{motivo} eq 'INC'?'<b>Incidencia    :</b>':_loc "Deleted package";
        $codigo=ref $p->{data}->{codigo}?undef:$p->{data}->{codigo} ;
    } elsif ( $p->{provider} eq 'namespace.harvest.package') {
        ## TODO en Harvest cogerlo del formulario de paquete:
        ## $tipo
        ## $codigo
    }
    my $ret="<tr><td rowspan=2><li></td><td colspan=2 nowrap><b>$name</b></td></tr><tr><td nowrap><b>$tipo</b></td>";
    $ret .= "<td nowrap width=100%>$codigo</td></tr>" if defined $codigo;
    return $ret;
}
1;
