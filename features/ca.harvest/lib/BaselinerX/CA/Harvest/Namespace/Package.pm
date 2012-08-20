package BaselinerX::CA::Harvest::Namespace::Package;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use BaselinerX::BdeUtils;
use Try::Tiny;
use Catalyst::Exception;

use BaselinerX::CA::Harvest::CLI;
use BaselinerX::CA::Harvest::Project;

with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::JobItem';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Approvable';

with 'Baseliner::Role::Namespace::Checkin';
with 'Baseliner::Role::Namespace::Rename';
with 'Baseliner::Role::Namespace::Delete';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Harvest Package') );
has 'view_to_baseline' => ( is=>'rw', isa=>'HashRef' );
has 'viewname' => ( is=>'rw', isa=>'Str' );
has 'inc_id' => (is => 'ro', isa => 'Int');

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
        my @related;
        push @related, 'application/'.$row->get_column('environmentname');
        my $info = _loc('State') . ': ' . $row->get_column('statename')
                 . " (" . lifecycle_for_packagename($row->get_column('packagename')) . ")"
                 . "<br>" 
                 . _loc('Project') . ': ' . $row->get_column('environmentname') . "<br>" ;
		my $state = $row->get_column('statename');
		my $viewname = $row->get_column('viewname');

        return {
                ns      => 'harvest.package/' . $row->packagename,
                ns_name => $row->get_column('packagename'),
                ns_info => $info,
                user    => $row->get_column('username'),
                date    => $row->get_column('modifiedtime'),
                icon    => '/static/images/scm/package.gif',
                service => 'service.harvest.runner.package',
                provider=> 'namespace.harvest.package',
                related => [ @related ],
                ns_id   => $row->packageobjid,
                ns_data => { $row->get_columns, state=>$state, viewname=>$viewname },
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub can_job {
    my ( $self, %p ) = @_;

	my $job_type = $p{job_type} or _throw 'Missing job_type parameter';
	my $bl = $p{bl} or _throw 'Missing bl parameter';

    # check active jobs
    my $active_job = Baseliner->model('Jobs')->is_in_active_job( $self->ns );
    if( ref $active_job ) {
        $self->why_not( _loc( "Package is in job %1 with status %2", $active_job->name, $active_job->status ) );
        return $self->_can_job(0);
    }
	
	# check if it's included in another release
	my $relid = $1 if $p{ns} =~ m/release\/(.*)/;
	my $relsearch = ($relid?{ns=>"harvest.package/".$self->ns_name,id_rel=>{ '<>' => $relid } }:{ns=>"harvest.package/".$self->ns_name }) ;
	my $rs = Baseliner->model('Baseliner::BaliReleaseItems')->search($relsearch);
	while ( my $r = $rs->next ) {
		$self->why_not( _loc "Item %1 already in release %2",$self->ns_name,$r->id_rel->name);
		return $self->_can_job( 0 );
	}

 	# check if it's pending to approve 
	unless ( $bl ne 'PROD' || Baseliner->model('Request')->list (ns=>$self->ns, pending=>1)->{count} eq 0 ) {
		$self->why_not( _loc('Package %1 is pending to approve.', $self->ns_name) );
		# $self->why_not( 'Package is pending to approve.' );
		return $self->_can_job( 0 );
	}

	return $self->_can_job(1);

    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
	#return 1 if( $self->bl eq $bl );
    #my $pkg = Baseliner->model('Harvest::Harpackage')->search({ packageobjid=>$self->ns_id },{ join=>['state', 'view'], prefetch=>['state','view'] });
	#my $state_to_bl = $self->state_to_bl;
}

# maps from package view to bl
sub map_bl {
    my ($self, $ns, $viewname ) = @_;
	my $new_bl;
    my $vb = $self->view_to_baseline ;
	if( ref $vb eq 'HASH' ) {
		$new_bl = $vb->{$viewname}; 
	} else {
		my $inf = Baseliner->model('ConfigStore')->get('config.ca.harvest.map', ns=>$self->ns );
		if( $inf ) {
			try {
				$self->view_to_baseline( $inf->{view_to_baseline} );
				$new_bl = $inf->{view_to_baseline}->{$viewname}; 
			} catch {
				Catalyst::Exception->throw("Error while processing map_bl: " . shift );
			};
		}
	}
    return $new_bl || $viewname;
}

sub packageobjid {
    my $self = shift;
	return $self->ns_id;
}

sub bl {
    my $self = shift;
    return $self->map_bl( $self->application , $self->ns_data->{viewname} ) || 'ERROR';
}

sub created_on {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid },);
    return $pkg->creationtime;
}

sub created_by {
    my $self = shift;
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['modifier'] });
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
	my $pid = $self->packageobjid;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
    my @rs =  Baseliner->config->{'Model::Harvest'}->{db_version} > 7 
        ?  $db->array_hash( qq{
                select pathfullname
                from haritems i,harpathfullname pa,harversions v,harpackage p
                where v.packageobjid=p.packageobjid
                and v.itemobjid=i.itemobjid
                and pa.versionobjid=(SELECT MAX(versionobjid) FROM HARPATHFULLNAME pa2 WHERE pa.itemobjid=pa2.itemobjid)
                and i.parentobjid=pa.itemobjid
                and p.packageobjid=$pid
            })
        :  $db->array_hash( q{
                select pathfullname
                from haritems i,harpathfullname pa,harversions v,harpackage p
                where v.packageobjid=p.packageobjid
                and v.itemobjid=i.itemobjid
                and i.itemtype = 1 -- folders only
                and i.parentobjid=pa.itemobjid
                and p.packageobjid=?
            }, $pid );
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
    #my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['harversions'], });
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
	#_check_parameters($p, qw/project state package/ );
	my $config = $p->{config} || Baseliner->model('ConfigStore')->get( 'config.ca.harvest.cli' );
	my $cli = $p->{cli} || BaselinerX::CA::Harvest::CLI->new({ broker=>$config->{broker}, login=>$config->{login} });
	my $state = $self->ns_data->{state} or _throw _loc 'Could not find current state for package %1', $self->ns_name;
	my $co = $cli->run(
			cmd      => $cmd,
			-en      => $self->project,
			-st      => $state,
			args     => $self->ns_name,
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

	my $pkgid = $self->ns_data->{packageobjid} or _throw "packageobjid not found";

	my @folders = $db->array(qq{
		SELECT DISTINCT
		 SUBSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\',1,
		 	INSTR(SUBSTR(pa.pathfullname,INSTR(pa.pathfullname,'\\',2)+1)||'\\','\\',1)-1)
		 FROM HARPATHFULLNAME pa, haritems i, harversions v
		 WHERE v.packageobjid=$pkgid
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
    my $pkg = Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['envobjid'] });
}

sub path {
    my $self = shift;
    my $pkg = $self->find;
    my $env = $pkg->envobjid;
    my $path = $self->compose_path($env->environmentname, $pkg->packagename);
}

sub state {
    my $self = shift;
    my $state = $self->find->state;
    return $state->statename;
}

sub get_row {
    my $self = shift;
    return Baseliner->model('Harvest::Harpackage')->find({ packageobjid=>$self->packageobjid }, { prefetch=>['envobjid'] });
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

sub rfc {
	my $self = shift;
	my $pkgname = $self->ns_name;
	my $rfc = $pkgname;
	$rfc =~ s{^.{5}(.*?)\@.*$}{$1}g;
	return $rfc; 
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

sub checkin {
    my ($self, %p ) = @_;
    use Baseliner::Sugar;
    $p{placement} ||= 'trunk'; # or branch
    my $comment = $p{comment} || _loc('Checkin via Baseliner');
    my $data = $self->ns_data;
    my $env = $data->{environmentname};
    my $package = $self->ns_name;
    my $state = $data->{statename};
    my $clientpath = $p{clientpath} or _throw 'Missing parameter clientpath';
    my $viewpath = $p{viewpath} || '/';
    $viewpath =~ s{\\}{/}g;

    my $config = config_get 'config.ca.harvest.cli';
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });
    my $output = "";
    my @files;
    my %vp;
    my $hardb = BaselinerX::CA::Harvest::DB->new;
    my $co_proc = $config->{checkout_process};
    my $ci_proc = $config->{checkout_process};
    _dir( $clientpath )->recurse( callback=>sub{
        my $f = shift;
        return if $f->is_dir;
        my $file = $f->relative( $clientpath );
        my $base = $file->basename;
        return if $base =~ /^harvest.sig/;
        return if $base =~ /^\.harvest.sig/;
        $output .= "- $file\n";
        push @files, $file;
        my $path = "". _dir( $viewpath, $file->dir );
        push @{ $vp{ $path } }, $base
            if $hardb->viewpath_exists( $path ); 
    });

    # checkout reserve for each viewpath
    for( keys %vp ) {
        $output .= "Processing vp $_\n";
        $output .= "Files: " . join(', ', _array($vp{$_}) );
        $output .= "\n";
        my %co_args = (	cmd	=> "hco ",
            args  => $vp{$_},
            #-s   => \@files,
            #-s   => '*',
            -to  => undef,
            -ro	 => undef,
            -en  => $env,
            -st  => $state,
            -p   => $package,
            -cp  => $clientpath,
            -vp  => $_,
            #-pn  => $co_proc,
        );
        $co_args{-pn} = $co_proc if $co_proc;
        #$co_args{-cu} = undef if $p{placement} eq 'branch';
        #$co_args{-bo} = undef if $p{placement} eq 'branch';
        #$co_args{-to} = undef if $p{placement} eq 'trunk';
        my $co = $cli->run( %co_args );
        $output .= $co->{msg};
        $output .= "RC = " . $co->{rc} . "\n";
    }
    #return { rc=>1, output=>$output };
    # checkin
    my %ci_args = ( cmd=>'hci',
        -en   => $env,
        -st   =>$state,
        -p    =>$package,
        -cp   =>$clientpath,
        -vp   =>$viewpath,
        -op   =>'pc',
        -de   =>$comment,
        -s    =>'*' );
    $ci_args{-pn} = $ci_proc if $ci_proc;
    $ci_args{-ob} = undef if $p{placement} eq 'branch';
    $ci_args{-ot} = undef if $p{placement} eq 'trunk';
    my $ci = $cli->run( %ci_args );
    $output .= $ci->{msg};
    $output .= "RC = " . $ci->{rc} . "\n";
    _dir( $clientpath )->rmtree unless $ci->{rc}; # delete 
    return { rc=>$ci->{rc} , output=>$output };
}

sub checkin_form_url { '/harvest/checkin_form' }

sub project_viewpaths { 
    my ($self, %p ) = @_;
    my $hardb = BaselinerX::CA::Harvest::DB->new;
    grep { length > 1 } $hardb->viewpaths_for_env( $self->ns_data->{envobjid} ); 
}

=head2 delete

Delete package using the hdp Harvest process.

=cut
sub delete {
    my ($self, %p ) = @_;
    my $config = config_get 'config.ca.harvest.cli';
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });
    my $dp_proc = $config->{package_delete_process};
    my $env = $self->ns_data->{environmentname};
    my $state = $self->ns_data->{statename};
    my %args = (
        cmd   =>'hdlp',
        -en   => $env,
        -st   => $state,
        -pkgs  => $self->ns_data->{packagename},
    );
    $args{-pn} = $dp_proc if $dp_proc;
    my $dp = $cli->run( %args );
    return { rc=>$dp->{rc} , output=>$dp->{msg} };
}

sub rename {
    my ($self, $name ) = @_;
    $name or _throw 'Missing name';
    my $row = $self->get_row;;
    $row->packagename( $name );
    $row->update;
    $self->ns_name( $name );
    $self->ns( 'harvest.package/' . $name );
}

1;
