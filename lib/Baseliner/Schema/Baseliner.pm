use utf8;
package Baseliner::Schema::Baseliner;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

sub connection {
     my $self = shift;
     my $rv = $self->next::method( @_ );
     $rv->storage->sql_maker->quote_char([ qw/[ ]/ ]);
     $rv->storage->sql_maker->name_sep('.');
     return $rv;
}

my $filter =  sub {
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
            if( $dbd eq 'ODBC' ) {
                $col->data_type('VARCHAR') if $col->data_type =~ /VARCHAR2/i;
                $col->size(8000) if $col->data_type =~ /VARCHAR/i && $col->size > 8000;
                $col->data_type('INTEGER') if $col->data_type =~ /NUMBER|NUMERIC/i;
                $col->size( 0 ) if $col->data_type =~ /.LOB/i;
                $col->data_type( 'VARCHAR(max)' ) if $col->data_type =~ /.LOB/i;
                $col->default_value( \'GETDATE()') if ref($def) eq 'SCALAR' && $$def =~ /SYSDATE/i;
            }
        }
    }
};

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
            add_drop_table    => $p{drop},
            quote_table_names => exists $p{quote},
            sources           => $p{schema},
            filters           => [ $filter ],
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
            filters           => [ $filter ],
            %p   # additional parameters
        });
        #$schema->storage->debug(1);
    }
}

1;
