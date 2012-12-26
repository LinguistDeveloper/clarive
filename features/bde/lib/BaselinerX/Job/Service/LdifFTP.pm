package BaselinerX::Job::Service::LdifFTP;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::BdeUtils;
use Try::Tiny;
use Class::Date qw/date now/;

with 'Baseliner::Role::Service';

register 'service.load.ldif.ftp.files' => {
  name    => 'Gets the files needed to load carga-l-dif',
  handler => \&init
};

sub init {
  my ($self, $c, $config) = @_;
  my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
  my $ftp_user   = $config_bde->{ldifuser} || 'vpscm';
  my $ftp_server = $config_bde->{ldifmaq} || 'prue';
  my $perl_temp  = $config_bde->{perltemp} || '/home/apst/scm/servidor/tmp';
  my $udp_home   = $config_bde->{udp_home};
  my $ldif_home_directory   = $config_bde->{ldif_home_directory};
  my $ldif_remote_directory = $config_bde->{ldif_remote_directory};

  my %group;
  my %user_group;
  my %user_group2;
  my $grpname;

  my @files = (qw/grp_adminis.ldif   grp_analist.ldif  
                  grp_progrm.ldif    grp_cfuentes.ldif  
                  infra_plat.txt     grp_soporte.ldif
                  grp_analist_z.ldif grp_progrm_z.ldif
                  /);

  try {
      my $whoami = `whoami`;
      chomp($whoami);
      $whoami =~ s/\s*(.+)\s*/$1/x;

      _log "whoami    : $whoami";
      _log "ftp_user  : $ftp_user";
      _log "ftp_server: $ftp_server";

      my $config_harvest = Baseliner->model('ConfigStore')->get('config.harvest');

      my $broker = $config_harvest->{broker};
      _log "broker: $broker";
      my $harvest_user = $config_harvest->{user};
      _log "harvest_user: $harvest_user";

      my $harvest_password = q{};
      my %initial_users = $c->model('CargaLdif')->all_users();

      my $secret = BaselinerX::Model::CargaFTP->set_ticket($ftp_server,$ftp_user);
      _throw "Could not retrieve ticket from racxtk: $secret" if substr($secret, 0, 5) eq "Error";
      _log "Got ticket: $secret";

      _log(BaselinerX::Comm::Balix->ahora() . " Downloading FTP files...");
      my $ftp = Net::FTP->new($ftp_server, Debug => 0);

      $ftp->login($ftp_user, $secret)   or _throw "Cannot connect to $ftp_server";
      $ftp->cwd($ldif_remote_directory) or _throw "Directory $ldif_remote_directory not valid";

      for my $file (@files) {
        _log(BaselinerX::Comm::Balix->ahora() . " Downloading $file ...");
        $ftp->get($file, "${ldif_home_directory}/${file}") or _throw "Could not retrieve $file";
      }
      _log(BaselinerX::Comm::Balix->ahora() . " Downloaded FTP files.");
      $ftp->quit;

      my %grp_inf_rpt = $c->model('CargaLdif')->groups_inf_rpt();

      my @data = do {
        # Try with ldif first.
        my @dummy = `cat ${ldif_home_directory}/*`;
        # Otherwise try with backups...
        scalar @dummy ? @dummy : `cat ${ldif_home_directory}/.last/*`;
      };
      
      unless (scalar @data) {
        _log "No se ha podido parsear los ficheros. Compruebe sus variables de configuración.";
        notify_ldif_error "No se ha podido parsear los ficheros. Compruebe sus variables de configuración.";
        #_throw "No se han podido parsear los ficheros. Compruebe sus variables de configuracion";;
        exit 1;
      }

      foreach (@data) {
        if ($_ =~ m/racfid=GP(...),profiletype=GROUP/i) {
          my $apl = uc $1;
          my $grp = 'SP';
          $grpname = $apl . "-" . $grp;
          $group{$grpname} = $grpname;
        }
        elsif ($_ =~ m/racfid=GP(...)(..),profiletype=GROUP/i) {
          my $apl = uc $1;
          my $grp = $2;
          if   ($grp eq "CF") { $grpname = $apl; }
          else                { $grpname = $apl . "-" . $grp; }
          $group{$grpname} = $grpname;
        }
        elsif ($_ =~ m/racfid=ADP(...),profiletype=GROUP/i) {
          my $apl = uc $1;
          my $grp = "RA";
          $grpname = $apl . "-" . $grp;
          $group{$grpname} = $grpname;
        }
        if (/racfinstallationdata: (.*)/i) {
          my $grpdesc = $1;
          $grpdesc =~ s/\r//g;
          $group{$grpname} = $grpdesc;
        }
        if (/racfid=(.*),profiletype=USER/i) {
          my $usu = $1;
          push @{$user_group{$usu}},  "$grpname";
          push @{$user_group2{$usu}}, "'$grpname'";
          if ($grpname =~ /\-/) {
            my $cam = substr($grpname, 0, 3);
            $group{$cam} = $cam;
            push @{$user_group{$usu}},  "$cam";
            push @{$user_group2{$usu}}, "'$cam'";
          }
        }
        if (/WGF-([A-Z0-9]*) ([A-Za-z0-9]*)/) {
          my $wingrp = uc $1;
          my $usu    = $2;
          for my $grp (keys %grp_inf_rpt) {
            # my $wgrp = @{$grp_inf_rpt{$grp}}[0];
            my $wgrp = $grp_inf_rpt{$grp};
            if ($wgrp eq $wingrp) {
              $group{$grp} = $grp;
              push @{$user_group{$usu}},  "$grp";
              push @{$user_group2{$usu}}, "'$grp'";
            }
          }
        }
      }
      _log(BaselinerX::Comm::Balix->ahora() . " Finished file parsing.");
  } catch {
      my $message=shift;
      _log $message;
      $self->notify({message=>_loc ("Error during LDIF files parse process")});
      #_throw _loc ("Error during LDIF files parse process");
      exit 1;
  };

  _log \%group;
  _log \%user_group;

  # Update Baseliner.
  try {
      _log "Updating Baseliner...";
      $c->launch('service.baseliner.update.ldif',
             data => {group       => \%group, 
             	      user_groups => \%user_group});
  } catch {
      my $message=shift;
      _log $message;
      $self->notify({message=>_loc ("Error during Baseliner users update")});
      #_throw _loc ("Error during Baseliner users update");
      exit 1;
  };
             
  # Make backups.	
  try {
      _log "Realizando backups...";      
      $c->launch('service.baseliner.bde.make-ldif-backups',
             data => {backup_home => $ldif_home_directory,
  	                  files_home  => $ldif_home_directory,
  	                  filenames   => [@files]});             	      
  } catch {
      my $message=shift;
      _log $message;
      $self->notify({message=>_loc ("Error during LDIF files backup")});
      # _throw_loc ("Error during LDIF files backup");
      exit 1;
  };

  $self->notify({message=>_loc ("Update LDIF user process finished successfully")});
  exit 0;
}

sub notify {
    use BaselinerX::BdeUtils;

    my ($self,$p) = @_;

    _log _dump $p;
    my $message  = $p->{message}||_loc('Error during update LDIF users process');
    my @users    = users_with_permission 'action.bde.receive.ldif_errors';
    my $mailcfg  = Baseliner->model('ConfigStore')->get( 'config.comm.email' );

    Baseliner->model('Messaging')->notify(
        to       => { users => [ @users ] },
        sender   => $mailcfg->{from},
        subject  => $message,
        carrier  => 'email',
        template => 'email/generic.html',
        template_engine => 'mason',
        vars     => {
            message => $message,
            subject => $message,
            to      => [ @users ],
            url     => _notify_address(),
        }
    );
}

1;
