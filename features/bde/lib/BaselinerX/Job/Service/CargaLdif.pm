package BaselinerX::Job::Service::CargaLdif;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::BdeUtils;
use BaselinerX::Model::CargaFTP;
use Data::Dumper;
use Net::FTP;
use Try::Tiny;

use utf8;

with 'Baseliner::Role::Service';

register 'service.update.users' => {
  name    => 'Carga de usuarios y sus permisos',
  handler => \&run
};

sub run  {
  my ($self) = @_;
  my $config_bde = Baseliner->model('ConfigStore')->get('config.bde');
  my $ftp_user = $config_bde->{ldifuser} || 'vpscm';
  my $ftp_server = $config_bde->{ldifmaq} || 'prue';
  my $perl_temp  = $config_bde->{perltemp} || '/home/apst/scm/servidor/tmp';
  my $udp_home   = $config_bde->{udp_home};
  my $ldif_home_directory   = $config_bde->{ldif_home_directory};
  my $ldif_remote_directory = $config_bde->{ldif_remote_directory};

  my $config_harvest = Baseliner->model('ConfigStore')->get('config.harvest');

  my $broker = $config_harvest->{broker};
  _debug "broker: $broker";
  my $harvest_user = $config_harvest->{user};
  _debug "harvest_user: $harvest_user";

  my $harvest_password = q{};

  my %initial_users = Baseliner->model('CargaLdif')->all_users();

#  my $secret = `racxtk 01 $whoami ftp $ftp_server`;
  my $secret = BaselinerX::Model::CargaFTP->set_ticket($ftp_server,$ftp_user);

  _throw "Could not retrieve ticket from racxtk" if substr($secret, 0, 5) eq "Error";

  _debug "Got ticket: $secret";

  # my @files = (qw/grp_adminis.ldif  grp_analist.ldif grp_progrm.ldif
  #                 grp_cfuentes.ldif infra_plat.txt   grp_soporte.ldif/);

  my @files = (qw/grp_adminis.ldif   grp_analist.ldif
                  grp_progrm.ldif    grp_cfuentes.ldif
                  infra_plat.txt     grp_soporte.ldif
                  grp_analist_z.ldif grp_progrm_z.ldif
                  /);


  _debug(BaselinerX::Comm::Balix->ahora() . " Downloading FTP files...");
  my $ftp = Net::FTP->new($ftp_server, Debug => 0);

  $ftp->login($ftp_user, $secret)   or die "Cannot connect to $ftp_server";
  $ftp->cwd($ldif_remote_directory) or die "Directory $ldif_remote_directory not valid";

  for my $file (@files) {
    _debug(BaselinerX::Comm::Balix->ahora() . " Downloading $file ...");
    $ftp->get($file, "${ldif_home_directory}/${file}") or die "Could not retrieve $file";
  }
  _debug(BaselinerX::Comm::Balix->ahora() . " Downloaded FTP files.");
  $ftp->quit;

  my %grp_inf_rpt = Baseliner->model('CargaLdif')->groups_inf_rpt();

  my @data = `cat ${ldif_home_directory}/*`;

  my %group;
  my %user_group;
  my %user_group2;
  my $grpname;
  
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

  #warn "user_group\n"._dump \%user_group;
  #warn "user_group2\n"._dump %user_group2;
  #warn "grpname\n"._dump $grpname;
  #warn "group\n"._dump \%group;

  _log(BaselinerX::Comm::Balix->ahora() . " Finished file parsing.");
  _debug(BaselinerX::Comm::Balix->ahora() . " Finished file parsing.");

  # Update Baseliner.
  Baseliner->launch('service.baseliner.update.ldif',
             data => {group => \%group, user_groups => \%user_group});

  # ldif_updates_harvest is a config variable that controls whether we also
  # want to update harvest when loading ldif files.
  return unless _bde_conf 'ldif_updates_harvest';

  _debug(BaselinerX::Comm::Balix->ahora() . " Creating groups...");

  for my $grp (keys %group) {
    my $cnt = Baseliner->model('CargaLdif')->group_count($grp);
    if ($cnt == 0) {
      _debug(BaselinerX::Comm::Balix->ahora() . " New group: $grp");
      my $group_id = Baseliner->model('CargaLdif')->group_id();
      Baseliner->model('CargaLdif')->new_group( group_id     => $group_id
                                       , group_name   => $grp
                                       , h_group_name => $group{$grp}
                                       );
    }
  }
  _debug(BaselinerX::Comm::Balix->ahora() . " Updating users...");
  #open my $fusr, '>', "${perl_temp}/karga$$";
  my $fusr = "${perl_temp}/carga$$";
  open FUSR, ">$fusr";

  for my $user (keys %user_group) {
    my $user_count = Baseliner->model('CargaLdif')->user_count($user);
    if ($user_count == 0) {
      _debug(BaselinerX::Comm::Balix->ahora() . " New user: $user");
      my $usrgrp = join('|', @{$user_group{$user}});
      print FUSR "$user||$user|0000|999|000|$user\@correo.interno|$user|$usrgrp\n";
    }
    else {
      _debug(BaselinerX::Comm::Balix->ahora() . " Updating user: $user");
      my $user_id = Baseliner->model('CargaLdif')->user_id($user);
      my $usrgrp = join(',', @{$user_group2{$user}});
      my $admin_count = Baseliner->model('CargaLdif')->count_admins($user_id);
          Baseliner->model('CargaLdif')->del_harusersingroup($user_id, $usrgrp) if $admin_count == 0;
      for my $group_name (@{$user_group2{$user}}) {
        my $cnt = Baseliner->model('CargaLdif')->count_harusersingroup($user_id, $group_name);
        Baseliner->model('CargaLdif')->insert_harusersingroup($user_id, $group_name) if $cnt == 0;
      }
    }
  }
  # Delete users not included in LDIF.
  my %harusers = Baseliner->model('CargaLdif')->harusers();
  my $del_count = 0;
  for my $har_id (keys %harusers) {
    my ($harvest_user, $real_name) = @{$harusers{$har_id}};
    if (!($user_group{lc($harvest_user)} || $user_group{uc($harvest_user)})) {
      _debug(BaselinerX::Comm::Balix->ahora() . " Deleting user $harvest_user (${real_name}) in Harvest");
      Baseliner->model('CargaLdif')->delete_haruser(uc($harvest_user));
      $del_count++;
    }
  }
  _debug(BaselinerX::Comm::Balix->ahora() . " $del_count users deleted from Harvest") if $del_count > 0;

  close FUSR;

  Baseliner->model('CargaLdif')->add_users_to_group2();

  if (-s $fusr) {
    _debug( BaselinerX::Comm::Balix->ahora() . " husrmgr of users for file: $fusr" );
    my $cmd = "husrmgr -b $broker $harvest_user $harvest_password -dlm '\|' -o ${udp_home}/husrmgr.log $fusr";
    _debug "cmd: $cmd";
    my @RET = `$cmd`;
    if ($? ne 0) {
      # TODO
      # my $ret = Baseliner->model('CargaLdif')->capture_debug("${udp_home}/husrmgr.log");
      # _debug(BaselinerX::Comm::Balix->ahora() . " New user load: $ret");
    }
    else {
      _debug(BaselinerX::Comm::Balix->ahora() . " New users:");
      my @RET2 = `grep 'User Name:' ${udp_home}/husrmgr.log`;
      _debug(BaselinerX::Comm::Balix->ahora() . @RET2);
    }
  }

  _debug(BaselinerX::Comm::Balix->ahora() . " Sync form data...");
  try {
    Baseliner->model('CargaLdif')->sync_inf_data();
  }
  catch {
    _debug(BaselinerX::Comm::Balix->ahora() . " Error while syncing form data:\n" . shift()  . "\n\n");
  };

  my %end_users = Baseliner->model('CargaLdif')->all_users();

  _debug(BaselinerX::Comm::Balix->ahora() . " End of cargaLdif");
  _debug(BaselinerX::Comm::Balix->ahora() . " Users before load: " . keys %initial_users);
  _debug(BaselinerX::Comm::Balix->ahora() . " Users after load: "  . keys %end_users);

  # Baseliner->launch('service.load.user.roles');  # Start bali update.

  return;
}

1
