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

my $project_mid1;
my $project_mid2;
my $user_mid;
my $role_id1;
my $role_id2;

#########################
#       roles           #
#########################


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


#########################
#       projects        #
#########################

{

    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'test_project',
            description    => 'Proyecto de pruebas',
            bl             => '*',
            moniker        => '',
            active         => 'on',
            children       => '',
            seq            => '100'
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'project',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    $project_mid1 = $res->{mid};
    is( ${ $res->{success} }, 1,  "$res->{msg}: project created succesfully" );
     
}

{

    my $data = {
        as_json   => 1,
        form_data => {
            name           => 'test_project2',
            description    => 'Proyecto de pruebas2',
            bl             => '*',
            moniker        => '',
            active         => 'on',
            children       => '',
            seq => '101'
        },
        _merge_with_params => 1,
        action             => 'add',
        collection         => 'project',
    };
    my $res = $ag->json( URL('ci/update') => $data );
    $project_mid2 = $res->{mid};
    is( ${ $res->{success} }, 1,  "$res->{msg}: project created succesfully" );
     
}

#########################
#       users           #
#########################

{
    my $data = {
        action=>    'add',
        alias=>     'test_user',
        email=>     'test_user@test_user.com',
        id=>        '-1',
        language=>  'spanish',
        pass=>      'test_user',
        pass_cfrm=> 'test_user',
        phone=>     '33334444',
        realname=>  'test_user',
        type=>      'user',
        username=>  'test_user'
    };
    $url = 'user/update';
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'user created succesfully';

    $data = {
        action=>                    'update',
        alias=>                     'test_user',
        email=>                     'test_user@test_user.com',
        id=>                        $user_mid,
        language=>                  'spanish',
        pass=>                      'test_user',
        pass_cfrm=>                 'test_user',
        phone=>                     '33334444',
        projects_checked=>          [$project_mid1,$project_mid2],
        projects_parents_checked=>  '',  
        realname=>                  'test_user',
        roles_checked=>             [$role_id1,$role_id2],
        type=>                      'roles_projects',
        username=>                  'test_user'
    };
    $url = 'user/update';
    $ag->post( URL($url), $data );
    $json = _decode_json( $ag->content );
    ok $json->{success}, 'user updated succesfully';

}

done_testing;