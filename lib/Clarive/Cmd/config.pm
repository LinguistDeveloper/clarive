package Clarive::Cmd::config;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use strict;

our $CAPTION = 'show all inherited config & options';

sub run_show {
    my ($self, %opts)=@_;
    say $self->app->yaml( $opts{key} ? $self->app->config->{ $opts{key} } : $self->app->config );
}

sub run_opts {
    my ($self)=@_;
    say $self->app->yaml( $self->app->opts );
}

sub run {
    my ($self)=@_;
    goto &run_show;
}

1;
