package Clarive::PSGI::Web;

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

my $app = builder {
    mount '/' => Baseliner->psgi_app;
};
