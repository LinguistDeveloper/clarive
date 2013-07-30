=head1 DESCRIPTION

This is the generic KV based CRUD system

=head1 SYNOPSIS

    my $ci = mdb->find( 1234 );
    mdb->delete( 1234 );
    mdb->save( 1234, { key1=>'value', key2=>2, ... }, { options... }  );
    mdb->load( 1234, { options...} );
    my @cis = mdb->query({ where... }, { opts... });
    my @cis = mdb->search( query=>'fulltext search +query' ); 

=cut
package Baseliner::Schema::KV;
use Moose;
use Try::Tiny;
use Baseliner::Utils qw(_fail _loc _error _debug _throw _log _array);

has index_name => ( is=>'ro', isa=>'Str', default=>'bali_master_kv_full' );
has index_sync_type => ( is=>'ro', isa=>'Str', default=>'commit' );
has rs => ( is=>'ro', lazy=>1, default=>sub{ DB->BaliMasterKV } );

sub find {
    my ($self,$mid) = @_;
    return $self->load( $mid );
}

sub load {
    my ($self,$mid, $opts) = @_;
    my $row = ref $mid ? $mid : DB->BaliMaster->find( $mid ); #  mid may be a BaliMaster row also
    _fail( _loc( 'Master row not found for mid %1', $mid ) ) unless ref $row;
    $mid = $row->mid if ref $row;  
    _fail( _loc( 'Missing mid for row' ) ) unless length $mid;
    # now load record
    return Util->_load( $row->yaml ); 
}

sub update {
    my ($self,$mid, $data, $opts) = @_;
    _fail _loc 'Missing data hash' unless ref $data eq 'HASH';
    my $doc = $self->load( $mid );
    $doc = $opts->{low_precedence} ? { %$data, %$doc } : { %$doc, %$data };
    $self->save( $mid, $doc, $opts );
}

sub delete {
    my ($self,$mid) = @_;
    my $row = DB->BaliMaster->find( $mid );
    _fail _loc 'Master row not found for mid %1', $mid unless $row;
    $row->delete;
}

sub save {
    my ($self,$mid, $doc, $opts) = @_;
    $mid = $mid->mid if ref $mid;  #  mid may be a BaliMaster row also
    Util->_fail( 'Missing mid' ) unless length $mid;
    my $m = Baseliner->model('Baseliner');
    my $sql = 'insert into bali_master_kv (mid,mtype,mpos,mkey,mvalue_num,mvalue_date,mvalue) values (?,?,?,?,?,?,?)';
    #my @flat = $self->_break_varchar( 2000, $self->_flatten( $doc ) );
    my @flat = $self->_flatten( $doc );
    return @flat if $opts->{flat_only};
    my @tuple_status;
    my $hint = $opts->{hint} // {};
    use DBD::Oracle qw/:ora_types/;
    my @flat_final;  # after modifications
    try {
        $m->txn_do( sub {
            # create yaml data for topic 
            unless( $opts->{kv_only} ) {
                my $master_row = DB->BaliMaster->find($mid);
                _fail _loc( 'Master row not found for mid %1', $mid ) unless $master_row;
                $master_row->update({ yaml=>Util->_dump($doc) });
            }
            # now index fields flat
            DB->BaliMasterKV->search({ mid=>$mid })->delete unless $opts->{no_delete};
            my $stmt = $m->storage->dbh->prepare($sql);
            my (@mid, @mtype, @mpos, @mkey, @mvalue, @mvalue_date, @mvalue_num );
            for my $row ( @flat ) {
                my $mkey = $row->{mkey};
                push @mid, $mid;
                push @mtype, $row->{mtype} // 'str';
                push @mpos, $row->{mpos} // 0;
                push @mkey, $row->{mkey} // Util->_fail('Missing key for row: ' . Util->_dump( $row ) );
                push @mvalue_num, $row->{mvalue_num} // ( Util->is_int( $row->{mvalue} ) ? $row->{mvalue} : undef );
                if( ( exists $hint->{$mkey} && $hint->{$mkey} eq 'date' ) || $self->_is_date( $row->{mvalue} ) ) {
                    my $date_str = $self->_date_to_string( $row->{mvalue} );
                    $row->{mvalue_date} //= $date_str;
                    $row->{mvalue} = $date_str;
                }
                push @mvalue_date, $row->{mvalue_date};
                push @mvalue, $row->{mvalue} // '';
                push @flat_final, $row;
            }
            $stmt->execute_array({ ArrayTupleStatus => \@tuple_status }, \@mid, \@mtype, \@mpos, \@mkey, \@mvalue_num, \@mvalue_date, \@mvalue  );
        });
    } catch {
        my $err = shift;
        Util->_throw( Util->_loc('Error inserting into master kv: %1. Doc: %2', $err, Util->_dump($doc) ) );
    };
    return @flat_final; #@tuple_status;
}

sub _date_to_string {
    my ($self,$v) = @_;
    my $ref = ref $v;
    my $s = "$v";
    $s =~ s{T}{ }g if $ref eq 'DateTime';  
    $s;
}

sub _is_date {
    my ($self,$v) = @_;
    return 1 if ref $v eq 'DateTime';
    return 1 if ref $v eq 'Class::Date';
    return 0;
}

sub _break_varchar {
    my ($self, $siz, @flat )=@_;
    return map {
        my $r = $_;
        if( defined $r->{mvalue} && length($r->{mvalue}) > $siz ) {
            my @chunks;
            # TODO dont split words, but also store searcheable version
            my $i=1;
            for my $chk ( unpack( "(A$siz)*", $r->{mvalue} ) ) {
                push @chunks, { %$r, mpos=>$i++, mvalue=>$chk }; 
            }
            @chunks;
        } else {
            $_ 
        }
    } @flat;
}

sub _is_special { 
    $_[1] =~ m/^(\>|\<|\!|\=|-in|-and|-or|-bool|-not_bool|-not|-like|-not_like|\!\=)/;
}

sub _split_special {
    my ($self,$v)=@_;
    my $ref = ref $v;
    return ($v, undef) unless $ref;
    if( $ref eq 'HASH' ) {
        my %vals;
        my %conds;
        for( keys %$v ) {
            $self->_is_special( $_ )
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
        return { mkey=>$prefix, mtype=>'str', mvalue=>$where };
    }
    elsif( $ref eq 'HASH' ) {
        while( my ($k,$v) = each %$where ) {
            $prefix and $k = "$prefix.$k";
            if( ref $v ) {
                my ($vals, $conds) = $self->_split_special( $v );
                push @flat, $self->_flatten($vals, $k) if defined $vals;
                push @flat, { mkey=>$k, mtype=>'hash', mvalue=>$conds } if defined $conds;
            } else {
                push( @flat, { mkey=>$k, mtype=>'str', mvalue=>$v } );
            }
        }
        return @flat;
    }
    elsif( $ref eq 'ARRAY' ) {
        if( $prefix =~ /^(-and|-or)/ ) {
            push @flat, { $prefix => [ map { $self->_flatten($_) } @$where ] };
        } else {
            my $kk = {};
            #push @flat, map{ +{ mkey=>$prefix, mpos=>$i++, mtype=>'array', mvalue=>$_ } } @$where;
            push @flat, map { $_->{mpos} = $kk->{ $_->{mkey} }++; $_ } map{ $self->_flatten($_, $prefix) } @$where;
        }
    }
    elsif( $ref eq 'SCALAR' ) {
        return { mkey=>$prefix, mvalue=> $$where };
    }
    else {
        return { mkey=>$prefix, mvalue=> $where };
        #die 'invalid type: ' . $ref;
    }
    return @flat;
}

sub _quote_keys {
    my ($self, $where) = @_;
    my $ref = ref $where;
    if( $ref eq 'HASH' ) {
        my @ret;
        for my $k ( keys %$where ) {
            if( ! $self->_is_special($k) ) {
                my $v = delete $where->{$k};
                $where->{'"' . $k . '"' } = $v;
                $self->_quote_keys( $v );
            } else {
                $self->_quote_keys( $where->{$k} );
            }
        }
    }
    elsif( $ref eq 'ARRAY' ) {
        my @ret;
        for my $v ( @$where ) {
            $self->_quote_keys( $v );
        }
    }
    return $where;
}

sub _apply_hints {
    my ($self, $where, $hint) = @_;
    $hint ||= {};
    my $ref = ref $where;
    if( $ref eq 'HASH' ) {
        for my $k ( keys %$where ) {
            my $v = $where->{$k};
            my $type = $hint->{$k};
            if( $type eq 'text' ) {   # fulltext search
                delete $where->{$k};
                $k =~ s/"|'//g;
                my ($str,$score) = ref $v eq 'ARRAY' ? @$v : ( $v, 0 );
                $where->{'-bool'} = \[ 'contains( "' . $k . '", ? ) > ? ', $v, $score ];
            }
            $self->_apply_hints( $v, $hint );
        }
    }
    elsif( $ref eq 'ARRAY' ) {
        for my $v ( @$where ) {
            $self->_apply_hints( $v, $hint );
        }
    }
}

sub _take_keys {
    my ($self, $where, $keys) = @_;
    $keys ||= {};
    my $ref = ref $where;
    if( $ref eq 'HASH' ) {
        my @ret;
        while( my($k,$v) = each %$where ) {
            $keys->{$k} = () unless $self->_is_special($k);
            $self->_take_keys( $v, $keys );
        }
    }
    elsif( $ref eq 'ARRAY' ) {
        my @ret;
        for my $v ( @$where ) {
            $self->_take_keys( $v, $keys );
        }
    }
    return $keys;
}

sub _querify {
    my ($self, $where) = @_;
    my $ref = ref $where;
    if( $ref eq 'HASH' ) {
        my @ret;
        while( my($k,$v) = each %$where ) {
            if( $self->_is_special->($k) ) {
                #$k=~ s{\!\=}{-not_like}g;
                return { $k => ( ref $v ? $self->_querify($v) : $v ) };
            } else {
                push @ret, { mkey=>$k, mvalue=>$v };
            }
        }
        return \@ret;
    }
    elsif( $ref eq 'ARRAY' ) {
        my @ret;
        for my $r ( @$where ) {
            push @ret, $self->_querify( $r );
        }
        return \@ret;
    }
    else {
        return $where;
    }
}

sub _flatten_as_hash {
    my $self = shift;
    my @flat = $self->_flatten( @_ );
    # turn array into hash
    my $flat_hash = {};
    $flat_hash->{ $_->{mkey} } = $_->{mvalue} for @flat;
    return $flat_hash;
}

# search utilities

=head2 query

This is a pivoted kv to column search query runner.

    my @rows = mdb->query( $where, $opts ) ;

Where:
    
    Read about L<SQL::Abstract> syntax.
    
Options:
    
    hint => { 'column' => 'type', ... }  
        ensures that WHERE and ORDER_BY clauses search data correctly. 
        
    select => ['description', 'username', ... ]
        selects only the columns listed from KV. Does not load CI.
   
    order_by => [ 'columns asc', { -desc => 'column' }, ... ]
        adds to order by list. Warning: use hint for better comparison control.

    start => 999
    limit => 999
        paging, rownum based overquery

    hash_on => 'key'    
        returns data hashed on key. Does not load CI. 
        
    as_query => 1 
        returns a bind array: [ $sql, @binds ]

    as_full_query => 1 
        returns the complete build_pivot_query object

    as_rs => 1 
        returns the DBIx::Simple result set from ->query

=head3 Hint system

These are the type conversions available:

        str         => 'to_char(mvalue)',
        text        => 'mvalue',   # special, full text type
        number      => 'mvalue_num',
        date        => 'mvalue_date',
        to_date     => 'to_date(mvalue)',
        to_number   => 'to_number(mvalue)',
        mvalue      => 'mvalue',
        mvalue_date => 'mvalue_date',
        mvalue_num  => 'mvalue_num'

Full text search on columns using the hint system:
    
    mdb->query({ description=>'etc' }, { hint=>{ description=>'text' } } );
    # becomes context( description, 'etc' ) > 0 
    
    mdb->query({ description=>['etc',99] }, { hint=>{ description=>'text' } } );
    # becomes context( description, 'etc' ) > 99 

Hint for literal conversions:

    mdb->query({ topic_mid=>12 }, { hint=>{ topic_mid=>\'nvl(mvalue_num,0)' } } );
    
TODO 
    
    - create a resultset type and return that
    - return a dynamic DBIC schema on demand
    - merge with full search so that aditional filtering can be done here
    - return hash built from kv instead of yaml on demand
    - return master_rel data built-in

=cut

sub query {
    my ($self, $where, $opts) = @_;

    my $q = $self->build_pivot_query( $where, $opts );
    return \( $q->{query} ) if $opts->{as_query};
    return $q if $opts->{as_full_query};
    my $dbs = $self->_dbis;
    my $rs = $dbs->query( @{ $q->{query} || {} });
    return $rs if $opts->{as_rs};
    return map { $_->{ $opts->{hash_on} } => $_ } $rs->hashes if exists $opts->{hash_on};
    return $rs->hashes if defined $opts->{select} || $opts->{hashes};
    # TODO run a query on KV itself to return kv rows
    my @cis;
    for my $row ( $rs->hashes ) {
        my $rec = Baseliner::Role::CI->load( $row->{mid}, $row, undef, $row->{yaml} );   
        my $yaml = delete $rec->{yaml};
        my $ci_class = $rec->{ci_class}; 
        # instantiate
        my $ci = $ci_class->new( $rec );
        $ci->{_ci} = $rec;
        push @cis, $ci;
    }
    return @cis;
}

=head2 search

This is a full text search, not the same as query.

TODO consider sending results to mdb->query for common return strategy

=cut
sub search {
    my ($self,%p) = @_;
    my $query=$p{query};
    my $from = $p{ci} 
        ? { select=>['mid'], as=>['mid'] }
        : { select=>['mid','name','collection','bl','ts','yaml'], 
            as=>['mid','name','collection','bl', 'ts','yaml'], 
            order_by=>{ -desc=>'ts' } };

    if( length $p{limit} ) {
        $from->{rows} = $p{limit} ;
    }
    my $where = {};
    length($query) and $where = $self->build_search( query=>$query );
    my $rs = DB->BaliMaster->search( $where, $from);
    return $rs if $p{rs};
    my @rows = $rs->hashref->all;
    unless( $p{master_only} ) {
        if( $p{ci} ) {
            @rows = map { Baseliner::CI->new( $_->{mid} ) } @rows; 
        } else {
            @rows = map { 
                my $r = $_;
                if( defined $r->{yaml} ) {
                    my $d = Util->_load( delete $r->{yaml} ); 
                    +{ %$r, %$d }
                } else {
                    $r
                }
            } @rows;
        }
    }
    return @rows;
}

sub rebuild_index {
    my ($self,%p) = @_;
    my $index_name = $self->index_name;
    my $dbs = $self->_dbis;
    my $sync_type = $p{sync_type} || $self->index_sync_type;  # commit, manual, every
    $p{drop} = 1 if $p{sync_type};  # sync_type param means drop me
    my $msg;
    eval { $msg = $dbs->dbh->do(qq{alter index $index_name rebuild}) } unless $p{drop};
    if( $p{drop} || $@ ) {
        _error( _loc "Error rebuilding index: %1", $@ ) if $@;
        eval { $dbs->dbh->do(qq{drop index $index_name}) };
        _error( _loc "Error droping index: %1", $@ ) if $@;
        # sync on commit, may be expensive:
        if( $sync_type eq 'commit' ) {
            $msg = $dbs->dbh->do(qq{create index $index_name on bali_master_kv( mvalue ) indextype is ctxsys.context parameters('sync ( on commit )') parallel 4});
        }
        elsif( $sync_type eq 'every' ) {
            # sync every 20 seconds:
            $msg = $dbs->dbh->do(qq{create index $index_name on bali_master_kv( mvalue ) indextype is ctxsys.context parameters('sync ( every "sysdate+(1/24/60/3)" )') parallel 4});
        }
        else {
            # manual sync:
            $msg = $dbs->dbh->do(qq{create index $index_name on bali_master_kv( mvalue ) indextype is ctxsys.context parallel 4});
        }
    }
    return $msg;
}

sub _dbis { 
    $Baseliner::_dbis // ( $Baseliner::_dbis = Util->_dbis() ) 
}

# XXX this could use full oracle semantics
sub build_search {
    my ($self,%p) = @_;
    return {} unless $p{query};
    my $where = {};
    my $query = Util->query_string_clean( $p{query} );
    my @terms = Util->query_to_terms( $query );
    my $clean_terms = sub { s/[^\w]//g for @_; @_  };  # terms can only have a few special chars, but this has to be done last, because we need minuses and pluses
    my @terms_normal = $clean_terms->(  grep(!/^\+|^\-/,@terms) ); # ORed
    my @terms_plus = $clean_terms->( grep(/^\+/,@terms) ); # ANDed
    my @terms_minus = $clean_terms->(  grep(/^\-/,@terms) ); # NOTed
    my @ors = map { \[ " EXISTS (select 1 from bali_master_kv kv where kv.mid=me.mid and contains(kv.mvalue, ?)>0 )  ", '%'.$_.'%' ] } @terms_normal;
    my @plus = map { \[ " EXISTS (select 1 from bali_master_kv kv where kv.mid=me.mid and contains(kv.mvalue, ?)>0 ) ", '%'.$_.'%' ] } @terms_plus;
    my @minus = map { \[ " NOT EXISTS (select 1 from bali_master_kv kv where kv.mid=me.mid and contains(kv.mvalue, ?)>0 ) ", '%'.$_.'%' ] } @terms_minus;
    $where->{'-and'} = [
        ( @ors ? [ -or => \@ors ] : () ), @plus,  @minus
    ];
    #my @score_fields = map { "contains(kv.mvalue, ?
    return $where;
}

# bali_master_search row
sub index_search_data {
    my( $self, %p ) = @_;
    my $no_save = delete $p{no_save};
    $p{data} = { %{ $self->{_ci} }, %{ $p{data} || {} } } if ref $self && ref $self->{_ci};
    my $mid = $p{mid} // $p{data}{mid} // _throw 'Missing mid for index search';
    my $data = $p{data} || {};
    my $row = $p{row} ? { $p{row}->get_columns } : {}; # master row
    my $enc = JSON::XS->new->convert_blessed(1);
    my $doc = { %$row, %$data };
    my $j = lc $enc->encode( $doc );
    $j = Util->_unac( $j );
    $j =~ s/[^\w|:|,|-]//g;  # remove all special chars, etc
    $j =~ s/\w+:\s*,//g;   # delete empty keys
    return $j if $no_save;
    DB->BaliMasterSearch->update_or_create({ mid=>$mid, search_data=>$j, ts=>Util->_dt });
}

sub build_pivot_query {
    my ($self, $where, $opts ) = @_;
    my $db_name = $self->{db_name};
    #my $query_head = "SELECT DISTINCT oid FROM ${db_name}_kv ";
    #my $coll_match = qq{ AND EXISTS ( select 1 from ${db_name}_obj vamp3
    #my $where_flat = $self->_flatten_as_hash( $where );
    #return $where_flat;

    my $hint = $opts->{hint};

    my %pivot_cols;
    my @order_by;
    # where?
    for my $key ( keys %{ $self->_take_keys($where) || {} } ) {
        next unless length $key;
        $key =~ s/"//g;  # cleanup in case it's quoted
        $pivot_cols{ $key } = ();
    }
    # order_by ?
    if( my @order_by_param =
        ref $opts->{order_by} eq 'ARRAY' ? @{$opts->{order_by}} : ( $opts->{order_by} ) ) {
        for my $order_by_column ( @order_by_param ) {
            next unless defined $order_by_column;
            my $dir;
            if( ref $order_by_column eq 'HASH' ) {
                $dir = [ keys %$order_by_column ]->[0]; 
                $dir =~ s/^-//g;
                $order_by_column = [ values %$order_by_column ]->[0]; 
            } elsif( $order_by_column =~ /^(.+)\s+(asc|desc)\s*$/ )  {
                $order_by_column = $1;
                $dir = $2;
            }
            $dir ||= 'ASC';
            $order_by_column =~ s/"//g; # cleanup
            my $quoted = qq{"$order_by_column"};
            # cast type on hint?  - XXX not needed, types are resolved on pivot
            #  if( my $type = $hint->{ $order_by_column } ) {
            #      push @order_by, "to_number( $quoted ) $dir" if $type eq 'number';
            #  } else {
            #      push @order_by, "$quoted $dir";
            #  }
            
            # add to order by
            push @order_by, "$quoted $dir";
            # add to pivot column select
            $pivot_cols{ $order_by_column } = ()
                unless exists $pivot_cols{ $order_by_column };
        }
    }

    # where sql abstract
    $self->_apply_hints( $where, $hint ) if exists $opts->{hint};
    my $where_quoted = $self->_quote_keys( $where );
    my ( $wh, @binds ) = keys %$where ? $self->_abstract( $where_quoted ) : ('WHERE 1=1');

    # select?
    my @select = _array( $opts->{select} );  # user defined select
    @select = map {
        my $col = $_;
        # add to pivot column select
        if( /^master\./ ) { # if it starts with master. don't quote
            $col
        } else {
            $pivot_cols{ $col } = ()
                unless exists $pivot_cols{ $col };
            # quote
            /"/ ? $col : qq{"$col"} ;  
        }
    } @select;

    # pivots
    my $pivots = join ',' => qw/mid/,
    my $pivots_with = join ',' =>
        map {
            my $col = $_;
            # solve hints
            my $type = $hint->{$col} || 'str';
            my $type_defs = {
                str         => 'to_char(mvalue)',
                text        => 'mvalue',
                number      => 'mvalue_num',
                date        => 'mvalue_date',
                to_date     => 'to_date(mvalue)',
                to_number   => 'to_number(mvalue)',
                mvalue      => 'mvalue',
                mvalue_date => 'mvalue_date',
                mvalue_num  => 'mvalue_num'
            };
            my $type_func = ref $type eq 'SCALAR' ? $$type : $type_defs->{$type} || $type_defs->{str};
            #unshift @binds, $collname;
            qq{"pivot_$_" as (
                    select kv.mid, $type_func as "$col" from bali_master_kv kv
                    where mkey='$col'
                )}
        } keys %pivot_cols;
    $pivots_with and $pivots_with = "WITH $pivots_with";
    my $pivots_from = join ',' => 'bali_master master', map { qq{ "pivot_$_" } } keys %pivot_cols;
    my $pivots_outer = join ' and ' => map { qq{master.mid = "pivot_$_".mid (+)} } keys %pivot_cols;
    $pivots_outer ||= '1=1';

    my $selects = join ',' => @select 
        ? @select 
        : ( qw/master.mid master.name master.collection master.moniker master.yaml/, map { qq{"$_"} } keys %pivot_cols );
    my $order_by_pivot = @order_by ? 'order by ' . join ',', @order_by : '';
    my $order_by = join ',', @order_by, 'master.mid';

    my $sql = qq{
        $pivots_with
        SELECT $selects
        FROM $pivots_from
         $wh 
           and $pivots_outer
         ORDER BY $order_by
    };
    # limit? (0 indexed)
    my $start = $opts->{start};
    my $limit = $opts->{limit};
    $sql = do {
        #my $page_num = int( $start / $limit ) + 1 ;
        my $limit_sql = $limit ? "where rownum < " . ( $limit + $start ) : "";
        my $start_sql = $start ? "where rownum__ >= $start" : "";
        qq{
            select * from (
                select m__.*, rownum rownum__ from ( $sql ) m__
                $limit_sql
            ) $start_sql
        }
    } if defined $start || defined $limit;

    Util->_debug( $sql );
    { query=>[ $sql, @binds ], sql=>$sql, binds=>\@binds, columns=>[ keys %pivot_cols ] };
}

sub _abstract {
    my $self = shift;
    my $sa = SQL::Abstract->new; 
    my ($q, @binds) = $sa->where( @_ );
    return ($q,@binds);
}


sub load_cis {
    my ($self, %p)=@_;
    my $i=0;
    my $cats = DB->BaliTopicCategories->hashref->hash_unique_on('id');
    my $where1 = {};
    $where1->{mid} = $p{mid} if $p{mid};
    DB->BaliTopic->search($where1)->hashref->each(sub{
        my $r = $_;
        my $t = Baseliner->model('Topic')->get_data(undef, $r->{mid}, with_meta=>1,);
        my $mid = $t->{topic_mid};
        my ($cnt, $grid_data ) = Baseliner->model('Topic')->topics_for_user({ username=>'root', topic_list=>$mid });
        $t->{category} = $cats->{ $t->{id_category} };
        delete $grid_data->{is_closed};
        my $doc = { %$grid_data, %$t };
        # save kv
        $self->save( $mid, $doc);
    });
    return;
    $i=0;
    local $Baseliner::CI::_record_only=1;
    local $Baseliner::CI::_no_form = 1;
    my $where2 = { -not=>{ collection=>'topic' } };
    $where2->{mid} = $p{mid} if $p{mid};
    DB->BaliMaster->search( $where2, { select=>'mid' })->hashref->each(sub{
        my $d = _ci( $_->{mid} );
        $self->save($d->{mid}, $d, { kv_only=>1 });
    });

    #my $rels = mdb->get_collection('master_rel');
    #$rels->drop;
    #DB->BaliMasterRel->search->hashref->each(sub{
    #    $rels->insert( $_ );
    #});
}

# XXX not useful, needs to be imported into schema
sub build_dynamic_view {
    my $self = shift;
    my %p = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    my $id = $p{id} || Util->_nowstamp() . int(rand(99999));
    my $table = "View$id";
    my $pkg = "Baseliner::Schema::Baseliner::Result::View$id";
    eval qq{
        package $pkg; 
        use base 'DBIx::Class::Core';
    };
    $pkg->table_class("DBIx::Class::ResultSource::View");
    $pkg->table($table);
    $pkg->result_source_instance->is_virtual(1);
    $pkg->result_source_instance->view_definition( $p{sql} );
    local $ENV{CAG_ILLEGAL_ACCESSOR_NAME_OK} = 1;
    my @cols = Util->_array($p{columns});
    @cols = map { s/\.//g; $_ } @cols; # quote cols if needed
    #@cols = map { /\./ ? '"'.$_.'"' : $_ } @cols; # quote cols if needed
    $pkg->add_columns( @cols ); 
    $pkg->set_primary_key( $p{pk} ) if $p{pk};
    $pkg;
}

1;

