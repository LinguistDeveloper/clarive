package BaselinerX::Service::GenericServices;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;
with 'Baseliner::Role::Service';

register 'service.get_date' => {
    data    => { date => '' },
    form    => '/forms/get_date.js',
    icon    => '/static/images/icons/calendar.svg',
    name    => _locl('Get date'),
    handler => \&get_date,
};

sub get_date {
    my ( $self, $c, $config ) = @_;

    my $format = $config->{format} || "%Y-%m-%d %H:%M:%S";
    local $Class::Date::DATE_FORMAT = $format;

    my $date = $config->{date};

    my $date_formatted = $date ? Class::Date->new($date) : Class::Date->now();

    if (!$date_formatted) {
        _fail _loc( "Date %1 is not a valid date: %2", $date, shift );
    }

    return '' . $date_formatted;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
