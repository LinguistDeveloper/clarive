package Baseliner::CI;
use strict;
use Baseliner::Utils;
use Module::Loaded;

sub new {
    my $class = shift;
    my %args;
    if( @_ == 0 ) {
        _throw "Missing node URI";
    } elsif( @_ == 1 && ref $_[0] eq 'HASH' ) {
        %args = %{ $_[0] };
    } elsif( @_ == 1 && is_number( $_[0] ) ) {   # mid! a CI!
        my $rec = Baseliner->model('Baseliner::BaliMaster')->find( $_[0] );
        my $class = "BaselinerX::CI::" . $rec->collection;
        return $class->new( _load( $rec->yaml ) );
    } elsif( @_ == 1 && ! ref $_[0] ) {
        $args{uri} = $_[0];
    } elsif( @_ == 2 && ! ref $_[0] && ref $_[1] eq 'HASH' ) {
        %args = %{ $_[1] };
        $args{uri} = $_[0];
    } else {
        %args = @_;
    }
    if( $args{uri} && ! exists $args{resource} ) {
        $args{resource} = Baseliner::CI::URI->new( $args{uri} );
    }
    ref $args{resource} or _throw "Missing or invalid resource";
    # merge resource params ?k=v&... into args
    %args = ( 
        %args,
        %{ $args{resource}{params} },
    );
    # load agent class
    my $agent_class =  "Baseliner::CI::" . $args{resource}->agent;
    unless ( is_loaded $agent_class ) {
    eval "require $agent_class"; 
    _throw _loc "Error loading node class %1: %2", $agent_class, $@ if $@;
    }
    # instantiate agent
    $agent_class->new( %args );
}

package Baseliner::CI::URI;
use Moose;
use Baseliner::Utils;

has agent    => qw(is rw isa Str required 1);
has host     => qw(is rw isa Str required 1);
has port     => qw(is rw isa Int);
has user     => qw(is rw isa Str);
has password => qw(is rw isa Str);
has home     => qw(is rw isa Str), default => '/';
has params   => qw(is rw isa HashRef), default => sub{+{}};

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args;
    if( @_ == 1 ) {
        %args = $class->parse_url( $_[0] ); 
        exists $args{params} and $args{params} = $class->parse_params( $args{params} );
    } else {
        %args = @_;
    }
    $class->$orig( %args );
};

=head2 parse_url

Parse the posible values:

        ssh://localhost
        ssh://localhost:88
        ssh://rod@172.10.11.12
        ssh://rod:secr3t@localhost
        ssh://rod:secr3t@172.10.11.12/tmp/dir
        ssh://rod:secr3t@172.10.11.12:1234/tmp/dir
        ssh://rod:secr3t@172.10.11.12/c:/TEMP
        ssh://rod:secr3t@172.10.11.12/c:/TEMP?arg=10&arg2=20

Returns a hash with the following keys:

    * agent
    * user (optional)
    * password (optional)
    * host 
    * port (optional)
    * home (optional)
    * params (optional)

=cut
sub parse_url {
    my( $self, $url) = @_;
    if( $url =~ m{
           ^
           (?<agent>\w+)://                     # agent name
           ((?<user>\w+)(:(?<password>.*))?@)?  # optional: "user:password" [user[:password]]
           (?<host>[^:/]+)(:(?<port>\d+))?   # host (Ip or name) [:port]
           (?<home>/[^\?]+)?                    # optional: home dir
           (\?(?<params>.+))?                   # optional: params
           $ }x ) {
        return %{ { %+ } };
    }
    return ();
}

sub parse_params {
    my( $self, $params ) = @_;
    my %ret;
    for my $p ( split /\&/, $params ) {
        my ($k,$v) = split /\=/, $p;
        next unless defined $k ;
        if( exists $ret{$k} ) {
            ! ref $ret{$k} and $ret{$k} = [ $ret{$k} ];
            push @{ $ret{$k} }, $v;
        } else {
            $ret{$k} = $v;
        }
    }
    return \%ret;
}

1;

