package Baseliner::View::JSON;
use strict;
use base 'Catalyst::View::JSON';
use Baseliner::Utils;
use Encode;

sub process {
    my $self = shift;
    my ($c) = @_;

    #return unless exists $c->stash->{json};
    #my $output = _to_json $c->stash->{json};
    #$output = Encode::decode_utf8( $output ) if Encode::is_utf8( $output );
    #Encode::_utf8_off( $output );
    #$c->res->output( $output );
    #return;

    $self->next::method(@_);
    my $output = $c->res->output;
    #warn "====== IS1=" . Encode::is_utf8( $output );
    #warn "====== ON =" . Encode::_utf8_on( $output );
    #warn "ON=" . Encode::_utf8_off( $output );
    #warn "====== IS =" . Encode::is_utf8( $output );
    if( $c->config->{'Baseliner::View::JSON'}->{decode_utf8} ) {
        $output = Encode::decode_utf8($output)
            unless $c->stash->{no_json_decode};
    }
    #Encode::from_to( $output, 'utf-8', 'iso-8859-1' );
    #Encode::from_to( $output, 'utf-8', 'iso-8859-1' );

    #my @aa=split//, $output;
    #my @bb=unpack 'W*', $output;
    #warn "BB=" . scalar @bb;
    #use List::MoreUtils qw/zip/;
    #warn join ', ', zip @aa, @bb;
    #$c->res->content_type("application/json");

    $c->res->output( $output );
}


=head1 NAME

Baseliner::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

Encodes the response after conversion. 

There are two ways of preventing this view from encoding:

Globally, in C</baseliner/baseliner.conf>:
    
    <Baseliner::View::JSON>
        decode_utf8 0
    </Baseliner::View::JSON>

Turn it off on a request basis:

    $c->stash->{no_json_decode} = 1;
    $c->view('View::JSON');

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

baseliner.org

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
