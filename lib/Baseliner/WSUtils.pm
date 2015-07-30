package Baseliner::WSUtils;
use Baseliner::Utils;
use Moose;
use LWP::UserAgent;
use XML::Smart;
use Data::Dumper;


sub ws_form_request {
    my ($self, %p) = @_;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout( $p{timeout} || 60 );
    my $response = $ua->post( $p{url}, [ %{ $p{data} } ]);

    if ($response->is_success) {
        my $data = new XML::Smart( $response->decoded_content );
        my $content = $data->{string}->{CONTENT};
        # my $xs = XML::Simple->new;
        # my $data = $xs->XMLin( $response->decoded_content );
        # my $content = $xs->XMLin( $data->{content} );
        return { response=>$response, data=>$data, content=>$content, success=>1 };
    } else {
        print $response->status_line;
        print $response->as_string;
        return { response=>$response, success=>0 };
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Baseliner::WSUtils

=head1 DESCRIPTION

Utilities for simplifying WS manipulation. 

=head1 METHODS

=head2 ws_form_request ( url => ?, data=>{ field => 'value' }, timeout=>60 )

Simplify calling a REST .NET style web-service with a form request. 

    use Data::Dumper;
    use v5.10;

    my $wsu = Baseliner::WSUtils->new;
    my $result = $wsu->ws_form_request(
        url  => 'http://webservices.example.com/webService',
        data => { form_param => q{some data in here} }, 
    );

    my $response = $result->{response};

    if ($response->is_success) {
       say Dumper $res->{content};
       say $res->{content}->{Registros};
    }
    else {
       print $response->status_line;
       print $response->as_string;
    }

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 The Authors of baseliner.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
