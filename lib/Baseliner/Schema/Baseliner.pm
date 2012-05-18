use utf8;
package Baseliner::Schema::Baseliner;
use strict;
use warnings;

our $VERSION = 3;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Baseliner::Base::ResultSet' );
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('sql/');
 

use Baseliner::Utils;

sub deploy_schema {
    my ( $self, %p ) = @_;

    # get config and connect
    my $config = delete $p{ config };
    warn _dump $config unless $p{show_config};
    $config ||= eval "Baseliner->config";
    die "Could not connect to db: no config loaded" unless $config;
    my ( $dsn, $user, $pass ) = @{ $config->{ 'Model::Baseliner' }->{ 'connect_info' } };
    $self->db_driver( $dsn );

    # setup driver, $schema is the actual $self
    my $driver = $__PACKAGE__::DB_DRIVER;
    my $schema = __PACKAGE__->connect( $dsn, $user, $pass, { RaiseError=>1 } )
        or die "Failed to connect to db";

    # process main command
    if( $p{install_version} ) {
        warn "Dumping files...\n";
        $schema->dump_file( $driver, $p{to}, $p{from}, %p );
        if (!$schema->get_db_version()) { # schema is unversioned
            warn sprintf "Installing schema versioning system for the first time. Version=%s\n", $schema->schema_version;
            $schema->install();
        }
        return 0;
    } elsif( $p{upgrade} ) {
        # generate the migration file?  1-2, etc
        my $file = $schema->_upgrade_file( $p{from}, $p{to} );
        my $question = qq{File '$file' already exists. Do you want to overwrite it with an automatically generated version?};
        if( ! -e $file || $self->_ask_me( $question ) ) {
            $schema->dump_file( $driver, $p{to}, $p{from}, %p  );
        }
        # show file
        open my $ff, '<', $file;
        print join '',<$ff>;
        close $ff;
        if (!$schema->get_db_version()) {
            # schema is unversioned
            $schema->install();
        } elsif( ! exists $p{show} ) {
            # upgrade (execute sql files) is done here:
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

#
# monkey patch to implement drop_table drop_column
#
sub SQL::Translator::Producer::Oracle::drop_table {
  my ($table) = @_;
  return "DROP TABLE $table CASCADE CONSTRAINTS";
}

sub SQL::Translator::Producer::Oracle::drop_field {
    my ($old_field, $options) = @_;

    my $qf = $options->{quote_field_names} || '';
    my $qt = $options->{quote_table_names} || '';
    #my $table_name = quote_table_name($old_field->table->name, $qt);
    my $table_name = $old_field->table->name;

    my $out = sprintf('ALTER TABLE %s DROP COLUMN "%s"',
                      $table_name,
                      $qf . $old_field->name . $qf);

    return $out;
}

# guess name of the upgrade file
sub _upgrade_file {
    my ($self, $from, $to) = @_;
    my $driver = $__PACKAGE__::DB_DRIVER;
    $from //= $self->get_db_version;
    $to //= $self->schema_version;
    return sprintf '%s/Baseliner-Schema-Baseliner-%s-%s-%s.sql', 'sql', $from, $to, $driver;
}

# dump the upgrade file
sub dump_file {
    my ($self, $driver, $version, $preversion, %p) = @_;
    $version //= $self->schema_version();
    $preversion //= $self->get_db_version();
    my $sql_dir = './sql';
    warn "****** Dumping files into $sql_dir: Schema Version=$version, Database Version=$preversion\n";
    $self->create_ddl_dir( $driver, $version, $sql_dir, $preversion, 
        {   # sqlt options
            quote_table_names => 0,
            quote_field_names => 0,
            add_drop_table    => $p{drop},
            #ignore_missing_methods => 1,   # like if drop_table is not implemented
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

sub _ask_me {
    my $self = shift;
    print shift . "\n";
    print "*** Are you sure [y/N]: ";
    unless( (my $yn = <STDIN>) =~ /^y/i ) {
        return 0;
    }
    return 1;
}

1;
