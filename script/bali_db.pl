use v5.10;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use File::Basename;
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

my $action = shift @ARGV;
if( ! $action ) {  # help
    die join '',<DATA>;
    exit 0;
}
require Baseliner;
my %args = _get_options( @ARGV );
my $dir = $args{dir} ||  _dir( Baseliner->path_to('etc/dump') );
my $format = 'yaml';

say "Baseliner DB Load/Dump Utility v.$VERSION";
say "dir: $dir";
say "format: $format";

sub db_dump {
    my %args = @_;
    my @schemas = _array $args{schema};
    my %schemas;
    @schemas{ @schemas } = ();
    my $sch = Baseliner->model('Baseliner')->schema;
    my %db;

    $dir->mkpath;

    for( $sch->sources ) {
       my $src = $sch->source( $_ );
       next if ref $src->from ;
       next if keys( %schemas ) && ! exists $schemas{ $_ };
       say pre . "===> Dumping $_.$format";
       #_log $_ . " => " . ;
       my @rows = $src->resultset->search->hashref->all;
       #$db{ $_ } = \@rows;
       #open my $f, '>:encoding(utf-8)', _file( $dir, "$_.yaml" );
       open my $f, '>:raw', _file( $dir, "$_.$format" );
       #binmode $f, ':utf8';
       my $s = YAML::XS::Dump( \@rows );
       utf8::decode( $s );
       _log $s if exists $args{v};
       print $f $s;
    };
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
  -truncate               : delete table before load
  -schema                 : schemas to deploy
                                bali db load --schema BaliRepo --schema BaliRepoKeys 

Examples:
    bin/bali db dump
    bin/bali db load
    bin/bali db load --schema BaliTopic
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel
    bin/bali db load --schema BaliTopic BaliMaster BaliMasterRel --truncate

EOF
