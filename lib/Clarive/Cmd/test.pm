package Clarive::Cmd::test;
use v5.10;
use strict;
use warnings;
use Mouse;
use Path::Class;

extends 'Clarive::Cmd';

our $CAPTION = 'run tests';

use Try::Tiny;
use Test::Harness;
use Test::More;
use Capture::Tiny qw(capture_merged capture);
use Path::Class qw(dir file);
use Baseliner::Utils qw(_array);

has color => qw(is rw default 1);
has verbose_tests => qw(is rw isa Num default 0);

sub run {
    my ($self, %opts)=@_;

    my $harness = TAP::Harness->new(
        {
            color     => $self->color,
            verbosity => $self->verbose || $self->verbose_tests,
            exec      => sub {
                my ( $harness, $test_file ) = @_;

                my $builder = Test::More->builder;

                # reset the Test::Builder object for every "file"
                $builder->reset;
                $builder->{Indent} = '';    # may not be needed

                # collect the output into $out
                $builder->output( \my ($out) );       # STDOUT
                $builder->failure_output( \my ($err) );    # STDERR
                $builder->todo_output( \$out );       # STDOUT

                local $SIG{'INT'} = sub { die "User cancelled tests\n" };

                # run the test
                my $rc;
                ($out,$err) = capture {
                    system qq{./bin/cla exec $0 test-file $test_file};
                    $rc = $?;
                };

                if( $self->app->verbose ) {
                    print STDERR $out;
                }

                if( $rc || length $err ) {
                    print STDERR $err;
                }

                # the output ( needs at least one newline )
                return $out || "\n";
            }
        }
    );


    my @test_files;

    my $cb = sub {
        my $f = shift;
        return if -d $f;
        push @test_files, "$f";
    };


    if ( my @arg_files = _array( $opts{args}{''} ) ) {
        for my $file (@arg_files) {
            if ( -d $file ) {
                dir( $file )->recurse( callback => $cb );
            }
            else {
                push @test_files, $file;
            }
        }
    }
    else {
        dir('t')->recurse( callback => $cb );
    }

    $harness->runtests( sort @test_files );
}

sub run_file {
    my ($self, %opts)=@_;

    local $SIG{'INT'} = sub { die "CLA-TESTRUNFILE-INT\n" };

    use lib 't/lib';

    if ( my @arg_files = _array( $opts{args}{''} ) ) {
        do( shift @arg_files );
    }
}

1;
