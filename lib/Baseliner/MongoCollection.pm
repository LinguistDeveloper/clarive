package Baseliner::MongoCollection;
use Moose;
use Try::Tiny;

has _collection => ( is=>'ro', isa=>'MongoDB::Collection', required=>1, handles=>qr/.*/ );
has _db => ( is=>'ro', isa=>'Object', weak_ref=>1 );

=head2 search

    my $res = mdb->master_doc->search( query=>$query, limit=>1000,
        #project=>{name=>1,collection=>1}, 
        filter=>{ collection=>mdb->nin('topic','job') }
    );

=cut
sub search {
    my ($self,%p) = @_;
    my $query = delete $p{query} or Util->_throw( 'search: missing query');
    my $limit = delete $p{limit} // 1000;
    $self->_db->run_command([ text=>$self->name, search=>$query, limit=>$limit, %p ]) ; #->{results} ;
}

sub search_re {
    my ($self,%p) = @_;
    my $query = delete $p{query} or Util->_throw( 'Missing query');
    my @cols = Util->_array( $p{fields} );
    @cols or @cols = do {
        my $doc = $self->find_one;
        $doc
        ? ( $p{deep} ? keys(%{ scalar Util->hash_flatten($doc) }) : keys(%$doc) )   # deep is not working, fields with _id fail in hash_flatten
        : Util->_fail("search_re failed: don't know which fields to look");
    };
    my @ors =  map { +{ $_ => $query } } @cols;
    my $rs = $self->find({ '$or'=>\@ors },{ limit=>$p{limit}//1000 });
    return wantarray ? $rs->all : $rs; 
}

sub search_index {
    my ($self,%p) = @_;
    $self->drop_indexes;
    $self->ensure_index({'$**'=> "text"}, {name=> $self->name . "_index_text"});
}

sub clone {
    my ($self,$collname)=@_;
    $collname //= $self->name . '_' . Util->_nowstamp;
    my $coll = mdb->collection($collname);
    Util->_fail( Util->_loc('Collection %1 already has rows in it, cannot clone')) if $coll->count; 
    for my $doc ( $self->find->all ) {
        try {
            $coll->insert($doc) 
        } catch {
            my $err = shift;
            Util->_error(sprintf 'Could not clone document with id %s (mid=%s). Skipped', $doc->{_id}, $doc->{mid} );
        };
    }
    return $collname;
}

sub compact {
    my ($self, %p) = @_;
    $self->_db->run_command([ compact=>$self->name, %p ]);
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
    Util->_throw( "mdb...->delete does not exist. Use ->remove");
}

sub all_keys {
    my ($self)=@_;
    my $tmp = $self->name . '_keys_' . Util->_nowstamp();
    mdb->run_command([   
      "mapreduce"=> $self->name, 
      "map"=> q{
           function() {
            var ff=function(obj,pf){
                for (var key in obj) { 
                    if( key == '_id' || key==undefined ) continue;
                    if( typeof obj[key] != 'function' ) emit(pf+key, null);
                    if( typeof obj[key] == 'object' ) {
                        ff(obj[key],key+'.'); 
                    }
                }
            }
            ff(this,'');
           }
      },
      "reduce"=> q{function(key, stuff) { return null; }}, 
      "out"=> $tmp,
    ]);
    my @ky = grep !/^_id/, map { $_->{_id} } mdb->$tmp->find->all;
    mdb->$tmp->drop;
    return @ky;
}


sub follow {
    my ($self, %p)=@_;
    my $iter = $p{iter} // -1;
    my $where = $p{where} // {};
    my $code = $p{code} // Util->_throw('Missing code parameter');
    my $rs = $self->query($where)->tailable(1); # ->hint({ '$natural' => 1 }); # hint makes perl cpu shoot up
    bless $rs => 'Baseliner::MongoCursor';
    $rs->await_data( 1 );
    ITER: while( $iter != 0 ) { 
        while ( my $r = $rs->next ) {
            if( my $err = mdb->db->last_error->{err} ) {
                Util->_fail( Util->_loc('Failed during mongo tail follow: %1', $err) );
            }
            last ITER unless $code->($r,$rs,%p);
        }
        $iter-- if $iter>0;
    }
}

# wrap around my own cursor
#  around query => sub {
#      my ($orig,$self) = (shift,shift);
#      my $rs = $self->$orig( @_ );
#      bless $rs => 'Baseliner::MongoCursor';
#      return $rs;
#  };
    
1;
