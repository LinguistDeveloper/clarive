package Clarive::Code::JSModules::ci;
use strict;
use warnings;

use Class::Load qw(is_class_loaded);
use Baseliner::Utils qw(packages_that_do to_base_class _to_camel_case);
use Clarive::Code::Utils;
use Clarive::Code::JSModules::db;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        getClass => js_sub {
            my ($camel) = @_;

            die "Missing parameter `classname`\n" unless $camel;

            my $classname = from_camel_class($camel);

            die "Class `$camel` not found\n" unless $classname;

            _map_ci($classname);
        },
        build => js_sub {
            my ( $camel, $obj ) = @_;

            die "Missing parameter `classname`\n" unless $camel;

            my $classname = from_camel_class($camel);

            my $instance = ci->$classname->new($obj);

            return _map_instance($instance);
        },
        isLoaded => js_sub {
            my ($classname) = @_;

            my $package = 'BaselinerX::CI::' . $classname;

            return Util->_package_is_loaded($package);
        },
        create => js_sub {
            my ( $classname, $obj ) = @_;

            die "Missing parameter `classname`\n" unless $classname;

            my $package = 'BaselinerX::CI::' . $classname;

            die "Class `$classname` already exists\n"
              if is_class_loaded($package);

            my $icon = $obj->{icon} || '/static/images/icons/ci.png';
            my $form = $obj->{form} || $js->current_filename;
            my $attributes = delete( $obj->{has} )     || {};
            my $methods    = delete( $obj->{methods} ) || {};
            my @method_names = keys %$methods;

            my @superclasses;

            for my $superclass ( @{ delete( $obj->{superclasses} ) || [] } ) {
                my $classname = from_camel_class($superclass);
                my $pkg       = Util->to_ci_class($classname);
                if ( !$classname ) {
                    die "Error: could not find superclass `$superclass`\n";
                }
                elsif ( !Util->_package_is_loaded($pkg) ) {
                    die
                      "Error: could not find superclass `$superclass` ($pkg)\n";
                }
                push @superclasses, $pkg;
            }

            my @roles;

            for my $role ( @{ delete( $obj->{roles} ) || [] } ) {
                my $pkg = 'Baseliner::Role::CI::' . $role;
                if ( !Util->_package_is_loaded($pkg) ) {
                    die "Error: could not find role `$role` ($pkg)\n";
                }
                push @roles, $pkg;
            }

            my $class = Moose::Meta::Class->create(
                $package,
                roles        => [ 'Baseliner::Role::CI', @roles ],
                superclasses => \@superclasses,
                attributes   => [
                    map {
                        Moose::Meta::Attribute->new( $_,
                            %{ $attributes->{$_} } )
                    } keys %$attributes
                ],
                methods => {
                    icon         => sub { $icon },
                    _lang        => sub { 'js' },
                    _duk_methods => sub {
                        +{ map { $_ => 1 } @method_names };
                    },
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
            [ map { ucfirst _to_camel_case( to_base_class($_) ) }
                  packages_that_do( $role || 'Baseliner::Role::CI' ) ];
        },
        find => js_sub {
            my $class_or_query = shift;

            if ( !ref $class_or_query ) {
                my $class = from_camel_class($class_or_query);
                my $query = shift;
                Clarive::Code::JSModules::db->_db_wrap_cursor( ci->$class->find( $query, @_ ) );
            }
            else {
                my $query = $class_or_query;
                Clarive::Code::JSModules::db->_db_wrap_cursor(
                    Baseliner::Role::CI->find( $query, @_ ) );
            }
        },
        findOne => js_sub {
            my $class_or_query = shift;

            my ( $class, $query );

            if ( !ref $class_or_query ) {
                my $class = from_camel_class($class_or_query);
                my $query = shift;
                _serialize( {}, ci->$class->find_one( $query, @_ ) );
            }
            else {
                my $query = $class_or_query;
                _serialize( {},
                    Baseliner::Role::CI->find_one( $query, @_ ) );
            }
        },
        load   => js_sub { _map_instance( ci->new(@_) ) },
        delete => js_sub { ci->delete(@_) }
    };
}

1;
