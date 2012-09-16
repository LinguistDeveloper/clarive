package BaselinerX::Service::ChangesetServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';

register 'service.changeset.checkout' => {
    name    => 'Checkout files of a changeset',
    handler => \&checkout,
};

register 'service.changeset.job_elements' => {
    name    => 'Fill job_elements',
    handler => \&job_elements,
};

register 'service.changeset.update' => {
    name    => 'Update Baselines',
    handler => \&update_baselines,
};

sub checkout {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    my $bl    = $job->bl;

    my $e = $job->job_stash->{elements};

    $log->debug( "Elements", data => _dump $e);
    my @eltos = $e->list( '' );

    my $checkout;

    # Topic Files
    for my $element ( @eltos ) {
        next if ( ref $element ne 'BaselinerX::ChangesetElement' );
        my $file = $c->model( 'Baseliner::BaliFileVersion' )->find( $element->{mid} );
        my $filepath = _file $job->root, $element->{path}, $element->{name};
        _mkpath( _file $job->root, $element->{path} );

        $log->debug( "Element $element->{mid}", data => _dump $element);

        open my $fout, '>', $filepath
            or _throw _loc( 'Changeset checkout: failed to write to file "%1": %2', $filepath, $! );
        print $fout $file->filedata;
        close $fout;
        $checkout .= $filepath . "\n";
    } ## end for my $element ( @eltos)
    $log->info( _loc( "Checked out files" ), data => $checkout );

    # Topic Files END

    # Git Checkouts
    my $git_checkouts = $stash->{git_checkouts};

    for ( keys %{$git_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->checkout( rev => $git_checkouts->{$_}->{rev}, prj => $git_checkouts->{$_}->{prj} );
    }

    # Git Checkouts End

    # Svn Checkouts
    my $svn_checkouts = $stash->{svn_checkouts};

    for ( keys %{$svn_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->checkout( repo => $repo, rev => $svn_checkouts->{$_}->{rev}, prj => $svn_checkouts->{$_}->{prj}, branch => $svn_checkouts->{$_}->{branch} );
    }

    # Svn Checkouts End
} ## end sub checkout

sub job_elements {
    my ( $self, $c, $config ) = @_;
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $job->job_stash;
    my $bl    = $job->bl;
    my @changesets;

    for my $item ( _array $stash->{contents} ) {
        my $ns = ns_get $item->{item};
        next unless $ns->ns_type eq 'changeset';

        if ( $ns->{ns} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            $log->debug( "Changeset $mid detected for job" );
            push @changesets, $mid;
        }

    } ## end for my $item ( _array $stash...)

    my @elems;
    my @versions;

    if ( $job->job_type eq 'demote' || $job->rollback ) {

    } else {

        #Topic Files
        my $versions_ref = $c->model( 'Baseliner::BaliMasterRel' )->search(
            {from_mid => \@changesets, rel_type => 'topic_file_version'},
            {
                join    => { 'topic_file_version_to' => { 'file_projects' => { 'directory' } } },
                +select => [
                    'topic_file_version_to.filename', 'max(topic_file_version_to.versionid)',
                    'max(topic_file_version_to.mid)', 'max(directory.name)'
                ],
                +as      => [ 'filename', 'version', 'mid', 'path' ],
                group_by => 'topic_file_version_to.filename',
            }
        )->hashref->all;
        
        @elems = map {
            BaselinerX::ChangesetElement->new(
                mid      => $_->{mid},
                fullpath => "/changesets/" . $_->{filename},
                status   => 'M',
                version  => $_->{version}
            );
        } @versions;
        $log->debug(_loc("<b>Changeset:</B> Files detected for job"), data => _dump @elems);

        #Topic Files end

    } ## end else [ if ( $job->job_type eq...)]

    #Git revisions
    my @revisions =
        $c->model( 'Baseliner::BaliMasterRel' )
        ->search( {from_mid => \@changesets, rel_type => 'topic_revision'} )->hashref->all;

    if ( @revisions ) {

        my $revisions_shas;
        my $git_checkouts;

        for ( @revisions ) {
            $log->debug(_loc("<b>GIT Revisions:</B> Treating revision"), data => _dump $_);
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::GitRevision';
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev->{sha};
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            my $projectid = $topic->projects->search()->first->id;
            my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
            $revisions_shas->{$repo->{mid}}->{prj} = $prj;
            $git_checkouts->{$repo->{mid}}->{prj}  = $prj;
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>GIT Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $log->debug("JOB", data => $job);
            $repo->job( $job );

            $log->debug( "Detecting last commit" );
            my $last_commit =
                $repo->get_last_commit( commits => $revisions_shas->{$_}->{shas} );
            $log->debug( "Detected last commit", data => $last_commit );
            $log->debug( "Generating git list of elements" );
            my @git_elements =
                $repo->list_elements( rev => $last_commit, prj => $revisions_shas->{$_}->{prj} );
            $log->debug( "Generated git list of elements", data => _dump @git_elements );
            push @elems, @git_elements;
            $git_checkouts->{$_}->{rev} = $last_commit;
        } ## end for ( keys %{$revisions_shas...})
        $job->job_stash->{git_checkouts} = $git_checkouts;
    } ## end if ( @revisions )

    #Git revisions fin

    #SVN revisions

    if ( @revisions ) {

        my $revisions_shas;
        my $svn_checkouts;
        my $branch;

        for ( @revisions ) {
            $log->debug(_loc("<b>SVN Revisions:</B> Treating revision"), data => _dump $_);
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::SvnRevision';
            $branch = $rev->{branch};
            $log->debug(_loc("<b>SVN Revisions:</B> Branch of revision $rev->{sha} ... $branch"), data => _dump $rev);
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev->{sha};
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            my $projectid = $topic->projects->search()->first->id;
            my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
            $revisions_shas->{$repo->{mid}}->{prj} = $prj;
            $svn_checkouts->{$repo->{mid}}->{prj}  = $prj;
            $svn_checkouts->{$repo->{mid}}->{branch}  = $branch;
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>SVN Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $repo->job( $job );

            $log->debug(_loc("<b>SVN Revisions:</B> Calling revision $_ list_elements"));
            my @svn_elements =
                $repo->list_elements( repo => $repo,  prj => $revisions_shas->{$_}->{prj}, commits => $revisions_shas->{$_}->{shas}, branch => $branch );
            $log->debug( "<b>SVN Revisions:</B> Generated git list of elements", data => _dump @svn_elements );
            push @elems, @svn_elements;
            $svn_checkouts->{$_}->{rev} = $repo->last_commit( commits => $revisions_shas->{$_}->{shas} );
        } ## end for ( keys %{$revisions_shas...})
        $job->job_stash->{svn_checkouts} = $svn_checkouts;
    } ## end if ( @revisions )

    #SVN revisions fin

    #CVS revisions

    if ( @revisions ) {

        my $revisions_shas;
        my $cvs_checkouts;
        my $branch;

        for ( @revisions ) {
            $log->debug(_loc("<b>CVS Revisions:</B> Treating revision"), data => _dump $_);
            my $rev  = Baseliner::CI->new( $_->{to_mid} );
            next if ref $rev ne 'BaselinerX::CI::CvsRevision';
            $branch = $rev->{branch};
            $log->debug(_loc("<b>CVS Revisions:</B> Branch of revision $rev->{sha} ... $branch"), data => _dump $rev);
            my $repo = $rev->{repo};
            push @{$revisions_shas->{$repo->{mid}}->{shas}}, $rev->{sha};
            my $topic     = Baseliner->model( 'Baseliner::BaliTopic' )->find( $_->{from_mid} );
            my $projectid = $topic->projects->search()->first->id;
            my $prj       = Baseliner::Model::Projects->get_project_name( id => $projectid );
            $revisions_shas->{$repo->{mid}}->{prj} = $prj;
            $cvs_checkouts->{$repo->{mid}}->{prj}  = $prj;
            $cvs_checkouts->{$repo->{mid}}->{branch}  = $branch;
        } ## end for ( @revisions )

        for ( keys %{$revisions_shas} ) {
            $log->debug(_loc("<b>CVS Revisions:</B> Processing revision $_"));
            my $repo = Baseliner::CI->new( $_ );
            $repo->job( $job );

            $log->debug(_loc("<b>CVS Revisions:</B> Calling revision $_ list_elements"));
            my @cvs_elements =
                $repo->list_elements( repo => $repo,  prj => $revisions_shas->{$_}->{prj}, commits => $revisions_shas->{$_}->{shas}, branch => $branch );
            $log->debug( "<b>CVS Revisions:</B> Generated git list of elements", data => _dump @cvs_elements );
            push @elems, @cvs_elements;
            $cvs_checkouts->{$_}->{rev} = $repo->last_commit( commits => $revisions_shas->{$_}->{shas} );
        } ## end for ( keys %{$revisions_shas...})
        $job->job_stash->{cvs_checkouts} = $cvs_checkouts;
    } ## end if ( @revisions )

    #CVS revisions fin

    my $e = $job->job_stash->{elements} || BaselinerX::Job::Elements->new;
    $e->push_elements( @elems );

    $job->job_stash->{elements} = $e;
    $log->info(
        _loc( "Elements included in job" ),
        data => join "\n",
        map { "M  " . $_->{filename} . ":" . $_->{version} } @versions
    );


} ## end sub job_elements


sub update_baselines {
    my ( $self, $c, $config ) = @_;
    my $job      = $c->stash->{job};
    my $log      = $job->logger;
    my $stash    = $job->job_stash;
    my $bl       = $job->bl;
    my $job_type = $job->job_type;
    my @changesets;


    if ( $job_type eq 'static' ) {
        $self->log->info( _loc "Changesets status not updated. Static job." );
        return;
    }

    my $status = $stash->{status_to};

    ### DANGER!!!! ADDED FOR DEMO PURPOSES ONLY
    if ( !$status ) {
        $status = $c->model( 'Baseliner::BaliTopicStatus' )->search( {bl => $bl} )->first->id;
    }
    ### DANGER!!!! ADDED FOR DEMO PURPOSES ONLY

    for my $item ( _array $stash->{contents} ) {

        if ( $item->{item} =~ /.*\/(.*)$/ ) {
            my $mid = $1;
            push @changesets, $mid;
        }
    } ## end for my $item ( _array $stash...)
    my $rs_changesets = DB->search( {mid => \@changesets}, { prefetch => 'status'} );

    while ( my $row = $rs_changesets->next ) {
        event_new 'event.topic.change_status' => { username => $job->row->username, status => $status, old_status => $row->status->name } => sub {
            $row->id_category_status( $status );
            $row->update;
            my $status_name = $c->model( 'Baseliner::BaliTopicStatus' )->find( $status )->name;
            $log->info( _loc( "%1 %2 to %3", $job_type, $row->title, $status_name ) );
            return { mid => $row->mid, topic => $row->title };
        }         
    } ## end while ( my $row = $rs_changesets...)

    # Git Update Baselines
    my $git_checkouts = $stash->{git_checkouts};

    for ( keys %{$git_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->update_baselines( rev => $git_checkouts->{$_}->{rev} );
    }

    # Git Update Baselines

    # Svn Update Baselines
    my $svn_checkouts = $stash->{svn_checkouts};

    for ( keys %{$svn_checkouts} ) {
        my $repo = Baseliner::CI->new( $_ );
        $repo->job( $job );
        $repo->update_baselines( repo => $repo, branch => $svn_checkouts->{$_}->{branch}, rev => $svn_checkouts->{$_}->{rev} );
    }

    # Svn Update Baselines
} ## end sub update_baselines

package BaselinerX::ChangesetElement;
use Moose;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;

with 'BaselinerX::Job::Element';

has mask => qw(is rw isa Str default /application/subapp/nature);
has sha  => qw(is rw isa Str);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = @_;

    if ( !exists $p{path} && !exists $p{name} ) {
        if ( $p{fullpath} =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        } else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    } ## end if ( !exists $p{path} ...)
    $self->$orig( %p );
};

1;
