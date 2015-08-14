package Baseliner::Sugar;

=head1 NAME

Baseliner::Sugar - sweet stuff

=head1 DESCRIPTION

Some convenient sugar to over called methods.

=cut 

use strict;
use Try::Tiny;
use Baseliner::Utils;
use Baseliner::Model::Events;
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
    event_new
    master_new
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
    my $mid = $master_data->{mid};  # user supplied mid? ok. 
    if( ref $code eq 'HASH' ) {
        my $ci = $class->new( %$master_data, %$code );
        return $ci->save;
        #return $class->save( %$master_data, data=>$code );   # this returns a mid
    } elsif( ref $code eq 'CODE' ) {
        return try {
            my $ret;
            # txn begin
            my $ci = $class->new( %$master_data );
            $ci->save;
            $mid = $ci->mid;
            ################################# 
            $ret = $code->( $mid );
            ################################# 
            # txn commit
            return $ret;
        } catch {
            my $e = shift; 
            ci->delete( $mid ) if length $mid;
            # txn rollback
            _throw $e;
        };
    } else {
        _throw 'Invalid master_new syntax';
    }
}

sub event_new { Baseliner::Model::Events->new_event(@_, caller) }

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
