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
#sub ns { Baseliner->model('Repository') }

sub bali_rs { Baseliner->model('Baseliner::Bali' . shift ) }

# sub relation { Baseliner->model('Relationships') }

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
    my $master_data = ref $name eq 'HASH' ? $name : { name=>$name };
    my $class = 'BaselinerX::CI::'.$collection;
    if( ref $code eq 'HASH' ) {
        my $ci = $class->new( %$master_data, %$code );
        return $ci->save;
        #return $class->save( %$master_data, data=>$code );   # this returns a mid
    } elsif( ref $code eq 'CODE' ) {
        return try {
            my $ret;
            Baseliner->model('Baseliner')->schema->txn_begin;
            my $ci = $class->new( %$master_data );
            $ci->save;
            my $mid = $ci->mid;
            #my $mid = $class->save( %$master_data ); 
            $ret = $code->( $mid );
            Baseliner->model('Baseliner')->schema->txn_commit;
            return $ret;
        } catch {
            my $e = shift; 
            Baseliner->model('Baseliner')->schema->txn_rollback;
            _throw $e;
        };
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
    my $module = caller;
    if( ref $data eq 'CODE' ) {
        $code = $data;
        $data = {};
    }
    my @rule_log;
    $data ||= {};
    my $ev = Baseliner->model('Registry')->get( $key ); # this throws an exception if key not found
    my $event_create = sub {
        my ($ed,@event_log) = @_;
        my $ev_id = mdb->seq('event');
        mdb->event->insert({
                id            => $ev_id,
                ts            => mdb->ts,
                event_key     => $key,
                event_data    => _dump($ed),
                event_status  => 'new',
                module        => $module,
                mid           => $ed->{mid},
                username      => $ed->{username}
        });
        for my $log (@event_log) {
            my $log = {
                id         => mdb->seq('event_log'),
                id_event   => $ev_id,
                id_rule    => $log->{id},
                ts         => mdb->ts,
                stash_data => _dump( $log->{ret} ),
                dsl        => $log->{dsl},
                log_output => $log->{output},
            };
            mdb->event_log->insert($log);
        }
    };
    return try {
        require Baseliner::Core::Event;
        my $obj = Baseliner::Core::Event->new( data => $data );
        try {
            if( length $data->{mid} ){
                my $ci = Baseliner::CI->new( $data->{mid} );
                my $ci_data = $ci->load;
                $data = { %$ci_data, ci=>$ci, %$data };
            }else{
                $data = { %$data };    
            }
        } catch {
            _error _loc("Error: Could not instantiate ci data for event: %1", shift() );
        };
        # PRE rules
        my $rules_pre = $ev->rules_pre_online( $data );
        push @rule_log, map { $_->{when} => 'pre-online'; $_ } _array( $rules_pre->{rule_log} );
        # PRE hooks
        for my $hk ( $ev->before_hooks ) {
            my $hk_data = $hk->( $obj );
            $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
            $obj->data( $data );
        }
        if( ref $code eq 'CODE' ) {
            # RUN
            my $rundata = $code->( $data );
            ref $rundata eq 'HASH' and $data = { %$data, %$rundata };
        }
        #if( !length $data->{mid} ) {
        #    _debug 'event_new is missing mid parameter' ;
            #_throw 'event_new is missing mid parameter' ;
        #} else {
        #}
        # POST hooks
        $obj->data( $data );
        for my $hk ( $ev->after_hooks ) {
            my $hk_data = $hk->( $obj );
            $data = { %$data, %$hk_data } if ref $hk_data eq 'HASH';
            $obj->data( $data );
        }
        # POST rules
        my $rules_post = $ev->rules_post_online( $data );
        push @rule_log, map { $_->{when} => 'post-online'; $_ } _array( $rules_post->{rule_log} );

        # create the event on table
        $event_create->( $data, @rule_log ); #if defined $data->{mid};
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
    my $evs_rs = mdb->event->find({ event_key=>$key })->sort({ ts=>-1 });
    return [ map { 
        # merge 2 hashes
        my $d = { %$_ , %{ _load( $_->{event_data} ) } };
        $d; 
    } $evs_rs->all ];
}

sub events_by_mid {
    my ($mid, %p ) = @_;
    my $min_level = $p{min_level} // 0;

    my $cache_key = [ "events:$mid:", \%p ];
    my $cached = Baseliner->cache_get( $cache_key );
    return $cached if $cached;

    my @evs = mdb->event->find({ mid=>"$mid" })->sort({ ts=>-1 })->all;
    my $ret = !@evs ? [] : [
      grep {
         $_->{ev_level} == 0 || $_->{level} >= $min_level;
      }
      map { 
        # merge 2 hashes
        my $event_data = _load( _to_utf8( $_->{event_data} ) );
        delete $event_data->{ts};
        my $d = { %$_ , %$event_data };
        try {
            my $ev = Baseliner->model('Registry')->get( $d->{event_key} ); # this throws an exception if key not found
            $d->{text} = $ev->event_text( $d );
            $d->{ev_level} = $ev->level;
        } catch {
            my $err = shift;
            Util->_error( Util->_loc('Error in event text generator: %1', $err) );
        };  
        $d; 
    } @evs ];

    Baseliner->cache_set( $cache_key, $ret );

    return $ret;
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
