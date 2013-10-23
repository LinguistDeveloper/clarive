package BaselinerX::CI::dbi_connection;
use Baseliner::Moose;
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::CI::DatabaseConnection';

has_ci 'server';
has data_source => qw(is rw isa Any);
has user        => qw(is rw isa Any);
has password    => qw(is rw isa Any);
has options     => qw(is rw isa Any), default=>sub{ +{} };

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

sub connect {
	my ( $self ) = @_;
    Util->_fail( 'Missing server attribute' ) unless $self->server;
    return $self->_connection if ref $self->_connection;
    require DBIx::Simple;
    my $conn = DBIx::Simple->connect( $self->data_source_parsed, $self->user, $self->password, $self->options );
    $self->_connection( $conn );
    return $conn; 
}

sub data_source_parsed {
    my ($self)=@_;
    return Util->parse_vars( $self->data_source, +{ host=>$self->server->hostname, %$self } );
}

sub ping {
	my ( $self ) = @_;
    my $db = $self->connect;
	return 'connected';
};

sub begin_work { $_[0]->connect->begin_work }
sub commit { $_[0]->connect->commit }
sub rollback { $_[0]->connect->rollback }

sub dosql {
	my ( $self, %p ) = @_;
    my $db = $self->connect;
    my $dbh = $db->dbh;
    my $split = $p{split};
    my @queries;
    for my $sql ( _array( $p{sql} ) ) {
        my @stmts = $p{split} ?  split( $p{split}, $sql) : ($sql);
        for my $st ( @stmts ) {
            my $ret = try {
                $dbh->func( 1000000, 'dbms_output_enable' );
                if( $p{mode} eq 'exec' ) {
                    _debug "Running sql $st against the database (mode $p{mode})", $st;
                    $db->query( q{BEGIN EXECUTE IMMEDIATE(?); END;}, $st );
                } elsif( $p{mode} eq 'plsql' ) {
                    $st = qq{begin\n$st;\nend;};
                    _debug "Running sql $st against the database (mode $p{mode})", $st;
                    $dbh->do( $st ); 
                } else {
                    _debug "Running sql $st against the database (mode $p{mode})", $st;
                    $dbh->do( $st ); 
                }
                my @ret = $dbh->func( 'dbms_output_get' );
                { sql=>$st, rc=>0, err=>'', ret=>join('', @ret) };
            } catch {
                my $err = shift;
                _fail _loc 'Database error: %1', $db->error unless $p{ignore};
                { sql=>$st, rc=>1, err=>$db->error, catch=>$err, ret=>'' };
            };
            push @queries, $ret;
        }
    }
    return { queries=>\@queries };
}

1;

