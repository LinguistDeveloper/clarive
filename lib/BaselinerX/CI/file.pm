=head1 file

file is a local file. 

=cut
package BaselinerX::CI::file;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Item';

sub icon { '/static/images/icons/file.gif' }

sub slurp {
    my ($self)=@_;
    return unless ! $self->is_dir;
    Util->_file( $self->path )->slurp ;
}


1;

