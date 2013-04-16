package Baseliner::Core::Deployment;
=head1 NAME

Baseliner::Core::Deployment - Base object for deploying and executing scripts remotely

=head1 DESCRIPTION

Maps a single destination node with many source (origin) 
files and dirs. 

Runs a list of scripts on each node.

=cut
use Moose;
use Baseliner::CI;
use Path::Class;
use Moose::Util::TypeConstraints;
use Baseliner::Utils;
use namespace::autoclean;

subtype 'PathClass',
  as 'Object',
  where { $_->isa('Path::Class::Dir') || $_->isa('Path::Class::File') };


has origin  => qw/is ro isa ArrayRef[PathClass] required 1/,
               traits  => ['Array'],
               handles => { each_origin => 'map', count=>'count' };

has destination => qw/is ro does Baseliner::Role::CI::Destination required 1/;

# base dir or regex to copy from origin path to destination path
has base => qw/is ro isa Str default/ => '';

has vars => qw/is rw isa HashRef/, default=>sub{{}};

has scripts     => qw/is ro isa CIs required 0/, default=>sub { [] },
    traits=>['Array'], handles=>{ each_script => 'map', has_scripts=>'count' };

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args;
    if( ref $_[0] ) {
        %args = %{ $_[0] };
    } else {
        %args = @_;
    }
    ref $args{destination} or $args{destination} = Baseliner::CI->new( $args{destination} );
    $class->$orig( %args ); 
};

=head1 METHODS

=head2 deploy

Deploy files/dirs to destination.

=cut
sub deploy {
    my ($self, %args ) = @_;
    my $node = $self->destination;
    my $cb = $args{callback};
    my $base = $self->base;
    if( $base ) {
        $base = qr{$base/?(?<base_path>.*)$} ;
    }
    $self->each_origin( sub {
        my $f = $_;
        # capture base path ?
        my $base_path;
        if( $base && "$f" =~ $base ) {
            my %captures = %+;  # named captures
            # prepare base_path to be added to remote
            $base_path = delete $captures{base_path};
            $base_path = _file( $base_path )->dir;
            $self->push_vars( %captures );
            # now use captures as variables in the remote base path
        }
        my $remote = $node->home;
        $remote = $self->parse_vars( $remote );
        $node->home( $remote );
        if( $f->is_dir ) {
            $node->put_dir( local=>$f, add_path=>$base_path );
            ref $cb and $cb->( 'deploy', $node, $f );
        } else {
            $node->put_file( local=>$f, add_path=>$base_path );
            ref $cb and $cb->( 'deploy', $node, $f );
        }
    });
}

=head2 run

Run remote scripts for this destination

=cut
sub run {
    my ($self, %args ) = @_;
    my $cb = $args{callback};
    my $node = $self->destination;
    $self->each_script( sub {
       my $ci = $_;
       # now run it
       my $ret = $ci->run;
       ref $cb and $cb->( 'run',$ci, $ci->{script} );
    });
}

=head2 deploy_and_run

Do both, in that order.

=cut
sub deploy_and_run {
    my ($self, %args ) = @_;
    $self->deploy( %args );
    $self->run( %args );
}

sub push_vars {
    my ($self, %vars ) = @_;
    $self->vars({  %{ $self->vars }, %vars });
}

sub parse_vars {
    my ($self, $str ) = @_;
    Baseliner::Utils::parse_vars( $str, $self->vars );
}

1;
