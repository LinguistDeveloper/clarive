package Clarive::Plugins;
use Mouse;
use Baseliner::Utils qw(_dir _file _debug);

use Path::Class ();
has app => qw(is ro isa Any weak_ref 1 required 1), default=>sub{ Clarive->app };

sub all_plugins {
    my $self = shift;
    my %options = @_;

    my $home = $self->app->home;

    my @plugins;

    for my $dir ( _dir($self->app->plugins_home), _dir($home,'plugins') ) {
        next unless -e $dir;
        push @plugins, grep { -d } $dir->children;
    }

    $options{name_only} ?
        map { _file($_)->basename } @plugins
        : @plugins;
}

sub locate_path {
    my $self = shift;
    my @files = @_;

    my @plugins = $self->all_plugins;
    for my $dir ( @plugins ) {
        for my $file ( @files ) {
            my $path = _file( $dir, $file );
            return "$path" if -e $path;
        }
    }
    return undef;
}

sub run_dir {
    my $self = shift;
    my ($dir,$opts) = @_;

    my $js;

    for my $path ( map { _dir($_) } Clarive::Plugins->new->locate_path($dir) ) {
        for my $file ( $path->children ) {
            my ($ext) = $file->basename =~ /\.(\w+)$/;
            if( $ext eq 'js' ) {
                _debug( "Running plugin init: $file" );
                require Clarive::Code::JS;
                $js //= Clarive::Code::JS->new( %{ $opts->{js} || {} } );
                $js->eval_code( scalar $file->slurp(iomode=>'<:utf8') );
            }
        }
    }
}

1;
