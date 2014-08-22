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
($env) = @$env if ref $env eq 'ARRAY';
$ENV{BALI_ENV} = $env;
$ENV{BASELINER_ENV} = $env;
$ENV{BASELINER_CONFIG_LOCAL_SUFFIX} = $env;
$ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = $env;
say "env: $env";

{
    local $SIG{__WARN__} = sub{};
    require Baseliner;
}

my $dir = _dir( $args{dir} ) ||  _dir( Baseliner->path_to('db/sample') );
my $format = 'yaml';
my $commit_num = $args{commit} // 100;  # insert/replace at 100 rows
my $inserting = exists $args{insert};
say "dir: $dir";
say "format: $format";
say "commit: each $commit_num rows";
my $dbh = Baseliner->model('Baseliner')->storage->dbh;
$dbh->{AutoCommit} = $args{autocommit} // 0;
say "autocommit: $dbh->{AutoCommit}";
my $conn = _dump( Baseliner->model('Baseliner')->storage->{_connect_info} );
$conn =~ s/password:(.*?)\n/password: **************\n/g;
say "connect info: ". $conn;
my $db = _dbis();
my @enabled_constraints = $db->query(q{select * from user_constraints where status ='ENABLED' and table_name like 'BALI_%'})->hashes;
say sprintf "Disabling %d constraints...", scalar @enabled_constraints;
for my $cons ( @enabled_constraints ) {
    $db->query( sprintf q{alter table %s disable constraint %s}, $cons->{table_name}, $cons->{constraint_name} );
}
say "OK Disabling constraints.";

my $replace = _build_replace( %args );
if( $action eq 'dump' ) {
    say pre . "Starting Dump...";
    db_dump( %args );
}
elsif( $action eq 'load' ) {
    say pre . "Starting Load...";
    
    my $m = Baseliner->model('Baseliner');
    if( $args{transactional} ) {
        $m->txn_do( sub {
             db_load( %args );
        });
    } else {
        db_load( %args );
    }
}
else {
    _fail "Option not found";
    exit 1;
}

finish();
say pre . "Done.";
exit 0;

########################################
sub finish {
    say sprintf "Enabling %d constraints...", scalar @enabled_constraints;
    for my $cons ( @enabled_constraints ) {
        $db->query( sprintf q{alter table %s enable constraint %s}, $cons->{table_name}, $cons->{constraint_name} );
    }
    say "OK enabling constraints.";
}

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
    for my $schema ( @schemas ) {
        ( my $schema_name = $schema ) =~ s{\.\w+}{};
        my $src = $sch->source( $schema_name );
        if( $args{truncate} ) {
            say "Truncating table for schema $schema_name...";
            $src->resultset->search->delete;
        }
        say pre . "===> Loading $schema_name ($schema)";
        open my $f, '<:raw', _file( $dir, $schema ) or die $!;
        my @yml;
        my $k=0;
        while ( my $s = <$f> ) {
            next if $s =~ /^---$/;
            utf8::encode($s);
            if ( @yml && substr( $s, 0, 1 ) eq '-' ) {
                my $row = YAML::XS::Load( join '', @yml );
                $row = $row->[0];
                $k++;
                insert_row( $schema_name,$sch,$src, $row );
                @yml=();
            }
            push @yml, $s;
        }
        say "Rows: $k";
        $k ?  insert_row($schema_name,$sch,$src) : _warn("No rows detected for $schema_name");
    }
}

sub insert_row {
    my ($schema_name,$sch,$src,$row)=@_;
    state @rows;
    if( $row ) {
        # if its insert mode, delete ids and mids
        if( $inserting ) {
            delete $row->{id};
            delete $row->{mid};
        }
        # replace keys
        if( $replace ) {
            $row = { %$row, %$replace };
        }
        push @rows, $row;
    }
    if( !$row || @rows >= $commit_num ) {
        _debug( \@rows ) if exists $args{v};
        
        my @cols = grep { $inserting ? $_ ne 'id' && $_ ne 'mid' : 1 } $src->columns;
        my $table = $src->name;
        say "Calculating row sizes...";
        my %sizes;
        for my $row ( @rows ) {
            for my $col ( @cols ) {
                $sizes{$col} //= 0; 
                $sizes{$col} += length( $row->{$col} );
            }
        }
        say _dump \%sizes;
        my $sum = 0;
        _log sprintf "Committing %d rows (%d KB)...", scalar(@rows), [reverse map { $sum+=$_; $sum } values %sizes ]->[0];
        
        # metadata to find blobs
        my $sql = 'SELECT column_name, data_type FROM user_tab_columns WHERE table_name=?';
        my %meta = map { lc $_->{column_name} => lc $_->{data_type} } _array $db->query($sql, uc $table)->hashes;
        my @blobs = grep { $meta{ lc $_ } eq 'blob' } @cols;
        my @clobs = grep { $meta{ lc $_ } eq 'clob' } @cols;
        @cols = grep { $meta{ lc $_ } !~ /lob/ } @cols; # filter blobs out
        my @cols_no_lob = @cols;
        #my ($lob,@lobs) = sort { $sizes{$b} <=> $sizes{$a} } (@clobs,@blobs); # only one lob per insert, the one with more data
        my ($lob,@lobs) = ( @clobs );
        push @cols, $lob if $lob;  # lobs last
        say "BLOBS=@blobs, CLOBS=@clobs, INSERTED=$lob, UPDATED=@lobs";

        _log \@cols if $args{v};
        my $sql = sprintf 'INSERT INTO %s (%s) values (%s)', $table, join(',',@cols), join(',',(map {'?'} @cols));
        my @tuple_status;
        say $sql;
        my @data;
        for my $col ( @cols ) {
            push @data, [ map { $_->{$col} } grep { exists $_->{$col} } @rows ];
        }
        #$sch->populate( $schema_name, \@rows );
        $dbh->do(qq{ALTER TABLE $table DISABLE ALL TRIGGERS});
        my $stmt = $dbh->prepare($sql);
        my $ret = eval { $stmt->execute_array({ ArrayTupleStatus => \@tuple_status }, @data ) };
        my $res = $@;
        my $failing = sub {
            my( $res ) = @_;
            $dbh->do(qq{ALTER TABLE $table ENABLE ALL TRIGGERS});
            _error $res;
            my @tt = grep { $_ ne '-1' } @tuple_status;
            _error(\@tt) if @tt;
            finish(); # reenable constraints, etc - constraints are global due to foreign keys, etc
            _fail $stmt->errstr unless $ret;
            $dbh->rollback;
        };
        $failing->( $res ) if $res;
        say "Inserted.";
        unless( $args{nolobs} ) {
            for my $lob ( @lobs ) {
                say "Updating LOB $lob...";
                @data = ();
                my $sql = sprintf 'UPDATE %s SET %s=? WHERE %s', $table, $lob, join(' AND ',(map {"$_ = ?"} @cols_no_lob ));
                my $stmt2 = $dbh->prepare($sql);
                say $sql;
                for my $col ( $lob, @cols_no_lob ) {
                    push @data, [ map { $_->{$col} } @rows ];
                }
                eval { $stmt2->execute_array({ ArrayTupleStatus => \@tuple_status }, @data ) };
                my $res = $@;
                $failing->( $res ) if $res;
                say "OK Updated LOB $lob";
            }
        }
        $dbh->do(qq{ALTER TABLE $table ENABLE ALL TRIGGERS});
        $dbh->commit unless $args{autocommit};
        @rows = ();
    }
}


__DATA__
Usage:
  bali db [load|dump]

Options:
  -v                      : verbose - print data dumps
  -transactional          : run the whole thing in a single transaction
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
