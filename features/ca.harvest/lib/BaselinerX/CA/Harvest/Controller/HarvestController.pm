package BaselinerX::CA::Harvest::Controller::HarvestController;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Baseliner::Core::DBI;

BEGIN { extends 'Catalyst::Controller' }

sub create_form : Path('/harvest/create_form') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    $c->stash->{template} = '/comp/harvest/package_create_form.js';
}

sub projects : Path('/harvest/projects') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;

    my $hardb = BaselinerX::CA::Harvest::DB->new;
    my @data;
    if( $c->is_root ) {
        @data = $hardb->active_projects( query=>$p->{query} );
    } else {
        @data = $hardb->projects_for_user( username=>$c->username, query=>$p->{query}  );
    }
    $c->stash->{ json } = { data => \@data };
    $c->forward( 'View::JSON' );
}

sub create_package : Path('/harvest/create_package') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;

    my $ret = { rc=>0, output=>'.............' };
    try {
        my $envobjid = $p->{envobjid} or _throw 'Missing parameter envobjid';
        my $packagename = $p->{packagename} or _throw 'Missing parameter packagename';
        my $username = $p->{username} || $c->username;
        my $assigned = $p->{assigned} || $username;

        $ret = BaselinerX::CA::Harvest::Provider::Package->create(
            packagename=>$packagename, envobjid=>$envobjid, username=>$username );
        _throw _loc('Error executing Harvest command') if $ret->{rc};
        $c->stash->{ json } = { success => \1, output=>$ret->{output} };
    } catch {
        my $err = shift;
        _log ">>> Harvest Package Create failed: $err ";
        $c->stash->{ json } = { success => \0, output=>$ret->{output}, msg=>_loc( 'Error creating package: ' ) . $err };
    };
    $c->forward( 'View::JSON' );
}

sub checkin_form : Path('/harvest/checkin_form') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my $nsid = $p->{ns} or _throw 'Missing parameter ns';

    my $ns = ns_get $nsid or _throw _loc('Not found: %1', $nsid);
    $c->stash->{nsid} = $nsid;
    $c->stash->{pkgname} = $ns->ns_name;
    $c->stash->{clientpath} = $p->{from_dir} or _throw 'Missing parameter from_dir';
    $c->stash->{viewpath} = '/';
    $c->stash->{template} = '/comp/harvest/checkin_form.js';
}

sub checkin : Path('/harvest/checkin') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my $ret = {};
    try {
        my $nsid = $p->{nsid} or _throw 'Missing parameter ns';
        my $viewpath = $p->{viewpath} or _throw 'Missing parameter viewpath';
        my $clientpath = $p->{clientpath} or _throw 'Missing parameter clientpath';
        my $comment = $p->{comment} || _loc('Baseliner checkin by user %1', $c->username );
        my $placement = $p->{placement} || 'trunk';
        my $username = $p->{username} || $c->username;
        my $ns = ns_get $nsid or _throw _loc('Not found: %1', $nsid);
        $ret = $ns->checkin( viewpath=>$viewpath,
            placement => $placement,
            clientpath=>$clientpath, comment=>$comment, username=>$username );
        _throw _loc('Error executing Harvest command') if $ret->{rc};
        $c->stash->{ json } = { success => \1, output=>$ret->{output} };
    } catch {
        my $err = shift;
        _log ">>> Checkin failed: $err ";
        $c->stash->{ json } = { success => \0, output=>$ret->{output}, msg=>_loc( 'Error checking in file: %1', $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub viewpaths : Path('/harvest/viewpaths') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    try {
        my $nsid = $p->{ns};
        my $query = $p->{query}; 
        my $prefix = $p->{prefix}; 
        my @vp = defined $nsid
            ? do { my $ns = ns_get( $nsid ); $ns->project_viewpaths( query=>$query ); }
            : do { BaselinerX::CA::Harvest::Namespace::Application->viewpath_query( "$prefix\%$query\%" ) } ;
        @vp = grep /$query/i, @vp;
        @vp = map { s{\\}{/}g; +{ viewpath=>$_ } } @vp;
        $c->stash->{ json } = { totalCount=>scalar(@vp), data=>\@vp };
    } catch {
        my $err = shift;
        _log $err;
        $c->stash->{ json } = { success => \0, msg=>_loc( 'Error selecting viewpaths: %1', $err ) };
    };
    $c->forward( 'View::JSON' );
}

sub client_files : Path('/harvest/client_files') {
    my ($self,$c)=@_;
    my $p = $c->req->parameters;
    my @data;
    try {
        my $clientpath = $p->{clientpath} or _throw 'Missing parameter clientpath';
        my $viewpath = $p->{viewpath} or _throw 'Missing parameter viewpath';
        $viewpath =~s{\\}{/}g;
        _dir( $clientpath )->recurse( callback=>sub{
            my $f = shift;
            return if $f->is_dir;
            my $file = $f->relative( $clientpath );
            my $base = $file->basename;
            return if $base =~ /^harvest.sig/;
            return if $base =~ /^\.harvest.sig/;
            push @data, { path=>""._file( $viewpath, $file ) };
        });
        $c->stash->{ json } = { totalCount=>scalar(@data), data=>\@data };
    } catch {
        my $err = shift;
        $c->stash->{ json } = { success => \0, msg=>_loc( 'Error selecting viewpaths: %1', $err ) };
    };
    $c->forward( 'View::JSON' );
}

1;
