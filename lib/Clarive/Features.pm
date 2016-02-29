package Clarive::Features {
    use Mouse;
    use Path::Class ();
    has app => qw(is ro isa Any weak_ref 1 required 1);
    sub list_and_home { 
        my $self = shift; 
        return (Clarive::Feature->new(path=>''.Clarive->home), $self->list) 
    }
    sub list {
        my ($self) = @_;
        my $app = $self->app;
        my @dirs = grep { -d } ( Path::Class::dir( $app->base, 'features' ), Path::Class::dir( $app->home, 'features' ) );     
        my @features = 
            map { Clarive::Feature->new( path=>"$_" ) } 
            grep { $_->basename !~ /^#/ } map { $_->children } @dirs; 
        return @features;
    }
}


# mini feature system
package Clarive::Feature {
    use Mouse;
    has path => qw(is ro isa Str required 1);
    sub id {  [ (Path::Class::dir(shift->path)->basename =~ /^(.*)\.(.*?)$/ ) ]->[0] }
    sub path_to { 
        my $self = shift;

        my $file = Path::Class::file( $self->path, @_ );

        return -d $file ? Path::Class::dir("$file") : $file;
    }
}

1;
