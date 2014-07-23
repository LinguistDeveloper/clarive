package BaselinerX::CI::GitRevision;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _array);
require Girl;

with 'Baseliner::Role::CI::Revision';

# has sha;
# has repo_dir;

has sha => qw(is rw isa Str);
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
sub icon { '/gitweb/images/icons/commite.png' }

sub url {
    my $self = shift;
    my $repo_dir = $self->repo->repo_dir;
    { url=>sprintf( '/gitweb.cgi?p=%s;a=commitdiff;h=%s', $repo_dir, $self->sha ), type=>'iframe' },
}

sub items {
    my ($self, %p)=@_;

    my $type = $p{type} // 'promote';
    my $tag = $p{tag} // _fail _loc 'Missing parameter tag';

    # TODO Comprobar si tengo last_commit
    my $repo = $self->repo;
    my $git = $repo->git;
    
    my $rev_sha  = $repo->git->exec( qw/rev-parse/, $self->sha );
    my $tag_sha  = $repo->git->exec( qw/rev-parse/, $tag );
    
    my $diff_shas;
        
    my @items;
    if ( $type eq 'demote' ) {
        @items = map { Girl->unquote($_) } $git->exec( qw/diff --name-status/, $tag_sha, $rev_sha . "~1" );
        $diff_shas = [$tag_sha, $rev_sha . "~1"];
    } else {
        if ( $rev_sha ne $tag_sha ) {
            Util->_debug( "BL and REV distinct" );
            @items = map { Girl->unquote($_) } $git->exec( qw/diff --name-status/, $tag_sha, $rev_sha );
            $diff_shas = [ $tag_sha, $rev_sha ];
        } else {
            Util->_debug( "BL and REV equal" );
            @items =map { Girl->unquote($_) } $git->exec( qw/ls-tree -r --name-status/, $tag_sha );
            @items = map { my $item = 'M   ' . $_; } @items;
            $diff_shas = [ $tag_sha ];
        }
    } 
    my %repo_items = $self->repo_items( $diff_shas );
    @items = map {
        my ( $status, $path ) = /^(.*?)\s+(.*)$/;
        my $info = $repo_items{ $path } // _fail _loc "Could not find diff-tree data for item '%1'", $path; #{ status=>$status };
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

# get full recursive repository info for this revision sha .. tag, esp. blob num
sub repo_items {
    my ($self, $diff_shas )=@_;
    my %repo_items;
    my $repo = $self->repo;
    my $git = $repo->git;
    my @all = grep /^:/, $git->exec( qw/diff-tree -r -c -M -C/, _array($diff_shas) );
    # process output
    for my $blob_line ( @all ) {
        my ($x,$mask,$y,$blob,$status,$path) = split /\s+/, $blob_line, 6;
        my ($path1,$path2) = split /\t+/, $path;
        $mask = substr( $mask, -3 );
        $status = 'M' if $status !~ /^(D|A|M)/;  # some statuses are like R089 and C089, for renamed items
        if( $blob =~ /^0+$/ || $status eq 'D' ) {  # turn 00000000 blobs into undef blobs
            $blob=undef;
            $mask=undef;
        }
        $repo_items{ $path2 // $path1 } = { mask=>$mask, blob=>$blob, status=>$status, old_path=>$path2?$path1:undef };
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
