package Baseliner::Role::LC::Node;
use Moose::Role;

requires 'node_id';
requires 'node_url';
requires 'node_menu';

sub serialize {
    my $self = shift;
    my %data = %$self;
    map { delete $data{$_} }
    grep { my $ref = ref $data{$_};
        $ref && $ref !~ /ARRAY|HASH/  } keys %data;
    return \%data
}

1;

