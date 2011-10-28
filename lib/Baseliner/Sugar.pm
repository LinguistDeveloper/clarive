package Baseliner::Sugar;

=head1 NAME

Baseliner::Sugar - sweet stuff

=head1 DESCRIPTION

Some convenient sugar to over called methods.

=cut 

use Exporter::Tidy default => [qw/
    config_store
    config_get
    bali_rs
    repo
    kv
    relation
    user_get
    ns_get
    /
];

sub mdl {  }

sub config_store { Baseliner->model('ConfigStore') }
sub config_get { Baseliner->model('ConfigStore')->get(@_) }

sub repo { Baseliner->model('Repository') }
sub kv { Baseliner->model('KV') }
#sub ns { Baseliner->model('Repository') }

sub bali_rs { Baseliner->model('Baseliner::Bali' . shift ) }

sub relation { Baseliner->model('Relationships') }

sub ns_get { Baseliner->model('Namespaces')->get(@_) }

sub user_get {
    use Baseliner::Utils;
    my $rs = Baseliner->model('Baseliner::BaliUser')->search({ username=>shift });
    rs_hashref( $rs );
    $rs->first;
}

1;
