package Baseliner::Schema::Baseliner;
use strict;
use warnings;

our $VERSION = 3;

use base 'DBIx::Class::Schema';


__PACKAGE__->load_namespaces( default_resultset_class => '+Baseliner::Schema::Baseliner::Base::ResultSet' );

#__PACKAGE__->load_components(qw/Schema::Versioned/);
#__PACKAGE__->upgrade_directory('sql/');

use Baseliner::Utils;

sub connection {
     my $self = shift;
     my $rv = $self->next::method( @_ );
     my $dbd = $self->db_driver;
     #my $dbd = "Oracle";
     # MSSQL quote chars
     if( $dbd eq 'ODBC' ) {
         $rv->storage->sql_maker->quote_char([ qw/[ ]/ ]);
         $rv->storage->sql_maker->name_sep('.');
     }

     my $lev = defined $ENV{DBIC_TRACE} ? substr( $ENV{DBIC_TRACE}, 0, 1 ): 0;
     
     if( defined $lev && $lev > 1 ) {
         require Baseliner::Schema::Profiler;
         $rv->storage->debugobj( Baseliner::Schema::Profiler->new );
         $rv->storage->debug(1);
     }

     return $rv;
}

sub _stop {
    die "\n*********** ERROR: " . (_loc @_ ) . "\n\n";
}

sub _warn2 { print STDERR "*********** WARN: " . (_loc @_ ) . "\n"; }

my $filter_to_generic =  sub {
    no warnings;
    my $s = shift;
    print STDERR "\n";
    # replace default (Oracle) for generic internal representation
    #  -- this is not deployable yet
    #  -- also checks for invalid/problematic schema column names
    for my $table_name ( $s->get_tables ) { 
        my $table = $s->get_table( $table_name );
        for my $col_name ( $table->get_fields ) {
            my $col = $table->get_field($col_name);  # perldoc SQL::Translator::Schema::Field
            my $type = $col->data_type;
            my $def = $col->default_value;
            # fix types
            if( defined $type && $type =~ /numeric/i ) {
                $col->data_type( 'number' );
                $type = 'number';
            }
            if( ref($def) eq 'SCALAR' && $$def =~ m/SYSDATE|datetime/i ) {
                $col->default_value( \"current_timestamp" );
            }
            # quote - unquote
            if( defined $type && $type =~ /^(num|int)/i && ! ref $def && defined $def && length $def ) {
                # unquotify numbers
                $def =~ s{^['"]}{};
                $def =~ s{['"]$}{};
                $def =~ s{ }{}g;
                $col->default_value( \"$def" );
            }

            if( $col_name =~ /^(desc)$/ ) {
                _stop "Invalid column name [%1] in table [%2]", $col_name, $table_name;
            }
            if( $col_name =~ /^(key)$/ ) {
                _warn2 "Potential keyword as column name: column [%1] in table [%2]", $col_name, $table_name;
            }
        }
    }
};

my $filter_to_driver =  sub {
    my $s = shift;
    my $driver = __PACKAGE__->db_driver;
    # replace default (Oracle) for equivalents
    for my $table_name ( $s->get_tables ) { 
        my $table = $s->get_table( $table_name );
        for my $col_name ( $table->get_fields ) {
            my $col = $table->get_field($col_name);  # perldoc SQL::Translator::Schema::Field
            my $type = $col->data_type;
            my $def = $col->default_value;
            if( $driver eq 'Oracle' ) {
                $col->default_value( \"SYSDATE" )
                    if ref($def) eq 'SCALAR' && $$def eq 'current_timestamp'; 
                $col->size( 0 ) if $type =~ /.LOB/i;
                if( $type =~ /number/i && $col->size > 0 ) { # get rid of NUMBER(38)
                    $col->size( 0 );
                }
            }
            elsif( $driver eq 'SQLite' ) {
                $col->default_value( \"(datetime('now'))" )
                    if ref($def) eq 'SCALAR' && $$def eq 'current_timestamp'; 
                $col->data_type( 'integer' )
                    if $col_name =~ m/.id/i && $type =~ m/^num/i;
            }
            elsif( $driver eq 'mysql' ) {
            }
            elsif( $driver eq 'ODBC' ) {
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

    # get config and connect
    my $config = delete $p{ config };
    warn _dump $config unless $p{show_config};
    $config ||= eval "Baseliner->config";
    die "Could not connect to db: no config loaded" unless $config;
    my $conn = $config->{ 'Model::Baseliner' }->{ 'connect_info' };
    die "Missing or invalid config option 'Model::Baseliner: connect_info = [dsn,user,password]'" unless ref $conn eq 'ARRAY';
    my ( $dsn, $user, $pass ) = @$conn;
    $self->db_driver( $dsn );

    sub show_file { open my $ff, '<', shift() or die $!; print join '',<$ff>; close $ff; }

    # setup driver, $schema is the actual $self
    my $driver = $__PACKAGE__::DB_DRIVER;
    my $schema = __PACKAGE__->connect( $dsn, $user, $pass, { RaiseError=>1 } )
        or die "Failed to connect to db";

    # process main command
    if( $p{run} ) {
        # get sql statements from stdin
        print qq{\n\nInteractive Mode. Type ^D (or ^Z on Windows) to execute statements, ^C to cancel.\n\n};
        print "> ";
        my @st;
        while( my $lin = <STDIN> ) {
            push @st, $lin;
        }
        if( @st > 0 ) {
            my $dbh = $schema->storage->dbh;
            $dbh->do( join '', @st );
        }
    } elsif( $p{diff} && $p{diff} ne '2schema' ) {
        my $sqltargs = {
            add_drop_table    => $p{drop},
            sources           => $p{schema},
            quote_identifiers     => 0,
            #quote_table_names => 0,
            #quote_field_names => 0,
            trace             => 1,
            filters           => [ $filter_to_generic, $filter_to_driver, \&_filter_diff ],
            format_table_name   => sub {my $t= shift; return lc($t)},
            %p
        };
        require SQL::Translator;
        # DBIC Schema (current Baseliner)
        print 'Parsing current Baseliner Schema...';
        my $sqlt = SQL::Translator->new({
            parser => 'SQL::Translator::Parser::DBIx::Class',
            %$sqltargs 
        }); 
        $sqlt->producer( $driver );
        my $schema_dbic = $sqlt->translate({ data => $schema })
            or $self->throw_exception ($sqlt->error);
        
        # DB schema
        my $dbh = $schema->storage->dbh;
        my $sqlt2 = SQL::Translator->new({   parser => "SQL::Translator::Parser::DBI::$driver",    #'SQL::Translator::Parser::DBI::Oracle',
                parser_args => { dsn => $dsn, db_user => $user, db_password => $pass },
                %$sqltargs
        });
        $sqlt2->producer( $driver );
        my $schema_dbic2 = $sqlt2->translate({ data=>$dbh })
            or $self->throw_exception ($sqlt2->error);

        # united we diff
        require SQL::Translator::Diff;
        my $obj = SQL::Translator::Diff->new(
            {   source_schema => $sqlt2->schema,
                target_schema => $sqlt->schema,
                output_db     => $driver,
                #quote_table_names => 0,
                #quote_field_names => 0,
                #ignore_constraint_names => 1,
                #ignore_index_names => 1,
                case_insensitive => 1,
                #caseopt => 1,
            }
        );

        # calculate diff
        $obj  = $obj->compute_differences; # here: $obj->table_diff_hash has keys as tablenames
        my @diff = $obj->produce_diff_sql;
        @diff = map{ s{"}{}gs; $_ } @diff;

        # grep ? 
        if( defined $p{'grep'} ) {
            my $re = $p{'grep'};
            for my $r ( _array $re ) {
                @diff = grep /$r/si, @diff; 
            }
        }
        # execute ALL?
        print "\n\n" . join( "", @diff ) . "\n";
        if( _ask_me("Execute ALL diff?") ) {
            if( _ask_me("ALL at ONCE?") ) {
                $dbh->do( join '', @diff );
            } else {
                # step by step
                for( map { s/\;(\s*)?\n?$//; $_ } @diff ) {
                    next if /^--/ or /^BEGIN/ or /^COMMIT/;
                    if( _ask_me( $_ ) ) { 
                        $dbh->do( $_ );
                    }
                }
            }
        }

        my $exec_specific = sub {
            my ($type, $re) = @_; 
            my @filtered = grep { length } grep /$re/, @diff;
            if( @filtered > 0 ) {
                print "\n", '=' x 70 , "| ${type}s: \n";
                print join '', @filtered, "\n";
                if( _ask_me("\nExecute only ${type}s") ) {
                    # do, but without the semicolon
                    $dbh->do( $_ ) for map { s/\;(\s*)?\n?$//; $_ } @filtered;
                }
            }
        };
        #        $dbh->do( $_ ) for map { s/\;(\s*)?\n?$//; $_ } @modifies;
        
        $exec_specific->( @$_ ) for (
             ['ADD', qr/ ADD \(/i],
             ['CREATE', qr/^CREATE/i],
             ['DROP TABLE', qr/^DROP TABLE/],
             ['ALTER DROP', qr/ALTER.*DROP/],
             ['ALTER ADD', qr/ALTER.*ADD/],
             ['MODIFY', qr/ MODIFY/i],
        );

        return 0;
    } elsif( $p{diff} && $p{diff} eq '2schema' ) {
        # diff with 2 schema comparison, done via DBIC-Loader
        my $sqltargs = {
            add_drop_table    => $p{drop},
            sources           => $p{schema},
            quote_table_names => 0,
            quote_field_names => 0,
            trace             => 1,
            filters           => [ $filter_to_generic ],
            %p
        };
        require SQL::Translator;

        # DBIC Schema (current Baseliner)
        print "Parsing current Baseliner Schema...\n";
        my $sqlt = SQL::Translator->new({
            parser => 'SQL::Translator::Parser::DBIx::Class',
            %$sqltargs 
        }); 
        $sqlt->producer( $driver );
        my $schema_dbic = $sqlt->translate({ data => $schema })
            or $self->throw_exception ($sqlt->error);

        # DB Schema 
        # We load the schema with the best db parser there is: DBIC::Schema::Loader
        #   then we diff DBIC schema x DBIC schema, $driver-producer oriented
        {
            package BaselinerPhonySchema;
            use base qw/DBIx::Class::Schema::Loader/;
        }
        BaselinerPhonySchema->dump_to_dir('tmp/ph');
        print "Connecting and generating in-memory DB schema. Be patient...\n";
            #use lib 'tmp/ph';
            #require BaselinerPhonySchema;
        my $schema2 = BaselinerPhonySchema->connect( $dsn, $user, $pass );
        print "Now parsing current DB Schema...\n";
        my $sqlt2 = SQL::Translator->new({
            parser => 'SQL::Translator::Parser::DBIx::Class',
            %$sqltargs 
        }); 
        $sqlt2->producer( $driver );
        my $schema_dbic2 = $sqlt2->translate({ data => $schema2 })
            or $self->throw_exception ($sqlt2->error);

        use YAML::XS;
        open my $f, '>f2';
        while( my ($k,$v) = each %{ $sqlt2->schema->{tables} } ) {
            delete $v->{schema};
        }
        print $f YAML::XS::Dump( $sqlt2->schema->{tables} );
        # united we diff
        require SQL::Translator::Diff;
        my $diff = SQL::Translator::Diff::schema_diff(
            $sqlt2->schema,  $driver,
            $sqlt->schema,  $driver,
            {
                quote_table_names => 0,
                quote_field_names => 0,
                ignore_constraint_names => 1,
                ignore_index_names => 1,
                caseopt => 1
            }
        );
        #print $diff;

        # deploy?
        if( $p{deploy_now} || $self->_ask_me( 'Execute migration?' ) ) {
            my $dbh = $schema->storage->dbh;
            $dbh->do( $diff );
            $p{deploy_now} = 1;
        }
    } elsif( $p{install_version} ) {
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
        show_file( $file );
        my $question = qq{File '$file' already exists. Do you want to overwrite it with an automatically generated version?};
        if( ! -e $file || $self->_ask_me( $question ) ) {
            $schema->dump_file( $driver, $p{to}, $p{from}, %p  );
        }
        # show file
        show_file( $file );
        if (!$schema->get_db_version()) {
            # schema is unversioned
            $schema->install();
        } elsif( ! $p{deploy_now} ) {
            print "Showing migration info only. No upgrade was done.\n";
        } else {
            # upgrade (execute sql files) is done here:
            print sprintf "Upgrading schema to version=%s\n", $schema->schema_version;
            if( exists $p{from} || exists $p{to} ) {
                my $from = $p{from} // $schema->get_db_version();
                my $to   = $p{to} // $schema->schema_version;
                $schema->upgrade_single_step( $from, $to );
                print "Done upgrading from version '$from' to version '$to'\n";
            } else {
                $schema->upgrade();
                print "Done upgrading.\n";
            }
        }
        return 0;
    } elsif( ! $p{deploy_now} ) {
        my $sqlt_opts = {
            add_drop_table    => $p{drop},
            quote_table_names => exists $p{quote},
            sources           => $p{schema},
            filters           => [ $filter_to_generic, $filter_to_driver ],
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
            filters           => [ $filter_to_generic , $filter_to_driver],
            %p   # additional parameters
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
            filters           => [ $filter_to_generic, $filter_to_driver ],
            #parser => 'Baseliner::Schema::Parser::Oracle',  NOT WORKING, probably ddl_dir is not calling parser directly
        }
    );
}

sub _filter_diff {
    my $s = shift;
    my $dbd = $__PACKAGE__::DB_DRIVER;
    for my $table_name ( $s->get_tables ) { 
        my $table = $s->get_table( $table_name );
        for my $col_name ( $table->get_fields ) {
            my $col = $table->get_field($col_name); 

            #if( $table_name eq 'bali_sem' && $col_name eq 'description' ) {
            #    use v5.10;
            #    say "SIZ=" . $col->data_type;
            #    say "SIZ=" . $col->size;
            #    say "DEF=" . $col->default_value;
            #    say "PRI=" . $col->is_primary_key;
            #    say "AUT=" . $col->is_auto_increment;
            #    say q{------------};
            #}
            # fix data types
            my $dt = $col->data_type;
            if( $dt =~ /[cb]lob/i ) {
                #$col->size(0);
                delete $col->{size};
            }
            elsif( $dt =~ /date/i ) {
                delete $col->{size};
            }
            elsif( $dt =~ /integer/i ) {
                $col->data_type( 'number' );
                delete $col->{size};
            }
            elsif( $dt =~ /numeric/i ) {
                $col->data_type( 'number' );
                delete $col->{size};
            }
            elsif( $dt =~ /int/i ) {
                $col->data_type( 'number' );
                delete $col->{size};
            }
            elsif( $dt =~ /number/i ) {
                delete $col->{size};
            }
            elsif( $dt =~ /VARCHAR/i ) {
                $col->data_type( 'varchar2' );
            }

            if( $col_name =~ /id/i ) {
                $col->is_auto_increment( 1 );
                $col->is_primary_key( 1 );
            }

            my $def = $col->default_value;
            if( ref $def eq 'SCALAR' ) {
                $col->default_value( uc $$def );
            }
            elsif( defined $def && $def =~ /sysdate$/i ) {
                $col->default_value( 'SYSDATE' );
            }
            elsif( defined $def && $def =~ /^([0-9]+)\s+$/ ) {
                $col->default_value( $1 );
            }
            #if( $col->default_value =~ /^'(.*)'$/ ) {
            #    $col->default_value( "'$1'" );
            #}
            #delete $col->{default_value};
            #if( $table_name eq 'bali_sem' && $col_name eq 'description' ) {
            #    use v5.10;
            #    say "SIZ=" . $col->data_type;
            #    say "SIZ=" . $col->size;
            #    say "DEF=" . $col->default_value;
            #    say "PRI=" . $col->is_primary_key;
            #    say "AUT=" . $col->is_auto_increment;
            #}
        }
    }
}

sub _ask_me {
    my $self = shift if ref $_[0];

    require Term::ReadKey;
    # flush keystrokes
    while( defined( my $key = Term::ReadKey::ReadKey(-1) ) ) {}
        
    print shift() . "\n";
    print "*** Are you sure [y/N/q]: ";
    unless( (my $yn = <STDIN>) =~ /^y/i ) {
        exit 1 if $yn =~ /q/i; # quit
        return 0;
    }
    return 1;
}

1;
