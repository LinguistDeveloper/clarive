package BaselinerX::CA::Harvest::Namespace::Application;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::Namespace::Application';

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
		( my $env_short = $row->environmentname )=~ s/\s/_/g;
		_log "Creating namespace $env_short";
		return {
                ns      => 'harvest.project/' . $env_short,
                ns_name => $env_short,
				ns_type => _loc('Harvest Project'),
				ns_id   => $row->envobjid,
				ns_data => { $row->get_columns },
                icon    => '/static/images/application.gif',
                provider=> 'namespace.harvest.project',
                related => [  ],
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub checkout {
    #TODO 
}

sub project_viewpaths { 
    my ($self, %p ) = @_;
    my $hardb = BaselinerX::CA::Harvest::DB->new;
    grep { length > 1 } $hardb->viewpaths_for_env( $self->ns_data->{envobjid}, $p{query} ); 
}

sub viewpath_query { 
    my ($self, $query ) = @_;
    my $hardb = BaselinerX::CA::Harvest::DB->new;
    grep { length > 1 } $hardb->viewpaths_query( $query ); 
}

1;
