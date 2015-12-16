package BaselinerX::CI::TestParentClass;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI';

has_ci 'the_kid';
has_ci 'grandad';
has_cis 'kids';

has test_attr => qw(is rw isa Str);

sub icon {'parent_class_icon'}

sub unique_keys {
    [ ['test_attr'] ]
}

sub rel_type {
    {
        kids    => [ from_mid => 'parent_kids' ],
        the_kid => [ from_mid => 'parent_kid' ],
        grandad => [ to_mid => 'child_grandad' ],
    }
}

1;
