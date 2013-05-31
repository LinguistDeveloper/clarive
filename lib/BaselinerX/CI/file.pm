=head1 file

file is a local file. 

=cut
package BaselinerX::CI::file;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Item';

sub icon { '/static/images/icons/file.gif' }

has _lines => qw(is rw isa ArrayRef lazy 1), default=>sub{
    my ($self)=@_;
    my @lines = Util->_file( $self->path )->slurp ;
    \@lines;
};

sub _lines2 {
    my ($self)=@_;
    my @lines = Util->_file( $self->path )->slurp ;
    \@lines;
};

sub slurp {
    my ($self)=@_;
    return unless ! $self->is_dir;
    return wantarray ? @{ $self->_lines2 } : join( '', @{ $self->_lines2 } );
}

sub done_slurping {
    $_[0]->_lines([]);
}


1;

