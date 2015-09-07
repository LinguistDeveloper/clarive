use v5.10;
use lib 'lib';
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use WWW::Mechanize;
use Baseliner::Utils;
use Clarive::Test;

BEGIN {
    plan skip_all => 'set TEST_LIVE to run this test' unless $ENV{TEST_LIVE};
}

my $ag = Clarive::Test->user_agent;

my $url;
my %data;
my $json;

sub test_login{
	my ($login,$pass) = @_;
	%data = ( login => $login, password => $pass );
	$ag->post( URL('/login'), \%data );
	$json = _decode_json( $ag->content );
	if ($json->{block_datetime}){
		say "Msg: " . $json->{msg} . " \nSuccess: " . $json->{success} . " - Block to: " .  $json->{block_datetime};
	}
	else { say "Msg: " . $json->{msg} . "\nSuccess: " . $json->{success} }
}

for (my $var = 0; $var < 20; $var++) {
	say "\nAttempt:" . $var . " Date: " . scalar localtime ();
	if ($var == 10) { 
		say "\n\n\n Wait 6s for unblock... and test with more incorrect user. \n\n\n";
		sleep(6); 
	}
	test_login('test_user','test_pass');
}
say "\n\n\n Wait 6s for unblock... and test with correct user. \n\n\n";
sleep(6);
for (my $var = 0; $var < 2; $var++) {
	say "Attempt:" . $var . " Date: " . scalar localtime ();
	test_login('local/root','admin');
}



done_testing;
