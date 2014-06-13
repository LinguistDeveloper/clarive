use v5.10;
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

my $ag = Clarive::Test->user_agent;

my $url;
my %data;
my $json;

#####################
#		ROLES	    #
#####################

{
    $url = 'role/update';
    my $data = {
        role_actions=>_encode_json([
            {
                action=>'action.change_password',
                bl=>'*'
            },
            {
                action=>'action.admin.baseline',
                bl=>'*'
            },
            {
                action=>'action.admin.config_list',
                bl=>'*'
            },
            {
                action=>'action.admin.event',
                bl=>'*'
            }]),
        mailbox=>'rol1@clarive.com',
        id=>-1,
        description=>'mi rol 1',
        name=>'rol_prueba1',
    };
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    $role_id1 = $json->{id};
    ok $json->{success}, 'Role created';
}


{
    $url = 'role/update';
    my $data = {
        role_actions=>_encode_json([
            {
                action=>'action.change_password',
                bl=>'*'
            }]),
        mailbox=>'',
        id=>-1,
        description=>'mi rol 2',
        name=>'rol_prueba2',
    };
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    $role_id2 = $json->{id};
    ok $json->{success}, 'Role created';
}

done_testing;