use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

use Test::TempDir::Tiny;
use File::Temp qw(tempfile);
use Capture::Tiny qw(capture_merged);
use Baseliner::I18N;

subtest 'installed_languages' => sub {
    my $po_dir = tempdir();

    _write_file(<<"EOP", "$po_dir/en.po");
msgid ""
msgstr ""

"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Site Information"
msgstr ""
EOP

    _write_file(<<"EOP", "$po_dir/es.po");
msgid ""
msgstr ""

"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Site Information"
msgstr "Datos de Registro"
EOP


    Baseliner::I18N->setup( paths => $po_dir );

    is_deeply(
        Baseliner::I18N->installed_languages,
        {
            en  => 'English',
            es  => 'Spanish',
        }
    );
};

subtest 'localize' => sub {
    my $po_dir = tempdir();

    _write_file(<<"EOP", "$po_dir/en.po");
msgid ""
msgstr ""

"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Site Information"
msgstr ""

msgid "Hello %1"
msgstr ""

msgid "_special"
msgstr ""
EOP

    _write_file(<<"EOP", "$po_dir/es.po");
msgid ""
msgstr ""

"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=utf-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Site Information"
msgstr "Datos de Registro"

msgid "Hello %1"
msgstr "Hola %1"

msgid "_special"
msgstr "_especial"
EOP

    Baseliner::I18N->setup( paths => $po_dir );

    Baseliner::I18N->languages(['en']);
    is(Baseliner::I18N->language, 'en');
    is(Baseliner::I18N->localize('unknown'), 'unknown');
    is(Baseliner::I18N->localize('1_2'), '1_2');
    is(Baseliner::I18N->localize('_unknown'), '_unknown');
    is(Baseliner::I18N->localize('_special'), '_special');
    is(Baseliner::I18N->localize('Site Information'), 'Site Information');
    is(Baseliner::I18N->localize('Hello %1', 'Bill'), 'Hello Bill');

    Baseliner::I18N->languages(['es']);
    is(Baseliner::I18N->language, 'es');
    is(Baseliner::I18N->localize('unknown'), 'unknown');
    is(Baseliner::I18N->localize('_unknown'), '_unknown');
    is(Baseliner::I18N->localize('_special'), '_especial');
    is(Baseliner::I18N->localize('Site Information'), 'Datos de Registro');
    is(Baseliner::I18N->localize('Hello %1', 'Pedro'), 'Hola Pedro');
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

subtest 'validates po files' => sub {
    my $root = "lib/Baseliner/I18N";

    opendir my $dir, $root or die $!;
    my @files = readdir $dir;
    closedir $dir;

    foreach my $file (@files) {
        next unless $file =~ m/\.po$/;

        my $output = capture_merged { `msgfmt -c $root/$file` };

        unlike $output, qr/fatal errors?/;
    }
};

done_testing;

sub _write_file {
    my ($content, $filename) = @_;

    my $fh;
    if ($filename) {
        open $fh, '>', $filename or die $!;
    }
    else {
        ($fh, $filename) = tempfile();
    }

    binmode $fh, ':utf8';
    print $fh $content;
    seek $fh, 0, 0;

    return $filename;
}
