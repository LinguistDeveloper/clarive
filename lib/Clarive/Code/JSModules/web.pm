package Clarive::Code::JSModules::web;
use strict;
use warnings;

use Clarive::Code::JSUtils;
use BaselinerX::UA;

sub generate {
    my $class = shift;
    my $stash = shift;
    my $js    = shift;

    +{
        agent => js_sub {
            my $opts = shift;

            my $ua = $class->_build_ua(%$opts);

            return {
                request  => js_sub { $ua->request(@_) },
                get      => js_sub { $ua->get(@_) },
                head     => js_sub { $ua->head(@_) },
                post     => js_sub { $ua->post(@_) },
                postForm => js_sub { $ua->post_form(@_) },
                put      => js_sub { $ua->put(@_) },
                delete   => js_sub { $ua->delete(@_) },
                mirror   => js_sub { $ua->mirror(@_) },
              }
        }
    };
}

sub _build_ua {
    my $self = shift;
    my (%params) = @_;

    return BaselinerX::UA->new(%params);
}

1;
