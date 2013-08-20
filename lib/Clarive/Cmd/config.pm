package Clarive::Cmd::config;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use strict;

our $CAPTION = 'show all inherited config & options';

sub run {
    my ($self)=@_;
    say $self->app->yaml( $self->app->opts );
}

sub run_config {
    my ($self)=@_;
    say $self->app->yaml( $self->app->config );
}

sub run_opts {
    goto &run;
}

1;
