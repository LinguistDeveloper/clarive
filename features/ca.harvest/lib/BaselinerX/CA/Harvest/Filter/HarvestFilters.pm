package BaselinerX::CA::Harvest::Filter::HarvestFilters;
use Baseliner::Plug;
use Baseliner::Utils;

register 'config.harvest.path_in_elements' => {
    metadata => [
        { id=>'path_regex', label=>'Path Regex to check if its in the element stash. Returns true if found' }, 
    ],
};

register 'filter.harvest.path_in_elements' => {
    config  => 'config.harvest.filter.path_in_elements',
    handler => \&check_elements,
};

sub check_elements {
    my ($self, $c, $config ) = @_;
    my $job = $c->stash->{job};
    my $job_stash = $job->{job_stash};
    my $elements = $job_stash->{elements};
    my $re = $config->{path_regex} or _throw 'Missing filter config parameter path_regex';
    $re = qr/$re/;
    for my $element ( _array $elements ) {
        return 1 if $element->{path} =~ $re;
    }
    return 0;
}

1;
