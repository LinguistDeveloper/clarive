use strict;
use warnings;
use Test::More tests => 8;
use utf8;

BEGIN {  $ENV{BALI_CMD} = 1; }

require Baseliner;
my $c = Baseliner->new();
Baseliner->app( $c );

BEGIN { use_ok 'Catalyst::Test' };
BEGIN { use_ok 'Baseliner::Utils' };
use Data::Dumper;

use Encode qw/is_utf8 encode decode encode_utf8 decode_utf8/;

print is_utf8( encode_utf8('á') );
my $str = 'Aquíéó';
sub to_hex { join',',unpack( 'H*', @_ ) }

{ 
    my $row = Baseliner->model('BaliBaseline')->create({ bl=>'DUMMY', name=>'Dummy', description=>$str });
    $row->update;
    ok( ref $row, 'baseline row created' );
}
{ 
    my $row = Baseliner->model('BaliBaseline')->search({ bl=>'DUMMY' })->first;
    ok( ref $row, 'row found' );
    my $desc = $row->get_column('description');
    warn " STR>>>>>>>><" .  to_hex($str) . ">" . Encode::is_utf8($str) . Baseliner::Utils::_dump $str;
    warn "DESC>>>>>>>><" .  to_hex($desc) . ">" . Encode::is_utf8($desc) . Baseliner::Utils::_dump $desc;
    ok( $desc eq $str, 'encode match' );
    $row->delete;
}
#{ 
    #my $row = Baseliner->model('BaliCalendar')->find({ id=>41 });
    #my $desc = $row->get_column('description');
    #warn "CALDESC>>>>" . to_hex($desc);
    #warn "ENCDESC>>>>" . Encode::is_utf8($desc);
#}
{ 
    #  $str = Baseliner::Utils::_loc_decoded('Production');  - this works
    $str = Baseliner::Utils::_loc('Production');
    my $row = Baseliner->model('BaliBaseline')->create({ bl=>'DUMMY', name=>'Dummy', description=>$str });
    $row->update;
    ok( ref $row, 'localized baseline row created' );
}
{ 
    my $row = Baseliner->model('BaliBaseline')->search({ bl=>'DUMMY' })->first;
    ok( ref $row, 'row found' );
    my $desc = $row->description;
    warn " STR>>>>>>>><" .  to_hex($str) . ">" . Encode::is_utf8($str) . Baseliner::Utils::_dump $str;
    warn "DESC>>>>>>>><" .  to_hex($desc) . ">" . Encode::is_utf8($desc) . Baseliner::Utils::_dump $desc;
    warn "DESC>>>>>>>><" .  to_hex($desc) . ">" . Baseliner::Utils::_dump Encode::encode_utf8 $desc;
    ok( $desc eq $str, 'encode match' );
    $row->delete;
}
