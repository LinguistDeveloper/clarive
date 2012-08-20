package BaselinerX::CA::Harvest::Controller::Reports;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;
use Baseliner::Core::DBI;

BEGIN { extends 'Catalyst::Controller' }

register 'action.reports.harvest' => { name=>'View All Harvest Reports' };

register 'menu.reports.harvest' => { label => 'Harvest',
	actions=>['action.reports.harvest'] };

register 'menu.reports.harvest.version_hist' => {
	label => 'Version History', url_comp=>'/reports/harvest/version_hist',
	title=>'Version History',
	icon=>'/static/images/scm/eversion.gif',
	actions=>['action.reports.harvest'] };

sub version_hist : Path('/reports/harvest/version_hist')  {
    my ( $self, $c ) = @_;
	#$c->stash->{ns_query} = { does=> 'Baseliner::Role::JobItem' };
	#$c->forward('/namespace/load_namespaces'); # all namespaces

    $c->stash->{template} = '/comp/harvest_version_hist_grid.mas';
}

sub vh_json : Path('/reports/harvest/vh_json')  {
    my ( $self, $c ) = @_;
	my $p = $c->req->params;
	my $query = $p->{query} || '%';
	$query =~ s{\*}{%}g;
	my $prj = 'GBP.0188_DESA';
	my $db = Baseliner::Core::DBI->new( model=>'Harvest' );
	my $page = to_pages( start=>$p->{start}, limit=>$p->{limit} );
	my $limit = $p->{limit} || 30;
	my @rows = $db->array_hash(
		qq{
		SELECT * FROM
		(
		    SELECT a.*, rownum r__
			    FROM
				    (

			select v.versionobjid,n.itemname,pathfullname,v.mappedversion,packagename,environmentname,statename,p.packageobjid,
			   (CASE WHEN (i.itemtype = '1' ) THEN 'file' ELSE 'dir' END ) itemtype
			from harversions v, haritems i, harpathfullname pa, harpackage p, haritemname n, harenvironment e, harstate s
			where v.itemobjid = i.itemobjid
			and v.itemnameid = n.nameobjid
			and p.packageobjid = v.packageobjid
			and p.envobjid = e.envobjid
			and p.stateobjid = s.stateobjid
			and e.environmentname like '$prj'
			and lower(pathfullname||'\\'||n.itemname||';'||mappedversion) like lower('%$query%')
			and pa.itemobjid = i.parentobjid
			ORDER BY i.itemobjid, v.versionobjid
			) a
			WHERE rownum < (( $page * $limit) + 1 )
			)
			WHERE r__ >= ((($page-1) * $limit) + 1)

		}
	);
	# get last job for each selected package
	my @pids = map { 'harvest.package/' . $_->{packagename} } @rows;
	my %pkg_last;
	@pkg_last{ @pids } = ();
	my $rs = Baseliner->model('Baseliner::BaliJobItems')->search(
	   { item=>\@pids } , { order_by => 'id desc' }
	);
	while( my $r = $rs->next ) {
		my $item = $r->item;
		next if defined $pkg_last{ $item };
		my $id_job = $r->id_job->id;
		my $job_name = $r->id_job->name;
		$pkg_last{ $item } = { id=>$id_job, name=>$job_name };
	}
	# find jobs for rows
	for( @rows ) {
		my $pkg = $_->{packagename};
		$_->{last_job} = $pkg_last{ 'harvest.package/' . $pkg }{name};
		$_->{id_job} = $pkg_last{ 'harvest.package/' . $pkg }{id};
	}
	$c->stash->{json} = {
		data=>\@rows, totalCount=>1000
	};
	$c->forward('View::JSON');
}

1;
