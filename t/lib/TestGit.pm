package TestGit;

use strict;
use warnings;

use Time::Piece;
use Test::TempDir::Tiny;
use TestUtils;

my %STORE = ();

sub create_repo {
    my $class = shift;

    my $dir = tempdir();

    $ENV{GIT_AUTHOR_NAME} = $ENV{GIT_COMMITTER_NAME} = 'clarive';
    $ENV{EMAIL} = $ENV{GIT_COMMITTER_EMAIL} = $ENV{GIT_AUTHOR_EMAIL} = 'clarive@localhost';
    system(qq{cd $dir; rm -rf *; git init});

    return $dir;
}

sub commit {
    my $class = shift;
    my ( $repo, %params ) = @_;

    $STORE{"$repo"}++;

    my $timestamp = $STORE{"$repo"};

    my $datetime = Time::Piece->new($timestamp)->strftime('%Y-%m-%d %T');

    local $ENV{GIT_AUTHOR_DATE}    = $datetime;
    local $ENV{GIT_COMMITTER_DATE} = $datetime;

    $params{file}    ||= 'README';
    $params{content} ||= TestUtils->random_string;
    $params{message} ||= 'update';
    $params{action} ||= 'add';

    my $dir = $class->_parse_dir($repo);

    my $cmd = '';
    if ($params{action} eq 'add') {
        $cmd = qq{echo '$params{content}' >> $params{file}; git add .};
    }
    else {
        $cmd = $params{action};
    }

    system("cd $dir; $cmd; git commit -a -m '$params{message}'");

    my @commits = map { chomp; $_ } `cd $dir; git rev-list HEAD`;

    return $commits[0];
}

sub rev_parse {
    my $class = shift;
    my ( $repo, $ref ) = @_;

    my $dir = $class->_parse_dir($repo);

    my $sha = `cd $dir; git rev-parse '$ref'`;
    chomp $sha;

    return $sha;
}

sub commits {
    my $class = shift;
    my ($repo) = @_;

    my $dir = $class->_parse_dir($repo);

    return map { chomp; $_ } `cd $dir; git rev-list HEAD`;
}

sub create_branch {
    my $class = shift;
    my ( $repo, %params ) = @_;

    $params{branch} ||= 'new';

    my $dir = $class->_parse_dir($repo);

    system("cd $dir; git checkout -b $params{branch} 2> /dev/null");

    return $params{branch};
}

sub switch_branch {
    my $class = shift;
    my ( $repo, $branch ) = @_;

    my $dir = $class->_parse_dir($repo);

    system("cd $dir; git checkout $branch 2> /dev/null");

    return $branch;
}

sub tag {
    my $class = shift;
    my ( $repo, %params ) = @_;

    $params{tag} ||= 'TAG';

    my $dir = $class->_parse_dir($repo);

    system("cd $dir; git tag '$params{tag}' 2> /dev/null");

    return $params{tag};
}

sub tags {
    my $class = shift;
    my ($repo) = @_;

    my $dir = $class->_parse_dir($repo);

    return map { chomp; $_ } `cd $dir; git tag -l`;
}

sub _parse_dir {
    my $class = shift;
    my ($repo) = @_;

    my $repo_dir = $repo->repo_dir;
    my ($dir) = $repo_dir =~ m/^(.*)\.git$/;

    return $dir;
}

1;
