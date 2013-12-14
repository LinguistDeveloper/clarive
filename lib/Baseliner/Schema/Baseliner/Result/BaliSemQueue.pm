package Baseliner::Schema::Baseliner::Result::BaliSemQueue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("bali_sem_queue");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 0,
    size => 126,
  },
  "sem",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "who",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "who_id",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "host",
  {
    data_type => "VARCHAR2",
    default_value => 'localhost',
    is_nullable => 1,
    size => 255,
  },
  "pid",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "status",
  {
    data_type => "VARCHAR2",
    default_value => 'idle',
    is_nullable => 1,
    size => 50,
  },
  "active",
  { data_type => "NUMBER", default_value => 1, is_nullable => 1, size => 126 },
  "seq",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "id_job",
  {
    data_type => "NUMBER",
    default_value => undef,
    is_nullable => 1,
    size => 126,
  },
  "run_now",
  {
    data_type => "NUMBER",
    default_value => 0,
    is_nullable => 1,
    size => 126,
  },
  "wait_secs",
  {
    data_type => "NUMBER",
    default_value => 0,
    is_nullable => 1,
    size => 126,
  },
  "busy_secs",
  {
    data_type => "NUMBER",
    default_value => 0,
    is_nullable => 1,
    size => 126,
  },
  "ts_request",
  {
    data_type => "DATE",
    default_value => \"sysdate",
    is_nullable => 1,
    size => 19,
  },
  "ts_grant",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "ts_release",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
  "bl",
  {
    data_type => "VARCHAR2",
    default_value => '*',
    is_nullable => 1,
    size => 50,
  },
  "caller",
  {
    data_type => "VARCHAR2",
    default_value => undef,
    is_nullable => 1,
    size => 1024,
  },
  "expire_on",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 19 },
);
__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
   my ($self, $sqlt_table) = @_;
   $sqlt_table->add_index(name =>'bali_sem_queue_idx_host_status', fields=>['host', 'status'] );
}

use Baseliner::Utils;
use namespace::clean;

=head2 wait_for ( frequency=>Int, logger=>Baseliner::Role::Logger, callback=>sub{ ... } )

Waits for a semaphore to be released.

Optional parameters:

    frequency: seconds in-between checks
    logger   : a logger object to receive norifications
    callback : a code block to execute after each sleep period
    timeout  : max time to wait for - error is thrown after timeout
    critical : code block to run when semafore is available
    args     : arguments to the critical section code

=cut
sub wait_for {
    my ($self, %p ) = @_;
    my $sem = $self->sem;
    my $bl = $self->bl;
    my $freq = $p{frequency} || 10;
    my $wait_secs = 0;
    $self->busy_secs( - time );
    $self->update;
    $p{logger}->warn( _loc("Waiting for semaphore %1...", $sem-$bl) ) if defined $p{logger};
    while( 1 ) {
        $self->discard_changes; # reselect the row
        if( $self->status eq 'granted' ) {
            $self->status( 'busy' );
            $self->wait_secs( $wait_secs );
            $self->ts_grant( _now() );
            $self->update;
            $p{logger}->warn( _loc("Semaphore %1 granted", $sem-$bl) ) if defined $p{logger};
            ref( $p{critical} ) eq 'CODE' and $p{critical}->($p{args});
            return $self;
        }
        elsif( $self->status eq 'cancel' ) {
            _throw new Baseliner::Exception::Semaphore::Cancelled( message=>_loc( 'Semaphore %1 cancelled', $sem-$bl ) );
        }
        elsif( $self->run_now ) {
            $self->status( 'done' );
            $self->ts_grant( _now() );
            $self->ts_release( _now() );
            $self->wait_secs( $wait_secs );
            $self->update;
            $p{logger}->warn( _loc("Semaphore %1 skipped", $sem-$bl) ) if defined $p{logger};
            return $self;
        }
        sleep $freq;
        ref($p{callback}) eq 'CODE' and $p{callback}->();
        $wait_secs += $freq;
        defined $p{timeout} and do {
            _throw _loc("Semaphore Timeout") if $p{timeout} < $wait_secs;
        };
    }
}

=head2 release

Release semaphore.

=cut
sub release {
    my $self = shift;
    $self->status('done');
    $self->update;
    $self->busy_secs( time + $self->busy_secs );
    $self->ts_release( _now() );
    $self->update;
}

=head2 next_status

Go to next status in the semaphore workflow.

Erroneuos and broken status not covered

=cut
sub next_status {
    my $self = shift;
    my $statuses = {
        idle    => 'waiting',
        waiting => 'granted',
        granted => 'busy',
        busy    => 'done'
    };
    if( my $next_status = $statuses->{ $self->status } ) {
        $self->status( $next_status );
        $self->update;
    }
}

=head2 DESTROY

Make sure the sem request disappears after it goes out of scope.

Unfortunately, if the status is C<granted>, this check
does not work because the C<discard_changes> method in 
C<wait_for> will trigger a C<DESTROY> everytime. 

=cut
sub DESTROY {
    my $self = shift;
    if( $self->status && $self->status =~ /busy|waiting|idle/ ) {
        $self->release;
        #$self->ts_release( \'sysdate' );
    }
}

1;

