use v5.10;
use Path::Class;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use Baseliner::Utils;

our $VERSION = 0.01;

say "Baseliner Localization and Translation Tool v$VERSION";

my %args = _get_options(@ARGV);
if( exists $args{h} ) {  # help
    print << 'EOF';
Usage:
   bali loc [options] dir1 dir2 ...

Options:
  -h              this help
  -gen            generate .po file entries
  -grep <regex>   search lines that matches the regex
  -unparsed       report _loc() and _() lines that could not be parsed
  -lang           language (es,fr,gr...) - default: all
  -po             list .po files
  -msgid          show .po files msgid
  -i              interactive mode

EOF
    exit 0;
}

my @search = _array( $args{''} );
@search or @search= ('.');
my @gen;
my %str;

defined $args{grep} and $args{grep}=qr/$args{grep}/i;
my $lang = $args{lang} || 'any';

# .po file load
say "Loading .po files for language: $lang";
$lang eq 'any' and $lang = '\w{2}';
my @po;
my %ids;

sub parse_po {
    my @arr = ( $_[0] =~ m{msgid\s+"(.+?)"}gms );
    grep { ! /\n|\r/ } @arr;
}

exists $args{try} or do {
    for (qw/lib features/) {
        _dir($_)->recurse(
            callback => sub {
                my $f = shift;
                return if $f->is_dir || "$f" !~ /I18N.*$lang\.po/;
                push @po, $f;
                say $f if exists $args{po} || exists $args{msgid};
                my @msgids = parse_po scalar $f->slurp;
                @ids{ @msgids } = ();
                exists $args{msgid} and say "\t$_" for @msgids;
            }
        );
    }
  };

die "Error: no .po files found for lang $args{lang}\n" if exists $args{lang} && ! @po;

say "Scanning localizable strings in dirs: " . join',',@search;

sub interactive {
    my $p = shift;
    if( exists $args{i} ) {
        print "$p\n>"; 
        my $in = <STDIN>;
        $in =~ s{\n|\r}{}gs;
        return $in;
    }
    $p; 
}

for my $dir ( @search ) {
    dir($dir)->recurse(
        callback => sub {
            $f = shift;
            return if $f->is_dir || -B "$f";
            say "-----> File: $f" if $args{debug};
            open $ff, "<", $f;
            my $lin = 0;
            while (<$ff>) {
                $lin++;
                chomp;
                next if exists $args{grep} && $_ !~ $args{grep};
                next unless /_loc|_\(/;
                say "0>>$_" if $args{debug};
                next unless /_loc\((.+?)\)|_\((.+?)\)|_loc '(.+?)'|_loc "(.+?)"/;
                my $p = $1 || $2 || $3 || $4;
                say "1>>$p" if $args{debug};
                do { $args{unparsed} and say "*** ERROR --->$p<---"; next } unless $p =~ /'(.+?)'|"(.+?)"/;
                $p = $1 || $2;
                say "2>>$p" if $args{debug};
                #return if _loc($p);
                #say _loc($p);
                if( $p ) {
                    if( exists $args{try} && $p eq _loc($p) ) {
                        say $p unless exists $args{gen} || exists $args{unparsed} || exists $str{$p};
                        if( ! exists $str{$p} ) {
                            my $in = interactive $p;
                            push @gen, { str=>$p, in=>$in || $p, file=>$f, line=>$lin };
                            $str{$p} = ();
                        }
                    } else {
                        say $p unless exists $args{gen} || exists $args{unparsed};
                        if( ! exists $ids{$p} ) {
                            my $in = interactive $p;
                            push @gen, { str=>$p, in=>$in || $p, file=>$f, line=>$lin };
                        }
                    }
                } else {
                    do { s/^\s+//g, say "File: $f, Line: $lin: $_" } if exists $args{unparsed};
                }
            }
            close $ff;
        }
    );
}


exists $args{gen} and do {
    for my $r ( @gen ) {
        print << "EOF";
# $r->{file} ($r->{line})
msgid "$r->{str}"
msgstr "$r->{in}"

EOF
    }
};

say;
say scalar(@gen) . " untranslated unique entrie(s) found.";
