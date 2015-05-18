=head1 folder

folder is a generic ci folder stored in Clarive's db.

Usually used to store CIs, may store any ci really. 

=cut
package BaselinerX::CI::folder;
use Baseliner::Moose;

with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/views.png' }

has_ci 'parent_folder';
has_cis 'cis';

sub rel_type { 
    { 
        parent_folder  => [ to_mid => 'folder_folder'],
        cis            => [ to_mid => 'folder_ci'],
    },
}


1;
