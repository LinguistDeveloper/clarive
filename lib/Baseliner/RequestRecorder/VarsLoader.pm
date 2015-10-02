package Baseliner::RequestRecorder::VarsLoader;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub load_from_file {
    my $self = shift;
    my ($file, @args) = @_;

    die "Error loading vars from file '$file': $!\n" unless -f $file;

    my $eval_cb = do $file or die $@;
    return ref $eval_cb eq 'CODE' ? $eval_cb->(@args) : $eval_cb;
}

1;
