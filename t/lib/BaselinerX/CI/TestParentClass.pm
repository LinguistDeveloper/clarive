package BaselinerX::CI::TestParentClass;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI';

has_ci 'the_kid';
has_ci 'grandad';
has_cis 'kids';

sub icon {'parent_class_icon'}

sub rel_type {
    {
        kids    => [ from_mid => 'parent_kids' ],
        the_kid => [ from_mid => 'parent_kid' ],
        grandad => [ to_mid => 'child_grandad' ],
    }
}

1;
