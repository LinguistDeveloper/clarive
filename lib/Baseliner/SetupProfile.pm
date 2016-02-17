package Baseliner::SetupProfile;
use strict;
use warnings;

use Class::Load qw(load_optional_class);

sub load {
    my $class = shift;
    my ($profile_name) = @_;

    for my $key (keys %{Clarive->config->{baseliner}}) {
        Clarive->config->{$key} = Clarive->config->{baseliner}->{$key};
    }

    my $profile_class = __PACKAGE__ . '::' . $profile_name;
    load_optional_class($profile_class)
      or die "Profile '$profile_name' not found\n";

    return $profile_class->new;
}

1;
