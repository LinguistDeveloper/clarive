package Baseliner::Mongo;
use Mouse;
use MongoDB;
use Baseliner::MongoCursor;
use Baseliner::MongoCollection;
use Try::Tiny;
use Baseliner::Utils qw(_fail _loc _error _debug _throw _log _array _dump _ixhash);

# mongo connection
has mongo_config  => qw(is rw isa Any), default=>sub{+{}};
has mongo_db_name => qw(is rw isa Any default clarive);
has mongo         => ( is=>'ro', isa=>'MongoDB::MongoClient', lazy=>1, default=>sub{
       my $self = shift;
       require MongoDB;
       MongoDB::MongoClient->new($self->mongo_config);
    });
has db => ( is=>'ro', isa=>'MongoDB::Database', lazy=>1, default=>sub{
       my $self = shift;
       $self->mongo->get_database($self->mongo_db_name); 
    }, handles=>[qw(run_command)],
);

sub oid {
    my($self,$oid)=@_;
    return MongoDB::OID->new( $oid );
}

sub seq {
    my($self,$name,$seq)=@_;
    my $coll = $self->collection('master_seq');
    $coll->update({ _id=>$name }, { seq=>$seq },{ upsert=>1 }), return($seq) if defined $seq;
    my $doc = $coll->find_and_modify({ query=>{ _id=>$name }, update=>{ '$inc'=>{ seq=>1 } }, new=>1 });
    return $doc->{seq} if $doc->{seq};
    $coll->insert({ _id=>$name, seq=>1 });
    return 1;
}

sub collection {
    my ($self,$coll_name) = @_;
    my $coll = $self->db->get_collection( $coll_name );
    #require Baseliner::MongoCollection;
    Baseliner::MongoCollection->new( _collection=>$coll, _db=>$self );
}

sub asset {
    my ($self, $in, %opts) = @_;
    require Baseliner::Schema::Asset;
    return Baseliner::Schema::Asset->new( $in, grid=>$self->db->get_gridfs, %opts );
}

sub ts { Util->_now() }
sub in { { '$in' => [ map { ref $_ eq 'HASH' ? "$_->{mid}" : "$_" } Util->_array( @_ ) ] } }

sub find {
    my ($self,$mid)=@_;
    my $master = $self->find_master( $mid );
    return Util->_load( $master->{yaml} ); 
}

sub find_master {
    my ($self,$mid)=@_;
    _fail( _loc( 'Missing mid for row' ) ) unless length $mid;
    my $row = $self->collection('master')->find_one({ mid=>"$mid" });
    _fail( _loc( 'Master row not found for mid `%1`', $mid ) ) unless ref $row;
    return $row;
}

sub master { $_[0]->collection('master') }
sub master_rel { $_[0]->collection('master_rel') }

sub master_all {
    my ($self,$where)=@_;
    return $self->master->find($where)->all;
}

sub master_rs {
    my ($self,$where)=@_;
    my $rs = $self->master->find($where);
    bless $rs => 'Baseliner::MongoCursor'; 
}

sub master_query {
    my ($self,$query)=@_;
    my $coll = $self->collection('master');
    my ($results) = $coll->search(query=>$query, limit=>9999 )->{results}; 
    my @rows = grep { defined } map {
        $_->{obj};
    } _array($results);
    return @rows;
}

sub save {
    my ($self,$mid, $doc, $opts) = @_;
    $mid = $mid->{mid} if ref $mid;  #  mid may be a BaliMaster row also
    Util->_fail( 'Missing mid' ) unless length $mid;
    my $m = $self->collection('master');
    my $row = $m->find_one();
    return $m->merge_into({ mid=>"$mid" },{ yaml=>Util->_dump($doc) });
}

# deprecated:
sub index_sync { }

sub index_all {
    my ($self, $collection)=@_;
    my $idx = {
        topic_image => [
            [{ id_hash => 1 }]
        ],
        master => [
            [{ mid=>1 },{ unique=>1 }],
            [{ name=>1 }],
        ],
        master_rel => [
            [{ from_mid=>1, to_mid=>1, rel_type=>1, rel_field=>1 },{ unique=>1 }],
        ],
    };
    for my $cn ( keys %$idx ) {
        next if defined $collection && $cn ne $collection;
        my $coll = $self->collection($cn);
        for my $ix ( @{ $idx->{$cn} } ) {
            $coll->ensure_index( @$ix );
        }
    }
}


our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($coll) = reverse( split(/::/, $name));
    return $self->collection( $coll );
}

1;
