=head1 DESCRIPTION

Plack PSGI file for Baseliner.

Usage with starman:

    BALI_ENV=prod starman --preload-app

    # reloadable:

    BALI_ENV=prod starman --preload-app -R lib

=cut
BEGIN {
    use FindBin qw($Bin);
    my $home = $Bin;
    $ENV{BASELINER_HOME} ||= $home;
    $home and chdir $home;
    exists $ENV{BALI_ENV} and $ENV{BASELINER_CONFIG_LOCAL_SUFFIX}=$ENV{BALI_ENV};
    $ENV{NLS_LANG} = $ENV{BASELINER_NLS_LANG} || 'AMERICAN_AMERICA.UTF8';
    $ENV{LANG} = $ENV{BASELINER_LANG} || 'en_US.UTF-8';
}
use lib "$ENV{BASELINER_HOME}/lib";
use Plack::Builder;
eval {
    require Baseliner;
};
if( $@ ) {
    print "\n\nBaseliner Startup Error:\n";
    print "-------------------------\n";
    print $@;
    print "-------------------------\n\n";
    die $@;
}

builder {
    Baseliner->psgi_app;
};

