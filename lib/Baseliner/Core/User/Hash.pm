package Baseliner::Core::User::Hash;
use Moose;
use Baseliner::Utils;
extends 'Catalyst::Authentication::User::Hash';
extends 'Baseliner::Core::User';
use namespace::clean;

# FIXME Catalyst::Authentication::User::Hash has an AUTOLOAD that breaks anymethod under $c->user

1;
