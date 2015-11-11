use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use File::Temp qw(tempfile);
use Baseliner::I18N;

subtest 'install_languages' => sub {
    is(Baseliner::I18N->installed_languages->{en}, 'English');
};

subtest 'localize' => sub {
    Baseliner::I18N->languages(['en']);
    is(Baseliner::I18N->language, 'en');
    is(Baseliner::I18N->localize('Site Information'), 'Site Information');

    Baseliner::I18N->languages(['es']);
    is(Baseliner::I18N->language, 'es');
    is(Baseliner::I18N->localize('Site Information'), 'Datos de Registro');
};

subtest 'parse_po: empty file' => sub {
    my $file = _write_file('');

    my $text = Baseliner::I18N->parse_po($file);

    is $text, '';
};

subtest 'parse_po: file' => sub {
    my $file = _write_file(qq{msgid "Hello"\nmsgstr "Hola"\n\nmsgid "Bye"\nmsgstr "Adios"});

    my $text = Baseliner::I18N->parse_po($file);

    is $text, qq{"Hello" : "Hola",\n"Bye" : "Adios"};
};

subtest 'parse_po: multiline' => sub {
    my $file = _write_file(<<"EOP");
"some"
"random"
"stuff"
#comment

msgid ""
"This "
"is "
"a "
"multiline"

msgstr ""
"Se "
"trata "
"de una línea de múltiples"

#comment
EOP

    my $text = Baseliner::I18N->parse_po($file);

    is $text, qq{"This is a multiline" : "Se trata de una línea de múltiples"};
};

subtest 'parse_po: real file' => sub {
    my $file = _write_file(qq{
msgid ""
msgstr ""

"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Site Information"
msgstr "Datos de Registro"
    });

    my $text = Baseliner::I18N->parse_po($file);

    is $text, qq{"" : "",\n"Site Information" : "Datos de Registro"};
};

done_testing;

sub _write_file {
    my ($content) = @_;

    my ($fh, $filename) = tempfile();
    binmode $fh, ':utf8';
    print $fh $content;
    seek $fh, 0, 0;

    return $filename;
}
