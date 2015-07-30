package BaselinerX::Tools;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

register 'menu.tools' => { label => 'Tools', index=>20 };

no Moose;
__PACKAGE__->meta->make_immutable;

1;


