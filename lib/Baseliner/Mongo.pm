package Baseliner::Mongo;
use Mouse;
use MongoDB;
use Baseliner::MongoCursor;
use Baseliner::MongoCollection;
use Try::Tiny;
use Function::Parameters qw(:strict);
use Baseliner::Utils qw(_fail _loc _error _warn _debug _throw _log _array _dump _ixhash);

# mongo connection
has retry_frequency => qw(is rw isa Num default 5);
has max_retries     => qw(is rw isa Num default 60);
has mongo_client  => qw(is rw isa Any), default=>sub{ Baseliner->config->{mongo}{client} // {} };
has mongo_db_name => qw(is rw isa Any), default=>sub{ Baseliner->config->{mongo}{dbname} // 'clarive' };
has mongo         => ( is=>'ro', isa=>'MongoDB::MongoClient', lazy=>1, default=>sub{
       my $self = shift;
       require MongoDB;
       my $max = $self->max_retries;
       my $last_error;
       for my $retry (1..$max){
           my $cli = try {
               local $Baseliner::logger = undef;  # if we're in a job, dont' try to write to db in _log()
               _log "Mongo: new connection to " . $self->mongo_db_name;
               return MongoDB::MongoClient->new($self->mongo_client);
           } catch {
               my $err = shift;
               $last_error = _loc( "Mongo error connecting to %1: %2", $self->mongo_db_name, $err );
               _error $last_error;
               _error _loc( 'Retrying (%1) in %2 secs...', $retry, $self->retry_frequency );
               sleep $self->retry_frequency;
               return undef;
           };
           return $cli if $cli;
       }
       _fail $last_error if $last_error;
    });
has db => ( is=>'ro', isa=>'MongoDB::Database', lazy=>1, default=>sub{
       my $self = shift;
       $self->mongo->get_database($self->mongo_db_name); 
    }, handles=>[qw(run_command)],
);

sub oid {
    my($self,$oid)=@_;
    return MongoDB::OID->new if !$oid;
    return MongoDB::OID->new( $oid );
}

=head2

Returns the next seq num as STRING

=cut
sub seq {
    my($self,$name,$seq)=@_;
    my $coll = $self->collection('master_seq');
    $coll->update({ _id=>$name }, { _id=>$name, seq=>$seq+0 },{ upsert=>1 }), return("$seq") if defined $seq;
    my $doc = $coll->find_and_modify({ query=>{ _id=>$name }, update=>{ '$inc'=>{ seq=>1 } }, new=>1 });
    return "$doc->{seq}" if $doc->{seq};
    $coll->insert({ _id=>$name, seq=>1 });
    return "1";
}

sub collection {
    my ($self,$coll_name) = @_;
    my $coll = $self->db->get_collection( $coll_name );
    #require Baseliner::MongoCollection;
    Baseliner::MongoCollection->new( _collection=>$coll, _db=>$self );
}

sub grid { $_[0]->db->get_gridfs }

sub asset {
    my ($self, $in, %opts) = @_;
    require Baseliner::Schema::Asset;
    return Baseliner::Schema::Asset->new( $in, grid=>$self->db->get_gridfs, %opts );
}

sub asset_new {
    my ($self,$in,%opts) = @_;
    $in //= '';
    my $fh;
    if( !ref $in ) {
        # open the string like a file
        my $basic_fh;
        open($basic_fh, '<', \$in) or _fail _loc 'Error trying to open string asset: %1', $!;
        # turn the file handle into a FileHandle
        $fh = FileHandle->new;
        $fh->fdopen($basic_fh, 'r');
    }
    elsif( ref $in eq 'Path::Class::File' ) {
        $fh = $in->open('r');
    }
    elsif( ref $in eq 'GLOB' ) {
        $fh = $in;
    }
    else {
        # open the string like a file
        my $basic_fh;
        open($basic_fh, '<', \$in);
        # turn the file handle into a FileHandle
        $fh = FileHandle->new;
        $fh->fdopen($basic_fh, 'r');
    }
    
    _fail _loc 'Could not get filehandle for asset' unless $fh; 
    
    # $grid->insert($fh, {"filename" => "mydbfile"});
    # TODO match md5, add mid to asset in case it exists
    my $id = $self->grid->insert($fh, { %opts } );
    return $id;
}

sub ts { Util->_now() }
sub ts_hires { Time::HiRes::time() }
sub now { Class::Date->now->to_tz( Util->_tz() ) }
sub in  { shift; {  '$in' => [ map { ref $_ eq 'HASH' ? "$_->{mid}" : "$_" } Util->_array( @_ ) ] } }
sub nin { shift; { '$nin' => [ map { ref $_ eq 'HASH' ? "$_->{mid}" : "$_" } Util->_array( @_ ) ] } }
sub str { shift; [ map { defined $_ ? "$_" : undef } Util->_array( @_ ) ] }

sub find {
    my ($self,$mid)=@_;
    my $master = $self->find_master( $mid );
    return Util->_load( $master->{yaml} ); 
}

sub find_master {
    my ($self,$mid)=@_;
    _throw( _loc( 'Missing mid for row' ) ) unless length $mid;
    my $row = $self->collection('master')->find_one({ '$or'=>[ {mid=>"$mid"},{mid=>0+$mid} ] });
    _throw( _loc( 'Master row not found for mid `%1`', $mid ) ) unless ref $row;
    return $row;
}

sub master     { $_[0]->collection('master') }
sub master_rel { $_[0]->collection('master_rel') }
sub master_cal { $_[0]->collection('master_cal') }
sub master_doc { $_[0]->collection('master_doc') }

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

=head2 joins 

    my @revisions = mdb->joins(
        { merge=>'flat' },
        ['master_rel','dad'] => { rel_type => 'topic_topic' },
        to_mid     => 'from_mid',
        master_rel => { rel_type => 'topic_topic' },
        to_mid     => 'mid',
        master     => {}
    );

=cut
sub joins {
    my $self = shift;
    my %opts = %{ shift() } if ref $_[0] eq 'HASH';
    my ( %res, %in, @merges );
    while( @_ ) {
        my ($coll,$where,$from,$to,$as) = (shift,shift,shift,shift);
        ($coll,$as) = @$coll if ref $coll eq 'ARRAY'; 
        my $rs = $self->collection( $coll )->find({ %$where, %in });
        if( ! $from ) {
            $res{coll} = $coll;
            $res{where} = $where;
            last;
        }
        my @docs;
        if( $opts{merge} ) {
            @docs = $rs->all; 
            my %merge;
            for my $doc ( @docs ) {
                $merge{ $doc->{ $from } } = $doc;
            }
            push @merges, [ $as // $coll,$from,$to, \%merge ];
        } else {
            $rs->fields({ _id=>-1, $from => 1 });
            @docs = $rs->all; 
        }
        _warn [ map{ $_->{$from} } @docs ];
        %in = ( $to => mdb->in(map{ $_->{$from} } @docs ) );
    }
    my $where = +{ %{ $res{where} }, %in };
    #_debug "final join = collection $res{coll}, where = " . _dump $where;
    my $rs = $self->collection( $res{coll} )->find($where);
    if( $opts{merge} ) {
        my @docs = $rs->all;
        my (%join_keys,$last_key);
        my $k = 1;
        for my $merge ( reverse @merges ) {
            my ($coll_or_as,$from,$to,$m) = @$merge;
            my $doc_key = '_join#'.$k;
            my $join_key = $join_keys{$coll_or_as} ? $coll_or_as . '_' . $join_keys{$coll_or_as}++ : $coll_or_as;
            $join_keys{$coll_or_as} //= 1;
            $k++;
            for my $doc ( @docs ) {
                $doc->{$doc_key} = $doc->{$to} unless $last_key;
                $opts{merge} eq 'flat' 
                ? do{ $doc = { %{ $m->{ $last_key ? $doc->{$last_key} : $doc->{$to} } }, %$doc } }
                : do{ $doc = { $join_key=>$m->{ $last_key ? $doc->{$last_key} : $doc->{$to} }, %$doc } };
            }
            $last_key = $doc_key;
        }
        return @docs;
    } else {
        return wantarray ? $rs->all : $rs;
    }
}


sub save {
    my ($self,$mid, $doc, $opts) = @_;
    $mid = $mid->{mid} if ref $mid;  #  mid may be a BaliMaster row also
    Util->_fail( 'Missing mid' ) unless length $mid;
    # save into master
    my $m = $self->master;
    my $row = $m->find_one();
    my $final = $m->merge_into({ mid=>"$mid" },{ yaml=>Util->_dump($doc) });
    # create the searcheable version of the doc
    Util->_unbless( $doc );
    $self->master_doc->update({ mid=>"$mid" }, $doc );
    return $final;
}

# deprecated:
sub index_sync { ... }

sub index_all {
    my ($self, $collection)=@_;
    my $idx = {
        topic => [
            [{ mid=>1 },{ unique=>1 }],
            [{ created_on=>1 }],
            [{ created_on=>1 },{ mid=>1 }],
            [{ created_on=>1 },{ m=>1 }],
            [{'$**'=> "text"}],
        ],
        job_log => [
            [{ id=>1 }],
            [{ mid=>1 }],
        ],
        event => [
            [{ ts=>1 }],
        ],
        topic_image => [
            [{ id_hash => 1 }]
        ],
        master => [
            [{ mid=>1 },{ unique=>1 }],
            [{ name=>1 }],
        ],
        notification => [
            [{'$**'=> "text"}],
        ],
        master_rel => [
            [{ from_mid=>1, to_mid=>1, rel_type=>1, rel_field=>1 },{ unique=>1 }],
            [{ from_mid=>1, rel_type=>1 }],
            [{ to_mid  =>1, rel_type=>1 }],
            [{ to_mid  =>1 }],
            [{ from_mid  =>1 }],
            [{ rel_type=>1 }],
        ],
        master_doc => [
            [{'$**'=> "text"}],
            [{ mid=>1 },{ unique=>1 }],
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

sub migra {
    my ($self,%p)=@_;
    require Baseliner::Schema::Migra::MongoMigration;
    return 'Baseliner::Schema::Migra::MongoMigration';
}

sub ixhash {
    my $self = shift;
    Util->_ixhash( @_ );
}

# default 20MB capped collection
sub create_capped {
    my ($self,$coll, %p) = @_;
    mdb->db->run_command([ create=> $coll, capped=>boolean::true, size=>$p{size}//(1024*1024*50), %p ]);
}

sub compact {
    my ($self, %p)=@_;
    my @colls = sort grep !/\./, $self->db->collection_names;
    for( @colls ) {
        Util->_log( sprintf '%s: compacting collection...', $_ );
        $self->run_command([ compact=>$_,%p ]);
        Util->_log( sprintf '%s: finished', $_ );
    }
}

# remove all dots and _ci from an unblessed doc
sub clean_doc {
    my ($self,$doc) = @_;
    
    return unless ref $doc eq 'HASH';
    delete $doc->{_ci};
    delete $doc->{$_} for grep /\./,keys $doc;
    for my $k ( keys %$doc ) {
        my $v = $doc->{$k};
        if( ref $v eq 'HASH' ) {
            $self->clean_doc( $v ); 
        }
        elsif( ref $v eq 'ARRAY' ) {
            $self->clean_doc( $_ ) for _array( $v ); 
        }
        elsif( ref $v eq 'SCALAR' ) {
            $doc->{$k} = $$v;
        }
        elsif( ref $v eq 'GLOB' ) {
            delete $doc->{$k};
        }
    }
}

sub integrity {
    my($self) = @_;

    # master_docs not in BaliMaster
    for ( mdb->master_doc->find->all ) {
       DB->BaliMaster->find({ mid=>$_->{mid} }) or do {
        warn "Not found: $_->{mid}";
        mdb->master_doc->remove({ mid=>$_->{mid} });
        };
    }
    
}

sub disconnect {
    $Baseliner::_mdb = undef;
}

=head2 query_build

Returns a Mongo query regex based statement
a query string and a list of fields.

    $query and $where = mdb->query_build( query=>$query, fields=>{
        name     =>'name',
        id       =>'to_char(me.id)',
        user     =>'username',
        comments =>'comments',
        status   =>'status',
        start    =>"starttime",
        sched    =>"schedtime",
        end      =>"endtime",
        items    =>"foreign.item",
    });

You can use an ARRAY for shorthand too:

    $where = mdb->query_build( query=>$query,
        fields=>[
            qw/id bl name requested_on requested_by finished_on finished_by/,
            [ 'age', 'foreign.age' ]     # handles pairs also
        ]);

    Or use where=>$where for merging. 

=cut
sub query_build {
    my ($self,%p) = @_;
    return {} unless $p{query};
    _throw 'Fields parameter should be HASH or ARRAY'
        unless ref( $p{fields} ) =~ m/HASH|ARRAY/i;
    my @terms;
    my $where = $p{where} // {};
    my @fields = ref $p{fields} eq 'HASH' ? keys( %{ $p{fields} } ) : _array($p{fields});
    # build columns   -----    TODO use field:lala
    $p{query} =~ s{\*}{.*}g;
    $p{query} =~ s{\?}{.}g;
    @terms = grep { defined($_) && length($_) } Util->split_with_quotes($p{query});  
    my @terms_normal = grep(!/^\+|^\-/,@terms);
    my @terms_plus = grep(/^\+/,@terms);
    my @terms_minus = grep(/^\-/,@terms);
    my $all_or_one = sub {
        my $term = shift;
        my $insensitive = 1;
        if( $term =~ /^([^:]+):(.+)$/ ) {
            my ($k,$v) = ($1,$2);
            $v =~ s/^"//;
            $v =~ s/"$//;
            $insensitive = 0 if $v=~/[A-Z]/;
            return ($v,$insensitive,$k);
        } else {
            $term =~ s/^"//;
            $term =~ s/"$//;
            $insensitive = 0 if $term=~/[A-Z]/;
            return ($term,$insensitive,@_);
        }
    };
    my @ors = map {
        my ($term,$insensitive,@term_fields) = $all_or_one->($_,@fields);
        map {
            +{ $_ => $insensitive ? qr/$term/i : qr/$term/ }
        } @term_fields;
    } @terms_normal;
    #push @ors, { 1=>1 } if ! @terms_normal;
    my @wh_and = (
        ( @ors ? {'$or' => \@ors} : () ),
        ( @terms_plus ? { '$and'=>[ map { my $v=substr($_,1); my $insensitive; ($v,$insensitive,@fields)=$all_or_one->($v,@fields); 
                { '$or'=>[map { +{$_ => $insensitive ? qr/$v/i : qr/$v/} } @fields] } } @terms_plus ]} : () 
        ),
        ( @terms_minus ? { '$and'=>[ map { my $v=substr($_,1); my $insensitive; ($v,$insensitive,@fields)=$all_or_one->($v,@fields); 
                { '$and'=>[map { +{$_ => {'$not' => $insensitive ? qr/$v/i : qr/$v/} } } @fields] } } @terms_minus ]} : () 
        ),
    );
    #push @ors, { 1=>1 } if ! @terms_normal;
    $where->{'$and'} = \@wh_and if @wh_and;
    return $where;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($coll) = reverse( split(/::/, $name));
    Util->_fail('The method is `joins` not `join`') if $coll eq 'join';
    return $self->collection( $coll );
}

1;
