package Baseliner::Mongo;
use Mouse;
use MongoDB;
use Baseliner::MongoCursor;
use Baseliner::MongoCollection;
use Try::Tiny;
use Function::Parameters qw(:strict);
use DateTime::Tiny;
use Baseliner::Utils qw(_fail _loc _error _warn _debug _throw _log _array _dump _ixhash);
use v5.10;

# mongo connection
has retry_frequency => qw(is rw isa Num default 5);
has max_retries     => qw(is rw isa Num default 60);
has mongo_client  => qw(is rw isa Any), default=>sub{ Clarive->config->{mongo}{client} // {} };
has mongo_db_name => qw(is rw isa Any), default=>sub{ Clarive->config->{mongo}{dbname} // 'clarive' };
has mongo         => ( is=>'ro', isa=>'MongoDB::MongoClient', lazy=>1, default=>sub{
       my $self = shift;
       require MongoDB;
       local $Baseliner::Utils::caller_level = 7;
       my $max = $self->max_retries;
       my $last_error;
       for my $retry (1..$max){
           my $cli = try {
               local $Baseliner::logger = undef;  # if we're in a job, dont' try to write to db in _log()
               _log sprintf "Mongo: new connection to db `%s`",$self->mongo_db_name;
               return MongoDB::MongoClient->new({ %{ $self->mongo_client }, dt_type=>'DateTime' });
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
    }, handles=>[qw(run_command eval)],
);
has db_cache => ( is=>'ro', isa=>'MongoDB::Database', lazy=>1, default=>sub{
       my $self = shift;
       $self->mongo->get_database($self->mongo_db_name . '-cache'); 
    },
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
    my ($self,$collname) = @_;

    my $coll = $collname =~ /^cache/ 
        ? $self->db_cache->get_collection( $collname )
        : $self->db->get_collection( $collname );
    
    #require Baseliner::MongoCollection;
    Baseliner::MongoCollection->new( _collection=>$coll, _db=>$self );
}

sub grid { $_[0]->db->get_gridfs }

sub grid_slurp {
    my ($self,$where) = @_; 
    my $doc = $self->grid->find_one($where);
    return unless $doc;
    my $data = $doc->slurp;
    utf8::decode($data);
    return $data;
}

sub grid_insert {  
    my ($self, $in, %opts) = @_;
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
    elsif( ref($in) =~ /GLOB|IO::File/ ) {
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
    my $md5 = Util->_md5( $self->fh );
    my $origin = _loc '%1:%3', caller;
    my $id = $self->grid->insert($fh, +{ md5=>$md5, origin=>$origin, %opts } );
    return $id;
}

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
sub in  { shift; {  '$in' => [ map { ref $_ eq 'HASH' ? "$_->{mid}" : defined $_ ? "$_" : $_ } Util->_array( @_ ) ] } }
sub nin { shift; { '$nin' => [ map { ref $_ eq 'HASH' ? "$_->{mid}" : defined $_ ? "$_" : $_ } Util->_array( @_ ) ] } }
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
    _throw( _loc( "Master row not found for mid '%1'", $mid ) ) unless ref $row;
    return $row;
}

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
    # detect if a find coll=>{ ... }  or query coll=>[{},{}] 
    my $rs_find = sub {
        my $coll = shift;
        my $wh = shift;
        my $rs;
        if( ref $wh eq 'ARRAY' ) {
            $rs = $self->collection( $coll )->query(+{ %{ $$wh[0] || {} }, @_ }, $$wh[1] );
            $rs->fields( $$wh[1]->{fields} ) if ref $$wh[1] eq 'HASH' && exists $$wh[1]->{fields};
            $rs->sort( $$wh[1]->{sort} ) if ref $$wh[1] eq 'HASH' && exists $$wh[1]->{sort};
        } else {
            $rs = $self->collection( $coll )->find(+{ %$wh, @_ });
        }
        return $rs;
    };
    while( @_ ) {
        my ($coll,$where,$from,$to,$as) = (shift,shift,shift,shift);
        ($coll,$as) = @$coll if ref $coll eq 'ARRAY'; 
        my $rs = $rs_find->( $coll => $where, %in ); 
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
        #_warn [ map{ $_->{$from} } @docs ];
        %in = ( $to => mdb->in(map{ $_->{$from} } @docs ) );
    }
    my $rs = $rs_find->( $res{coll} => $res{where}, %in);
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
                ? do{ 
                    my $h = $m->{ $last_key ? $doc->{$last_key} : $doc->{$to} } // {};
                    $doc = { %$h, %$doc } 
                }
                : do{ 
                    $doc = { $join_key=>$m->{ $last_key ? $doc->{$last_key} : $doc->{$to} }, %$doc }
                };
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
    $mid = $mid->{mid} if ref $mid;  #  mid may be a master row also
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

=head2 index_all

Builds all collection indexes. By default drops current
indexes before creating them.

    mdb->index_all;
    mdb->index_all('master_doc');
    mdb->index_all('master_doc', drop=>0 );  # do not drop current indexes before indexing

=cut
sub index_all {
    my ($self, $collection, %p)=@_;
    $p{drop} //= 1;
    my $base_indexes = {
        activity => [
            [{ mid=>1, ts=>-1 }],
            [{ ts=>-1 }],  # Dashboards.pm
        ],
        cache => [
            [{ _id=>1 }],
        ],
        category => [
            [{ id=>1 }],
            [{ name=>1 }],
            [{ 'workflow.id_role'=>1 }],
        ],
        event => [
            [{ id=>1 }],
            [{ mid=>1 }],
            [{ mid=>1, ts=>1 }],
            [{ mid=>1, event_key=>1, ts=>1 }],
            [{ ts=>1 }],
            [{ event_key=>1 }],
            [{ 'event_status'=>1 }],
            [{ 'event_status'=>1, '_id'=>1 }],
        ],
        event_log =>[
            [{ 'id_event'=>1 }],
        ],
        'fs.files' =>[ 
            [{ parent_mid=>1 }],
            [{ topic_mid=>1 }],
            [{ id_rule=>1 }],
        ],
        job_log => [
            [{ id=>1 }],
            [{ mid=>1 }],
            [[ ts=>1, t=>1 ]],
            [{ mid=>1, exec=>1 }],
            [{ mid=>1, lev=>1, exec=>1 }],
            [{ mid=>1, exec=>1, ts=>1, t=>1 }],
        ],
        master => [
            [{ mid=>1 },{ unique=>1 }],
            [{ collection=>1 }],
            [{ name=>1 }],
            [{ moniker=>1 }],
        ],
        master_rel => [
            [{ from_mid=>1, to_mid=>1, rel_type=>1, rel_field=>1 },{ unique=>1 }],
            [{ from_mid=>1, rel_type=>1 }],
            [{ to_mid  =>1, rel_type=>1 }],
            [{ to_mid=>1, from_mid =>1, rel_type=>1 }],
            [{ to_mid  =>1 }],
            [{ from_mid  =>1 }],
            [{ from_mid=>1, to_mid=>1 }],
        ],
        master_seen => [
            [{ mid=>1, username=>1 }],
        ],
        master_doc => [
            [{ mid=>1 },{ unique=>1 }],
            [{ name=>1, moniker=>1, collection=>1 }],
            [{ step=>1, status=>1 }],
            [{ projects=>1 }],
            [{ collection=>1 }],
            [{ starttime=>-1 }],  # used by Dashboards.pm and monitor_json
            [{ collection=>1, name=>1 }],
            [[ collection=>1, starttime=>-1 ]],  # job monitor
            [{ status=>1, pid=>1, collection=>1 }],
            [{ status=>1, maxstarttime=>1, collection=>1 }],
            [{'$**'=> "text"},{ background=>1 }],
        ],
        message => [
            [{ queue=>1 }],
        ],
        notification => [
            [{'$**'=> "text"},{ background=>1 }],
        ],
        role => [
          [{ role=>1 }],
          [{ id=>1 }], 
        ],
        rule => [
            [{ id=>1 }],
            [{ rule_name=>1 }],
            [[ rule_seq=>1, _id=>-1 ]],
            [[ rule_seq=>1, ts=>-1 ]],
        ],
        rule_version => [
            [{ ts=>1 }],
        ],
        sem => [
            [{ key=>1 },{ unique=>1, dropDups => 1 }],
            [{ key=>1, 'queue._id'=>1 }],
            [{ key=>1, 'queue._id'=>1, 'queue.seq'=>1 }],
        ],
        topic => [
            [{ mid=>1 },{ unique=>1 }],
            [{ '_sort.title' => 1}],
            [{ created_on=>1 }],
            [{ modified_on=>1 }],
            [{ modified_on=>-1 }],
            [{ created_on=>1, mid=>1 }],
            [{ mid=>1, 'category.id'=>1 }],
            [{ created_on=>1, m=>1 }],
            [{ name_category=>1 }],
            [{ 'category.id'=>1, 'category_status.id'=>1, 'category_status.type'=>1 }],
            [{ '_project_security.project'=>1, 'category.id'=>1 }],
            [{ '_project_security.area'=>1, 'category.id'=>1 }],
            [{ '_project_security'=>1, category_name=>1 }],
            [{ '_project_security'=>1, 'category.id'=>1, 'category_status.type'=>1 }],
            [{ '_sort.numcomment'=>1, _project_security=>1, category_status=>1, 'category.id'=>1 }],
            [{'$**'=> "text"},{ background=>1 }],
        ],
        topic_image => [
            [{ id_hash => 1 }],
        ],
        'fs.files' => [
            'db.fs.files.ensureIndex({ topic_mid: 1 })',
            'db.fs.files.ensureIndex({ parent_mid: 1 })',
        ],
    };
    
    my $index_hash = sub{
        my $idx = shift;
        for my $cn ( keys %{ $idx || {} } ) {
            next if defined $collection && $cn ne $collection;
            Util->_log( "Indexing collection: $cn..." );
            my $coll = $self->collection($cn);
            if( $p{drop} && $cn ne 'fs.files' ) {
                Util->_info('Dropping indexes first.');
                $self->$cn->drop_indexes;
            }
            for my $ix ( @{ $idx->{$cn} } ) {
                my $json = ref $ix ? Util->_encode_json($ix) : $ix;
                try {
                    if( ref $ix eq 'ARRAY' ) {
                        _log "ENSURING $cn INDEX: $json";
                        $coll->ensure_index( @$ix );
                    } else {
                        _log _loc 'Eval collection %1 index %2', $cn, $ix;
                        mdb->db->eval($ix); 
                    }
                } catch {
                    my $err = shift;
                    _error(_loc('Error indexing collection %1 (index: %2): %3', $cn, $json, $err ));
                };
            }
        }
    };
    
    $index_hash->($base_indexes);
    
    # load list from files
    my @from_files = 
        grep /\.yml$/,
        map { $_->children }
        grep { -d } map { $_->path_to('etc','index') } Clarive->features->list_and_home;
     
    for my $f ( @from_files ) {
        my $i = Util->_load( ''.$f->slurp );
        Util->_log( "Processing index file $f" );
        $index_hash->($i);
    }
}

sub migra {
    my ($self,%p)=@_;
    require Baseliner::Schema::Migra::MongoMigration;
    return 'Baseliner::Schema::Migra::MongoMigration::Wrap';
}

sub ixhash {
    my $self = shift;
    Util->_ixhash( @_ );
}

sub true {
   +{ '$nin'=>[undef,'','0',0] }; 
}

sub false {
   +{ '$in'=>[undef,'','0',0] }; 
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

sub disconnect {
    $Clarive::_mdb = undef;
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
    
Possible queries:
   
    term
    "term"  - case insensitive
    Term  - case insensitive
    T?rm  - match 1 char in ?
    T*rm  - match 0 to many chars in *
    /term regex.*/  - regex
    +term1 +term2  - AND query
    +term1 -term2  - AND + NOT query

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
    $p{query} = Encode::encode('UTF-8',$p{query});
    @terms = grep { defined($_) && length($_) } Util->split_with_quotes($p{query});  
    my @terms_normal = grep(!/^\+|^\-/,@terms);
    my @terms_plus = grep(/^\+/,@terms);
    my @terms_minus = grep(/^\-/,@terms);
    my $re_gen = sub{
        my ($term,$is_re,$insensitive)=@_;
        if( !$is_re && $term=~/[\*\?]/ ) {
            # we're not regex, but have * or ? in term, turn into regex
            $is_re = 1;
            $term =~ s{\*}{.*}g;
            $term =~ s{\?}{.}g;
        }
        return $insensitive 
            ? ( $is_re ? qr/$term/i : qr/\Q$term\E/i )
            : ( $is_re ? qr/$term/ : qr/\Q$term\E/ );
    };
    my $all_or_one = sub {
        my $term = shift;
        my $insensitive = 1;
        my $is_re = 0;
        if( $term =~ /^([^:]+):(.+)$/ ) {
            my ($k,$v) = ($1,$2);
            $is_re = 1 if $v =~ s{^/(.*)/$}{$1};
            $insensitive = 0 if $v=~/[A-Z]/;
            $insensitive = 0 if $v =~ s/^"(.*)"$/$1/ && !$is_re;
            return ($v,$is_re,$insensitive,$k);
        } else {
            $is_re = 1 if $term =~ s{^/(.*)/$}{$1};
            $insensitive = 0 if $term=~/[A-Z]/;
            $insensitive = 0 if $term =~ s/^"(.*)"$/$1/ && !$is_re;
            return ($term,$is_re,$insensitive,@_);
        }
    };
    my @ors = map {
        my ($term,$is_re,$insensitive,@term_fields) = $all_or_one->($_,@fields);
        map {
            +{ $_ => $re_gen->($term,$is_re,$insensitive) }
        } @term_fields;
    } @terms_normal;
    my @wh_and = (
        ( @ors ? {'$or' => \@ors} : () ),
        ( @terms_plus ? { '$and'=>[ map { my $v=substr($_,1); ($v,my $is_re,my $insensitive,@fields)=$all_or_one->($v,@fields); 
                { '$or'=>[map { +{$_ => $re_gen->($v,$is_re,$insensitive) } } @fields] } } @terms_plus ]} : () 
        ),
        ( @terms_minus ? { '$and'=>[ map { my $v=substr($_,1); ($v,my $is_re,my $insensitive,@fields)=$all_or_one->($v,@fields); 
                { '$and'=>[map { +{$_ => {'$not' => $re_gen->($v,$is_re,$insensitive) } } } @fields] } } @terms_minus ]} : () 
        ),
    );
    $where->{'$and'} = \@wh_and if @wh_and;
    return $where;
}

=head2 txn

Simulated transaction in Mongo. 

1) insert a _tx with any insert, keep track of collections
2) update, brings the updated equivalent of the older doc into mdb->_txn() 
3) insert a _tx id with every update / insert 

=cut
sub txn {
    my ($self,$code) =@_;
    local $mdb::_tx = Util->_md5;
    $code->($mdb::_tx );
}

our $AUTOLOAD;
our $TRACE_DB = $ENV{CLARIVE_TRACE} =~ /db/;

sub AUTOLOAD {
    my $self = shift;
    my $collname = ( split /::/, $AUTOLOAD )[-1];
    Util->_fail('The method is `joins` not `join`') if $collname eq 'join';
    #Util->_debug( "TRACE: $coll: ". join('; ',caller) ) if $ENV{CLARIVE_TRACE};
    my $coll = $self->collection($collname);
    return $TRACE_DB
          ? bless { orig=>$self, coll=>$coll, collname=>$collname } => 'Baseliner::Mongo::TraceCollecion'
          : $coll; 
}

sub trace_results {
    my ($class,$callstr,$elapsed,$caller)=@_;
    state %counts;
    my $ela = sprintf "%0.6fs", $elapsed;
    my $ler = sprintf "%s:%s", @{ $caller || [ caller(1) ] }[1..2];
    my $high = '!' x int( $elapsed / .001 );
    my $cnt = ++$counts{ $callstr };
    return unless $ENV{CLARIVE_TRACE}!~/(\d+)ms/ || ($1/1000)<$elapsed;
    return unless $ENV{CLARIVE_TRACE}!~/(\d+)cnt/ || ($1<$cnt);
    Util->_debug( "TRACE: $ler\n\n  $callstr\n\n  $ela ELAPSED". ($cnt>1 ? ", $cnt CNT" : '' ) . " $high\n" );
    Util->_debug( "STACK: " . Util->_whereami ) if $ENV{CLARIVE_TRACE} =~ /stack|all/;
}

package Baseliner::Mongo::TraceCollecion {
    use strict;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $meth = ( split /::/, $AUTOLOAD )[-1];
        my $collname = $self->{coll}->name;
        my $callstr ='';
        if( $ENV{CLARIVE_TRACE}=~/db|all/ && $meth ne 'DESTROY' && ( $ENV{CLARIVE_TRACE}!~/cache/ && $collname ne 'cache' ) ) {
            require Data::Dumper;
            my $d = Data::Dumper->new(\@_);
            $d->Indent(0)->Purity(1)->Quotekeys(0)->Terse(1)->Deepcopy(1);
            my $dump = join ',', $d->Dump;
            #Util->_debug( "TRACE $collname->$meth:" . Util->_dump(\@_) );
            $callstr = "mdb->$collname->$meth($dump)";
        }
        my $t0=[Time::HiRes::gettimeofday];
        my @ret = $self->{coll}->$meth(@_);
        my $elapsed = Time::HiRes::tv_interval( $t0 );
        if( @ret == 1 ) {
            my $ret = $ret[0]; 
            if( ref($ret) =~ /MongoDB::Cursor|Baseliner::MongoCursor/ ) {
                # find()
                return bless { cur=>$ret, collname=>$collname, callstr=>$callstr } => 'Baseliner::Mongo::TraceCursor';
            } elsif( $meth ne 'DESTROY' && $collname ne 'cache' ) {
                # find_one(), update, find_and_modify, etc
                Baseliner::Mongo->trace_results($callstr,$elapsed,[caller(0)]);
            }
            return $ret; 
        } elsif( @ret>1 && ($ENV{CLARIVE_TRACE}!~/cache/ && $collname ne 'cache') ) {
            Baseliner::Mongo->trace_results("$callstr",$elapsed,[caller(0)]);
            return @ret;
        } else {
            return @ret;
        }
    }
}

package Baseliner::Mongo::TraceCursor {
    use strict;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $meth = ( split /::/, $AUTOLOAD )[-1];
        my $t0=[Time::HiRes::gettimeofday];
        my @ret = $self->{cur}->$meth(@_);
        my $elapsed = Time::HiRes::tv_interval( $t0 );
        my $callstr = $self->{callstr};
        my $collname = $self->{collname};
        if( ( $meth=~/all|count|next/ 
                && ($ENV{CLARIVE_TRACE}!~/cache/ && $collname ne 'cache') 
            ) || $ENV{CLARIVE_TRACE}=~/all/ ) {
            Baseliner::Mongo->trace_results("$callstr->$meth()",$elapsed,[caller(0)]);
        } else {
            my $ret = $ret[0]; 
            if( ref($ret) =~ /MongoDB::Cursor|Baseliner::MongoCursor/ ) {
                my $d = Data::Dumper->new(\@_);
                $d->Indent(0)->Purity(1)->Quotekeys(0)->Terse(1)->Deepcopy(1);
                my $dump = join ',', $d->Dump;
                return bless { cur=>$ret, collname=>$collname, callstr=>$self->{callstr}."->$meth($dump)" } => 'Baseliner::Mongo::TraceCursor';
            }
        }
        return wantarray ? @ret : $ret[0];
    }
}

1;
