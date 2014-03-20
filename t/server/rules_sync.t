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
my $id_rule;

$id_rule = get_seq(seq_id => 'rule')+1;

sub get_seq {
	my %p = @_;
	my $seq_id = $p{seq_id};
	$url = '/repl/sequence_test';
	%data = ( option => 2, seq_id => $seq_id );
	$ag->post( URL($url), \%data );
	my $json = _decode_json( $ag->content );
	$json->{seq};
}

sub simulate_statements_change {
	$url = '/rule/rule_test';
	%data = ( option => 0, id_rule => $id_rule );
	$ag->post( URL($url), \%data );
}

sub reset_previous_state {
	$url = '/rule/rule_test';
	%data = ( option => -1, id_rule => $id_rule );
	$ag->post( URL($url), \%data );
	
}

## Rule creation 
$url = '/rule/save';
%data = ('chain_default' => '-', 'rule_event' => 'event.user.create', 'rule_name' => 'prueba', 'rule_type' => 'event', 'rule_when' => 'post-offline');
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'Rule added!';



## Change the rule during edition process_
simulate_statements_change();
my $stmts = '[{"attributes":{"icon":"/static/images/icons/cog.png","palette":false,"text":"DO","holds_children":true,"nested":0,"key":"statement.perl.do","leaf":false,"loader":{"baseParams":{},"dataUrl":"/rule/palette","events":{"loadexception":true,"load":true,"beforeload":true},"transId":false},"id":"xnode-3846","name":"DO","expanded":false},"children":[]}]';
$url = '/rule/stmts_save';
%data = ('id_rule' => $id_rule, 'ignore_dsl_errors' => '0', 'old_ts' => '2014-03-14 13:00:00', 'stmts' => $stmts);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
if ($json->{msg} eq  'An other user changed rule statements during edition process!'){
	say "Result: " . $json->{msg};
	ok $json->{success}, 'Modification of rule detected successfully';
}else{
	say "Result: " . $json->{msg};
	ok $json->{success}, 'Modification of rule not detected';
}

reset_previous_state();
done_testing;