package BaselinerX::CI::dbi_connection;
use Baseliner::Moose;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::CI::DatabaseConnection';

has_ci 'server';
has data_source => qw(is rw isa Any);
has connect_str => qw(is rw isa Any);
has driver      => qw(is rw isa Any);
has user        => qw(is rw isa Any);
has password    => qw(is rw isa Any);
has timeout     => qw(is rw isa Any);
has envvars     => qw(is rw isa HashRef), default=>sub{ +{} };
has parameters  => qw(is rw isa Any), default=>sub{ +{} };

has _connection => qw(is rw isa Any);

sub rel_type { { server=>[ from_mid => 'database_server' ] } }

sub error {}
sub rc {}
service ping => {
    name    => 'Ping',
    handler => sub {
        my ( $self ) = @_;
        $self->ping;
    }
};

sub gen_data_source {
    my ($self)=@_;
    return $self->data_source if length $self->data_source;
    return length $self->all_vars->{sid}
        ? 'dbi:Oracle:host=${host};sid=${sid};port=${port}'
        : 'dbi:Oracle:host=${host};service_name=${service_name};port=${port}';
};

sub connect {
	my ( $self ) = @_;
    Util->_fail( 'Missing server attribute' ) unless $self->server;
    my $tmout = $self->timeout;
    return $self->_connection if ref $self->_connection;
    my $conn;
    local $SIG{ALRM} = sub { _fail _loc 'timeout connecting to database %1 (timeout=%2)', $self->name, $tmout } if $tmout;
    if( $tmout ) {
        alarm $tmout;
    }
    $conn = DBI->connect( $self->data_source_parsed, $self->user, $self->password, $self->parameters);
    if( $tmout ) {
        alarm 0;
    }
    $self->_connection( $conn );
    return $conn; 
}

sub dbis {
    my ($self)=@_;
    require DBIx::Simple;
    return DBIx::Simple->connect( $self->connect );
}

sub all_vars {
    my ($self)=@_;
    return {
        host=>$self->server->hostname, 
        %$self, 
        %{ $self->parameters || {} }, 
    };
}

sub gen_connect_str {
    my($self)=@_;
    return Util->parse_vars( $self->connect_str, $self->all_vars ) if length $self->connect_str;
    my $vars = $self->all_vars;
    # TODO depends on driver
    my $str = length $vars->{sid} 
        ? q{${user}/${password}@//${sid}} 
        : q{${user}/${password}@//${host}:${port}/${service_name}};
    $str = Util->parse_vars( $str, $self->all_vars );
}

sub list_drivers {
    { data=>[ map { +{driver => $_} } DBI->available_drivers ] }
}

sub data_source_parsed {
    my ($self)=@_;
    return Util->parse_vars( $self->gen_data_source, $self->all_vars );
}

sub ping {
	my ( $self ) = @_;
    my $db = $self->connect;
	return 'connected';
};

sub begin_work { my $dbh = $_[0]->connect; $dbh->begin_work if $dbh->{AutoCommit} }
sub commit     { $_[0]->connect->commit }
sub rollback   { $_[0]->connect->rollback }

method dosql( :$sql, :$comment='strip', :$split_mode='auto', :$split=';', :$mode='direct', :$exists_action='drop', :$error_mode='fail' ) {
    #my ( $self, %p ) = @_;
    my %ENV_ORIG = %ENV;
    for my $env_key ( keys %{ $self->envvars || {} } ) {
        my $v = $self->envvars->{ $env_key };
        next if ref $v;
        $ENV{ $env_key } = $v;
    }
    my $dbh = $self->connect;
    Util->_fail( Util->_loc('Could not connect to database %1', $self->name || $self->data_source_parsed ) ) unless ref $dbh;
    my @queries;
    $dbh->func( 1000000, 'dbms_output_enable' );
    SQL: for my $sql ( _array( $sql ) ) {
        # comments?
        $sql =~ s{--[^\n]*\r?\n}{\n}sg if $comment eq 'strip';
        
        my @stmts = $split_mode eq 'none' ? ($sql)
            # auto = split on ; but not if its inside quotes '',"" - may be in comment, better if used with "strip"
            : $split_mode eq 'auto' ? split( /;(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/, $sql)  
            # manual - user defined split
            : split( $split, ($sql) );
        STMT: for my $st ( @stmts ) {
            next if $st =~ /^\s*$/;  # empty ? 
            my (@drops,@skips);
            if( $exists_action eq 'drop' ) {
                @drops =  $self->gen_drop( $st );
                for my $st_drop ( @drops ) {
                    _log "Running Drop Statement: $st_drop";
                    try { $dbh->do( $st_drop ); }
                    catch { _error "AUTO DROP failed, but ignored.", shift() };
                }
            } elsif( $exists_action =~ /skip|ignore/ ) {
                @skips =  $self->gen_drop( $st );
                if( @skips ) {
                    _log "SQL OBJECT ALREADY EXISTS (action: $exists_action): $st";
                    next STMT if $exists_action eq 'skip';
                }
            } elsif( $exists_action eq 'fail' ) {
                @skips =  $self->gen_drop( $st );
                if( @skips ) {
                    _fail "SQL OBJECT ALREADY EXISTS (action: fail): $st"
                }
            }
            my $ret = try {
                if( $mode eq 'execute' ) {
                    _debug "Running sql $st against the database (mode execute)", $st;
                    $dbh->do( q{BEGIN EXECUTE IMMEDIATE(?); END;}, undef, $st );
                } elsif( $mode eq 'block' ) {
                    $st = qq{begin\n$st;\nend;};
                    _debug "Running sql $st against the database (mode block)", $st;
                    $dbh->do( $st ); 
                } else {  # mode direct
                    _debug "Running sql $st against the database (mode direct)", $st;
                    $dbh->do( $st ); 
                }
                my @ret = $dbh->func( 'dbms_output_get' );
                { sql=>$st, rc=>0, err=>'', ret=>join('', @ret), catch=>'', skips=>join("\n",@skips), drops=>join("\n",@drops), mode=>$mode };
            } catch {
                my $err = shift;
                my @ret = $dbh->func( 'dbms_output_get' );
                %ENV = %ENV_ORIG;
                my $msg = _loc( 'Database error: %1 %2', $dbh->errstr, $err );
                my @errlog = ( $msg, "SQL:\n$st\n\n$msg\n\n" . join('',@ret) );
                _log( @errlog );
                { sql=>$st, rc=>1, err=>$dbh->errstr, catch=>$err, ret=>join('', @ret), skips=>join("\n",@skips), drops=>join("\n",@drops), mode=>$mode };
            };
            push @queries, $ret;
            # maybe stop due to an error, the rest (skip,ignore,warn) will be taken care of later
            if( $error_mode eq 'error' && $ret->{rc} ) {
                _debug( _loc('Stopping SQL execution due to an error') );
                last SQL;
            }
        }
    }
    %ENV = %ENV_ORIG;
    return { queries=>\@queries };
}

sub gen_drop {
    my ( $self, $st ) = @_;
    my @drops;
    my $db= $self->connect;
    my $dbis = $self->dbis;
    my $obj_types = join( '|',
        'CONSUMER GROUP', 'INDEX PARTITION', 'SEQUENCE',  'SCHEDULE',           'TABLE PARTITION',
        'RULE',           'JAVA DATA',       'PROCEDURE', 'OPERATOR',           'WINDOW',
        'PACKAGE',        'PACKAGE BODY',    'LIBRARY',   'RULE SET',           'PROGRAM',
        'LOB',            'TYPE BODY',       'CONTEXT',   'JAVA RESOURCE',      'XML SCHEMA',
        'TRIGGER',        'JOB CLASS',       'DIRECTORY', 'TABLE',              'INDEX',
        'SYNONYM',        'VIEW',            'FUNCTION',  'WINDOW GROUP',       'JAVA CLASS',
        'INDEXTYPE',      'CLUSTER',         'TYPE',      'EVALUATION CONTEXT', 'JOB' );

    while ( $st =~ m{CREATE\s+($obj_types)\s+([\w\.]+)}gi ) {
        my ( $type, $obj ) = ( $1, $2 );
        $obj =~ s{'|"}{}g;
        my ( $sch, $name ) = split /\./, $obj;
        if ( !$name ) {
            $name = $sch;
            $sch  = $self->user;
        }
        _debug( "SQL drop checking $sch.$name" );

        # check if object exists
        my $cnt = $dbis->query( 
            'select count(*) from all_objects where object_name=? and object_type=? and owner=?',
            uc $name, uc $type, uc $sch )->list;
        if ( $cnt > 0 ) {
            push @drops, qq{DROP $type $obj};
        }
    }
    return @drops;
}

sub query_from_field {
    my ($self,$p)=@_;
    my $query = $p->{query};
    my $data = Util->hash_flatten($p);
    
    my $meta = ci->topic->get_meta();
    my ($field) = grep { $_->{id_field} eq $p->{id_field} && $_->{id_category} == $data->{'meta.id_category'} } @$meta; 
    my $db= $self->connect;
    my $dbis = $self->dbis;
    my $sql = $field->{sql};
    _warn $data;
    my @placeholders = Util->_array_or_commas( $field->{placeholders} );
    my $rs = $dbis->query($sql, @{$data}{ @placeholders } );
    my @ret;
    @ret = $rs->hashes;
    $db->disconnect;
    
    return { data=>[ @ret ], totalCount=> 1 };
}

1;

