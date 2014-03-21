use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

my @mids;

my $ag = Clarive::Test->user_agent;

{
    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'test1',
            hostname       => 'test1.host',
            description    => 'automated test generated server',
            bl             => '*',
            connect_ssh    => '1',
            connect_balix  => '1',
            moniker        => '',
            connect_worker => '1',
            active         => 'on',
            children       => '',
            remote_tar     => 'tar',
            remote_tmp     => '',
            os             => 'unix',
            remote_perl    => 'perl',
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'generic_server',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    is( ${ $res->{success} }, 1,  'ci update ok' );
    warn YAML::XS::Dump( $res );
     
}

done_testing;
