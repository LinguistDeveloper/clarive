use strict;
use warnings;
use lib 't/lib';

use Test::More;
use TestEnv;

TestEnv->setup;

use File::Temp;
use Baseliner::Utils qw(_load);

use_ok 'Baseliner::Middleware::RecordRequests';

subtest 'records request and response' => sub {
    my $file = File::Temp->new;

    my $mw = _build_mw(
        file => $file,
        app  => sub {
            my $env = shift;

            return [ 200, [], ['OK'] ];
        }
    );

    my $env = { REQUEST_METHOD => 'GET', PATH_INFO => '/' };

    $mw->call($env);

    my $log = _slurp($file);

    ok $log =~ s{^\*\*\* \d+\.\d+ \*\*\*}{}ms;

    my $dump = _load $log;

    my $req = $dump->{request};
    is $req->{env}->{REQUEST_METHOD}, 'GET';
    is $req->{body}, '';

    my $res = $dump->{response};
    is $res->{status}, 200;
    is_deeply $res->{headers}, [];
    is_deeply $res->{body}, ['OK'];
};

sub _slurp {
    my ($file) = @_;

    return do { local $/; open my $fh, '<', $file or die $!; <$fh> }

}

sub _build_mw {
    return Baseliner::Middleware::RecordRequests->new(@_);
}

done_testing;
