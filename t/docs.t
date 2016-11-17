use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Deep;
use File::Find;

use FindBin '$Bin';

use HTTP::Tiny;

our $ROOT;

subtest 'links in markdown files work' => sub {
    my $root = "$ENV{CLARIVE_HOME}/docs";
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

        $content =~ m/<!--.*?-->/msg;
        my @links = $content =~ m/\[.*?\]\((.*?)\)/msg;

        ok $content !~ m/\r/gsm, "DOS line-ending in $file";

        foreach my $link (@links) {
            if( $link =~ /^http/ ) {

                SKIP: {
                    my $ua = HTTP::Tiny->new(
                        timeout=>5, verify_SSL=>0,
                        agent=>'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
                    );

                    my $response = $ua->head( $link );

                    my $rc = $response->{status};

                    if( $rc eq 599 ) {
                        skip "599 error, probably no connectivity or a SSL configuration problem: $response->{content}", 1;
                    }
                    else {
                        is $rc, 200, $link;

                        if( $rc ne 200 ) {
                            warn "ERROR $link: $rc:\n". $response->{content};
                        }
                    }
                }
            }
            else {
                my $link_to = $ROOT . "/$link.markdown";
                ok( -e $link_to, "Link '$link' is broken in '$file' ($link_to)" );
            }
        }
    }
}
