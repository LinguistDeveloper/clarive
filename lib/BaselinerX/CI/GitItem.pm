package BaselinerX::CI::GitItem;
use Baseliner::Moose;
use Baseliner::Utils;
use Moose::Util::TypeConstraints;

with 'Baseliner::Role::CI::Item';

has sha   => qw(is rw isa Str);
has blob  => qw(is rw isa Maybe[Str]);
has moved  => qw(is rw isa Maybe[Str]);  # indicates that this item (a 'D') was moved, and the value is the new blob or undef

has_ci 'repo';
sub rel_type { { repo => [ from_mid => 'repo_item' ] } }

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %p = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    if( ! exists $p{path} && ! exists $p{name} ) {
        if(  $p{ fullpath } =~ /^(.*)\/(.*?)$/ ) {
            ( $p{path}, $p{name} ) = ( $1, $2 );
        } 
        else {
            ( $p{path}, $p{name} ) = ( '', $p{fullpath} );
        }
    }
    $p{name} = Util->_file( $p{path} )->basename if !$p{name};
    $p{ns} //= $p{blob} if $p{blob};
    $p{versionid} = $p{blob} if $p{blob};
    $self->$orig( %p );
};

sub source {
    my ($self, %p) = @_;
    my $sha = $p{version} // $p{sha} // $self->sha; 
    my $repo = $p{repo} // $self->repo;
    my $git = $repo->git;
    local $Baseliner::logger = undef;
    my @lines = $git->exec( 'cat-file', '-p',  $self->blob, { no_chomp=>1, %p } );
    return join '',@lines;
}

sub checkout {
    my ($self, %p) = @_;
    
    my $flat = $p{flat};
    my $path = $p{path};
    my $repo = $p{repo} // $self->repo // _fail _loc 'Missing parameter repo';
    my $dir = $p{dir} // _fail 'Missing dir parameter' unless $path;
    
    my $mask = $self->mask;
   
    $path //= File::Spec->catfile( 
        "$dir", 
        $flat ? _file( $self->path )->basename : $self->path 
    );
    my $dir_for_file = _file( $path )->dir;
    $dir_for_file->mkpath;
    _fail _loc "Could not find or create dir %1 for file %2", $dir_for_file, $self->path 
        unless -e $dir_for_file;
        
    if( my $blob = $self->blob ) {
        my $git = $repo->git;
        $git->exec( 'cat-file', '-p',  "'$blob'", "> '$path'", { cmd_unquoted=>1, no_chomp=>1, %p } );
        system 'chmod', $mask, "$path" if $mask;  # TODO consider using Perl's chmod with oct($mask) to convert string to octal
    } elsif( $self->status ne 'D' ) {
        _warn( _loc('File %1 does not have a blob', $path) );
    } else {
        unlink "$path"; # delete local file, may exist due to a previous baseline checkout, so unlink is due
    }
    #open my $ff, '>', $path 
    #or _fail _loc "Could not checkout to file '%1': %2", $path, $!;
    #binmode $ff;
    #print $ff $self->source( no_encode=>1, repo=>$repo );
    #close $ff; 
}

1;
