package Baseliner::SetupProfile::Reset;
use strict;
use warnings;
use base 'Baseliner::SetupProfile::Base';

use Clarive::Cmd::init;
use Clarive::Cmd::migra;

sub setup {
    my $self = shift;

    my $init = Clarive::Cmd::init->new(app => $Clarive::app, opts => {});
    $init->run(args => {reset => 1, yes => 1});

    my $migra = Clarive::Cmd::migra->new(app => $Clarive::app, opts => {});
    $migra->run(args => {yes => 1});
}

1;
