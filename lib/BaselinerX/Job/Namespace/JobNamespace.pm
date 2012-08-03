package BaselinerX::Job::Namespace::JobNamespace;
use Moose;
use Baseliner::Utils;
with 'Baseliner::Role::Namespace';

sub BUILDARGS {
    my $class = shift;

    if( defined ( my $row = $_[0]->{row} ) ) {
        my $name = $row->name;
        _log "Creating namespace $name";
        return {
                ns      => 'job/' . $name,
                ns_name => $name,
                ns_type => _loc('Job'),
                ns_id   => $row->id,
                ns_data => { $row->get_columns },
                icon    => '/static/images/icon/job.gif', 
                icon_on => '/static/images/application.gif',
                icon_off=> '/static/images/application.gif',
                provider=> 'namespace.job',
                related => [ ],
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

1;

