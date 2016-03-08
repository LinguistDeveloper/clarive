use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;

BEGIN { TestEnv->setup }

use Capture::Tiny qw(capture);
use MongoDB::OID;
use Baseliner::VarsParser;

subtest 'parse_vars: parses string' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars(), undef;
    is $parser->parse_vars(undef), undef;
    is $parser->parse_vars(''),    '';

    is $parser->parse_vars( undef, {} ), undef;
    is $parser->parse_vars( '',    {} ), '';

    is $parser->parse_vars('foo'), 'foo';

    is $parser->parse_vars( '${foo}', { foo => 'bar' } ), 'bar';
    is $parser->parse_vars( '${foo} ${bar}', { foo => 'bar', bar => 'baz' } ), 'bar baz';
    is $parser->parse_vars( 'before${foo}after', { foo => '|' } ), 'before|after';
};

subtest 'parse_vars: parses references' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( \'${foo}', { foo => 'bar' } ), 'bar';
    is_deeply $parser->parse_vars( { foo => '${foo}' }, { foo => 'bar' } ), { foo => 'bar' };
    is_deeply $parser->parse_vars( ['${foo}'], { foo => 'bar' } ), ['bar'];
    is $parser->parse_vars( MongoDB::OID->new( value => '${foo}' ), { foo => 'bar' } ), 'bar';
};

subtest 'parse_vars: parses references in values' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( '${foo}', { foo => \'bar' } ), 'bar';
    is $parser->parse_vars( '${foo}', { foo => MongoDB::OID->new( value => 'bar' ) } ), 'bar';
};

subtest 'parse_vars: parses recursively' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( 'before${foo}after', { foo => '${bar}', bar => '|' } ), 'before|after';
};

subtest 'parse_vars: throws when direct recursion' => sub {
    my $parser = _build_parser();

    capture {
        like exception { $parser->parse_vars( '${foo}', { foo => '${foo}' } ) },
          qr/Deep recursion in parse_vars for variable `foo`, path \$\{foo}/;
    };
};

subtest 'parse_vars: throws when indirect recursion' => sub {
    my $parser = _build_parser();

    capture {
        like exception { $parser->parse_vars( '${foo}', { foo => '${bar}', bar => '${foo}' } ) },
          qr/Deep recursion in parse_vars for variable `foo`, path \$\{foo}/;
    };
};

subtest 'parse_vars: not parses recursively' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( '${{foo}}', { foo => '${bar}', bar => 'recursive!' } ), '${bar}';
};

subtest 'parse_vars: throws when unknown variables' => sub {
    my $parser = _build_parser( throw => 1 );

    capture {
        like exception { $parser->parse_vars( '${foo}', { blah => 'blah' } ) }, qr/Unresolved vars: 'foo' in \$\{foo}/;
    };

    capture {
        like exception { $parser->parse_vars( '${foo} ${{bar}}', { blah => 'blah' } ) },
          qr/Unresolved vars: 'bar', 'foo' in \$\{foo}/;
    };
};

subtest 'parse_vars: parses with field access' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( '${foo.bar}', { foo => '' } ), '${foo.bar}';
    is $parser->parse_vars( '${foo.bar}', { foo => { bar => '123' } } ), '123';
};

subtest 'parse_vars: parses with functions' => sub {
    my $parser = _build_parser();
    is $parser->parse_vars( '${lc(foo)}', { foo => 'BAR' } ), 'bar';
    is $parser->parse_vars( '${uc(foo)}', { foo => 'bar' } ), 'BAR';
    is $parser->parse_vars( '${json(foo)}', { foo => { aa=>100 } } ), '{"aa":100}';
    is $parser->parse_vars( '${yaml(foo)}', { foo => { aa=>200 } } ), '{"aa":200}';
    is $parser->parse_vars( '${to_id(this is 123 and #more... !stuff)}', {} ), 'this_is_123_and_more_stuff';
    is $parser->parse_vars( '${quote_list(foo)}', { foo => 'bar' } ), '"bar"';
};

subtest 'parse_vars: cleans up unresolved vars' => sub {
    my $parser = _build_parser( cleanup => 1 );

    is $parser->parse_vars( '${foo}', {} ), '';
};

subtest 'parse_vars: mixing recursive and non-recursive' => sub {
    my $parser = _build_parser();

    is $parser->parse_vars( '${foo} ${{bar}}', { foo => '${baz}', bar => '${baz}', baz => '123' } ), '123 ${baz}';
};

subtest 'parse_vars: resolves 2 vars in one string' => sub {
    my $parser = _build_parser( cleanup => 1 );

    is $parser->parse_vars( '${foo} ${foo}', { foo => 'bar' } ), 'bar bar';
};

subtest 'parse_vars: resolves 2 empty vars in one string' => sub {
    my $parser = _build_parser( cleanup => 1 );

    is $parser->parse_vars( '${foo} ${foo}', {} ), ' ';
};

subtest 'parse_vars: returns reference in var when single' => sub {
    my $parser = _build_parser( cleanup => 1 );

    is_deeply $parser->parse_vars( '${foo}', { foo => { foo => 'bar' } } ), { foo => 'bar' };
};

subtest 'parse_vars: throws when unexpected reference in var when used in string' => sub {
    my $parser = _build_parser( cleanup => 1 );

    capture {
        like exception { $parser->parse_vars( 'Hello, ${foo}!', { foo => { foo => 'bar' } } ) },
          qr/Unexpected reference found in \$\{foo\}/;
    };
};

done_testing;

sub _build_parser {
    return Baseliner::VarsParser->new(@_);
}
