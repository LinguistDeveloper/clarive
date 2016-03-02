package Clarive::Plugins;
use strict;
use warnings;
use Baseliner::Utils qw(_dir _file);

sub all_plugins {
    shift;
    my %options = @_;

    my $home = Clarive->app->home;

    my @plugins;

    for my $dir ( _dir(Clarive->app->plugins_home), _dir($home,'plugins') ) {
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

1;
