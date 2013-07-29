package Baseliner::Schema::KV;
use Moose;
use Try::Tiny;

has rs => ( is=>'ro', lazy=>1, default=>sub{ DB->BaliMasterKV } );

sub save {
    my ($self,$mid, $doc, $opts) = @_;
    Util->_fail( 'Missing mid' ) unless length $mid;
    my $m = Baseliner->model('Baseliner');
    my $sql = 'insert into bali_master_kv (mid,mtype,mpos,mkey,mvalue_str,mvalue_num) values (?,?,?,?,?,?)';
    my @flat = $self->_break_varchar( 2000, $self->_flatten( $doc ) );
    #return @flat;
    my @tuple_status;
    try {
        $m->txn_do( sub {
            DB->BaliMasterKV->search({ mid=>$mid })->delete unless $opts->{no_delete};
            my $stmt = $m->storage->dbh->prepare($sql);
            my (@mid, @mtype, @mpos, @mkey, @mvalue_str, @mvalue_num );
            for my $row ( @flat ) {
                push @mid, $mid;
                push @mtype, $row->{mtype} // 'str';
                push @mpos, $row->{mpos} // 0;
                push @mkey, $row->{mkey} // Util->_fail('Missing key for row: ' . Util->_dump( $row ) );
                push @mvalue_str, $row->{mvalue_str} // '';
                push @mvalue_num, $row->{mvalue_num};
            }
            $stmt->execute_array({ ArrayTupleStatus => \@tuple_status }, \@mid, \@mtype, \@mpos, \@mkey, \@mvalue_str, \@mvalue_num );
        });
    } catch {
        my $err = shift;
        Util->_throw( Util->_loc('Error inserting into master kv: %1. Doc: %2', $err, Util->_dump($doc) ) );
    };
    return @flat; #@tuple_status;
}

sub _break_varchar {
    my ($self, $siz, @flat )=@_;
    return map {
        my $r = $_;
        if( defined $r->{mvalue_str} && length($r->{mvalue_str}) > $siz ) {
            my @chunks;
            # TODO dont split words, but also store searcheable version
            my $i=1;
            for my $chk ( unpack( "(A$siz)*", $r->{mvalue_str} ) ) {
                push @chunks, { %$r, mpos=>$i++, mvalue_str=>$chk }; 
            }
            @chunks;
        } else {
            $_ 
        }
    } @flat;
}

sub _is_special {
    my ($self,$v)=@_;
    my $ref = ref $v;
    return ($v, undef) unless $ref;
    if( $ref eq 'HASH' ) {
        my %vals;
        my %conds;
        for( keys %$v ) {
            /-like|-not_like|\>|\<|\!|\=/
                ? $conds{ $_ } = $v->{$_}
                : $vals{ $_ } = $v->{$_};
        }
        return ( %vals ? \%vals : undef, %conds ? \%conds : undef );
    }
    return ($v,undef);
}

sub _flatten {
    my ($self, $where, $prefix) = @_;
    my @flat;
    my $ref = ref $where;
    if( $ref eq '' ) {
        return { mkey=>$prefix, mtype=>'str', mvalue_str=>$where };
    }
    elsif( $ref eq 'HASH' ) {
        while( my ($k,$v) = each %$where ) {
            $prefix and $k = "$prefix.$k";
            if( ref $v ) {
                my ($vals, $conds) = $self->_is_special( $v );
                push @flat, $self->_flatten($vals, $k) if defined $vals;
                push @flat, { mkey=>$k, mtype=>'hash', mvalue_str=>$conds } if defined $conds;
            } else {
                push( @flat, { mkey=>$k, mtype=>'str', mvalue_str=>$v } );
            }
        }
        return @flat;
    }
    elsif( $ref eq 'ARRAY' ) {
        if( $prefix =~ /-and|-or/ ) {
            return { mkey=>$prefix, mvalue_str => $self->_flatten($where) };
        } else {
            my $kk = {};
            #push @flat, map{ +{ mkey=>$prefix, mpos=>$i++, mtype=>'array', mvalue_str=>$_ } } @$where;
            push @flat, map { $_->{mpos} = $kk->{ $_->{mkey} }++; $_ } map{ $self->_flatten($_, $prefix) } @$where;
        }
    }
    elsif( $ref eq 'SCALAR' ) {
        return { mkey=>$prefix, mvalue_str => $$where };
    }
    else {
        die 'invalid type: ' . $ref;
    }
    return @flat;
}

sub _flatten_as_hash {
    my $self = shift;
    my @flat = $self->_flatten( @_ );
    # turn array into hash
    my $flat_hash = {};
    $flat_hash->{ $_->{key} } = $_->{value} for @flat;
    return $flat_hash;
}

sub _quote_keys {
    my ($self, $hash) = @_;
    return {} unless ref $hash eq 'HASH' && keys %$hash;
    my %ret;
    $ret{ '"' . $_ . '"' } = $hash->{$_} for keys %$hash;
    \%ret;
}

sub _abstract {
    my ($self,@where) = @_;
    my ($where,@binds) = $self->abstract->where({ -and => \@where });
    return $where, @binds;
}

sub load_cis {
    my ($self)=@_;
    my $i=0;
    my $cats = DB->BaliTopicCategories->hashref->hash_unique_on('id');
    DB->BaliTopic->search({})->hashref->each(sub{
        my $r = $_;
        my $t = Baseliner->model('Topic')->get_data(undef, $r->{mid}, with_meta=>1,);
        my $tv = Baseliner->cache_get("topic:view:$r->{mid}:") || {};
        $t->{category} = $cats->{ $t->{id_category} };
        delete $tv->{is_closed};
        my $doc = { %$tv, %$t };
        $self->save($t->{topic_mid}, $doc);
        DB->BaliMaster->find($t->{topic_mid})->update({ yaml=>_dump($doc) });
    });
    $i=0;
    local $Baseliner::CI::_record_only=1;
    local $Baseliner::CI::_no_form = 1;
    DB->BaliMaster->search({ -not=>{ collection=>'topic' } }, { select=>'mid' })->hashref->each(sub{
        my $d = _ci( $_->{mid} );
        $self->save($d->{mid}, $d);
    });

    #my $rels = mdb->get_collection('master_rel');
    #$rels->drop;
    #DB->BaliMasterRel->search->hashref->each(sub{
    #    $rels->insert( $_ );
    #});
}

1;

