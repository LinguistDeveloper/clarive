use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestEnv;
BEGIN { TestEnv->setup }

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

done_testing;
