package TestDriver;
use strict;
use warnings;
use base 'Selenium::Remote::Driver';

use Carp qw(croak);
use Time::HiRes qw(usleep);
use HTTP::Tiny;
use TestExtJsComponent;

sub resolve {
    my ($name) = @_;

    if ( $name eq 'loginButton' ) {
        return 'input[name=login]';
    }
}

sub login {
    my $self = shift;
    my ($username, $password) = @_;

    $self->get_fresh_and_ready;

    #$self->wait_for_element_not_visible('#bali-loading-mask');

    $self->wait_for_element_visible('input[name=login]')->send_keys($username);
    $self->wait_for_element_visible('input[name=password]')->send_keys($password);

    $self->wait_for_extjs_component_enabled('#login_btn')->elem->click;

    $self->wait_for_element_visible('.img-main-logo-file');
}

sub setup {
    my $self = shift;
    my ($profile) = @_;

    my $ua = HTTP::Tiny->new;

    my $response = $ua->get("http://$ENV{TEST_SELENIUM_HOSTNAME}/test/setup?profile=$profile");

    if (!$response->{success}) {
        die $response->{content};
    }
}

sub toggle_user_menu {
    my $self = shift;

    $self->wait_for_extjs_component('#user-menu')->elem->click;

    $self->wait_for_extjs_component('#user-menu-logout');
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
    my $elems = [ map { TestExtJsComponent->new( elem => $_, driver => $self ) } @$cmps ];

    return $self->_execute_with_timeout(
        sub {
            foreach my $elem (@$elems) {
                return unless $elem->is_rendered;
            }

            return $elems;
        },
        error => "element '$selector' was not rendered"
    );

    return $elems;
}

sub get_fresh {
    my $self = shift;
    my ($hostname) = @_;

    my $dimensions = `xdpyinfo | grep 'dimensions:'`;
    my ($width, $height) = $dimensions =~ m/(\d+)x(\d+)/;

    $width  ||= 1200;
    $height ||= 800;

    $self->set_window_size( $height, $width );

    $hostname //= $ENV{TEST_SELENIUM_HOSTNAME} || 'localhost:3000';

    $self->delete_all_cookies;

    $self->execute_script( "window.onbeforeunload = function(e){};" );

    $self->get($hostname);

    $SIG{__DIE__} = sub {
        eval { $self->quit };

        die @_;
    };
}

sub get_fresh_and_ready {
    my $self = shift;

    $self->get_fresh(@_);

    $self->wait_for_extjs_ready;

    return $self;
}

sub wait_for_extjs_component {
    my $self = shift;
    my ($selector) = @_;

    return $self->_execute_with_timeout(
        sub {
            my $elem = $self->find_extjs_component($selector);
            return $elem if $elem;

            return;
        },
        error => "element '$selector' was not found"
    );
}

sub wait_for_extjs_component_visible {
    my $self = shift;
    my ($selector) = @_;

    my $elem = $self->wait_for_extjs_component($selector);

    return $self->_execute_with_timeout(
        sub {
            return unless $elem->is_displayed;

            return $elem;
        },
        error => "element '$selector' was not found"
    );
}

sub wait_for_extjs_component_enabled {
    my $self = shift;
    my ($elem) = @_;

    $elem = $self->wait_for_extjs_component($elem) unless ref $elem;

    return $self->_execute_with_timeout(
        sub {
            return $elem if $elem->is_rendered && $elem->is_enabled;

            return;
        },
        timeout => 5,
        error   => "element not enabled"
    );
}

sub wait_for_element_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    return $self->_execute_with_timeout(
        sub {
            my $elements = $self->find_elements( $selector, $type );

            foreach my $element (@$elements) {
                return unless $element->is_displayed;
            }

            return $elements->[0];
        },
        timeout => 5,
        error   => "element '$selector' not present"
    );
}

sub element_present {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    my $elements = $self->find_elements( $selector, $type );

    return @$elements ? 1 : 0;
}

sub element_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    my $elements = $self->find_elements( $selector, $type );
    croak("Element '$selector' not found") unless $elements && @$elements;

    foreach my $element (@$elements) {
        croak("Element '$selector' not visible") unless eval { $element->is_displayed };
    }

    return 1;
}

sub element_not_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    my $elements = $self->find_elements( $selector, $type );

    foreach my $element (@$elements) {
        croak("Element '$selector' is visible") if eval { $element->is_displayed };
    }

    return 1;
}

sub wait_for_element_not_visible {
    my $self = shift;
    my ( $selector, $type ) = @_;

    if ( $selector =~ m/^@(.*)$/ ) {
        ( $selector, $type ) = resolve($1);
    }

    $type //= 'css';

    return $self->_execute_with_timeout(
        sub {
            my $elements = $self->find_elements( $selector, $type );

            foreach my $element (@$elements) {
                return if eval { $element->is_displayed };
            }

            return 1;
        },
        timeout => 5,
        error   => "element '$selector' is present"
    );
}

sub wait_for_extjs_ready {
    my $self = shift;

    usleep(300_000);    # 0.3

    my $script = q{ return Ext.isReady; };

    return $self->_execute_with_timeout(
        sub {
            my $is_ready = $self->execute_script($script);
            return $is_ready if $is_ready;

            return;
        },
        timeout => 5,
        error   => 'extjs was not ready'
    );
}

sub _execute_with_timeout {
    my $self = shift;
    my ( $action, %params ) = @_;

    $params{timeout} ||= 5;
    $params{error}   ||= 'timeout';

    my $start = time;
    while (1) {
        last if time - $start > $params{timeout};

        my $result = $action->();
        if (defined $result) {
            usleep(200_000);    # 0.2

            return $result;
        }

        usleep(300_000);    # 0.3
    }

    mkdir "screenshots";
    $self->capture_screenshot(sprintf 'screenshots/%s.png', time);

    croak($params{error});
}

sub wait_for {
    my $self = shift;
    my ( $action, %params ) = @_;

    $params{timeout} ||= 5;
    $params{error}   ||= 'timeout';

    my $start = time;
    while (1) {
        last if time - $start > $params{timeout};

        my $result = $action->();
        if (defined $result) {
            usleep(200_000);    # 0.2

            return $result;
        }

        usleep(300_000);    # 0.3
    }

    mkdir "screenshots";
    $self->capture_screenshot(sprintf 'screenshots/%s.png', time);

    croak($params{error});
}

sub find_element_by_jquery {
    my $self = shift;
    my ($selector) = @_;

    my $script = qq{
       var selector = arguments[0];

       return jQuery(selector).get(0);
    };

    return $self->execute_script( $script, $selector );
}

sub wait_for_element_by_jquery {
    my $self = shift;
    my ($selector) = @_;

    return $self->wait_for(
        sub {
            $self->find_element_by_jquery($selector);
        },
        error => qq{Element '$selector was not found}
    );
}

1;
