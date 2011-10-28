package Baseliner::Controller::Project;
use Baseliner::Plug;
BEGIN { extends 'Catalyst::Controller' };
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Moose::Autobox;
use JSON::XS;
use namespace::clean;

register 'menu.admin.project' => {
	label => 'Projects', url_comp=>'/project/grid', actions=>['action.admin.role'],
	title=>'Projects', index=>80,
	icon=>'/static/images/icons/project.gif' };

sub list : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;

    my $page = to_pages( start=>$start, limit=>$limit );
    my $where = $query
        ? { 'lower(name||ns||description)' => { -like => "%".lc($query)."%" } } 
        : undef;
	my $rs = $c->model('Baseliner::BaliProject')->search(
       $where,
    {
        page => $page,
        rows => $limit,
        order_by => $sort ? "$sort $dir" : undef
    });
	rs_hashref( $rs );
	my @rows = $rs->all;
	$c->stash->{json} = { data => \@rows, totalCount=>scalar(@rows) };		
	$c->forward('View::JSON');
}

sub grid : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '/comp/project_grid.mas';
}

sub show : Local {
    my ( $self, $c, $id ) = @_;
	my $p = $c->request->parameters;
	$id ||= $p->{id};
	my $prj = Baseliner->model('Baseliner::BaliProject')->search({ id=>$id })->first;

    $c->stash->{id} = $id;
    $c->stash->{prj} = $prj;
    $c->stash->{template} = '/site/project/project.html';
}

=head2 user_projects

returns the user project json

    include_root => 1     includes the "all prroject" or "/" namespace

=cut
sub user_projects : Local {
    my ($self,$c) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    $sort ||= 'name';
    $dir ||= 'asc';
    $limit ||= 100;
    $query and $query = qr/$query/i;
    my @rows;
    my $username = $c->username;
    my $perm = $c->model('Permissions');
    #if( $username && ! $perm->is_root( $username ) && ! $perm->user_has_action( username=>$username, action=>'action.job.viewall' ) ) {
        #$where->{'bali_job_items.application'} = { -in => \@user_apps } if ! ( grep { $_ eq '/'} @user_apps );
        # username can view jobs where the user has access to view the jobcontents corresponding app
        # username can view jobs if it has action.job.view for the job set of job_contents projects/app/subapl
    #}
    @rows =  $perm->user_namespaces( $username ); # user apps
    @rows = grep { $_ ne '/' } @rows unless $c->is_root || $p->{include_root};
    @rows = grep { $_ =~ $query } @rows if $query;
    my $rs = $c->model('Baseliner::BaliProject')
                   ->search({ ns        => \@rows
                            , id_parent => {'=' => undef} });  # Added by Eric (q74613x) 20110719
    rs_hashref($rs);
    @rows = map { $_->{data}=_load($_->{data});
        $_->{ns} = 'project/' . $_->{id};
        $_->{description} ||= $_->{name};
        $_ } $rs->all;
  @rows = sort { $$a{'name'} cmp $$b{'name'} } @rows;  # Added by Eric (q74613x) 20110719
	$c->stash->{json} = { data => \@rows, totalCount=>scalar(@rows) };		
	$c->forward('View::JSON');
}

1;
