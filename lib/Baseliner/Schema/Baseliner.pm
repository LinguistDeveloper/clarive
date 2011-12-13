package Baseliner::Schema::Baseliner;
use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Baseliner::Base::ResultSet' );

use Baseliner::Utils;

sub deploy_schema {
    my ( $self, %p ) = @_;
    my $config = delete $p{ config };
    warn _dump $config unless $p{show_config};
    $config ||= eval "Baseliner->config";
    die "Could not connect to db: no config loaded" unless $config;
    my ( $dsn, $user, $pass ) = @{ $config->{ 'Model::Baseliner' }->{ 'connect_info' } };
    $self->db_driver( $dsn );
    my $schema = __PACKAGE__->connect( $dsn, $user, $pass, { RaiseError=>1 } )
        or die "Failed to connect to db";
    if( $p{show} ) {
        my $sqlt_opts = {
            add_drop_table => $p{drop}, 
            quote_table_names => exists $p{quote},
            sources => $p{schema},
        };
        print join ";\n\n",$schema->deployment_statements(undef, undef, undef, $sqlt_opts );
        print ";\n";
        return 0;
    } else {
        $schema->deploy({
            add_drop_table    => $p{drop},
            quote_table_names => 0,
            sources           => $p{schema},
            quote_field_names => 0,
            trace             => 1,
            filters           => [
                sub {
                    my $s = shift;
                    my $dbd = $__PACKAGE__::DB_DRIVER;
                    # replace default (Oracle) for equivalents
                    for my $table_name ( $s->get_tables ) { 
                        my $table = $s->get_table( $table_name );
                        for my $col_name ( $table->get_fields ) {
                            my $col = $table->get_field($col_name); 
                            my $def = $col->default_value;
                            if( ref($def) eq 'SCALAR' && $$def eq 'SYSDATE' ) {
                                $col->default_value( \"(datetime('now'))" ) if $dbd eq 'SQLite';
                            }
                            if( $col_name eq 'id' && $col->data_type =~ m/^num/i && $dbd eq 'SQLite' ) {
                                $col->data_type( 'integer' );
                            }
                        }
                    }
                }
            ],
            %p
        });
        #$schema->storage->debug(1);
    }
}

sub db_driver {
    my ($self, $dsn ) = @_;
    use Try::Tiny;
    return $__PACKAGE__::DB_DRIVER if defined $__PACKAGE__::DB_DRIVER;
    return do { 
        ($__PACKAGE__::DB_DRIVER) = $dsn =~ m{dbi:(\w+):};
    } if defined $dsn;
    return try {
        my $conn = Baseliner->config->{'Model::Baseliner'}->{connect_info};
        my ($lin) = $conn->[0] =~ m{dbi:(\w+):};
        $__PACKAGE__::DB_DRIVER = $lin;
    } catch {
        my $dbh = $self->storage->dbh;
        $__PACKAGE__::DB_DRIVER = $dbh->{Driver}->{Name}; # Oracle SQLite mysql ...
    };
}

1;
