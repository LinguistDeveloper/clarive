package Clarive::Code::JSModules::ci;
use strict;
use warnings;

use Class::Load qw(is_class_loaded load_class);
use Baseliner::Utils qw(packages_that_do to_base_class _to_camel_case);
use Baseliner::MongoCursorCI;
use Clarive::Code::JSUtils qw(js_sub _map_ci _map_instance from_camel_class _bc_sub _serialize);
use Clarive::Code::JSModules::db;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    return {
        getClass => js_sub {
            my ($camel) = @_;

            die "Missing parameter `classname`\n" unless $camel;

            my $classname = from_camel_class($camel);

            return _map_ci($classname);
        },
        build => js_sub {
            my ( $camel, $obj ) = @_;

            die "Missing parameter `classname`\n" unless $camel;

            my $classname = from_camel_class($camel);

            $obj //= {};
            my $instance = ci->$classname->new($obj);

            return _map_instance($instance);
        },
        isLoaded => js_sub {
            my ($classname) = @_;

            my $package = 'BaselinerX::CI::' . $classname;

            return Util->_package_is_loaded($package);
        },
        createClass => js_sub {
            my ( $classname, $obj ) = @_;

            die "Missing parameter `classname`\n" unless $classname;

            my $package = 'BaselinerX::CI::' . $classname;

            die "Class `$classname` already exists\n"
              if is_class_loaded($package);

            $obj //= {};
            my $icon       = $obj->{icon}              || '/static/images/icons/ci-green.svg';
            my $attributes = delete( $obj->{has} )     || {};
            my $methods    = delete( $obj->{methods} ) || {};
            my @method_names = keys %$methods;

            my @superclasses;

            for my $superclass ( @{ delete( $obj->{superclasses} ) || [] } ) {
                my $classname = from_camel_class($superclass);
                my $pkg       = Util->to_ci_class($classname);

                push @superclasses, $pkg;
            }

            my @roles;
            for my $role ( @{ delete( $obj->{roles} ) || [] } ) {
                my $pkg = 'Baseliner::Role::CI::' . $role;

                load_class $pkg;

                push @roles, $pkg;
            }

            my $class = Moose::Meta::Class->create(
                $package,
                roles        => [ 'Baseliner::Role::CI', @roles ],
                superclasses => \@superclasses,
                attributes => [ map { Moose::Meta::Attribute->new( $_, %{ $attributes->{$_} } ) } keys %$attributes ],
                methods    => {
                    icon => sub { $icon },
                    map {
                        my $meth = $methods->{$_};
                        $_ => _bc_sub($meth);
                    } keys %$methods
                },
                %$obj,
            );
            $class->make_immutable;

            return _map_ci($classname);
        },
        listClasses => js_sub {
            my $role = shift;

            return [ map { ucfirst _to_camel_case( to_base_class($_) ) }
                  packages_that_do( $role || 'Baseliner::Role::CI' ) ];
        },
        find   => js_sub { Clarive::Code::JSModules::db->_db_wrap_cursor( _find(@_) ) },
        findCi => js_sub {
            my $cursor = _find(@_);

            $cursor = Baseliner::MongoCursorCI->new( cursor => $cursor );

            return Clarive::Code::JSModules::db->_db_wrap_cursor($cursor);
        },
        findOne   => js_sub { _serialize( {}, _findOne(@_) ) },
        findOneCi => js_sub {
            my $doc = _findOne(@_);

            return unless $doc;

            return _serialize( {}, ci->new( $doc->{mid} ) );
        },
        load   => js_sub { _map_instance( ci->new(@_) ) },
        delete => js_sub { ci->delete(@_) }
    };
}

sub _findOne {
    my $class_or_query = shift;

    my $val;

    if ( !ref $class_or_query ) {
        my $class = from_camel_class($class_or_query);
        my $query = shift;

        $val = ci->$class->find_one( $query, @_ );
    }
    else {
        my $query = $class_or_query;

        $val = mdb->master_doc->find_one( $query, @_ );
    }

    return $val;
}

sub _find {
    my $class_or_query = shift;

    my $cursor;

    if ( !ref $class_or_query ) {
        my $class = from_camel_class($class_or_query);
        my $query = shift;

        $cursor = ci->$class->find( $query, @_ );
    }
    else {
        my $query = $class_or_query;

        $cursor = mdb->master_doc->find( $query, @_ );
    }

    return $cursor;
}

1;
