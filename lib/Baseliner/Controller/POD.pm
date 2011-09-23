package Baseliner::Controller::POD;
use base 'Catalyst::Controller::POD';

__PACKAGE__->config(
    inc        => 1,
    namespaces => [qw(Baseliner::* BaselinerX::*)],
    self       => 1,
    dirs       => [ "".Baseliner->path_to('.') ],
);
__PACKAGE__->meta->make_immutable( inline_constructor=>0 );

1;
