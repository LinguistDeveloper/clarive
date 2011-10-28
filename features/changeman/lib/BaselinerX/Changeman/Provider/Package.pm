#
#===============================================================================
#
#         FILE:  package.pm
#
#  DESCRIPTION: Package provider for Changeman
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Javi Rodriguez
#      COMPANY:  VassLabs
#      VERSION:  1.0
#      CREATED:  07/05/2011 02:37:31 PM
#     REVISION:  ---
#===============================================================================

package BaselinerX::Changeman::Provider::Package;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Changeman;
use BaselinerX::Changeman::Namespace::Package;
use Try::Tiny;
use DateTime;
use Data::Dumper;

with 'Baseliner::Role::Provider';

register 'action.nature.changeman' => { name=>'Work with Changeman' };
register 'action.job.create.Z' => { name=>'Create jobs in Z' };

register 'config.changeman.connection' => {
    name => 'Changeman Connection Data',
	metadata => [
		{ id=>'host', label=>'Changeman Host', type=>'text', default=>'prue' },
		{ id=>'port', label=>'Changeman Port', type=>'text', default=>'24' },
		{ id=>'user', label=>'Changeman User', type=>'text', default=>'vpchm' },
		# { id=>'role', label=>'Changeman role for test', type=>'hash', default=>"Z=>['AZ','PZ'], T=>['AN','PR'] "},
	]
};

register 'namespace.changeman.package' => {
    name    =>_loc('Changeman Package'),
    domain  => domain(),
    can_job => 1,
    finder  => \&find,
    handler => \&list,
};

sub namespace { 'BaselinerX::Changeman::Namespace::Package' }
sub domain    { 'changeman.package' }
sub icon      { '/static/images/package.png' }
sub name      { 'ChangemanPackages' }

# returns the first rows it finds for a given name
sub find {
    my ($self, $ns) = @_;
	my ($prov, $pkg) = ns_split $ns;
	my %pkgs;

	my $pkg_data = Baseliner->model('Repository')->get( ns=>$self->domain . '/' . $pkg );
	return undef unless( ref $pkg_data );

    return BaselinerX::Changeman::Namespace::Package->new($pkg_data);
    }

sub get { find(@_) }

sub list {
    my ($self, $c, $p) = @_;

    _log "Changeman provider list started...";
    my $bl = $p->{bl};
    return if $bl eq 'TEST';  ## En changeman no hay pases a TEST
    my $rfc = $p->{rfc};
    ( ref $c && ref $c->stash ) and $bl ||= $c->stash->{bl};
    my $job_type = $p->{job_type};
    
    my ($query, $pattern) = ($1||$3, uc($2)) if $p->{query} =~ m{(\S+)\s+(.*)|(\S+)};
    my @projects;
    
    if ($c->model('Permissions')->user_has_action(username=>$p->{username}, action=>'action.admin.root')) {
        push @projects, '*';
    } else {
        foreach my $id (_array $c->model('Permissions')->user_projects_with_action(username=>$p->{username}, action=>'action.job.create', bl=>$bl, cam=>'S')) {
               push @projects, $c->model('Baseliner::BaliProject')->find({id=>$id})->name . "T";
               }
        foreach my $id (_array $c->model('Permissions')->user_projects_with_action(username=>$p->{username}, action=>'action.job.create.Z', bl=>$bl, cam=>'S')) {
               push @projects, $c->model('Baseliner::BaliProject')->find({id=>$id})->name . "Z";
               }
        }
    _log "Looking for Changeman packages in : " . join(" ", @projects);

    my $cfgChangeman = Baseliner->model('ConfigStore')->get('config.changeman.connection' );
    my $chm = BaselinerX::Changeman->new( host=>$cfgChangeman->{host}, port=>$cfgChangeman->{port}, user=>$cfgChangeman->{user}, password=>sub{ require BaselinerX::BdeUtils; BaselinerX::BdeUtils->chm_token } );
    my $pkgs = $chm->xml_pkgs( filter=>$query, to_env=>$bl, job_type=>$job_type eq 'promote'?'P':'M', projects=>@projects );

    my @ns;
    my ($cnt,$total)=(0,0);
    
    foreach my $pkg ( $pkgs->{PackList}->{Package} ) {
        $total=keys %$pkg;
        foreach (sort keys %$pkg) {
            $cnt++;
            next if $cnt <= $p->{start};
            last if $cnt > ($p->{start} + $p->{limit});
            my $pkgInfo=$$pkg{$_};


            my $related     = "application/$1" if $_ =~ m{^(...).+};
            my $user        = $pkgInfo->{creator} || _loc('Unknown');
            my $circuito    = $pkgInfo->{circuito} || _loc('Unknown');
            my $codigo      = $pkgInfo->{codigo} || _loc('Unknown');
            my $audit       = ref $pkgInfo->{audit} ne 'HASH'?$pkgInfo->{audit}:_loc('Unknown');
            my $db2         = $pkgInfo->{db2}  || _loc('Unknown');
            my $linklist    = $pkgInfo->{linklist} || _loc('Unknown');
            my $motivo      = ref $pkgInfo->{motivo} ne 'HASH'?$pkgInfo->{motivo}:_loc('Unknown');
            my $promote     = $job_type eq 'promote'?$pkgInfo->{promote} || _loc('Unknown'):join (', ', _array $pkgInfo->{site});
            my $urgente     = ref $pkgInfo->{urgente} ne 'HASH'?$pkgInfo->{urgente}:_loc('Unknown');
            my $descripcion = $pkgInfo->{descripcion}|| _loc('Unknown');
            my $site        = $job_type eq 'promote'?join (', ', _array $pkgInfo->{site}):$pkgInfo->{promote} || _loc('Unknown');
            my $incidencia  = $motivo eq 'INC'?$codigo:undef;
            _log "\nCODIGO: #$codigo#\nMOTIVO: #$motivo#\nINCIDENCIA: #$incidencia#";
            my $tipoPkg     = 'Changeman';
            $tipoPkg.='/DB2' if $db2 eq 'SI';
            $tipoPkg.='/linkList' if $linklist eq 'SI';
            my $label=$motivo eq 'PRO'?'Proyecto: ':$motivo eq 'PET'?'Petición: ':'Incidencia: ';
            
            # searching 
            if( $rfc ) {
                }

            if ( $pattern ) {
                my $search     = uc($user.$circuito.$codigo.$audit.$tipoPkg.$motivo.$promote.$urgente.$descripcion.$site);
                if ($search !~ m{$pattern}) {
                    $cnt--;
                    next;
                    }
                }

            my $data={  icon_on  => '/static/images/changeman/package.gif',
                        icon_off => '/static/images/changeman/package_off.gif',
                        provider => 'namespace.changeman.package',
                        ns_type  => _loc('Changeman package'),
                        ns_name  => $_,
                        item     => $_,
                        ns       => "changeman.package/$_",
                        id       => "changemanpackage$_",
                        inc_id      => [ {codigo=>$incidencia} ], 
                        ns_data  => {
                                     circuito    => $circuito,
                                     codigo      => $codigo,
                                     audit       => $audit,
                                     motivo      => $motivo,
                                     promoteFrom => $promote,
                                     urgente     => $urgente,
                                     site        => $site,
                                     db2         => $db2,
                                     linklist    => $linklist,
                                     },
                        ns_info  =>$descripcion,
                        moreInfo => qq{<b>Tipo: </b>$tipoPkg<br><b>RC Audit: </b>$audit<br><b>Entorno Origen: </b>$promote<br><b>Entorno Destino: </b>$site<br><b>$label</b>$codigo},
                        user     => $user,
                        service  => 'service.changeman.runner.package',
                        can_job  => 1,
                        related  => [ $related ],
                        why_not  => ""
                    };
                        # moreInfo => qq{<table>
                                          # <tr><td class="search-l">Tipo: $tipoPkg</td><td class="search-r">RC Audit: $audit</td></tr>
                                          # <tr><td class="search-l">Origen: $promote</td><td class="search-r">Destino: $site</td></tr>
                                          # <tr><td class="search-l">Código: $motivo</td><td class="search-r">Motivo: $codigo</td></tr>
                                       # </table>}, # $pkgInfo->{$_}->{descripcion},

                    _log Dumper $data;
            push @ns, BaselinerX::Changeman::Namespace::Package->new($data);

            # Añadimos al repositorio el paquete...
            try {
                Baseliner->model('Repository')->set( ns=>"changeman.package/$_", data=>$data );
            } catch {
                my $error = shift;
                _log $error;
                }
            }
        }

    _log "provider list finished (records=".scalar (@ns)."/$total).";
    return { data=>\@ns, total=>$total, count=>scalar(@ns) };
    }

1;

