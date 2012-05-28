package Baseliner::Sugar;

=head1 NAME

Baseliner::Sugar - sweet stuff

=head1 DESCRIPTION

Some convenient sugar to over called methods.

=cut 

use strict;
use Try::Tiny;
use Exporter::Tidy default => [qw/
    config_store
    config_get
    bali_rs
    repo
    kv
    relation
    user_get
    ns_get
    set_job
    set_logger
    log_info
    log_debug
    log_warn
    log_error
    lifecycle
    master_new
    master_rel
    event_new
    events_by_key
    events_by_mid
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

sub lifecycle { Baseliner->model('LCModel')->lc }

# job dsl

our $job;
sub set_job { $__PACKAGE__::job = shift }
sub set_logger { $job->logger( @_ ) }
sub log_info { $job->log->info( @_ ) }
sub log_debug { $job->log->debug( @_ ) }
sub log_error { $job->log->error( @_ ) }
sub log_warn { $job->log->warn( @_ ) }

sub log_section {}

=head2 master_new

Creates a master row, then your row by calling your code,
all within a transaction.

Usage:

    master_new 'bali_topic' => sub {
       my $mid = shift;
       ...
    };

Or:

    master_new 'something' => {  yada=>1234, etc=>'...' };

=cut
sub master_new {
    my ($collection, $code ) =@_;
    if( ref $code eq 'HASH' ) {
        my $master = Baseliner->model('Baseliner::BaliMaster')
            ->create( { collection => $collection, yaml => Baseliner::Utils::_dump($code) } );
        return $master;
    } elsif( ref $code eq 'CODE' ) {
        my $ret;
        Baseliner->model('Baseliner')->txn_do(sub{
            my $master = Baseliner->model('Baseliner::BaliMaster')->create({
                collection => $collection,
            });
            $ret = $code->( $master->mid, $master );
        });
        return $ret;
    } else {
        _throw 'Invalid master_new syntax';
    }
}

sub master_rel {
    my ($from, $to, $rel_type ) =@_;
    if( defined $from && defined $to ) {
        my $p = { from_mid=>$from, to_mid=>$to };
        if( defined $rel_type ) {  # just one row
            $p->{rel_type} = $rel_type;
            return Baseliner->model('Baseliner::BaliMasterRel')->search($p)->first;
        } else {   # all relations in an Array
            return Baseliner->model('Baseliner::BaliMasterRel')->search($p)->all;
        }
    } else {
        return Baseliner->model('Baseliner::BaliMasterRel');
    }
}

sub event_new {
    my ($key, $data, $code ) =@_;
    $data ||= {};
    _throw 'event_new is missing mid parameter' unless length $data->{mid};
    my $event_create = sub {
        Baseliner->model('Baseliner::BaliEvent')->create({ event_key=>$key, event_data=>_dump( $data ), mid=>$data->{mid}, username=>$data->{username} });
    };
    if( ref $code eq 'CODE' ) {
        try {
            $code->( $data );
            $event_create->();
        };  # no event if fails
    } else {
        $event_create->();
    }
}

sub events_by_key {
    my ($key, $args ) = @_;
    my $evs_rs = Baseliner->model('Baseliner::BaliEvent')->search({ event_key=>$key }, { order_by=>{ '-desc' => 'ts' } });
    rs_hashref( $evs_rs );
    return [ map { 
        # merge 2 hashes
        my $d = { %$_ , %{ _load( $_->{event_data} ) } };
        $d; 
    } $evs_rs->all ];
}

sub events_by_mid {
    my ($mid, $args ) = @_;
    my $evs_rs = Baseliner->model('Baseliner::BaliEvent')->search({ mid=>$mid }, { order_by=>{ '-desc' => 'ts' } });
    rs_hashref( $evs_rs );
    return [ map { 
        # merge 2 hashes
        my $d = { %$_ , %{ _load( $_->{event_data} ) } };
        try {
            my $ev = Baseliner->model('Registry')->get( $d->{event_key} ); # this throws an exception if key not found
            $d->{text} = $ev->event_text( $d );
        };  
        $d; 
    } $evs_rs->all ];
}

1;
