=head1 Baseliner::Sem

UNIX semaphores.  

This module is useful for online semaphores, because
it won't go to the database.

The number of slots is set to 1 by default. 

    my $sem = Baseliner::Sem->new( key=>'abcde' );
    $sem->take;

    # critical section here

    $sem->release;   # or on $sem destruction, it's released

Set slots:

    my $sem = Baseliner::Sem->new( key=>'abcde' );
    $sem->slots( 5 );

=cut
package Baseliner::Sem;
use Moose;
use Baseliner::Utils;

has key => qw(is rw isa Str required 1);
has sem => qw(is rw isa Any);
has key_tok => qw(is rw isa Any);
has taken => qw(is rw isa Bool default 0);
has slots => qw(is rw isa Num default 1), trigger => sub {
    # changes the number of slots available
    #   WARNING: this will reset the semaphore queue, releasing pending requests
    my ($self, $v )= @_;
    $self->sem->setall( $v );
};

sub BUILD {
    my ($self) = @_;

    # create semaphore if it does not exist
    my $sem = $self->_get_sem();
    $self->sem( $sem );
}

use IPC::SysV qw(IPC_NOWAIT SEM_UNDO IPC_EXCL S_IRWXU IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT ftok);
use IPC::Semaphore;

sub _get_sem {
    my ($self ) = @_;
    require String::CRC32;
    my $key = $self->key_tok // String::CRC32::crc32( $self->key);
    $self->key_tok( $key);
    my $sem = IPC::Semaphore->new( $key, 1, 0666 );
    unless( $sem ) {
        # "SEM is new";
        _debug "SEM CREATING " . $key;
        $sem = IPC::Semaphore->new( $key, 1, 0666 | IPC_CREAT );
        $sem->setall( $self->slots ); # 1 slot
        _fail "semget: $!" unless $sem;
    }
    return $sem;
}

=head2 take

takes a slot. Locks on wait.

=cut
sub take {
    my $self = shift;
    #say "VAL=" . $sem->getval( 0 );
    _debug sprintf "SEM TAKE %s GETVAL %s" , $self->key_tok,  $self->sem->getval( 0 );
    # SEM_UNDO destroys all operations on the semaphore for this pid in case pid exits
    $self->sem->op( 0, -1, SEM_UNDO ) or _fail "sem_take: $!" ; #| IPC_NOWAIT );
    $self->taken( 1 );
}


sub release {
    my $self = shift;
    #say "VAL=" . $sem->getval( 0 );
    _debug sprintf "SEM REL %s GETVAL %s" , $self->key_tok,  $self->sem->getval( 0 );
    if( $self->taken ) {
        $self->sem->op( 0, 1, SEM_UNDO ) or _fail "sem_take: $!" ; #| IPC_NOWAIT );
        $self->taken( 0 );
    }
}

sub DESTROY {
    my $self = shift;
    $self->release if $self->taken;
}


1;
