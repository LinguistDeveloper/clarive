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
#insert a new calendar not a copy

my $url;
my %data;
my $json;
my $id_cal;

#####################
#	MENSAJES		#
#####################

$url = '/message/detail';

my $id;
my $username;

#1 crear un mensaje
$id = "110";
$username = "rodrigo";

%data = ('id' => $id, 'username' => $username);
$ag->post( URL($url), \%data );
$json = _decode_json( $ag->content );
say "Result: " . $json->{msg};
ok $json->{success}, 'message readed';



# my %p;
# $p{body} = 'body body body';
# $p{template_engine} ||= 'text';
# $p{subject} = 'un sujeto';
# $p{sender} ||= 'clarive@vasslabs.com';

# my $msg_id = Baseliner->model('Messaging')->create(%p);

# my $qid = mdb->seq('message_queue');
# mdb->message->update(
# 	{_id => $msg_id},
# 	{
#     	'$push' => {
#         	queue => {
# 				id => $qid,
#                 username=>'usuario1111', 
#                 carrier=>'email', 
#                 carrier_param=>'to', 
#                 active => '1',
#                 attempts => '0',
#                 swreaded => '0',
#                 sent => mdb->ts
# 			}
#         }
# 	}
# );
    
# my $qid2 = mdb->seq('message_queue');
# mdb->message->update(
# 	{_id => $msg_id},
# 	{
#     	'$push' => {
#         	queue => {
# 				id => $qid2,
#                 username=>'usuario2222', 
#                 carrier=>'email', 
#                 carrier_param=>'to', 
#                 active => '1',
#                 attempts => '0',
#                 swreaded => '0',
#                 sent => mdb->ts
# 			}
#         }
# 	}
# );


# Baseliner->model('Messaging')->failed( id=>$qid, result=>'error', max_attempts=>'10' );  

# Baseliner->model('Messaging')->delivered( id=>$qid2, result=>'success' );

# return $qid, $qid2;

done_testing;