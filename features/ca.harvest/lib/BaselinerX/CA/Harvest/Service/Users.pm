package BaselinerX::CA::Harvest::Service::Users;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use File::Spec;
use BaselinerX::CA::Harvest::CLI;

use utf8;

with 'Baseliner::Role::Service';

register 'config.harvest.users' => {
    name => 'Harvest User Management Configuration',
    metadata => [
        #{ id=>'active', name=>'Approvals activation flag', default=>0 },
    ]
};

register 'service.harvest.users.import' => {
    name => 'Baseliner -> Harvest User Import',
    config => 'config.harvest.users',
    handler => \&import_users,
};

sub import_users {
    my ($self, $c, $p ) = @_;
	
    my $tempfile = $p->{tempfile} || File::Spec->catfile( File::Spec->tmpdir, 'husr-' . _nowstamp . $$ . ".txt" );
    my $tempfile_grp = $p->{tempfile_grp} || File::Spec->catfile( File::Spec->tmpdir, 'hgrp-' . _nowstamp . $$ . ".txt" );
    my $tempfile_grp_update = $p->{tempfile_grp_update} || File::Spec->catfile( File::Spec->tmpdir, 'hgrp-up-' . _nowstamp . $$ . ".txt" );

    my $note = "Created by service.harvest.users.import"; # at " . _now;
    #salida para cargar en harvest husrmgr
    my @harusers;
    my @hargroups;
    my %uig;
    my %giu;
    my $rs = Baseliner->model('Baseliner::BaliUser')->search;
    while ( my $r = $rs->next ) {
        my $newuser;
        my $usu = $r->username or next;
        # _log "Checking user $usu";
        my $ns = 'harvest.user/' . $usu;
        # my $item = Baseliner->model('Namespaces')->get( $ns );
        # unless( ref $item ) {
            # _log "Usuario $usu no existe en Harvest. Se creará...";
            # push @harusers, $usu;
            # $newuser = 1;
        # }
        # forzamos el borrado de los usuarios para recrearlos...
            push @harusers, $usu;
            $newuser = 1;
        # groups need to be created in any case
        my @roles = Baseliner->model('Permissions')->user_roles( $usu );
        my @groups = map { my ($d,$it)=ns_split($_->{ns}); ($it) ? $it .'-'. $_->{role} : $_->{role} } @roles;
		
        # push @groups,  map { my ($d,$it)=ns_split($_->{ns}); $it } @roles;
        my @grps,  map { my ($d,$it)=ns_split($_->{ns}); $it } @roles;
		push @groups,  @grps if scalar @grps gt 0;
		
		@groups=map {my $str=$_;$str=~s/^AD$/Administrator/;$str=~s/^OP$/Operador/;$str} @groups;

        $uig{ $usu }{ groups } = \@groups;
        $uig{ $usu }{ is_new } = $newuser;
        #unless( $newuser ) {
            push( @{ $giu{$_} }, $usu ) for( _unique @groups );
        #}
        push @hargroups, @groups;
        # _log "Groups: " . join ', ' , _unique( @groups );
    }
    my $inf_cli = Baseliner->model('ConfigStore')->get('config.ca.harvest.cli' );
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$inf_cli->{broker}, login=>$inf_cli->{login} });
    
    # CREATE User Group
    if( @hargroups ) {
        #UserGroup1<tab>0<tab>note<tab>user1<tab>user2
        open my $hgrp, '>', $tempfile_grp or _throw _loc("Error trying to create group file %1: %2", $tempfile_grp, $!);
        _log "Fichero temporal para la carga de grupos $tempfile_grp";
        for my $group ( _unique @hargroups ) {
            next if ref Baseliner->model('Harvest::Harusergroup')->search( usergroupname=>$group )->first;
			next unless $group;
            _log "Creating $group...";
            print $hgrp "$group\t0\t$note\n";
        }
        close $hgrp;

        my $ret_grp = $cli->run(cmd   => "husrmgr", -cug => $tempfile_grp );
        _throw _loc ("Error importing user groups: %1", $ret_grp->{msg} ) if $ret_grp->{rc};
        #unlink $tempfile_group unless $p->{tempfile}_group;
    }

    # CREATE User
    #File Format
    #UserName<tab>Password<tab>RealName<tab>Phone#<tab>Ext<tab>Fax#<tab>Email
    #<tab>note <tab>Usrgrp1<tab>Usrgrp2<tab>Usrgrp3<tab>...

    if( @harusers ) {
        open my $husr, '>', $tempfile or _throw _loc("Error trying to create users file %1: %2", $tempfile, $!);
        _log "Fichero temporal para la carga de usuarios: $tempfile";
        for my $usu ( _unique @harusers ) { 
            my @groups = _array $uig{ $usu }{ groups };
            print $husr "$usu\t$usu\t$usu\t\t\t\t\t$note\t" . join("\t", @groups) . "\n";
        }
        close $husr;

        my $ret_usu = $cli->run(cmd => "husrmgr", -du=>$tempfile );
        _throw _loc ("Error deleting users: %1", $ret_usu->{msg} ) if ( $ret_usu->{rc} gt 0 && $ret_usu->{rc} ne 768 );

        $ret_usu = $cli->run(cmd   => "husrmgr", args=>$tempfile );
        _throw _loc ("Error importing users: %1", $ret_usu->{msg} ) if ( $ret_usu->{rc} gt 0 && $ret_usu->{rc} ne 768 );
        #unlink $tempfile unless $p->{tempfile};
    } else {
        _log "No users need updating.";
    }
    _log "Update users done.";

    # UPDATE User Group
    if( keys %giu ) {
        #UserGroup1<tab>0<tab>note<tab>user1<tab>user2
        open my $hgrp, '>', $tempfile_grp_update or _throw _loc("Error trying to create group file %1: %2", $tempfile_grp_update, $!);
        _log "Fichero temporal para la actualizacion de grupos $tempfile_grp_update";
        for my $group ( keys %giu ) {
            if( ref $giu{ $group } eq 'ARRAY' ) {
                # there are known users to update
                _log "Updating $group...";
                my $users = join "\t", _array( $giu{ $group } );
                print $hgrp "$group\t0\t\t$users\n";
            }
        }
        close $hgrp;

        my $ret_grp = $cli->run(cmd   => "husrmgr", -oug => $tempfile_grp_update );
        _throw _loc ("Error updating user groups: %1", $ret_grp->{msg} ) if ( $ret_grp->{rc} gt 0 && $ret_grp->{rc} ne 768 );
        #unlink $tempfile_group unless $p->{tempfile}_group;
    }
}
1;