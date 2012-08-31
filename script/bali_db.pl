use v5.10;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use File::Basename;
use Try::Tiny;
use Baseliner::Utils;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
my $t0 = [gettimeofday];

sub now {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    $year += 1900; $mon  += 1;
    sprintf "%04d/%02d/%02d %02d:%02d:%02d", ${year}, ${mon}, ${mday}, ${hour}, ${min}, ${sec};
}

sub pre {
    my $ret = "==============| " . now() . " " . sprintf( "[%.04f]", tv_interval( $t0 ) ). ' ';
    $t0 = [gettimeofday]; $ret;
}

our $VERSION = '1.0';

say "Baseliner DB Load/Dump Utility v.$VERSION";

# get main action
my $action = shift @ARGV;
if( ! $action ) {  # help
    die join '',<DATA>;
    exit 0;
}

# read args
my %args = _get_options( @ARGV );

# setup DB env
my $env = $args{env} || $ENV{BALI_ENV} || 't';
$env = @$env if ref $env eq 'ARRAY';
$ENV{BALI_ENV} = $env;

require Baseliner;

my $dir = _dir( $args{dir} ) ||  _dir( Baseliner->path_to('db/sample') );
my $format = 'yaml';
say "dir: $dir";
say "format: $format";

sub db_dump {
    my %args = @_;
    my $replace = _build_replace( %args );
    my @schemas = _array $args{schema};
    my %schemas;
    @schemas{ @schemas } = ();
    my $sch = Baseliner->model('Baseliner')->schema;
    my %db;

    $dir->mkpath;

    for my $schema_name ( $sch->sources ) {
       my $src = $sch->source( $schema_name );
       next if ref $src->from ;
       next if keys( %schemas ) && ! exists $schemas{ $schema_name };
       say pre . "===> Dumping $schema_name.$format";
       #_log $schema_name . " => " . ;
       try {
           my @rows = $src->resultset->search->hashref->all;
           # replace keys
           if( $replace ) {
                @rows = map {
                    { %$_, %$replace }
                } @rows;
           }
           open my $f, '>:raw', _file( $dir, "$schema_name.$format" );
           my $s = YAML::XS::Dump( \@rows );
           utf8::decode( $s );
           _log $s if exists $args{v};
           print $f $s;
        } catch {
            say shift();
            say "Schema $schema_name ignored...";
        };
    };
}

sub _build_replace {
    my %args = @_;
    my $ret;
    if( exists $args{'replace-json'} ) {
        $ret = _decode_json( $args{'replace-json'} );
    }
    elsif( exists $args{'replace-yaml'} ) {
        $ret = YAML::XS::Load( $args{'replace-yaml'} );
    }
    $ret;
}

sub db_load {
    my %args = @_;
    my @schemas = _array $args{schema};
    if( @schemas ) {
        @schemas = map { "$_.$format" } @schemas;
    } else {
        @schemas = map { $_->basename } $dir->children
    }
    my $sch = Baseliner->model('Baseliner')->schema;
    my $replace = _build_replace( %args );
    for my $schema ( @schemas ) {
        ( my $schema_name = $schema ) =~ s{\.\w+}{};
        my $src = $sch->source( $schema_name );
        if( $args{truncate} ) {
            say "Truncating table for schema $schema_name...";
            $src->resultset->search->delete;
        }
        say pre . "===> Loading $schema_name ($schema)";
        open my $f, '<:raw', _file( $dir, $schema ) or die $!;
        my $s = join '',<$f>;
        utf8::encode( $s );
        my $rows = YAML::XS::Load( $s );
        # if its insert mode, delete ids and mids
        if( exists $args{insert} ) {
            $rows = [
                map {
                    delete $_->{id};
                    delete $_->{mid};
                    $_
                } _array $rows
            ];
        }
        # replace keys
        if( $replace ) {
            $rows = [
                map {
                    { %$_, %$replace }
                } _array $rows
            ];
        }
        _log _dump $rows if exists $args{v};
        $sch->populate( $schema_name, $rows );
    }
}

if( $action eq 'dump' ) {
    say pre . "Starting Dump...";
    db_dump( %args );
}
elsif( $action eq 'load' ) {
    say pre . "Starting Load...";
    db_load( %args );
}
else {
    _fail "Option not found";
    exit 1;
}

say pre . "Done.";

exit 0;

__DATA__
Usage:
  bali db [load|dump]

Options:
  -v                      : verbose - print data dumps
  -insert                 : insert mode, deletes ids and tries to insert rows
  -truncate               : delete table before load
  -replace-json           : replace column values in rows using a json hash in a string
  -replace-yaml           : replace column values in rows using a yaml hash in a string
  -env                    : sets BALI_ENV (local, test, prod, t, etc...)
  -dir                    : output directory (otherwise: $BASELINER_HOME/etc/dump)
  -schema                 : schemas to deploy
                                bali db load --schema BaliRepo --schema BaliRepoKeys 

Examples:
    bin/bali db dump
    bin/bali db load
    bin/bali db load --schema BaliTopic
    bin/bali db load --schema BaliTopic --dir tmp/dump
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel --truncate
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel --insert
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel --insert --replace-json '{ "title": "dummy title" }'
    bin/bali db load --schema BaliTopic --insert --replace-yaml 'id_category: 2'
    bin/bali db load --schema BaliTopic --insert --replace-yaml '{ id_category: 2, title: dummy title }'

EOF
