use strict;
use warnings;
use Getopt::Long;
use FindBin '$Bin';
use Path::Class;

my @dirs = qw(
                lib
                t
                root
                root/static
                root/static
                root/comp
                lib/BaselinerX
                lib/BaselinerX/Controller
                lib/BaselinerX/Model
                lib/Baseliner/I18N
);

GetOptions(
    'dir|d'        => \( my $fdir ),
);

scalar( @ARGV ) or die "usage: feature.pl [-d feature_dir ] feature_name\n";

$fdir ||= $Bin.'/../features';

die "Could not find the features directory '$fdir'\n" unless -d $fdir;
chdir $fdir or die $!;

for my $feature ( @ARGV ) {
    my ($name) = split /_|-/, $feature;
    my $dir = Path::Class::dir( $feature );
    warn "Feature dir $dir already exists. Overwriting.\n" if -d $dir;
    mkdir $feature;
    mkdir "$feature/$_" for( @dirs );
    open my $out, ">", "$feature/$name.conf";
    print $out <<'';
<$name>
    #put your feature specific configuration variables here
</$name>

    close $out;
    print "Feature $feature created successfully in ". $dir->absolute ."\n";
    $dir->recurse( callback => sub { my $d = shift; print " $d\n"; } );
}

