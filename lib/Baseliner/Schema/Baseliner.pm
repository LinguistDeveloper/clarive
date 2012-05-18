use utf8;
package Baseliner::Schema::Baseliner;
use strict;
use warnings;

our $VERSION = 2;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Baseliner::Base::ResultSet' );
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('sql/');
 

use Baseliner::Utils;

sub deploy_schema {
    my ( $self, %p ) = @_;
    my $config = delete $p{ config };
    warn _dump $config unless $p{show_config};
    $config ||= eval "Baseliner->config";
    die "Could not connect to db: no config loaded" unless $config;
    my ( $dsn, $user, $pass ) = @{ $config->{ 'Model::Baseliner' }->{ 'connect_info' } };
    $self->db_driver( $dsn );
    my $driver = $__PACKAGE__::DB_DRIVER;
    my $schema = __PACKAGE__->connect( $dsn, $user, $pass, { RaiseError=>1 } )
        or die "Failed to connect to db";
    if( $p{install_version} ) {
        warn "Dumping files...\n";
        $schema->dump_file( $driver, $p{version}, $schema->get_db_version(), %p );
        if (!$schema->get_db_version()) { # schema is unversioned
            warn sprintf "Installing schema versioning system for the first time. Version=%s\n", $schema->schema_version;
            $schema->install();
        }
        return 0;
    } elsif( $p{upgrade} ) {
        $schema->dump_file( $driver, $p{version}, $schema->get_db_version, %p  );
        if (!$schema->get_db_version()) {
          # schema is unversioned
          $schema->install();
        } else {
        print sprintf "Upgrading schema to version=%s\n", $schema->schema_version;
          $schema->upgrade();
        }
        return 0;
    } elsif( $p{show} ) {
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
            sources           => $p{schema},
            quote_table_names => 0,
            quote_field_names => 0,
            trace             => 1,
            filters           => [ \&_filter ],
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

sub SQL::Translator::Producer::Oracle::drop_table {
  my ($table) = @_;
  return "DROP TABLE $table CASCADE CONSTRAINTS";
}

sub dump_file {
    my ($self, $driver, $version, $preversion, %p) = @_;
    $version //= $self->schema_version();
    my $sql_dir = './sql';
    warn "****** Dumping files into $sql_dir: Schema Version=$version, Database Version=$preversion\n";
    $self->create_ddl_dir( $driver, $version, $sql_dir, $preversion, 
        {   # sqlt options
            quote_table_names => 0,
            quote_field_names => 0,
            add_drop_table    => $p{drop},
            #ignore_missing_methods => 1,
            producer_args => {
                quote_table_names => 0,
                quote_field_names => 0,
            },
            trace             => 1,
            filters           => [ \&_filter ],
            #parser => 'Baseliner::Schema::Parser::Oracle',  NOT WORKING, probably ddl_dir is not calling parser directly
        }
    );
}

sub _filter {
    my $s = shift;
    my $dbd = $__PACKAGE__::DB_DRIVER;
    # replace default (Oracle) for equivalents
    for my $table_name ( $s->get_tables ) { 
        my $table = $s->get_table( $table_name );
        for my $col_name ( $table->get_fields ) {
            my $col = $table->get_field($col_name); 
            my $def = $col->default_value;
            if( ref($def) eq 'SCALAR' && $$def =~ /^SYSDATE/i ) {
                $col->default_value( \"current_timestamp" ) if $dbd eq 'SQLite';
            }
            if( $col_name eq 'id' && $col->data_type =~ m/^num/i && $dbd eq 'SQLite' ) {
                $col->data_type( 'integer' );
            }
        }
    }
}

1;
