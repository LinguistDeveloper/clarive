package Baseliner::Sugar;

=head1 NAME

Baseliner::Sugar - sweet stuff

=head1 DESCRIPTION

Some convenient sugar to over called methods.

=cut 

use strict;
use Try::Tiny;
use Baseliner::Utils;
use Exporter::Tidy default => [qw/
    config_store
    config_get
    config_value
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
    event_hook
    events_by_key
    events_by_mid
    /
];

sub mdl {  }

sub config_store { Baseliner->model('ConfigStore') }
sub config_get { Baseliner->model('ConfigStore')->get(@_) }
sub config_value { Baseliner->model('ConfigStore')->get($_[0], value=>1) }

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

    master_new 'topic' => 'my_ci_name' => sub {
       my $mid = shift;
       ...
    };

Or:

    master_new 'something' => 'my_ci_name' => {  yada=>1234, etc=>'...' };

=cut
sub master_new {
    my ($collection, $name, $code ) =@_;
    if( ref $code eq 'HASH' ) {
        my $row = { collection => $collection, name => $name, yaml => Baseliner::Utils::_dump($code) };
        $row->{bl} = $code->{bl} if defined $code->{bl};
        my $master = Baseliner->model('Baseliner::BaliMaster')->create( $row );
        return $master;
    } elsif( ref $code eq 'CODE' ) {
        my $ret;
        Baseliner->model('Baseliner')->txn_do(sub{
            my $master = Baseliner->model('Baseliner::BaliMaster')->create({
                collection => $collection, name=> $name
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
    my ($key, $data, $code, $catch ) =@_;
    if( ref $data eq 'CODE' ) {
        $code = $data;
        $data = {};
    }
    $data ||= {};
    my $ev = Baseliner->model('Registry')->get( $key ); # this throws an exception if key not found
    my $event_create = sub {
        my $ed = shift;
        Baseliner->model('Baseliner::BaliEvent')
            ->create( { event_key => $key, event_data => _dump($ed), mid => $ed->{mid}, username => $ed->{username} } );
    };
    return try {
        if( ref $code eq 'CODE' ) {
            require Baseliner::Core::Event;
            my $obj = Baseliner::Core::Event->new( data => $data );
            # PRE
            for my $hk ( $ev->before_hooks ) {
                my $hk_data = $hk->( $obj );
                $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
                $obj->data( $data );
            }
            # RUN
            my $rundata = $code->( $data );
            ref $rundata eq 'HASH' and $data = { %$data, %$rundata };
            if( !length $data->{mid} ) {
                _debug 'event_new is missing mid parameter' ;
                #_throw 'event_new is missing mid parameter' ;
            }
            # POST
            $obj->data( $data );
            for my $hk ( $ev->after_hooks ) {
                my $hk_data = $hk->( $obj );
                $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
                $obj->data( $data );
            }
        }
        # create the event on table
        $event_create->( $data ) if defined $data->{mid};
        return $data; 
    } catch {  # no event if fails
        my $err = shift;
        if( ref $catch eq 'CODE' ) {
            $catch->( $err ) ;
            _error "*** event_new: caught $key: $err";
        } else {
            _error "*** event_new: untrapped $key: $err";
            _throw $err;
        }
    };
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
    my @evs = $evs_rs->all;
    return [] unless @evs;
    return [ map { 
        # merge 2 hashes
        my $d = { %$_ , %{ _load( $_->{event_data} ) } };
        try {
            my $ev = Baseliner->model('Registry')->get( $d->{event_key} ); # this throws an exception if key not found
            $d->{text} = $ev->event_text( $d );
        };  
        $d; 
    } @evs ];
}

=head2 event_hook

Adds hooks to events. 

    event_hook 'event.topic.create' => 'before' => sub {
         ...
    };

=cut
sub event_hook {
    my ( $keys, $when, $code ) = @_;
    if( ref $when eq 'CODE' ) {
        $code = $when;
        $when = 'after';
    }
    my $pkg = caller();
    my @keys = ref $keys eq 'ARRAY' ? @$keys : ($keys);
    my $regs = 'Baseliner::Core::Registry';  # Baseliner->model('Registry') not available on startup
    for my $key ( @keys ) {
        my $regkey = "$key._hooks";
        if( my $hooks = $regs->get_node( $regkey ) ) {
            push @{ $hooks->param->{$when} }, $code;
        } else {
            my $param = { 
                before => [], 
                after  => [],
            };
            push @{ $param->{ $when } }, $code; 
            Baseliner::Core::Registry->add( $pkg || __PACKAGE__, $regkey, $param );
        }
    }
}

1;
