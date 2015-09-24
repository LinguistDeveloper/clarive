use strict;
use warnings;

use Test::More;

use Baseliner::RequestRecorder::Vars;

subtest 'extracts captures' => sub {
    my $vars = _build_vars();

    $vars->extract_captures(
        [
            {
                names => 'var',
                re    => qr/hello (.*)/
            }
        ],
        'hello there'
    );

    is_deeply $vars->vars, { var => 'there' };
};

subtest 'extracts multiple captures' => sub {
    my $vars = _build_vars();

    $vars->extract_captures(
        [
            {
                names => 'var,bar',
                re    => qr/(.*?) (.*)/
            }
        ],
        'hello there'
    );

    is_deeply $vars->vars, { var => 'hello', bar => 'there' };
};

subtest 'replace vars' => sub {
    my $vars = _build_vars( vars => { foo => 'bar' } );

    my $output = $vars->replace_vars('hello ${foo}');

    is $output, 'hello bar';
};

sub _build_vars {
    Baseliner::RequestRecorder::Vars->new(@_);
}

done_testing;
