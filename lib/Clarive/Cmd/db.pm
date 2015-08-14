package Clarive::Cmd::db;
use Mouse;
use Path::Class;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
extends 'Clarive::Cmd';
use v5.10;

our $CAPTION = 'database diff and deploy tool';
our $t0;

with 'Clarive::Role::Baseliner';

has all => qw(is rw isa Bool default 0);  # dump all or just essential?
has drop => qw(is rw isa Bool default 0);  # drop index on rebuid
has collection => qw(is rw isa Str default),'';  # drop index on rebuid

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

sub run_reindex {
    my ($self, %opts)=@_;
    require Clarive::mdb;
    require Baseliner::Utils;
    my $collection = $self->collection || $self->pos->[0];
    $collection 
        ? Util->_log( "Rebuilding indexes for collection `$collection`" ) 
        : Util->_log( "Rebuilding all indexes..." );
    mdb->index_all( $collection, drop=>$self->drop ); 
    Util->_log("Done." );
}

sub run_dump {
    my ($self)=@_;
    require Baseliner::Utils;
    my $mongo = $self->app->opts->{mongo};
    ( my $host = $mongo->{client}{host} // '' ) =~ s{mongodb://}{}g;
    my $dbname = $mongo->{dbname};
    Util->_log( "Dumping data from mongo, db=$dbname, host=$host..." );
    my $cmd = join ' ', 'mongodump', '-h', $host, '-d', $dbname;
    if( ! $self->all ) {
        for my $coll ( qw(
            _migrations activity calendar calendar_window category config
            daemon dashboard dispatcher master master_cal master_doc master_rel master_seen
            master_seq notification repl role rule rule_version scheduler shared_html topic topic_image
        )) {
            say "$cmd -c $coll"; 
            system "$cmd -c $coll";
        }
    } else {
        say $cmd;
        system $cmd;
    }
    Util->_log("Done." );
}

=pod

Clarive DB Schema Management

=head1 cla db-reindex

Reindexes the database, droping old-indexes.

Uses all standard indexes, plus any
feature-defined index in C<etc/index/*.yml>

=cut

1;
