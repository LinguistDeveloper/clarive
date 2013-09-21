package Baseliner::View::JSON;
use strict;
use base 'Catalyst::View::JSON';
use Encode;

#sub encode_json {
#    my($self, $c, $data) = @_;
#    my $encoder = JSON::XS->new->ascii->pretty->allow_nonref;
#    $encoder->encode($data);
#}

sub process {
    my $self = shift;
    my ($c) = @_;
    $self->next::method(@_);
    my $output = $c->res->output;
    if( $c->config->{'Baseliner::View::JSON'}->{decode_utf8} ) {
        $output = Encode::decode_utf8($output)
            unless $c->stash->{no_json_decode};
    }
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
