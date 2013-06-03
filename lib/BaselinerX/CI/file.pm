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

sub ci_form { '/ci/item.js' }

sub slurp {
    my ($self)=@_;
    return unless ! $self->is_dir;
    return wantarray ? @{ $self->_lines } 
        : $self->{_body} // ( $self->{_body}= join( '', @{ $self->_lines } ) );  # join '' is expensive, so we cache
}

sub done_slurping {
    my $self = shift;
    delete $self->{_body};
    $self->_lines([]);
}


1;

