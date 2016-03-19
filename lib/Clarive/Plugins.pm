package Clarive::Plugins;
use Mouse;
use Baseliner::Utils qw(_dir _file _debug);

use Path::Class ();
has app => qw(is ro isa Any weak_ref 1 required 1), default=>sub{ Clarive->app };

sub _plugin_id {
    shift;
    _file($_[0])->basename;
}

sub load_info {
    my $self = shift;
    my ($plugin_home) = @_;

    my $info;

    my $plugin_id = $self->_plugin_id( $plugin_home );

    my $plugin_yml = _file( $plugin_home, 'plugin.yml' );

    if( -e $plugin_yml ) {
        $info = Util->_load( scalar $plugin_yml->slurp( iomode=>'<:utf8' ) );
    } else {
        $info->{name} = $plugin_id;
    }

    $info->{id} = $plugin_id;
    $info->{version} //= '';

    return $info;
}

sub all_plugins {
    my $self = shift;
    my %opts = @_;

    my @plugins;
    my @ids;

    my $cla_home = $self->app->home;

    for my $base ( _dir($self->app->plugins_home), _dir($cla_home,'plugins') ) {
        next unless -e $base;

        if( exists $opts{id} ) {
            my $home = _dir($base,$opts{id});
            return "$home" if -e $home;
        }

        for my $home ( $base->children ) {
            next unless -d $home;

            my $id = $self->_plugin_id($home);
            next if $id =~ /^#/;

            push @ids, $id;
            push @plugins, $home;
        }
    }

    return if exists $opts{id};

    $opts{id_only} ? @ids : @plugins;
}

sub locate_plugin {
    my $self = shift;
    my $id = shift;

    $self->all_plugins( id=>$id );
}

sub locate_first {
    my $self = shift;
    my @files = @_;

    my @plugins = $self->all_plugins;

    for my $plugin_home ( @plugins ) {

        my $plugin_id = $self->_plugin_id($plugin_home);

        for my $file ( @files ) {
            my $path = _file( $plugin_home, $file );
            return { path=>"$path", plugin=>$plugin_id } if -e $path;
        }
    }
    return undef;
}

sub locate_all {
    my $self = shift;
    my @files = @_;

    my @paths;
    my @plugins = $self->all_plugins;

    for my $plugin_home ( @plugins ) {

        my $plugin_id = $self->_plugin_id($plugin_home);

        for my $file ( @files ) {
            my $path = _file( $plugin_home, $file );
            push @paths, { path=>"$path", plugin=>$plugin_id } if -e $path;
        }
    }
    return @paths;
}

sub for_each_file {
    my $self = shift;
    my ( $path_names, $cb ) = @_;

    for my $path_name ( Util->_array($path_names) ) {
        for my $item ( $self->locate_all($path_name) ) {
            my $path   = $item->{path};
            my $plugin = $item->{plugin};

            _dir($path)->recurse(
                callback => sub {
                    my $file = shift;
                    return if -d $file;
                    $cb->( "$file", $plugin );    # a false value stops this loop
                }
            );
        }
    }
}

sub run_dir {
    my $self = shift;
    my ( $dir, $opts ) = @_;

    $self->for_each_file( $dir, sub {
        my $file = shift;

        _debug("Running plugin init: $file");

        require Clarive::Code;
        Clarive::Code->new->run_file("$file");
    });
}

1;
