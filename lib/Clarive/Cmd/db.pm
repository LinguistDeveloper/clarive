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
    shift->show_help;
}

sub run_upgrade {
    my ($self,%opts) = @_;
    require Clarive::mdb;
    require Clarive::ci;
    require Clarive::model;
    
    require Baseliner::Schema::Migrator;
    Baseliner::Schema::Migrator->check( $opts{migrate} );
}

sub run_reindex {
    require Clarive::mdb;
    require Baseliner::Utils;
    
    Util->_log( "Rebuilding all indexes..." );
    mdb->index_all; 
    Util->_log("Done." );
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

=head1 cla db-reindex

Reindexes the database, droping old-indexes.

Uses all standard indexes, plus any
feature-defined index in C<etc/index/*.yml>

=cut

1;
