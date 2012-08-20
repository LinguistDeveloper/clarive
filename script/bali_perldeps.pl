use v5.10;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$FindBin::Bin/../lib";
use Path::Class;
use Encode;

# from utils.pm:
sub _get_options {
    my ( $last_opt, %hash );
    for my $opt (@_) {
        if ( $opt =~ m/^-+(.*)/ ) {
            $last_opt = $1;
            $hash{$last_opt} = [] unless ref $hash{$last_opt};
        }
        else {
            $opt =      Encode::encode_utf8($opt) if Encode::is_utf8($opt);
            push @{ $hash{$last_opt} }, $opt;
        }
    }
    # convert single option => scalar
    for( keys %hash ) {
        if( @{ $hash{$_} } == 1 ) {
            $hash{$_} = $hash{$_}->[0];
        }
    }
    return %hash;
}
sub _array {
    my @array;
    for my $item ( @_ ) {
        if( ref $item eq 'ARRAY' ) { push @array, @{ $item };
        } elsif( ref $item eq 'HASH' ) { push @array, %{ $item };
        } else { push @array, $item if $item; }
    }
    return @array;
}

# main:

my %args = _get_options( @ARGV );
if( exists $args{'h'} ) {
    print <DATA>;
    exit 0;
}

my $home = dir( $ENV{BASELINER_HOME} // '.' );
my @dirs = defined $args{dir} ? _array( $args{dir} ) : qw/lib script bin features/ ;
my %mods;

# scan files

for my $dir (  @dirs ) {
    dir( $home, $dir )->recurse( callback=>sub {
        my $f = shift;
        return if $f->is_dir;
        return if $f !~ /\.(pm|pl)$/i;

        my $d =  $f->slurp;

        #say $f . '=' . length $d;

        if( $f->basename eq 'Baseliner.pm' ) {
            for my $cats ( $d =~ m{modules = qw/(.*?)/;}gsm ) {
                for my $mod ( grep { length } split /\s+/, $cats ) {
                    if( $mod =~ /^\+/ ) {
                        $mod = substr( $mod, 1);
                    } else {
                        $mod = "Catalyst::Plugin::$mod"
                    }
                    $mods{ $mod }{ $f->relative( $home ) } = ();
                }
            }
        }

        say $f if exists $args{vv};
        for my $mod ( $d =~ m/^\s*use\s+([\w:]+)\s*(?:.*?);/gsm ) {
            say $mod if exists $args{vv};
            $mods{ $mod }{ $f->relative( $home ) } = ();
        }

        for my $mod ( $d =~ m/^\s*require\s+([\w:]+)\s*(?:.*?);/gsm ) {
            say $mod if exists $args{vv};
            $mods{ $mod }{ $f->relative( $home ) } = ();
        }

        if( exists $args{model} ) {
            for my $mod ( $d =~ m/\-\>model\(['"]([\w:]+)['"]/gsm ) {
                say $mod if exists $args{vv};
                if( $mod=~ /Baseliner::(Bali.+)$/g ) {
                    $mod = "Baseliner::Schema::Baseliner::ResultSet::$1" ;
                } else {
                    $mod = "Baseliner::Model::$mod" ;
                }
                $mods{ $mod }{ $f->relative( $home ) } = ();
            }
        }

    });
}

# transform names if needed

if( exists $args{transform} ) {
    %mods = map {
        my $k = $_;
        my $v = $mods{$k};
        my $m=$k;
        $m eq 'Catalyst' and $m='Catalyst::Runtime';
        $m => $v;
    } keys %mods;
}

# compress and select

my @modlist =
    sort { uc($a) cmp uc($b) }
    map {
        my $m = $_;
        if( exists $args{transform} ) {
            $m
        }
        $m;
    }
    grep { length }
    grep { exists $args{bali} || !/^Baseliner/ }
    grep { !/^\d+/ }
    grep { !/^v5/ }
    grep { !/^\W/ }
    grep { exists $args{pragma} || !/^(bytes|vars|version|locale|lib|constant|feature|subs|base|strict|warnings)/ }
    keys %mods;

# print out list

my $query = qr/$args{q}/ if exists $args{q};
for my $mod ( @modlist ) {
    next if defined $query && $mod !~ $query;

    if( exists $args{check} ) {
        say "Requiring $mod..." if exists $args{v};
        eval qq{
            require $mod;
        };
        next unless $@;
    }
    my @from = sort keys %{ $mods{ $mod } };

    print $args{prefix} . $mod . $args{suffix} . ( $args{sep} // "\n" );
    exists $args{'at'}  and say "   $_" for @from ;
}

say if exists $args{sep};

exit 0;

__DATA__
Baseliner Perl Module Scanner

Usage:
  bali perldeps

Options:
  -h                      : help
  -v                      : verbose, with filenames and matches
  -vv                     : ultra verbose
  -q                      : query regex of module name to search
  -dir                    : dir to search
  -at                     : show where which module is defined
  -prefix                 : put a prefix to module name
  -suffix                 : put a suffix to module name
  -sep                    : module separator ; don't use with 'at'
  -check                  : check if module is installed; show only if not found.
  -transform              : transform non-installable module names to the CPAN installable dist
  -pragma                 : show pragma modules too, like 'lib' and 'feature'
  -bali                   : show Baseliner[x] modules too
  -model                  : include model requires

Examples:
  bali perldeps
  bali perldeps -at  # show modules where defined also
  bali perldeps -dir features/gitscm/lib lib # limit to directory
  bali perldeps -q YAML -at
  bali perldeps -prefix 'cpan -n ' -suffix ';'
  bali perldeps -bali -at -q Baseliner   # a little cross-usage impact analysis
