package Clarive::Cmd::db;
use Mouse;
use Path::Class;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'database diff and deploy tool';
our $t0;

with 'Clarive::Role::Baseliner';

BEGIN {
    $ENV{ DBIC_TRACE }                   = 0;
    $ENV{ CATALYST_CONFIG_LOCAL_SUFFIX } = 't';
    chdir $ENV{BASELINER_HOME} if $ENV{BASELINER_HOME};
    #XXX _load_features('lib', use_lib=>1 );
}

sub now {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $year += 1900;
    $mon  += 1;
    sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour},
      ${min}, ${sec};
}

sub pre {
    my $ret = "==============| " . now() . " " . sprintf( "[%.04f]", tv_interval( $t0 ) ). ' ';
    $t0 = [gettimeofday]; 
    $ret;
}

sub run {
    goto &run_deploy;
}

sub run_deploy {
    my ($self,%opts) = @_;

    $t0 = [gettimeofday];

    say "Clarive RDBMS Schema Deploy";

    require Carp::Always if exists $opts{carp};
    $ENV{BASELINER_DEBUG}=1 if exists $opts{debug};

    # deploy schema
    say pre . "Deploying schema " . join', ', $self->bali_utils->_array($opts{schema});
    say pre . "Starting DB deploy...";
    $Baseliner::Schema::Baseliner::DB_DRIVER = 'SQLite';
    my $env = $self->env;
    $env = @$env if ref $env eq 'ARRAY';

    require Baseliner::Schema::Baseliner;

    my $config = $self->setup_baseliner;
    my $db_config = $config->{ 'Model::Baseliner' }{ 'connect_info' };
    if( $db_config->[2]  && $db_config->[2] =~ /^__.*\(.*\)__$/ ) {
        say sprintf "Invalid password [%s] - function detected.\n", $db_config->[2];
        $config->{ 'Model::Baseliner' }{ 'connect_info' }->[2] = $self->bali_utils->_read_password( sprintf "PASSWORD for %s: ", $db_config->[1] );
    }

    if( $opts{schema} ) {
        $opts{schema} = [ $self->bali_utils->_array( $opts{schema} ) ];
    }
    my $dropping= exists $opts{drop} ? ' (with DROP)' : '';
    if( exists $opts{drop} && ! @{ $opts{schema} || [] } && ! exists $opts{installversion} ) {
        say "\n*** Warning: Drop specified and no --schema parameter found.";
        say "*** All tables in the schema will be dropped. Data loss will ensue.";
        print "*** Are you sure [y/N]: ";
        unless( (my $yn = <STDIN>) =~ /^y/i ) {
            say "Aborted.";
            exit 1;
        }
    }
    say pre . "Deploying started$dropping.";

    my $deploy_now = exists $opts{deploy};
    say pre . "No deployments will run. Only printing information." unless $deploy_now;

    Baseliner::Schema::Baseliner->deploy_schema(
        config          => $config,
        run             => exists $opts{run},
        version         => exists $opts{'version'},
        install_version => exists $opts{'installversion'},
        upgrade         => exists $opts{ upgrade },
        diff            => $opts{ diff },
        downgrade       => exists $opts{ downgrade },
        show_config     => !exists $opts{show_config},
        deploy_now      => $deploy_now,
        from            => $opts{from}, # from version num
        to              => $opts{to},  # to version num
        drop            => exists $opts{drop},
        'grep'          => $opts{grep},
        schema          => $opts{schema}
    ) and die pre . "Errors while deploying DB. Aborted\n";

    say pre . "No DB statements were executed. Use --deploy to actually deploy/migrate the schema. " unless $deploy_now;
    say pre . "Done.";

    exit 0;
}

sub run_upgrade {
    my ($self,%opts) = @_;
    require Clarive::mdb;
    require Clarive::ci;
    require Clarive::cache;
    
    require Baseliner::Schema::Migrator;
    Baseliner::Schema::Migrator->check( $opts{migrate} );
}

=pod

Clarive DB Schema Management. Deploys, fixes and migrates the DB

=head1 cla db-upgrade

Upgrades the schema to the latest version.

Options:

   --migrate migration_name

Examples:

   cla db-upgrade --migrate from61        # migrates from a Clarive 6.1 schema
   cla db-upgrade --migrate from615       # migrates from a Clarive 6.1.5 schema

=head1 cla db-deploy [options]

Deploys the optional RDBMS (DBI-based) tables.

Options:

  -h                      : this help
  -deploy                 : actually execute statements in the db
                              cla db-deploy --deploy
  -run                    : Run DB statements interactively or from STDIN
  -quote                  : quote table names
  -drop                   : add drop statements
  -grep                   : grep a string or re in the generated sql
  -env                    : sets CLARIVE_ENV (local, test, prod, t, etc...)
  -schema                 : schemas to deploy (does not work for migrations)
                                cla db-deploy --schema BaliUser --schema BaliProject 

Versioning Options:

  --diff                  : diffs this schema against the database
  --installversion        : installs versioning tables if needed
  --upgrade               : upgrades database version
  --from <version>        : from version (replaces current db version)
  --to <version>          : to version (replaces current schema version)
  --grep <re>             : filter diff statements with a reg. expression

Examples:

    cla db-deploy --env t   
    cla db-deploy --env t --diff
    cla db-deploy --env t --diff --deploy
    cla db-deploy --env t --installversion   
    cla db-deploy --env t --upgrade                   # print migration scripts only, no changes made
    cla db-deploy --env t --upgrade --deploy          # print migration scripts only, no changes made
    cla db-deploy --env t --upgrade --show --to 2     # same, but with schema version 2
    cla db-deploy --env t --upgrade --show --from 1   # same, but with db version 2

=cut

1;
