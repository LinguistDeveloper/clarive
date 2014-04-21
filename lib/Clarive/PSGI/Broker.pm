package Clarive::PSGI::Web;
use Plack::Builder;

our $PP = $$;

eval {
    #warn ">>>>>>>>>>>>>>RELOADING";
    $ENV{BALI_CMD} = 1; 
    require Baseliner;
};
if( $@ ) {
    print "\n\nBaseliner Startup Error:\n";
    print "-------------------------\n";
    print $@;
    print "-------------------------\n\n";
    die $@;
}

use PocketIO;
my $pocket = PocketIO->new(handler=>sub{
    my($self,$env) = @_;
    my $id = $self->id;
    warn "------------| pocketio session started: $id\n";
    $self->send( PocketIO::Message->new( type=>'event', data=>{ name=>'session_start', args=>[{ aa=>11 }] } ) );
    $self->on('nada', sub{ 
        my ($self,$msg,$cb) = @_;
        $cb->('hello bord');
    });
    $self->on('list', sub{ 
        my ($self,$msg,$cb) = @_;
        my @data = ci->user->find->fields({ username=>1, realname=>1 })->all;
        $cb->( \@data );
    });
}) ; #Baseliner::Pocket->new( app=>Baseliner );

builder {
    mount '/socket.io' => $pocket;
    #mount '/' => Baseliner->psgi_app;
};

