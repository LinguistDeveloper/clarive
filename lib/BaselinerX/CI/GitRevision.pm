package BaselinerX::CI::GitRevision;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _array);
require Girl;
use Baseliner::Utils;
with 'Baseliner::Role::CI::Revision';

# has sha;
# has repo_dir;

has sha => qw(is rw isa Str);
has _sha_long => qw(is rw isa Str);
has_ci 'repo';

has moniker  => qw(is rw isa Maybe[Str] lazy 1), 
    default=>sub{   
        my $self = shift; 
        if( ref $self ) {
            my $nid = $self->sha;
            return $nid;
        } else {
            return '';
        }
    };  # a short name for this

sub rel_type { { repo => [ from_mid => 'repo_revision' ] } }

sub collection { 'GitRevision' }
sub icon { '/static/images/icons/commite_new_.png' }

# sub url {
#     my $self = shift;
#     my $repo_dir = $self->repo->repo_dir;
#     { url=>sprintf( '/gitweb.cgi?p=%s;a=commitdiff;h=%s', $repo_dir, $self->sha ), type=>'iframe' },
# }

sub url {
    my $self = shift;

    my $repo_dir = $self->repo->repo_dir;
    my $repo_mid = $self->repo->mid;

    {
        url        => '/comp/view_diff.js',
        repo_dir   => $repo_dir,
        repo_mid   => $repo_mid,
        rev_num    => $self->sha,
        branch     => '',
        title      => $self->name,
        repo_type  => 'git',
        controller => 'gittree'
    },
}

sub items {
    my ($self, %p)=@_;

    my $type = $p{type} // 'promote';
    my $tag = $p{tag} // _fail _loc 'Missing parameter tag';

    # TODO Comprobar si tengo last_commit
    my $repo = $self->repo;
    my $git = $repo->git;
    
    my $rev_sha  = $self->sha_long; 
    my $tag_sha  = $repo->git->exec( qw/rev-parse/, $tag );
    
    my $diff_shas;
        
    my @items;
    if ( $type eq 'demote' ) {
        @items = $git->exec( qw/diff --name-status/, $tag_sha, $rev_sha . "~1" );
        $diff_shas = [$tag_sha, $rev_sha . "~1"];
    } else {
        if ( $rev_sha ne $tag_sha ) {
            Util->_debug( "BL and REV distinct" );
            @items = $git->exec( qw/diff --name-status/, $tag_sha, $rev_sha );
            $diff_shas = [ $tag_sha, $rev_sha ];
        } else {
            Util->_debug( "BL and REV equal" );

            if ( $type eq 'promote' ) {
                my $sha = ci->GitRevision->search_ci( sha => $rev_sha );
                my @topics = map { $_->{mid} } $sha->parents( where => { collection => 'topic'}, mids_only => 1);

                if ( scalar(@topics) eq 0 ) {
                    _fail _loc("No changesets for this sha");
                } elsif ( scalar(@topics) gt 1 ) {
                    _fail _("This sha is contained in more than one sha");
                }
                my $cs = $topics[0];

                my (@last_jobs) = map {$_->{mid}} sort { $b->{endtime} cmp $a->{endtime} } grep { $_->{final_status} eq 'FINISHED' && $_->{bl} eq $p{tag} } ci->new($cs)->jobs;

                if ( @last_jobs ) {
                    my $last_job;
                    my $job;
                    my $st;
                    my $found = 0;

                    for $last_job ( @last_jobs ) {
                        $job = ci->new($last_job);
                        $st = $job->stash;
                        if ( $st->{bl_original} && $st->{bl_original}->{$repo->mid}->{sha} ne $rev_sha ) {
                            $found = 1;
                            last;
                        }
                    }

                    if ( $found ) {                    
                        $tag_sha = $st->{bl_original}->{$repo->mid}->{sha};
                        _warn _loc("Tag sha set to %1 as it was in previous job %2", $tag_sha, $job->{name});
                        @items = $git->exec( qw/diff --name-status/, $tag_sha, $rev_sha );
                        $diff_shas = [ $tag_sha, $rev_sha ];
                    } else {
                        _warn _loc("No last job detected for commit %1.  Cannot redeploy it", $tag_sha);
                        @items = $git->exec( qw/ls-tree -r --name-status/, $tag_sha );
                        @items = map { my $item = 'M   ' . $_; } @items;
                        $diff_shas = [ $tag_sha ];
                    }
                } else {
                    _warn _loc("No last job detected for commit %1.  Cannot redeploy it", $tag_sha);
                    @items = $git->exec( qw/ls-tree -r --name-status/, $tag_sha );
                    @items = map { my $item = 'M   ' . $_; } @items;
                    $diff_shas = [ $tag_sha ];
                }
            } else {
                @items = $git->exec( qw/ls-tree -r --name-status/, $tag_sha );
                @items = map { my $item = 'M   ' . $_; } @items;
                $diff_shas = [ $tag_sha ];
            }
        }
    } 
    my %repo_items = $self->repo_items( $diff_shas );



    @items = map {
        my ( $status, $path ) = /^(.*?)\s+(.*)$/;
        my $info = $repo_items{ Girl->unquote($path) } // _fail _loc "Could not find diff-tree data for item '%1'", $path; #{ status=>$status };
        my $fullpath = Util->_dir( "/", $path );
        BaselinerX::CI::GitItem->new(
            repo    => $repo,
            sha     => $rev_sha,
            path    => "$fullpath",
            versionid => $rev_sha,
            %$info,
        );
    } @items;
    return @items;
}


sub sha_long {
    my $self = shift;
    # full rev-parsed sha 
    my $fs = $self->_sha_long;
    return $fs if length $fs;
    return $self->_sha_long( $self->repo->git->exec( qw/rev-parse/, $self->sha ) );
}

# return all items in revision
sub show {
    my ($self, %p)=@_;
    my $repo = $self->repo;
    my $git = $repo->git;
    
    my $type = $p{type} // 'promote';
    my $rev_sha  = $self->sha_long;
    #my @items = $git->exec( qw/diff-tree --no-commit-id --name-status -r/, $tag_sha );
    my %repo_items = $self->repo_items( $rev_sha );
    my %demote_statuses = ( M=>'M', D=>'A', A=>'D' );
    my @items = map {
        my $path = $_;
        my $info = $repo_items{ $path } // _fail _loc "Could not find diff-tree data for item '%1'", $path; #{ status=>$status };
        my $fullpath = Util->_dir( "/", $path );
        my $status = $type eq 'demote' ? $demote_statuses{ $$info{status} } : $$info{status}; # invert status on demote
        $status ||= 'M'; # just in case...
        BaselinerX::CI::GitItem->new(
            repo    => $repo,
            sha     => $rev_sha,
            path    => "$fullpath",
            versionid => $rev_sha,
            %$info,
            status => $status, 
        );
    } keys %repo_items; 
    return @items;
}

# get full recursive repository info for this revision sha .. tag, esp. blob num
sub repo_items {
    my ($self, $diff_shas )=@_;
    my %repo_items;
    my $repo = $self->repo;
    my $git = $repo->git;
    my @all = grep /^:/, $git->exec( qw/diff-tree -r -c -M -C/, _array($diff_shas) );
        # process output
    for my $blob_line ( @all ) {
        my ($x, $x2, $mask,$y, $y2, $blob,$status,$path);
        ($x,$mask,$y,$blob,$status,$path) = split /\s+/, $blob_line, 6;
        if(length $y == 6){
            ($x, $x2, $mask,$y, $y2, $blob,$status,$path) = split /\s+/, $blob_line;
        }
        my ($path1,$path2) = split /\ {7}|\t/, $path;
        $mask = substr( $mask, -3 );
        $status = 'M' if !($status =~ /^D$|^A$|^M$/);  # some statuses are like R089 and C089, for renamed items
        if( $blob =~ /^0+$/ || $status eq 'D' ) {  # turn 00000000 blobs into undef blobs
            $blob=undef;
            $mask=undef;
        }
        $repo_items{ Girl->unquote($path2) // Girl->unquote($path1) } = { mask=>$mask, blob=>$blob, status=>$status, old_path=>$path2?$path1:undef };
    }
    # now created 'D' items for renamed ones
    for my $path ( keys %repo_items ) {
        my $ri = $repo_items{ $path };
        my $old_path = delete $ri->{old_path} // next;
        if( !exists $repo_items{$old_path} ) {
            my $ri2 = +{ moved=>$ri->{blob}, status=>'D', blob=>undef, mask=>undef };
            $repo_items{$old_path} = $ri2;            
        }
    }

    return %repo_items;
}
1;
