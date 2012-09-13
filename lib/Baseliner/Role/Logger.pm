package Baseliner::Role::Logger;
use Moose::Role;
use Baseliner::Utils;
use Carp;

{
    package Baseliner::Core::LogEntry;
    use Moose;
    has 'msg'   => ( is=>'rw', isa=>'Str', default=>'' );
    has 'level' => ( is=>'rw', isa=>'Str', default=>'info' );
}

# unique logger id
has 'id' => ( is=>'rw', isa=>'Int', default=>0 );

# return code
has 'rc' => ( is=>'rw', isa=>'Int' );

# concatenated messages
has 'data' => ( is=>'rw', isa=>'Any', default=>sub{{}} );

# concatenated messages
has 'msg' => ( is=>'rw', isa=>'Any', default=>'' );

# debug mode
has 'verbose' => ( is=>'rw', isa=>'Bool', default=>0 );

# fatal function
has 'fatal_method' => ( is=>'rw', isa=>'Any', default=>'Carp::confess'  );

# fatal callback sub
has 'fatal_callback' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {
        my $self   = shift;
        my $method = $self->fatal_method;
        no strict;
        local $Carp::CarpLevel = _find_level;
        &$method(@_);
    } }
);

# also print
has 'quiet' => ( is=>'rw', isa=>'Bool', default=>0 );

# list of messages
has 'roll' => ( is=>'rw', isa=>'ArrayRef[Baseliner::Core::LogEntry]', );

requires 'info';
requires 'warn';
requires 'debug';
requires 'error';

#requires 'last_message';

1;

