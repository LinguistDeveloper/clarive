BEGIN {
    use FindBin qw($Bin);
    my $home = $Bin;
    $ENV{BASELINER_HOME} ||= $home; 
    $home and chdir $home;
    exists $ENV{BALI_ENV} and $ENV{CATALYST_CONFIG_LOCAL_SUFFIX}=$ENV{BALI_ENV};
}
use lib "$ENV{BASELINER_HOME}/lib";
use Plack::Builder;
use Baseliner;
 
builder {
    Baseliner->psgi_app;
};

