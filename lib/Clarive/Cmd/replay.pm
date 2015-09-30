package Clarive::Cmd::replay;
use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Replay';

use Test::More;
use Test::Fatal;
use Test::WWW::Mechanize;
use JSON ();
use Baseliner::Utils qw(_load);
use Baseliner::RequestRecorder::Vars;

sub run {
    my $self = shift;
    my (%opts) = @_;

    die "--file is required\n" unless my $file = $opts{args}->{file};

    open my $fh, '<', $file or die "Can't open file '$file': $!\n";
    my @cases = split /\s*\*\*\* \d+\.\d+ \*\*\*\s*/ms, do { local $/; <$fh> };
    close $fh;

    my $mech = Test::WWW::Mechanize->new;

    my $vars = Baseliner::RequestRecorder::Vars->new;
    foreach my $case (@cases) {
        next unless $case;

        my $data = _load $case;

        my $env = $data->{request}->{env};

        my $url = "http://$env->{SERVER_NAME}:$env->{SERVER_PORT}$env->{PATH_INFO}";
        $url .= "?$env->{QUERY_STRING}" if length $env->{QUERY_STRING};
        my $method = $env->{REQUEST_METHOD};

        $url = $vars->replace_vars($url);

        my @params;
        if ( $method eq 'POST' ) {
            my $body = $vars->replace_vars($data->{request}->{body});
            push @params, Content => $body;
        }

        if ( my $with = $env->{'HTTP_X_REQUESTED_WITH'} ) {
            push @params, 'X-Requested-With' => $with;
        }

        if ( my $content_type = $env->{'CONTENT_TYPE'} ) {
            push @params, 'Content-Type' => $content_type;
        }

        my $mech_method = lc $method;
        my $response = $mech->$mech_method( $url, @params );

        is $response->code, $data->{response}->{status}, "$method $url ($data->{response}->{status})"
          or _fail( $response, $data->{response} );

        my $expected_body =
          join '', ref $data->{response}->{body} eq 'ARRAY'
          ? @{ $data->{response}->{body} }
          : ( $data->{response}->{body} );

        my $content_type = $response->headers->header('Content-Type');
        if ( $content_type =~ m/json/ ) {
            ok !exception { JSON::decode_json($expected_body) }, 'JSON expected'
              or _fail( $response, $data->{response} );
        }

        if (my $captures = $data->{response}->{captures}) {
            $vars->extract_captures($captures, $response->content);
        }
    }

    done_testing;
}

sub _fail {
    my ( $got, $exp ) = @_;

    print "\n";
    print "= REQUEST ========\n\n";
    print $got->request->as_string;
    print "\n";
    print "= RESPONSE =======\n\n";
    print $got->as_string;
    print "\n";
    print "= EXPECTED =======\n\n";
    my $res = HTTP::Response->new( $exp->{status}, '', $exp->{headers},
        join( '', ref $exp->{body} eq 'ARRAY' ? @{ $exp->{body} } : $exp->{body} ) );
    print $res->as_string;
    print "\n";

    done_testing;
    BAIL_OUT 'ERROR';
}

1;
__END__

=head1 Replay

Common options:

    --file <file>           file to replay

=cut
