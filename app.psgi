=head1 DESCRIPTION

Plack PSGI file for Baseliner.

Usage with starman:

    BALI_ENV=prod starman --preload-app

    # reloadable:

    BALI_ENV=prod starman --preload-app -R lib

=cut
use v5.10;
BEGIN { 
    use FindBin qw($Bin);
    my $home = $Bin;
    $ENV{BASELINER_HOME} ||= $home; 
    $home and chdir $home;
    exists $ENV{BALI_ENV} and $ENV{BASELINER_CONFIG_LOCAL_SUFFIX}=$ENV{BALI_ENV};
    say "env: $ENV{BASELINER_CONFIG_LOCAL_SUFFIX}"; 
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

#use PocketIO;
#my $pocket = PocketIO->new(handler=>sub{
#    my($self,$env) = @_;
#    warn $cv;
#    warn "------------| pocketio started\n";
#    $self->send( PocketIO::Message->new( type=>'event', data=>{ name=>'session_start', args=>[{ aa=>11 }] } ) );
#    $self->on('nada', sub{ 
#        my ($self,$msg,$cb) = @_;
#        $cb->('hello bord');
#        });
#}) ; #Baseliner::Pocket->new( app=>Baseliner );

builder {
    #mount '/socket.io' => $pocket;
    mount '/' => Baseliner->psgi_app;
};

