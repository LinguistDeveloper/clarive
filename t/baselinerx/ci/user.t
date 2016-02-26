use strict;
use warnings;
use lib 't/lib';

use Test::More;
use TestEnv;
BEGIN { TestEnv->setup }

use TestSetup;

use_ok 'BaselinerX::CI::user';

subtest 'general_prefs_save: preferences by default' => sub {
    _setup(); 

	my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project);   
   
 	my $ci_user = BaselinerX::CI::user->new;
    $ci_user->general_prefs_save( {data =>$user });
    is ($ci_user->{country}, 'es');
    is ($ci_user->{currency}, 'EUR');
    is ($ci_user->{decimal}, 'Comma');
    is ($ci_user->{date_format_pref}, 'format_from_local');
    is ($ci_user->{time_format_pref}, 'format_from_local');
    is ($ci_user->{timezone_pref}, 'server_timezone');   
};

subtest 'general_prefs_save: user with currency, decimal and country changed' => sub {
    _setup(); 

	my $project = TestUtils->create_ci_project;
    my $id_role = TestSetup->create_role;
    my $user = TestSetup->create_user( name => 'developer', id_role => $id_role, project => $project, country => 'us', currency => 'USD', decimal => 'Period' );   
   
 	my $ci_user = BaselinerX::CI::user->new;
    $ci_user->general_prefs_save( {data =>$user });
    is ($ci_user->{country}, 'us');  
    is ($ci_user->{currency}, 'USD'); 
    is ($ci_user->{decimal}, 'Period');
};  

done_testing;

sub _setup {

    TestUtils->cleanup_cis;
    TestUtils->setup_registry('BaselinerX::CI', 'BaselinerX::Type::Event');  
    
}

