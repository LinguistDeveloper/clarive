package Baseliner::Model::KV;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;
=head1 NAME

Baseliner::Model::KV - Key-Value store based on bali_repo

=cut

sub set {
    my $self = shift;
    my $p    = _parameters(@_);
    $p->{data} or _throw "Missing parameter 'data'";
    $p->{provider} ||= delete $p->{domain};
    $p->{ns} || $p->{provider} or _throw "Missing either 'ns' or 'provider'";
    my ( $package, ) = caller();
    my $ns           = $p->{ns} || $p->{provider} . '/' . _clsid() ;
    my $data         = $p->{data};
    my ( $domain, $item ) = ns_split($ns);
	my $now = _dt();
    my $row = Baseliner->model('Baseliner::BaliRepo')->update_or_create(
        {
            ns       => $ns,
			item     => $p->{item} || $item,
            provider => $domain || $package,
			ts       => $now, #\'sysdate',
            class    => $package
        }
    );
    $row->update;
    $row->kv( data=>$data, add=>$p->{add}, search=>$p->{search}, select=>$p->{select} ) if $data;
    return $row;
}

sub _clsid {
    my $key = join'',$$,int(rand(99999999999)), _dt() ;
    $key =~ s{[^0-9]}{}g;
    return $key;
}

sub get {
    my $self = shift;
    my $p    = _parameters(@_);
    $p->{ns} || $p->{provider} or _throw "Missing either 'ns' or 'provider'";
    my $row = $self->record( %$p );
	return undef unless ref $row;
    return $row->load_kv( %$p );
}

sub find {
    my ($self,%p) = @_;
    my $keys = delete $p{keys};
    my $args = {};
    $args->{prefetch} = ['keys'] if $keys;
    my $rs = Baseliner->model('Baseliner::BaliRepo')->search( \%p, $args );
    return wantarray ? do { rs_hashref( $rs ); $rs->all } : $rs;
}

sub find_one {
    my ($self,%p) = @_;
    my $rs = $self->find( %p );
    wantarray and rs_hashref( $rs );
    return $rs->first;
}


# returns the top row for a given provider
sub top {
    my $self = shift;
    my $p    = _parameters(@_);
    my ( $package, ) = caller();
    return Baseliner->model('Baseliner::BaliRepo')->search(
        { provider => $p->{domain}||$p->{provider} || $package, },
		{ order_by => 'ts desc' },
    )->first;
}

sub all {
	my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/provider/ );
    my $args = { order_by => 'ns' };
    $args->{select} = $p->{select} if defined $p->{select};
	my $rr = Baseliner->model('Baseliner::BaliRepo')->search( { provider=>$p->{provider} }, $args );
	rs_hashref( $rr );
    return map {
        $_->{data} = $_->kv;
        $_
    } $rr->all;
}

sub item_hash {
	my $self = shift;
	my @all = $self->all( @_ );
	my %hash = map { $_->{item} => $_->{data} } @all ;
	return %hash;
}

sub delete_all {
	my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/provider/ );
    my $rs = Baseliner->model('Baseliner::BaliRepo')->search( { provider=>$p->{provider} } );
	while( my $row = $rs->next ) {
		$row->delete;
	}
}

sub bulk_replace {
	my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/provider data/ );
    my %data = %{ $p->{data} || {} };
    return unless keys %data;
    # delete and update in one transaction
    Baseliner->model('Baseliner')->txn_do(sub{
        $self->delete_all( provider=>$p->{provider} );
        for my $ns ( keys %data ) {
            $self->set( ns=>$ns, provider=>$p->{provider}, data=>$data{$ns} );   
        }
    });
}

sub delete {
	my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/ns/ );
    my $r = Baseliner->model('Baseliner::BaliRepo')->search( { ns=>$p->{ns} } );
	$r->delete if ref $r;
    unless( $p->{keep_relations} ) {
        Baseliner->model('Relationships')->delete( from=>$p->{ns} );
        Baseliner->model('Relationships')->delete( to=>$p->{ns} );
    }
}

sub list {
	my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/provider/ );
    my $rs = Baseliner->model('Baseliner::BaliRepo')->search( { provider=>$p->{provider} });
	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
	my @ns;
	while( my $row = $rs->next ) {
		push @ns, $row->{ns};
	}
	return @ns;
}

sub search {
	my $self = shift;
    return Baseliner->model('Baseliner::BaliRepo')->search( @_ );
}

sub record {
    my $self = shift;
    my $p    = _parameters(@_);
    my $row = Baseliner->model('Baseliner::BaliRepo')->find( $p->{ns} );
	_debug 'Not found: ' . $p->{ns} unless ref $row;
	return undef unless ref $row;
	$row->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return $row;
}

=head1 DESCRIPTION

Store NS data locally.

	my $repo = Baseliner->model('KV');

	$repo->set( ns=>'package/P123', data=> { ... } );

	$repo->set( backend=>'fich_backup', ns=>'package/P123', data=> { ... } );

	my $data = $repo->get( backend=>'fich_backup', ns=>'package/P123' );

=cut

1;

