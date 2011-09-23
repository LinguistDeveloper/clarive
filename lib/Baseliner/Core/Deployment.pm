package Baseliner::Core::Deployment;
=head1 NAME

Baseliner::Core::Deployment - Base object for deploying and executing scripts remotely

=head1 DESCRIPTION

Maps a single destination node with many source (origin) 
files and dirs. 

Runs a list of scripts on each node.

=cut
use Moose;
use Baseliner::Node;
use Path::Class;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'PathClass',
  as 'Object',
  where { $_->isa('Path::Class::Dir') || $_->isa('Path::Class::File') };


has origin  => qw/is ro isa ArrayRef[PathClass] required 1/,
               traits  => ['Array'],
               handles => { each_origin => 'map', count=>'count' };

has destination => qw/is ro does Baseliner::Role::Node::Filesys required 1/;
has scripts     => qw/is ro isa ArrayRef[Str] required 0/, default=>sub { [] },
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
    ref $args{destination} or $args{destination} = Baseliner::Node->new( $args{destination} );
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
    $self->each_origin( sub {
        if( $_->is_dir ) {
            $node->put_dir( local=>$_ );
            ref $cb and $cb->( $node );
        } else {
            $node->put_file( local=>$_ );
            ref $cb and $cb->( $node );
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
       $node->execute( $_ ); 
       ref $cb and $cb->( $node );
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

1;
