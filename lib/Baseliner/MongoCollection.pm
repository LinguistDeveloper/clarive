package Baseliner::MongoCollection;
use Moose;
use Try::Tiny;
use Baseliner::Utils;
use MongoDB::Collection;
use experimental 'autoderef';

has _collection => ( is=>'ro', isa=>'MongoDB::Collection', required=>1, handles=>qr/^(?!meta|clone)/ );
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
    my $mongo_version = mdb->mongo_version;
    if($mongo_version lt '3'){
        return $self->_db->run_command([ text=>$self->name, search=>$query, limit=>$limit, %p ]) ;
    }else{
        #TODO: Include options like limit
        my $rs = $self->find({'$text' => {'$search' => $query } })->limit($limit);
        if( my $project = delete $p{project} ) {
            $rs->fields($project);
        }
        my @results = map { +{ obj=>$_ } } $rs->all;
        return { ok=>1, results=>\@results };
    }
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

#around save => sub {
#    my ($orig,$self,@args) = @_;
#    try { 
#        $self->$orig( @args );
#    } catch {
#        my $err = shift;
#        my $msg = Util->_loc( 'Error in Mongo save: %1. %2', $err );
#        _throw( $msg );
#    };
#};

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

=head2 find_values ( key => { var=>'val' ... })

Returns a list of values for the found docs and a given key.

    my @mids = mdb->topic->find_values( mid => { mid=>$topic_mid });

=cut
sub find_values {
    my $self = shift;
    my $key = shift;
    return map { $$_{ $key } } $self->find( @_ )->fields({ $key=>1 })->all;
}

=head2 find_one_value

Returns the value for a given key or undef if not found.

    say "ID=" . mdb->topic->find_one_value( id_category => { mid=>$topic_mid });

=cut
sub find_one_value {
    my $self = shift;
    my $key = shift;
    my $doc = $self->find_one( @_==0 ? ({},{ $key=>1 }) : @_==1 ? (@_, { $key=>1 }) : @_ );
    if( ref $doc ) {
        return $$doc{$key};
    } else {
        return undef;
    }
}

=head2 find_hashed

Returns a hash indexed by key pointing to an array of hashes

    my %users = mdb->master_doc->find_hashed( username=>{ username=>qr/^A/ }, { realname=>1 });
    
    say $users{ $id }->[0]->{name};

=cut

sub find_hashed {
    my ($self,$key,$where,$fields)=@_;
    my $rs = $self->find( $where );
    if( $fields ) {
        $fields->{$key} //= 1;
        $rs->fields($fields);
    }
    my %ret;
    while( my $r = $rs->next ) {
        if ( ref $$r{$key} eq 'ARRAY'){
            for my $item ( @{$$r{$key}} ){
                push @{ $ret{ $item // '' } }, $r    
            }
        }else{
            push @{ $ret{ $$r{$key} // '' } }, $r   
        }
    }
    return wantarray ? %ret : \%ret;
};


=head2 find_hash_one

Returns a hash indexed by key pointing to a SINGLE VALUE (no arrayref)

    my %users = mdb->master_doc->find_hashed( username=>{ username=>qr/^A/ }, { realname=>1 });
    
    say $users{ $id }{name};

=cut

sub find_hash_one {
    my ($self,$key,$where,$fields)=@_;
    my $rs = $self->find( $where );
    if( $fields ) {
        $fields->{$key} //= 1 if scalar grep { $_ } values $fields;
        $rs->fields($fields);
    }
    my %ret;
    while( my $r = $rs->next ) {
        if( length $ret{ $$r{$key} } ) {
            $ret{ $$r{$key} } = [ $ret{ $$r{$key} } ];
            push @{ $ret{ $$r{$key} } }, $r
        } else {
            $ret{ $$r{$key} } = $r; 
        }
    }
    return wantarray ? %ret : \%ret;
};

# wrap around my own cursor
#  around query => sub {
#      my ($orig,$self) = (shift,shift);
#      my $rs = $self->$orig( @_ );
#      bless $rs => 'Baseliner::MongoCursor';
#      return $rs;
#  };


sub find_mid {
    my ($self,@mids)=@_;
    my @docs = $self->find({ mid=>mdb->in(@mids) })->all;
    return @docs==1 ? $docs[0] : @docs;
}
    
no Moose;
__PACKAGE__->meta->make_immutable;

1;
