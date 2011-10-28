package Baseliner::Model::Repository;
use Baseliner::Plug;
extends qw/Catalyst::Model/;
use Baseliner::Utils;

sub set {
    my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/ns data/ );
    my ( $package, ) = caller();
    my $ns           = $p->{ns};
    my $data         = $p->{data};
    my $data_dump    = _dump($data);
    my ( $domain, $item ) = ns_split($ns);
	my $now = _dt();
    my $row = Baseliner->model('Baseliner::BaliRepo')->update_or_create(
        {
            ns       => $ns,
            data     => $data_dump,   #TODO consider merging previous data with new one
			item     => $p->{item} || $item,
            provider => $p->{domain} || $domain || $package,
			ts       => $now, #\'sysdate',
            class    => $package
        }
    );
    $row->update;
    return $row;
}

sub get {
    my $self = shift;
    my $p    = _parameters(@_);
    _check_parameters( $p, qw/ns/ );
    my $row = $self->record( ns=>$p->{ns} );
	return undef unless ref $row;
    return _load( $row->data );
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
	$rr->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return map {
        $_->{data} = _load( $_->{data} );
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
    my $domain = $p->{domain} || $p->{provider};
    _throw 'Missing domain or provider' unless $domain;
    my $rs = Baseliner->model('Baseliner::BaliRepo')->search( { provider=>$domain });
	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
	my @ns;
	while( my $row = $rs->next ) {
		push @ns, $row->{ns};
	}
	return @ns;
}

sub find {
    my ($self,%p) = @_;
    my $keys = delete $p{keys};
    my $args = {};
    $args->{prefetch} = ['keys'] if $keys;
    my $rs = Baseliner->model('Baseliner::BaliRepo')->search( \%p, $args );
    return wantarray ? do { rs_hashref( $rs ); $rs->all } : $rs;
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

Store any data locally.

	my $repo = Baseliner->model('Repository');

	$repo->set( ns=>'package.data/12345', data=> { ... } );

	for my $ns ( $repo->list( provider=>'package.data' ) ) {
        my $data = $repo->get( ns=>$ns );
    }

    $repo->delete( ns=>'package.data/12345' );

    $repo->delete_all( provider=>'package.data' );

    # or with some sugar...

    use Baseliner::Sugar;

    repo->get( ... );
    repo->set( ... );
    repo->list( ... );
    repo->delete( ... );

=cut

1;
