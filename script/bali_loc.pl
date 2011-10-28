use v5.10;
use Path::Class;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use Baseliner;
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
  -lang <en|..>   language
  -unparsed       report _loc() and _() lines that could not be parsed

EOF
    exit 0;
}

my @search = _array( $args{''} );
@search or @search= ('.');
my @gen;
my %str;

defined $args{grep} and $args{grep}=qr/$args{grep}/i;

Baseliner::Utils::loc_lang( $args{lang} ) if exists $args{lang};
say "Scanning localizable strings in dirs: " . join',',@search;
say;

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
                next unless /_loc\((.+?)\)|_\((.+?)\)|_loc '(.+?)'|_loc "(.+?)"/;
                my $p = $1 || $2 || $3 || $4;
                say "1>>$p" if $args{debug};
                do { $args{unparsed} and say "*** ERROR --->$p<---"; next } unless $p =~ /'(.+?)'|"(.+?)"/;
                $p = $1 || $2;
                say "2>>$p" if $args{debug};
                #return if _loc($p);
                #say _loc($p);
                if( $p ) {
                    if( $p eq _loc($p) ) {
                    	say "[$p] == [" . _loc($p) . "]" if $args{debug};
                        say $p unless exists $args{gen} || exists $args{unparsed};
                        if( ! exists $str{$p} ) {
                            push @gen, { str=>$p, file=>$f, line=>$lin };
                            $str{$p} = ();
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
msgstr "$r->{str}"

EOF
    }
};

say;
say scalar(@gen) . " untranslated unique entrie(s) found.";
