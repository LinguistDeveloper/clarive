use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use TestEnv;
TestEnv->setup;

use boolean;

use_ok 'Clarive::Cmd::docs';

my $tempdir = tempdir();

subtest 'dump_mkhelp: test tree' => sub {
    _setup(no_system_init => 1);

    my $cmd = _build_cmd();

    my @tree = (
        { text=>'title1', data=>{ body=>'my body', html=>'a html', path=>'devel/test1' }, children=>[] },
        { text=>'title2', data=>{ body=>'my body 2', html=>'a html', path=>'devel/test2' }, children=>[] },
    );
    my @pages = $cmd->dump_mkhelp( @tree );

    is_deeply( \@pages, [ {title1=>'devel/test1'}, { title2=>'devel/test2'} ] );
};

subtest 'dump_mkhelp: check doc content' => sub {
    _setup(no_system_init => 1);

    my $cmd = _build_cmd();

    my @tree = (
        { text=>'title1', data=>{ body=>'somebody', html=>'a html', path=>'devel/test1' }, children=>[] },
    );
    my @pages = $cmd->dump_mkhelp( @tree );

    is_deeply( \@pages, [ {title1=>'devel/test1'} ] );

    my $doc = Util->_file( $tempdir, "mkdocs/docs/devel/test1" );

    ok -e $doc;

    like( scalar $doc->slurp, qr/somebody/ );
};

done_testing;

sub _setup {
    my (%params) = @_;

    mdb->clarive->drop;

    mdb->clarive->insert( { initialized => true, migration => { version => '0100' } } ) unless $params{no_system_init};
}

sub _build_cmd {
    my (%params) = @_;

    return Clarive::Cmd::docs->new( app => $Clarive::app, mkdocs_path =>"$tempdir/mkdocs"  );
}
