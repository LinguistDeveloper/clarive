package BaselinerX::Namespace::Project;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;

with 'Baseliner::Role::Namespace::Project';

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
		return {
                ns      => 'project/' . $row->id,
                ns_name => $row->name,
				ns_type => _loc('Project'),
				ns_id   => $row->id,
				ns_data => { $row->get_columns },
                icon_on => '/static/images/application.gif',
                icon_off=> '/static/images/application.gif',
                provider=> 'namespace.project',
                related => [  ],
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub checkout { }

sub parents {
	my ($self) = @_;
	my $dad = $self->{ns_data}->{id_parent} ;
	return unless defined $dad;
	#return ns_get( 'project/' . $dad );
	return 'project/' . $dad;
}

=head1 DESCRIPTION

A project object.

=cut

1;

