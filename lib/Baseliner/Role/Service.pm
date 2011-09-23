package Baseliner::Role::Service;
use Moose::Role;

has 'log' => (
    is      => 'rw',
    does    => 'Baseliner::Role::Logger',
	default=>sub {
		require Baseliner::Core::Logger::Base;
		return Baseliner::Core::Logger::Base->new();
	}
);

1;
