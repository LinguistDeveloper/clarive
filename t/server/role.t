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
				action=>'User can change his password',
				bl=>'*',
				description=>'action.change_password'
			},
			{
				action=>'Administer baselines',
				bl=>'*',
				description=>'action.admin.baseline'
			},
			{
				action=>'Administer configuration variables',
				bl=>'*',
				description=>'action.admin.config_list'
			},
			{
				action=>'Admin Events',
				bl=>'*',
				description=>'action.admin.event'
			}]),
		mailbox=>'rol1@clarive.com',
		id=>-1,
		description=>'mi rol 1',
		name=>'rol_prueba1',
	};
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'Role created';
}


{
	$url = 'role/update';
    my $data = {
		role_actions=>_encode_json([
			{
				action=>'User can change his password',
				bl=>'*',
				description=>'action.change_password'
			}]),
		mailbox=>'',
		id=>-1,
		description=>'mi rol 2',
		name=>'rol_prueba2',
	};
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'Role created';
}

done_testing;