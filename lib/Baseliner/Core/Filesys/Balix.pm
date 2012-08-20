package  Baseliner::Core::Filesys::Balix;
use Baseliner::Plug;
use IO::Socket;
use Carp;
use Crypt::Blowfish::Mod;
use BaselinerX::Comm::Balix;
use Data::Dumper;

with 'Baseliner::Role::Filesys';

has 'home' => ( is => 'rw', isa => 'Str', required => 1 );
has 'host' => ( is => 'rw', isa => 'Str', );
has 'user' => ( is => 'rw', isa => 'Str', );
has 'port' => ( is => 'rw', isa => 'Int', );
has 'os'   => ( is => 'rw', isa => 'Str', default  => 'unix' );
has 'balix'   => ( is => 'rw', isa => 'BaselinerX::Comm::Balix' );

register 'config.filesys.balix' => {
    metadata=>[
        { id=>'key', type=>'text', default=>'TGtkaGZrYWpkaGxma2psS0tKT0tIT0l1a2xrbGRmai5kLC4yLjlka2ozdTQ4N29sa2hqZGtzZmhr' },
        { id=>'port', type=>'text', default=>32100 },
    ]
};

# perl -MBaseliner::Core::Filesys::Balix -le '$b=Baseliner::Core::Filesys::Balix->new( home=>"balix://OAM7315R@B0007502554107:32100=C:\\" ); print $b->execute("dir");'
# perl -MBaseliner::Core::Filesys -le "$b=Baseliner::Core::Filesys->new( home=>'balix://OAM7315R@B0007502554107:32100=C:\\' ); print $b->execute('dir');"
# perl -MBaseliner::Core::Filesys -le '$b=Baseliner::Core::Filesys->new( home=>"balix://OAM7315R@B0007502554107:32100=C:\\" ); print $b->execute("dir");'

sub BUILD {
    my $self = shift;
    my $home = $self->home;
    my $os = $self->os;
    my ( $user, $host, $port, $home_real ) =
      ($1,$2,$3,$4) if( $home =~ m/^(\w+)\@(\w+)\:(\d+)\=(\w+)/ );

    $self->user($user);
    $self->host($host);
    $self->port($port);
    $self->home($home_real);
    $self->os($os);

    #my $balix = BaselinerX::Comm::Balix->open( $host,$port,'win' ); 
    my $balix = BaselinerX::Comm::Balix->new( host=>$host, port=>$port, key=>'TGtkaGZrYWpkaGxma2psS0tKT0tIT0l1a2xrbGRmai5kLC4yLjlka2ozdTQ4N29sa2hqZGtzZmhr', os=>$os,  timeout=>10 );
    $self->balix($balix);
}

sub execute {
    my $self = shift;
    my %p  =  %{ shift() } if ref $_[0];
    
    return $self->balix->execute($p{cmd});
}

sub get {
    my ($self, %P)=@_;
    my $remoteFile = $P{from};
    my $localFile = $P{to} || $P{to_file};
    my $os = $P{os};
    return $self->balix->getFile( $remoteFile, $localFile, $os );
}

sub put {
    my ($self, %P)=@_;
    my $remoteFile = $P{to} || $P{to_file};
    my $localFile = $P{from};
    my $os = $P{os};
    return $self->balix->sendFile( $localFile, $remoteFile, $os );
}


sub copy {

    #TODO kizas no sea necesario
}


sub end {
    my ($self)=@_;
    $self->balix->end();
}
1;
