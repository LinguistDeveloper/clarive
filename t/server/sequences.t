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
my $url;
my %data;
my $json;
my $mod;

sub init_test_sequences {
	$url = '/repl/sequence_test';
	%data = ( option => 0 );
	$ag->post( URL($url), \%data );
}

sub restore_previous_state {
	$url = '/repl/sequence_test';
	%data = ( option => -1 );
	$ag->post( URL($url), \%data );
}

sub simulate_sequence_change {
	$url = '/repl/sequence_test';
	%data = ( option => 1 );
	$ag->post( URL($url), \%data );
}

sub get_seq {
	my %p = @_;
	my $seq_id = $p{seq_id};
	$url = '/repl/sequence_test';
	%data = ( option => 2, seq_id => $seq_id );
	$ag->post( URL($url), \%data );
	my $json = _decode_json( $ag->content );
	$json->{seq};
}


##### Update a sequence whit a new value ######
init_test_sequences();
$url = '/repl/sequences_update';
$mod = '{"id1":[2,1]}';
%data = ('modificados' => $mod);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
say "Value of seq in id1: " . ''.get_seq(seq_id => 'id1') . ' = 2';
ok $json->{success}, 'Sequence updated';

### Update 2 sequences
init_test_sequences();
$url = '/repl/sequences_update';
$mod = '{"id1":[2,1], "id2":[3,1]}';
%data = ('modificados' => $mod);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
say "Value of seq in id1: " . ''.get_seq(seq_id => 'id1') . ' = 2';
say "Value of seq in id2: " . ''.get_seq(seq_id => 'id2') . ' = 3';
ok $json->{success}, 'Sequences updated';

##### Sync test ####
## Simulate an other user changing a sequence
init_test_sequences();
simulate_sequence_change();
## Should return an error,
$url = '/repl/sequences_update';
$mod = '{"id1":[2,1]}';
%data = ('modified_records' => $mod);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
say "Value of seq in id1: " . ''.get_seq(seq_id => 'id1') . ' = 2';
ok !$json->{success}, 'Sequence has changed during editing process, and the system has detected it';

restore_previous_state();
done_testing;
