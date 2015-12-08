package BaselinerX::CI::TestGrandParent;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI';

has_ci 'son';

sub icon {'grand_parent_icon'}

sub rel_type {
    {
        son => [ from_mid => 'child_grandad' ],
    }
}

1;

