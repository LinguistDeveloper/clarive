package TestDriver;
use strict;
use warnings;
use base 'Selenium::Firefox';

use Time::HiRes qw(usleep);

sub resolve {
    my ($name) = @_;

    if ( $name eq 'loginButton' ) {
        return 'input[name=login]';
    }
}

sub get_fresh {
    my $self = shift;

    $self->delete_all_cookies;

    $self->get('localhost:3000');

    $SIG{__DIE__} = sub {
        eval { $self->quit }
    }
}

sub wait_for_element_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    usleep(300_000); # 0.3

    my $start = time;
    while (1) {
        last if time - $start > 5;

        my $elements = $self->find_elements( $selector, $type );

        foreach my $element (@$elements) {
            if ($element->is_displayed) {
                usleep(300_000); # 0.3
                return $element;
            }
        }

        usleep(300_000); # 0.3
    }

    die "element '$selector' not present";
}

1;
