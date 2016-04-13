use strict;
use warnings;

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }
use TestUtils ':catalyst';
use TestGit;

use_ok 'Baseliner::GitSmartParser';

subtest 'parse_fh: returns no changes when input is empty' => sub {
    my $parser = _build_parser();

    is_deeply [ $parser->parse_fh ], [];

    open my $fh, '<', \'';
    is_deeply [ $parser->parse_fh($fh) ], [];
};

subtest 'parse_fh: skips everything that doesnt look like a change' => sub {
    my $parser = _build_parser();

    my $sha = _generate_sha();

    my $body = "0082";
    $body .= "want d30eb1c3bfb9ba62f3e1d64588484bd869a00430 multi_ack_detailed no-done side-band-64k thin-pack ofs-delta agent=git/2.7.0.rc3";
    $body .= "0031";
    $body .= "want 37b88df6173aa5fd41f9c3b560cbe161fdce4128";

    open my $fh, '<', \$body;

    my @changes = $parser->parse_fh($fh);

    is @changes, 0;
};

subtest 'parse_fh: parses single push' => sub {
    my $parser = _build_parser();

    my $sha = _generate_sha();

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my @changes = $parser->parse_fh($fh);

    is_deeply \@changes,
      [
        {
            ref => 'refs/heads/master',
            old => '0000000000000000000000000000000000000000',
            new => $sha
        }
      ];
};

subtest 'parse_fh: parses several pushes' => sub {
    my $parser = _build_parser();

    my $master_sha = _generate_sha();
    my $new_sha    = _generate_sha();

    my $body =
        "0094"
      . "0000000000000000000000000000000000000000 $master_sha refs/heads/master\x00 report-status side-band-64k agent=git/2.6.4"
      . "0064"
      . "0000000000000000000000000000000000000000 $new_sha refs/heads/new" . "0000";
    open my $fh, '<', \$body;

    my @changes = $parser->parse_fh($fh);

    is_deeply \@changes,
      [
        {
            ref => 'refs/heads/master',
            old => '0000000000000000000000000000000000000000',
            new => $master_sha
        },
        {
            ref => 'refs/heads/new',
            old => '0000000000000000000000000000000000000000',
            new => $new_sha
        }
      ];
};

subtest 'parse_fh: parses tag push' => sub {
    my $parser = _build_parser();

    my $sha = _generate_sha();

    my $body = "0094"
      . "0000000000000000000000000000000000000000 $sha refs/tags/TAG\x00 report-status side-band-64k agent=git/2.6.4"
      . "0000";
    open my $fh, '<', \$body;

    my @changes = $parser->parse_fh($fh);

    is_deeply \@changes,
      [
        {
            ref => 'refs/tags/TAG',
            old => '0000000000000000000000000000000000000000',
            new => $sha
        }
      ];
};

done_testing;

sub _generate_sha {
    my @alpha = ( '0' .. '9', 'a' .. 'f' );
    my $sha = '';

    $sha .= $alpha[ int( rand($#alpha) ) ] for 1 .. 40;

    return $sha;
}

sub _build_parser {
    return Baseliner::GitSmartParser->new;
}
