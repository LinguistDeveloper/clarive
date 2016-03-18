package Clarive::Code::JSModules::db;
use strict;
use warnings;

use Baseliner::Utils qw(_unbless);
use Clarive::Code::Utils;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        seq => js_sub {
            mdb->seq(@_);
        },
        getDatabase => js_sub {
            my ($name) = @_;

            my $db = Baseliner::Mongo->new( db_name => $name );

            return +{ $class->_generate_db_methods($db) }
        },
        ( $class->_generate_db_methods($Clarive::_mdb) ),
    };
}

sub _generate_db_methods {
    my $class = shift;
    my ($db) = @_;

    return (
        getCollection => js_sub {
            my ($name) = @_;

            my $col = $db->collection($name);

            return {
                insert => js_sub {
                    return $col->insert(@_);
                },
                remove => js_sub {
                    return $col->remove(@_);
                },
                update => js_sub {
                    return $col->update(@_);
                },
                drop => js_sub {
                    return $col->drop;
                },
                findOne => js_sub {

                    my $doc = $col->find_one( @_ );
                    return _serialize( {}, $doc );
                },
                clone => js_sub {
                    return $col->clone( @_ );
                },
                find => js_sub {

                    my $cursor = $col->find(@_);
                    return $class->_db_wrap_cursor( $cursor );
                }
            };
        }
    );
}

sub _db_wrap_cursor {
    my $class = shift;
    my $cursor = shift;
    return {
        next    => js_sub { _unbless( $cursor->next ) },
        hasNext => js_sub { $cursor->has_next },
        forEach => js_sub {
            my ($cb) = @_;

            return unless $cb && ref $cb eq 'CODE';

            while ( my $doc = $cursor->next ) {
                $cb->( _unbless( $doc ) );
            }

            return;
        },
        count => js_sub { $cursor->count },
        all   => js_sub { [ map { _unbless($_) } $cursor->all(@_) ] },
        fields=> js_sub { $class->_db_wrap_cursor( $cursor->fields(@_) ) },
        limit => js_sub { $class->_db_wrap_cursor( $cursor->limit(@_) ) },
        skip  => js_sub { $class->_db_wrap_cursor( $cursor->skip(@_) ) },
        sort  => js_sub { $class->_db_wrap_cursor( $cursor->sort(@_) ) },
    };
}

1;

