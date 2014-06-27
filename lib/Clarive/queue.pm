# queue : worker queue
package queue;
use strict;
our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my ($method) = reverse( split( /::/, $name ) );
    my $queue = $Baseliner::_queue // (
        $Baseliner::_queue = do {
            require Baseliner::Queue;
            Baseliner::Queue->new;
            }
    );
    $method = 'Baseliner::Queue::' . $method;
    @_ = ( $queue, @_ );
    goto &$method;
}
1;
