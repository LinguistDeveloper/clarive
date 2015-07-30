package Baseliner::Script::Server;
=head1 NAME

Baseliner::Script::Server - setup the baseliner server engine

=head1 DESCRIPTION

This is used by C<script/bali_server.pl> to chose which server
is going to be used. 

    default: basic HTTP
    prefork: Starman

=cut
use v5.10;
use Moose;
use namespace::autoclean;

given( $ENV{BASELINER_SERVER_ENGINE} ) {
    when( 'prefork' ) {
        extends 'CatalystX::Script::Server::Starman';
    }
    default {
        extends 'Catalyst::Script::Server';
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

