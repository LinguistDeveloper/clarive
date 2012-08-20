package Baseliner::Node::rsync;
use Moose;
extends 'Baseliner::Node::ssh';
has _method => qw(is ro default rsync);

# TODO configure remote rsync path to executable

1;
