package Baseliner::Queue;
use Moose;
use Function::Parameters;

use Baseliner::Utils qw(_stash_dump _stash_load);
use Clarive::mdb;
use Time::HiRes ();

method push( :$msg, :$data ) {
    my $ts = mdb->ts;
    my $data_ser = _stash_dump( $data );
    mdb->queue->insert({ msg=>$msg, data=>$data_ser, ts=>mdb->ts, t=>Time::HiRes::time() }); 
}

method pop( :$msg ) {
    my $ts = mdb->ts;
    # TODO race condition, 2 pops can pop the same - set a unique key and reserve first with '$inc' or '$set'
    my $doc = mdb->queue->find({ msg=>$msg })->sort({ t=>-1 })->next; # LIFO
    if( $doc ) {
        mdb->queue->remove({ _id=>$doc->{_id} });
        return _stash_load($doc->{data});
    } else {
        return undef;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
