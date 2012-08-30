package BaselinerX::Model::Purga;
use BaselinerX::Comm::Balix;
use Baseliner::Plug;
use Baseliner::Utils;
use Catalyst::Log;
use v5.10;
use strict;
use warnings;
use Try::Tiny;
BEGIN { extends 'Catalyst::Model' }

sub purga_consola {
    my $self = shift;
    my $dias = shift() || 1;
    
    my $inf_db = BaselinerX::Ktecho::INF::DB->new;
    $inf_db->do( "
        DELETE FROM distlogdata 
        WHERE  dat_ts < ( SYSDATE -$ dias ) 
            AND dat_pase LIKE 'consola%'  
        " );

    return;
}

1;
