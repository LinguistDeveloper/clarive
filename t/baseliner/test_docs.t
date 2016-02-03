use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use File::Find;

our $ROOT;

subtest 'links in markdown files work' => sub {

    my $root = "docs";
    opendir my $dir, $root or die $!;
    my @languages = grep { !/^\./ && "$root/$_" } readdir $dir;
    closedir $dir;

    foreach my $language (@languages) {
        local $ROOT = "$root/$language";
        find( { wanted => \&check_links, no_chdir => 1 }, "$root/$language" );

    }

};
done_testing;

sub check_links {

    my $file = $File::Find::name;
    if ( -f $file && $file =~ /\.markdown$/ ) {
        open my $fh, '<', $file or die "Could not open '$file' $!\n";
        my $content = join '', <$fh>;
        close $fh;

        my @links = $content =~ m/\[.*?\]\((.*?)\)/msg;

        foreach my $link (@links) {

            my $link_to = $ROOT . "/$link.markdown";
            ok( -e $link_to, "Link '$link' is broken in '$file'" );

        }
    }
}
