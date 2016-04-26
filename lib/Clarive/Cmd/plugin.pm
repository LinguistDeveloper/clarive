package Clarive::Cmd::plugin;
use v5.10;
use strict;
use warnings;
use Mouse;

extends 'Clarive::Cmd';

use Capture::Tiny qw(capture_merged capture_stdout);
use Path::Class qw(dir file);

use Clarive::Code;

our $CAPTION = 'plugin utilities';

use Try::Tiny;
use Test::Harness;
use Test::More;

has color => qw(is rw default 1);

*run = \&run_list;

sub run_list {
    my ($self, %opts)=@_;

    my @plugins = $self->app->plugins->all_plugins;
    my @infos = map { $self->app->plugins->load_info($_) } @plugins;

    for my $info ( sort { lc $a->{id} cmp lc $b->{id} } @infos ) {
        my $ver_str = $info->{version} ? "($info->{version})" : '';
        say sprintf '%s: %s %s', $info->{id}, $info->{name}, $ver_str;
    }
}

sub run_info {
    my ($self, %opts)=@_;

    my ($id) = ($opts{plugin}) || @{ $opts{argv} || [] };
    die "Missing plugin id/name --plugin\n" unless $id;

    my $home = $self->app->plugins->locate_plugin($id);

    die "Plugin `$id` not found\n" unless $home;

    my $info = $self->app->plugins->load_info($home);

    say "Info for plugin $id:";
    $info->{location} = $home;
    say Util->_dump($info);

    my @files;
    dir($home)->recurse( callback=>sub{
        my $file = shift;
        return if -d $file;
        push @files, "$file";
    });
    say '---';
    say for sort @files;

    $info;
}

sub run_test {
    my ($self, %opts)=@_;

    my $harness = TAP::Harness->new({
            color => $self->color,
            verbosity => $self->verbose,
            exec => sub{
                my ( $harness, $test_file ) = @_;


                my $builder = Test::More->builder;

                # reset the Test::Builder object for every "file"
                $builder->reset;
                $builder->{Indent} = ''; # may not be needed

                # collect the output into $out
                $builder->output(\my($out));     # STDOUT
                $builder->failure_output(\$out); # STDERR
                $builder->todo_output(\$out);    # STDOUT

                # run the test
                try {
                    Clarive::Code->new->run_file( $test_file );
                } catch {
                    my $err = shift;
                    fail( $err );
                };

                # the output ( needs at least one newline )
                return $out || "\n";
            }
    });


    my @test_files;

    my $plugins = $self->app->plugins;

    if( my @arg_files = @{ $opts{argv} || [] } ) {
        for my $file ( @arg_files ) {
            if( my $first = $plugins->locate_first( "t/$file" ) ) {
                if( -d $first->{path} ) {
                    dir($first->{path})->recurse( callback=>sub{
                        my $f = shift;
                        return if -d $f;
                        say "Found test file: $f";
                        push @test_files, $f;
                    });
                } else {
                    say "Found test file: $first->{path}";
                    push @test_files, $first->{path};
                }
            } else {
                die "ERROR: Test file `$file` not found\n";
            }
        }
    } else {
        $plugins->for_each_file('t', sub{
            my ( $file,$plugin_name ) = @_;
            push @test_files, "$file";
        });
    }

    $harness->runtests( @test_files );
}

sub run_new {
    my ($self, %opts)=@_;

    my $id = $opts{plugin};
    die "Missing plugin id/name --plugin\n" unless $id;

    my $home = $self->app->plugins_home;

    die "Could not find plugins home: $home\n" unless -e $home;

    $home = dir($home, $id);

    die "Plugin `$id` already exists: $home\n" if -e $home;

    say "Creating plugin boilerplate for `$id` at `$home`";

    $home->mkpath;

    my $plugin_yml = file($home,'plugin.yml');
    say "Creating $plugin_yml";
    my $author = $opts{author} // 'The Author';
    my $year = 1900 + [localtime]->[5];
    $plugin_yml->spew(sprintf <<'END', $opts{name}//$id, $opts{version}//'1.0', $author, $year, $author);
name: %s
version: %s
author: %s
license: |+
    Copyright (c) %s %s

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
END
    for my $dir ( qw(init public modules t cmd) ) {
        say "Creating $dir/...";
        dir($home,$dir)->mkpath;
    }
}

1;
