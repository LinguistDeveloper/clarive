package TestDriver;
use strict;
use warnings;
use base 'Selenium::Firefox';

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
}

sub wait_for {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    my $start = time;
    while (1) {
        last if time - $start > 5;

        my $elements = $self->find_elements( $selector, $type );

        foreach my $element (@$elements) {
            return $element if $element->is_displayed;
        }
    }

    $self->quit();

    die "element '$selector' not present";
}

1;
