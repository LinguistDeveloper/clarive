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
    event_new
    event_hook
    /
];

sub mdl {  }

sub config_store { Baseliner->model('ConfigStore') }
sub config_get { Baseliner->model('ConfigStore')->get(@_) }
sub config_value { Baseliner->model('ConfigStore')->get($_[0], value=>1) }

# sub relation { Baseliner->model('Relationships') }

sub ns_get { Baseliner->model('Namespaces')->get(@_) }

sub user_get {
    use Baseliner::Utils;
    my $rs = ci->user->find({ username=>shift })->next;
}

# job dsl

our $job;
sub set_job { $__PACKAGE__::job = shift }
sub set_logger { $job->logger( @_ ) }
sub log_info { $job->log->info( @_ ) }
sub log_debug { $job->log->debug( @_ ) }
sub log_error { $job->log->error( @_ ) }
sub log_warn { $job->log->warn( @_ ) }

sub log_section {}

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
    # mdb->create_capped('event'); # not capped for now
    my $event_create = sub {
        my ($ed,@event_log) = @_;
        my $ev_id = mdb->seq('event');
        # rgo: remember, top mongo doc size is 16MB. #11905 
        # TODO large data should be in the Grid instead
        my $event_data = substr( _dump($ed), 0, 4_096_000 );  # 4MB
        mdb->event->insert({
                id            => $ev_id,
                ts            => mdb->ts,
                t             => mdb->ts_hires,
                event_key     => $key,
                event_data    => $event_data,
                event_status  => 'new',
                module        => $module,
                mid           => $ed->{mid},
                username      => $ed->{username}
        });

        if( _array( $ev->{vars} ) > 0 ) {
            my $ed_reduced={};
            # fix "unhandled" Mongo errors due to unblessed structures
            my $ed_cloned = Util->_clone($ed); 
            Util->_unbless( $ed_cloned );
            foreach (_array $ev->{vars}){
                $ed_reduced->{$_} = $ed_cloned->{$_};
            }
            $ed_reduced->{ts} = mdb->ts;

            mdb->activity->insert({
                vars            => $ed_reduced,
                event_key       => $key,
                event_id        => $ev_id,
                mid             => $ed->{mid},
                module          => $module,
                ts              => mdb->ts,
                username        => $ed->{username},
                text            => $ev->{text},
                ev_level        => $ev->{ev_level},
                level           => $ev->{level}
            });    
        }
        
        for my $log (@event_log) {
            my $stash_data = substr( _dump($log->{ret}), 0, 1_024_000 ); # 1MB
            my $log_output = substr( _dump($log->{output}), 0, 4_096_000 ); # 4MB
            my $dsl = substr( $log->{dsl}, 0, 1_024_000 );
            my $log = {
                id         => mdb->seq('event_log'),
                id_event   => $ev_id,
                id_rule    => $log->{id},
                ts         => mdb->ts,
                t          => mdb->ts_hires,
                stash_data => $stash_data, 
                dsl        => $log->{dsl},
                log_output => $log_output,
            };
            mdb->event_log->insert($log);
        }
    };
    return try {
        require Baseliner::Core::Event;
        my $obj = Baseliner::Core::Event->new( data => $data );
        try {
            if( length $data->{mid} ){
                my $ci = ci->new( $data->{mid} );
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
            _fail $err;
        }
    };
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
