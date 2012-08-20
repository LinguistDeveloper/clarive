package BaselinerX::CA::Harvest::Namespace::Environment;
use Moose;
with 'Baseliner::Role::Namespace::Application';
use Baseliner::Utils;

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
		( my $env_short = $row->environmentname )=~ s/\s/_/g;
		return {
                ns      => 'harvest.project/' . $env_short,
                ns_name => $env_short,
				ns_type => _loc('Harvest Project'),
				ns_id   => $row->envobjid,
				ns_data => { $row->get_columns },
                icon_on => '/static/images/application.gif',
                icon_off=> '/static/images/application.gif',
                provider=> 'namespace.harvest.project',
                related => [  ],
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub checkout { }

=head1 DESCRIPTION

A Harvest Environment is one of many encarnations of an application.

=cut

1;
