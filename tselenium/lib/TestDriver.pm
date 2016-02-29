package TestDriver;
use strict;
use warnings;
use base 'Selenium::Firefox';

use Time::HiRes qw(usleep);
use TestExtJsComponent;

sub resolve {
    my ($name) = @_;

    if ( $name eq 'loginButton' ) {
        return 'input[name=login]';
    }
}

sub find_extjs_component {
    my $self = shift;

    my $cmps = $self->find_extjs_components(@_);
    return $cmps->[0];
}

sub find_extjs_components {
    my $self = shift;
    my ( $selector, $type ) = @_;

    my $script = q{
       var selector = arguments[0];

       var elems = [];
       Ext.Element.select(selector).each(function(elem) {
           elems.push(elem);
       });

       return elems;
   };

    my $cmps = $self->execute_script( $script, $selector );
    return [ map { TestExtJsComponent->new( elem => $_, driver => $self ) } @$cmps ];
}

sub get_fresh {
    my $self = shift;
    my ($hostname) = @_;

    $hostname //= $ENV{TEST_SELENIUM_HOSTNAME} || 'localhost:3000';

    $self->delete_all_cookies;

    $self->get($hostname);

    $SIG{__DIE__} = sub {
        eval { $self->quit };
      }
}

sub wait_for_element_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    usleep(300_000);    # 0.3

    my $start = time;
    while (1) {
        last if time - $start > 5;

        my $elements = $self->find_elements( $selector, $type );

        foreach my $element (@$elements) {
            if ( $element->is_displayed ) {
                usleep(300_000);    # 0.3
                return $element;
            }
        }

        usleep(300_000);            # 0.3
    }

    die "element '$selector' not present";
}

1;
