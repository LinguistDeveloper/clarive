package Baseliner::SetupProfile::Base;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

1;
