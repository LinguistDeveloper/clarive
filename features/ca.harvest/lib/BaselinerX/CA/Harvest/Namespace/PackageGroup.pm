package BaselinerX::CA::Harvest::Namespace::PackageGroup;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use Catalyst::Exception;

use BaselinerX::CA::Harvest::Project;

# required by roles:
sub locked { 1 } 
sub locked_reason  { '' } 

with 'Baseliner::Role::Namespace::Release';
with 'Baseliner::Role::Namespace::PackageGroup';
with 'Baseliner::Role::JobItem';
with 'Baseliner::Role::Transition';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Package Group') );
has 'view_to_baseline' => ( is=>'rw', isa=>'HashRef' );
has '_bl' => ( is=>'rw', isa=>'Any' );
has '_bl_map' => ( is=>'rw', isa=>'Any' );
has 'packages' => (is => 'rw', isa => 'ArrayRef');
has 'inc_ids' => (is => 'rw', isa => 'HashRef');

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
        my @related;
        push @related, 'application/'.$row->envobjid->environmentname;
        my $info = _loc('Project').': '.$row->envobjid->environmentname."<br>";
        
        return {
            ns       => 'harvest.packagegroup/' . $row->pkggrpname,
            ns_name  => $row->get_column('pkggrpname'),
            ns_info  => $info,
            user     => $row->modifier->username,
            date     => $row->get_column('modifiedtime'),
            icon_on  => '/static/images/scm/packages.gif',
            icon_off => '/static/images/scm/packages_off.gif',
            service  => 'service.harvest.runner.packagegroup',
            provider => 'namespace.harvest.packagegroup',
            inc_ids  => BaselinerX::CA::Harvest::DB->packagegroup_inc_id(id => $row->pkggrpobjid),
            related  => [ @related ],
            ns_id    => $row->pkggrpobjid,
            ns_data  => { $row->get_columns },
            packages => [BaselinerX::CA::Harvest::DB->packages_for_packagegroup(id => $row->pkggrpobjid)]
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub bind {
    my $self = shift;
    return undef;
}

sub can_job {
    my ( $self, %p ) = @_;

    _log _dump %p;
    
    my $job_type = $p{job_type} or _throw 'Missing job_type parameter';
    my $bl = $p{bl} or _throw 'Missing bl parameter';

    # check if it's pending to approve  
    unless ( $bl ne 'PROD' || Baseliner->model('Request')->list (ns=>$self->ns, pending=>1)->{count} eq 0 ) {
        $self->why_not( _loc('Package Group %1 is pending to approve.', $self->ns_name) );
        # $self->why_not( 'Package Group is pending to approve.' );
        return $self->_can_job( 0 );
    }

    # check if it's included in another release
    my $relid = $1 if $p{ns} =~ m/release\/(.*)/;
    my $relsearch = ($relid?{ns=>"harvest.packagegroup/".$self->ns_name,id_rel=>{ '<>' => $relid } }:{ns=>"harvest.packagegroup/".$self->ns_name }) ;
        
    my $rs = Baseliner->model('Baseliner::BaliReleaseItems')->search($relsearch);
    while ( my $r = $rs->next ) {
        $self->why_not( _loc "Item %1 already in release %2",$self->ns_name,$r->id_rel->name);
        return $self->_can_job( 0 );
    }

    # check can_job of contents
    my $can_job = 1;
    my @why;
    for my $item ( $self->contents ) {
        next unless ref $item;
        next if $item->isa( 'Baseliner::Core::Namespace' );
        unless( $item->can_job( bl=>$bl, job_type=>$job_type ) ) {
            push @why, $item->why_not;
            $can_job = 0;
        }
    }
    $self->why_not( join ', ', @why ) unless $can_job;
    return $self->_can_job( $can_job );
}

sub contents {
    my $self = shift;
    my $pkggrp = Baseliner->model('Harvest::Harpackagegroup')->find( $self->ns_id );
    my @items;
    if( ref $pkggrp ) {
        my $rs = $pkggrp->harpkgsinpkggrps;
        while( my $pkg = $rs->next ) {
            my $ns = 'harvest.package/' . $pkg->packageobjid->packagename;
            push @items, Baseliner->model('Namespaces')->get( $ns );
        }
    }
    return @items;
}

# maps from package view to bl
sub map_bl {
    my ($self, $ns, $bl ) = @_;
    my $new_bl;
    if( ref $self->view_to_baseline eq 'HASH' ) {
        $new_bl = $self->view_to_baseline->{$bl}; 
    } else {
        my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>$self->ns );
        if( $inf ) {
            try {
                $self->view_to_baseline( $inf->{view_to_baseline} );
                $new_bl = $inf->{view_to_baseline}->{$bl}; 
            } catch {
                Catalyst::Exception->throw("Error while processing map_bl: " . shift );
            };
        }
    }
    return $new_bl || $bl;
}

sub pkggrpobjid {
    my $self = shift;
    return $self->ns_id;
}

sub bl {
    my $self = shift;
    my $hardb = BaselinerX::CA::Harvest::DB->new;
    my $bl_map = $self->_bl_map;
    unless( $bl_map ) {
        # setup bl lookup
        my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>'/' );
        $bl_map = $inf->{view_to_baseline} || {};
        $self->_bl_map( $bl_map );
    }
    my @views = $hardb->views_for_packagegroup( $self->ns_data->{pkggrpobjid} );
    my @bls = _unique map { $bl_map->{$_} } grep { $_ } @views;
    #return wantarray ? @bls : ( @bls>1 ? '*' : $bls[0] );
    return $bls[0];
    #return $self->_bl || $self->_bl( $self->bl_from_contents );
}

sub bl_from_contents {
    my $self = shift;
    my $bl = '*';
    my @bl;
    for my $item ( $self->contents ) {
        next unless ref $item;
        next if $item->isa( 'Baseliner::Core::Namespace' );
        push @bl, $item->bl;
    }
    @bl = _unique grep {$_} @bl;
    return wantarray ? @bl : ( @bl==1 ? $bl[0] : '*' ) ;
}


sub created_on {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackagegroup')->find({ pkggrpobjid=>$self->pkggrpobjid },);
    return $pkg->creationtime;
}

sub created_by {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackagegroup')->find({ pkggrpobjid=>$self->pkggrpobjid }, { prefetch=>['modifier'] });
    return $pkg ? $pkg->modifier->username : _loc 'Package not found';
}

=head2 viewpaths

    $self->viewpaths();   # /APL/PATH/PATH/PATH
    $self->viewpaths(1);  # /APL
    $self->viewpaths(2);  # /APL/PATH
    $self->viewpaths(3);  # /APL/PATH/PATH

=cut
use Baseliner::Core::DBI;
sub viewpaths {
    my ($self, $level ) = @_;
    my $pid = $self->pkggrpobjid;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
    my @rs = $db->array_hash( qq{
        select pathfullname
        from haritems i,harpathfullname pa,harversions v,harpackage p,harpkgsinpkggrp pp
        where v.packageobjid=p.packageobjid
        and v.itemobjid=i.itemobjid
        and pa.versionobjid=(SELECT MAX(versionobjid) FROM HARPATHFULLNAME pa2 WHERE pa.itemobjid=pa2.itemobjid)
        and i.parentobjid=pa.itemobjid
        and p.packageobjid=pp.packageobjid
        and pp.pkggrpobjid = $pid
    });
    my %paths;
    for my $row ( @rs ) {
        my $path = $row->{pathfullname};
        $path =~ s{\\}{/}g;
        if( $level ) {
            my @parts = split /\//, $path;
            $path = '/'.join('/', @parts[1..$level]);
        }
        $paths{$path}=1 unless $paths{$path};
    }
    return keys %paths;
    #my $pkg = Baseliner->model('Harvest::Harpackagegroup')->find({ pkggrpobjid=>$self->pkggrpobjid }, { prefetch=>['harversions'], });
    #$pkg->harversions->itemobjid->itemname;
}

sub environmentname {
    my $self = shift;
    my $row = $self->find;
    return $row->envobjid->environmentname;
}

sub checkout { }

our %transition_cmd = ( promote=>'hpp', demote=>'hdp' );

sub transition {
    my $self = shift;
    my $trans = shift;
    my $cmd = $transition_cmd{$trans} or _throw _loc 'Invalid transition type %1', $trans;
    my $p = _parameters( @_);

    my $config = $p->{config} || Baseliner->model('ConfigStore')->get( 'config.ca.harvest.cli' );
    my $cli = $p->{cli} || BaselinerX::CA::Harvest::CLI->new({ broker=>$config->{broker}, login=>$config->{login} });
    my $state = $self->ns_data->{state} or _throw _loc 'Could not find current state for package group %1', $self->ns_name;
    my $co = $cli->run(
            cmd      => $cmd,
            -en      => $self->project,
            -st      => $state,
            -pg      => $self->ns_name,
    );
    _throw _loc( 'Error during %1: %2', $trans, $co->{msg} ) if $co->{rc};
    return $co;
}

sub promote {
    my $self = shift;
    $self->transition( 'promote', @_ );
}

sub demote {
    my $self = shift;
    $self->transition( 'demote', @_ );
}

sub nature {
    my $self = shift;
    use Baseliner::Core::DBI;
    my $db = Baseliner::Core::DBI->new({ model=>'Harvest' }); 

    my $config = Baseliner->registry->get('config.harvest.nature')->data;
    my $cnt = $config->{position};

    my $pgid = $self->ns_data->{pkggrpobjid} or _throw "pkggrpobjid not found";

    my @folders = $db->array(qq{
        SELECT DISTINCT
         SUBSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\',1,
            INSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\','\\',1)-1)
         FROM HARPATHFULLNAME pa, haritems i, harversions v, harpkgsinpkggrp pp
         WHERE v.packageobjid=pp.packageobjid
         and pp.pkggrpobjid=$pgid
         and v.itemobjid = i.itemobjid
         and i.parentobjid = pa.itemobjid
        });
    my %done;
    return map { 'harvest.nature/' . uc } grep { length > 0 } @folders;
}

sub approve { }
sub reject { }
sub is_approved { }
sub is_rejected { }
sub user_can_approve { }

sub find {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackagegroup')->find({ pkggrpobjid=>$self->pkggrpobjid }, { prefetch=>['envobjid'] });
}

sub path {
    my $self = shift;
    my $pkg = $self->find;
    my $env = $pkg->envobjid;
    my $path = $self->compose_path($env->environmentname, $pkg->pkggrpname);
}

sub state {
    my $self = shift;
    my $state = $self->find->state;
    return $state->statename;
}

sub get_row {
    my $self = shift;
    return Baseliner->model('Harvest::Harpackagegroup')->find({ pkggrpobjid=>$self->pkggrpobjid }, { prefetch=>['envobjid'] });
}

sub project {
    my $self = shift;
    my $pkg = $self->get_row;
    return $pkg->envobjid->environmentname;
}

sub application {
    my $self = shift;
    my $env = $self->project;
    my $app = BaselinerX::CA::Harvest::Project::get_apl_code( $env );
    return 'application/' . $app;
}

our @parents;
sub parents {
    return @parents if scalar @parents;
    my $self = shift;
    my $pkg = $self->get_row;
    my $env = $pkg->envobjid->environmentname;
    my $app = BaselinerX::CA::Harvest::Project::get_apl_code( $env );
    push @parents, "application/" . $app;
    push @parents, "harvest.project/" . $env;
    push @parents, "/";
    return @parents;
}

1;

