package Baseliner::MongoCollection;
use Moose;

has _collection => ( is=>'ro', isa=>'MongoDB::Collection', required=>1, handles=>qr/.*/ );
has _db => ( is=>'ro', isa=>'Object', weak_ref=>1 );

sub search {
    my ($self,%p) = @_;
    my $query = delete $p{query} or Util->_throw( 'Missing query');
    my $limit = delete $p{limit} // 1000;
    $self->_db->run_command([ text=>$self->name, search=>$query, limit=>$limit, %p ]) ; #->{results} ;
}

sub search_re {
    my ($self,%p) = @_;
    my $query = delete $p{query} or Util->_throw( 'Missing query');
    my $coll_name = delete $p{collection} || 'master';
    my $coll = $self->get_collection( $coll_name );
    $coll or Util->_throw( Util->_loc( 'collection %1 not found', $coll_name ) );
    $coll->find({ descripcion=>qr/$query/i  },{ limit=>10 })->all; 
    $coll->find->all
}

sub search_index {
    my ($self,%p) = @_;
    $self->drop_indexes;
    $self->ensure_index({'$**'=> "text"}, {name=> $self->name . "_index_text"});
}

sub merge_into {
    my ($self,$where,$partial,@args) = @_;
    my $doc = $self->find_one( $where ) // Util->_fail( Util->_loc('Document not found: %1', Util->_to_json($where) ) );
    return $doc unless $partial;
    $doc = { %$doc, %$partial };
    $self->update( $where, $doc, @args );
    return $doc;
}

sub get {
    my ($self,$mid)=@_;
    return ref $mid eq 'ARRAY' 
        ? $self->find_one({ mid=>{ '$in'=>$mid } })
        : $self->find_one({ mid=>"$mid" });
}

sub set {
    my ($self,$mid,$doc) = @_;
    $doc //= {};
    $self->update({ mid=>"$mid" },$doc,{ upsert=>1 });
}
    
sub find_or_create {
    my ($self,$doc) = @_;
    return if $self->find($doc)->count;
    $self->update($doc,$doc,{ upsert=>1 });
}
    
sub update_or_create {
    my ($self,$doc) = @_;
    $self->update($doc,$doc,{ upsert=>1 });
}

sub delete { 
    die "->delete does not exist. Use ->remove";
}
    
1;
