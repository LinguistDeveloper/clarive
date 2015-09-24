package Baseliner::RequestRecorder::Vars;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{vars} = $params{vars} || {};
    $self->{quiet} = $params{quiet};

    return $self;
}

sub vars { shift->{vars} }

sub extract_captures {
    my $self = shift;
    my ( $captures, $data ) = @_;

    foreach my $capture (@$captures) {
        my @names = split /,/, $capture->{names};
        my $re = $capture->{re};

        my @captures = $data =~ m/$re/;
        if (@captures) {
            foreach my $name (@names) {
                $self->{vars}->{$name} = shift @captures;
            }

            unless ($self->{quiet}) {
                print "    Extracted captures:\n";
                foreach my $name (@names) {
                    print "        - $name: $self->{vars}->{$name}\n";

                }
            }
        }
    }
}

sub replace_vars {
    my $self = shift;
    my ( $data ) = @_;

    my $first = 1;
    while ($data =~ m/\${(.*?)}/) {
        my $var = $1;

        if (exists $self->{vars}->{$var}) {
            if ($first) {
                print "    Replaced vars:\n" unless $self->{quiet};
                $first = 0;
            }
            if ($data =~ s/\${$var}/$self->{vars}->{$var}/g) {
                print "        - $var: $self->{vars}->{$var}\n" unless $self->{quiet};
            }
        }
    }

    return $data;
}

1;
