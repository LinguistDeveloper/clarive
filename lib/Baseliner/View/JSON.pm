package Baseliner::View::JSON;
use strict;
use base 'Catalyst::View::JSON';
use Encode;
use JSON::XS ();
use Baseliner::Utils;

# doesn't seem to save _json_encoder into self
# sub new {
#     my($class, $c, $arguments) = @_;
#     my $self = $class->next::method($c);
#     $self->{_json_encoder} = JSON::XS->new->allow_blessed->convert_blessed;
#     return $self;
# }

sub encode_json {
    my($self, $c, $data) = @_;

    if( ref $data eq 'HASH' && ( my $msg = delete $c->stash->{__broadcast} ) && !$c->session->{login_from_api} ) {
        $$data{__broadcast} = $msg if ref $msg eq 'HASH';
    }
    
    if( !ref $data ) {
        Util->_throw( 'Missing JSON data in stash');
    }
    
    my $encoder = $self->{_json_encoder} // ( $self->{_json_encoder} = JSON::XS->new->allow_blessed->convert_blessed );
    $encoder->max_depth([1024]);
    $encoder->encode($data);
}

sub process {
    my $self = shift;
    my ($c) = @_;
    
    $self->system_messages($c);
    
    $self->next::method(@_);
    
    my $output = $c->res->output;
    if( $c->config->{'Baseliner::View::JSON'}->{decode_utf8} ) {
        $output = Encode::decode_utf8($output)
            unless $c->stash->{no_json_decode};
    }
    $c->res->output( $output );
}

sub system_messages {
    my ( $self, $c ) = @_;
    return if $c->stash->{no_system_messages};
    my @all = mdb->sms->find({ username=>{ '$in'=>[undef,$c->username] }, expires=>{ '$gt'=>mdb->ts } })->fields({ _id=>1 })->all;
    if( my @sms = map { $$_{_id}.=''; $_ } @all ) {
        $c->stash->{__broadcast}{system_messages} = \@sms;
    }
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
