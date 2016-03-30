use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::LongString;
use TestEnv;

BEGIN { TestEnv->setup }

use Baseliner::Utils qw(
  _pointer
  query_grep
  _unique
  _array
  _to_camel_case
  parse_vars
  _trend_line
  _strip_html
  _strip_html_editor
);
use Baseliner::Utils qw(_pointer query_grep _unique _array _to_camel_case parse_vars _trend_line _truncate);
use Clarive::mdb;

####### _pointer 

subtest '_pointer returns value from valid structures' => sub {
    is _pointer( 'foo', { foo => 'bar' } ), 'bar';
    is _pointer( 'foo.bar', { foo => { bar => 'baz' } } ), 'baz';
    is _pointer( 'foo.[0].bar', { foo => [ { bar => 'baz' } ] } ), 'baz';
    is _pointer( 'foo.[1].bar.[0]', { foo => [ {}, { bar => ['baz'] } ] } ), 'baz';
};

subtest '_pointer returns undef from valid structures' => sub {
    is _pointer( '[0]', [] ), undef;
    is _pointer( 'hello', { foo => 'bar' } ), undef;
};

subtest '_pointer returns undef from invalid structures' => sub {
    is _pointer( '[0]', {} ), undef;
    is _pointer( 'hello', [] ), undef;
};

subtest '_pointer throws on invalid structures' => sub {
    like exception { _pointer( '[0]', {}, throw => 1 ) }, qr/array ref expected at '\.'/;
    like exception { _pointer( 'hello', [], throw => 1 ) }, qr/hash ref expected at '\.'/;
    like exception { _pointer( 'hello.[0]', { hello => {} }, throw => 1 ) }, qr/array ref expected at 'hello'/;

    like exception { _pointer( '[0].foo.[1]', [ { foo => {} } ], throw => 1 ) }, qr/array ref expected at '\[0\]\.foo'/;
};

####### query_grep

my @rows = (
    { id=>'bart', name=>'Bart Simpson' },
    { id=>'lisa', name=>'Lisa Simpson' },
    { id=>'moe', name=>'Moe' },
    { id=>'kasim', name=>'Kasim' },
);

subtest 'query_grep finds rows single field' => sub {
    is scalar query_grep( query=>'bart', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Bart"', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'simpson', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simpson', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"sim"', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Sim"', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"Sim" -bart', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'+Si', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'ba +Si', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'li ba +Si', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'ba?t', fields=>['name'], rows=>\@rows ), 1;
    #is scalar query_grep( query=>'"Sim" -"Bart"', fields=>['name'], rows=>\@rows ), 1;
};

subtest 'query_grep finds rows single field masked' => sub {
    is scalar query_grep( query=>'S?mp', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simp*', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'+lisa Simp*', fields=>['name'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'+lisa Simp*', fields=>['name'], rows=>\@rows ), 1;
};

subtest 'query_grep all fields' => sub {
    is scalar query_grep( query=>'Simp', all_fields=>1, rows=>\@rows ), 2;
    is scalar query_grep( query=>'bart', all_fields=>1, rows=>\@rows ), 1;
};

subtest 'query_grep finds rows single field regexp' => sub {
    is scalar query_grep( query=>'/S..p/', fields=>['name'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'/S.*ps/', fields=>['name'], rows=>\@rows ), 2;
};

subtest 'query_grep finds rows multi-field' => sub {
    is scalar query_grep( query=>'bart', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'bart Bart', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'simpson', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'Simpson', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"sim"', fields=>['name','id'], rows=>\@rows ), 1;
    is scalar query_grep( query=>'"Sim"', fields=>['name','id'], rows=>\@rows ), 2;
    is scalar query_grep( query=>'"Sim" -bart', fields=>['name','id'], rows=>\@rows ), 1;
};

subtest 'query_grep finds none' => sub {
    is scalar query_grep( query=>'hank', fields=>['name','id'], rows=>\@rows ), 0;
    is scalar query_grep( query=>'"bart"', fields=>['name'], rows=>\@rows ), 0;
    is scalar query_grep( query=>'-k -m -l -b', fields=>['name'], rows=>\@rows ), 0;
};

subtest '_unique: returns unique fields' => sub {
    is_deeply [_unique()], [()];
    is_deeply [_unique('')], [('')];
    is_deeply [_unique('', undef)], [('', undef)];
    is_deeply [_unique(undef, undef)], [(undef)];

    is_deeply [_unique('foo', undef, 'foo')], [('foo', undef)];
    is_deeply [_unique('foo', 'foo')], [('foo')];
    is_deeply [_unique('foo', 'bar', 'foo')], [('foo', 'bar')];
};

subtest '_array' => sub {
    is_deeply [_array(undef, '', 0)], [0];
    is_deeply [_array([undef, '', 0])], [0];

    is_deeply [_array(qw/foo bar baz/)], [(qw/foo bar baz/)];
    is_deeply [_array([qw/foo bar baz/])], [(qw/foo bar baz/)];

    is_deeply [_array({}, undef, {})], [{}, {}];
    is_deeply [_array([{}, undef, {}])], [{}, {}];
};

subtest '_to_camel_case: camelize strings' => sub {
    is _to_camel_case(''), '';
    is _to_camel_case('foo'), 'foo';
    is _to_camel_case('foo_bar'), 'fooBar';
    is _to_camel_case('foo_bar_'), 'fooBar_';
    is _to_camel_case('_foo_bar'), '_fooBar';
    is _to_camel_case('____foo_____bar____'), '_fooBar_';
};


subtest 'parse_vars: parses vars' => sub {
    is parse_vars('foo'), 'foo';
    is parse_vars('${foo}', {foo => 'bar'}), 'bar';
};

subtest 'ns_split: splits namespace' => sub {
    is_deeply( [Util->ns_split('')], ['', '']);
    is_deeply( [Util->ns_split('foo/bar')], ['foo', 'bar']);
    is_deeply( [Util->ns_split('/bar')], ['', 'bar']);
    is_deeply( [Util->ns_split('foo/')], ['foo', '']);
};


subtest 'in_range: checks that numbers are in range' =>  sub {
    ok !(Util->in_range());
    ok (Util->in_range( 0, '0-'));
    ok (Util->in_range(11, '1,2,3,10-'));
    ok (Util->in_range(999999, '1,2,3,10-'));
    ok !(Util->in_range(7, '1,2,3,10-'));
};

subtest 'icon_path: builds absolute icon path' => sub {
    is (Util->icon_path('foo/'),'foo/');
    is (Util-> icon_path('/foo'), '/foo');
    is (Util-> icon_path('foo.bar'), '/static/images/icons/foo.bar');
    is (Util-> icon_path('foo'), '/static/images/icons/foo.png' );
};

subtest '_replace_tags: change < and >' => sub {
    is (Util->_replace_tags('<'),'&lt;');
    is (Util->_replace_tags('>'),'&gt;');
    is (Util->_replace_tags(''),'');
    is (Util->_replace_tags('<string>'),'&lt;string&gt;');
};

subtest '_name_to_id: converts name to id' => sub {
    is (Util->_name_to_id(undef), undef);
    is (Util->_name_to_id(''), '');
    is (Util->_name_to_id('ab    foo'), 'ab_foo');
    is (Util->_name_to_id('foo?bar'), 'foo_bar');
    is (Util->_name_to_id('ab_____foo'),'ab_foo');
    is (Util->_name_to_id('foobar__'),'foobar');
    is (Util->_name_to_id('_foobar'),'foobar');
    is (Util->_name_to_id('foobar'),'foobar');
    is (Util->_name_to_id('__foo__  ?bar__'),'foo_bar');
    is (Util->_name_to_id('FOO'),'foo');
};

subtest '_size_unit: human readable format' => sub {
    is_deeply ( [Util->_size_unit()], ['0','bytes']);
    is_deeply ( [Util->_size_unit(500)], ['500','bytes']);
    is_deeply ( [Util->_size_unit(1050)], ['1','KB']);
    is_deeply ( [Util->_size_unit(10000000)], ['9.54','MB']);
    is_deeply ( [Util->_size_unit(10000000000)], ['9.31','GB']);
};

subtest 'job_icon: builds and icon from status' => sub {
    is (Util->job_icon ('RUNNING'),'gears.gif');
    is (Util->job_icon ('READY'),'waiting.png');
    is (Util->job_icon ('APPROVAL'),'user_delete.gif');
    is (Util->job_icon ('FINISHED'),'log_i.png');
    is (Util->job_icon ('FINISHED','1'),'close.png');
    is (Util->job_icon ('IN-EDIT'),'log_w.png');
    is (Util->job_icon ('WAITING'),'waiting.png');
    is (Util->job_icon ('PAUSED'),'paused.png');
    is (Util->job_icon ('TRAPPED_PAUSED'),'paused.png');
    is (Util->job_icon ('CANCELLED'),'close.png');
    is (Util->job_icon (),'log_e.png');
};

subtest '_cut: joins paths' => sub {
    is (Util->_cut(0,'\foo','\static\images'),'\static\images');
    is (Util->_cut(1,'\foo','\static\images'),'\static\images\foo');
    is (Util->_cut(2,'\bar', '\static\images'),'\static\images\bar\bar');
};

subtest 'is_number: checks if is a number' => sub {
    is (Util->is_number('123'),1);
    is (Util->is_number(123),1);
    is (Util->is_number('abc'),'');
    ok (Util->is_number('1.8'));
};

subtest 'is_int: checks if is an integer' => sub {
    is (Util->is_int('abc'),'');
    is (Util->is_int(12.11),'');
    is (Util->is_int('1234'),1);
    is (Util->is_int(1234),1);
};

subtest '_trim: remove whitespaces at the beginning and at the end' => sub {
    is (Util->_trim(),'');
    is (Util->_trim('   a'),'a');
    is (Util->_trim('       foo'),'foo');
    is (Util->_trim('ab   cd'),'ab   cd');
    is (Util->_trim('    text    '), 'text');
};

subtest '_bool: converts value to 0 or 1' => sub {
    is (Util->_bool(),'0');
    is (Util->_bool('foo'),'1');
    is (Util->_bool(10),'1');
    is (Util->_bool('true'),'1');
    is (Util->_bool('on'),'1');
    is (Util->_bool('off'),'0');
    is (Util->_bool('false'),'0');
};

subtest '_markdown_escape: escapes special symbols' => sub {
    is (Util->_markdown_escape('(foo.bar'),'\(foo\.bar');
    is (Util->_markdown_escape('(foo__bar'),'\(foo\_\_bar');
};

subtest '_markup_escape: encodes special symbols' => sub {
    is (Util->_markup_escape('\*'),'&#42;');
    is (Util->_markup_escape('\`'),'&#96;');
    is (Util->_markup_escape('\]'),'&#93;');
};

subtest '_markup_unescape: decodes special symbols' => sub {
    is (Util->_markup_unescape('&#42;'),'*');
    is (Util->_markup_unescape('&#96;'),'`');
    is (Util->_markup_unescape('&#92;'),'\\');
};

subtest '_markup: converts markup to html' => sub {
    is (Util->_markup('**$foo**'),'<span><b>$foo</b></span>');
    is (Util->_markup('*$foo*'),'<b>$foo</b>');
    is (Util->_markup('`$foo`'),'<code>$foo</code>');
    is (Util->_markup('`*$foo*`'),'<code><b>$foo</b></code>');
};

subtest '_trend_line: calculates trend' => sub {
    is_deeply _trend_line( x => [ 0, 1, 2, 3, 4, 5 ], y => [ 10, 8, 6, 5, 4 ] ),
      [ '10.00', '8.20', '6.40', '4.60', '2.80', '1.00' ];
};

subtest '_trend_line: calculates trend with special cases' => sub {
    is_deeply _trend_line( x => [], y => [] ), [];
    is_deeply _trend_line( x => [ 0, 0, 0, 0, 0 ], y => [ 0, 0, 0, 0, 0 ] ),
      [ '0.00', '0.00', '0.00', '0.00', '0.00', ];
};

subtest '_strip_html: strips html' => sub {
    is _strip_html('<b>Bold</b>'), 'Bold';
    is _strip_html('<b><script>alert!</script>Bold</b>', rules => {b => []}), '<b>Bold</b>';
};

subtest '_strip_html_editor: strips html preserving allowed html formatting' => sub {
    my $html = <<'EOF';
    <span style="font-weight: bold;">1</span>
    <br>
    <span style="font-style: italic;">2</span>
    <br>
    <span style="text-decoration: underline;">3</span>
    <br>
    <span style="text-decoration: line-through;">4</span>
    <br>
    <sub>5</sub>
    <br>
    <sup>6</sup>
    <span style="font-family: Narrow;">
        <br>7<br>
        <font size="5">8<br>
        </font>
    </span>
    <div>
        <span style="font-family: Narrow;">
            <font size="5">9<br>
                <span style="color: rgb(204, 102, 0);">10<br>
                    <span style="background-color: rgb(153, 0, 0);">11<br>
                    </span>
                </span>
            </font>
        </span>12<span style="font-family: Narrow;">
            <font size="5">
                <span style="color: rgb(204, 102, 0);">
                    <span style="background-color: rgb(153, 0, 0);">
                        <br>
                    </span>
                </span>
            </font>
        </span>
        <ul>
            <li>
                <span style="font-family: Narrow;">
                    <font size="5">
                        <span style="color: rgb(204, 102, 0);">
                            <span style="background-color: rgb(153, 0, 0);">13</span>
                        </span>
                    </font>
                </span>
            </li>
        </ul>
        <ol>
            <li>
                <span style=" font-family: Narrow;">
                    <font size="5">
                        <span style=" color: rgb(204, 102, 0);">
                            <span style=" background-color: rgb(153, 0, 0);">14</span>
                        </span>
                    </font>
                </span>
            </li>
        </ol>
        <span style=" font-family: Narrow;">
            <font size="5">
                <span style=" color: rgb(204, 102, 0);">
                    <span style=" background-color: rgb(153, 0, 0);">
                        <br>
                    </span>
                </span>
            </font>
        </span>
        <div style="text-align: center;">
            <span style="color: rgb(204, 102, 0);">
                <font size="5">
                    <span style="font-family: Narrow;">123123<br>
                        <br>
                    </span>
                </font>
            </span>
            <div style="text-align: left;">
                <hr>
                <img src="http://123">
                <br>
                <font size="5">12312</font>
                <br>
            </div>
            <span style="color: rgb(204, 102, 0);">
                <font size="5">
                    <span style="font-family: Narrow;">
                    </span>
                </font>
            </span>
            <span style=" font-family: Narrow;">
                <font size="5">
                    <span style=" color: rgb(204, 102, 0);">
                        <span style=" background-color: rgb(153, 0, 0);">
                        </span>
                    </span>
                </font>
            </span>
            <a href="http://123">123123</a>
            <br>
            <span style=" font-family: Narrow;">
                <font size="5">
                    <span style=" color: rgb(204, 102, 0);">
                        <span style=" background-color: rgb(153, 0, 0);">
                        </span>
                    </span>
                </font>
            </span>
        </div>
    </div>
    <div>
        <span style="font-family: Narrow;">
        </span>
    </div>
EOF

    $html =~ s{^\s+}{}g;
    $html =~ s{\s+$}{}g;
    $html =~ s{>\s+<}{><}g;

    is_string _strip_html_editor($html), $html;

subtest '_truncate: truncates string' => sub {
    is _truncate( 'foobar',    5 ), '[...]';
    is _truncate( 'foobarbaz', 6 ), 'f[...]';
    is _truncate( 'foobar', 5,  '...' ), 'fo...';
    is _truncate( 'foobar', 5,  '' ),    'fooba';
    is _truncate( 'foobar', 10, '' ),    'foobar';
};

done_testing;
