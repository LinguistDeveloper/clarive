package Girl::Repo;
use Any::Moose;
#use Git::Wrapper;
#use Path::Class;
use Girl::Git;
use Girl::Ref;
use Carp;
use namespace::autoclean;

has path        => qw( is rw isa Str required 1 );
has working_dir => qw( is rw isa Str );
has bare        => qw( is rw isa Bool );
has git         => qw( is rw isa Girl::Git ), handles=>['run', 'exec'];

sub BUILD {
    my $self = shift;
    use Path::Class;

    my $path = dir( $self->path );
    if ( -e ( my $gitpath = dir($path)->subdir('.git') ) ) {  # working tree dir/.git
        $self->path( "$gitpath" );
        $self->working_dir( "$path" );
        $self->bare(0);
        $self->git( Girl::Git->new( work_tree => $path ) );
    } elsif ( -e dir($path) ) {   # bare
        $self->bare(1);
        $self->git( Girl::Git->new( git_dir => $path ) );
    } else {
        croak "Invalid repository path: " . $self->path;
    }
}

sub heads {
    my ($self, %args) = @_;
    Girl::Head->find_all( $self ); 
}

sub refs {
    my $self = shift;
    ( Girl::Head->find_all($self), Girl::Tag->find_all($self), Girl::Remote->find_all($self) );
}

sub refs_list {
    my $self = shift;
}

sub commit {
    my ($self, $sha) = @_;
    return Girl::Commit->new( repo=>$self, sha=>$sha );
}

1;
