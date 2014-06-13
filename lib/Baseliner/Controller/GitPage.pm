package Baseliner::Controller::GitPage;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use namespace::clean;

require Git::Wrapper;
BEGIN { extends 'Catalyst::Controller' }

=head2 commit

    repo_dir: xxxxxxx
    sha: xxxxxxxxxx

=cut
sub commit : Local  {
    my ($self, $c, $repo, $sha) = @_;
    my $node = $c->req->params;
    my $url = sprintf '/gitweb.cgi?p=%s;a=commitdiff;h=%s', $node->{repo_dir}, $node->{sha};
    $c->stash->{template} = $url;
}

sub commit_real : Local  {
    my ($self, $c, $repo, $sha) = @_;
    my $node = $c->req->params;
    #my $git  = Git::Wrapper->new( $node->{repo_dir} );
    $repo = Girl::Repo->new( path=>$node->{repo_dir} );
    my $git = $repo->git->git;
    $sha = $node->{sha};
    my $commit = $repo->commit( $sha );
    my $changes = [
        $git->show( { }, $sha )
    ];
    $c->stash->{changes} = $changes;
    $c->stash->{template} = '/git/commit.html'; 
}

sub commit_tree : Local  {
    my ($self, $c, $repo, $sha) = @_;
    my $node = $c->req->params;
    my $git  = Git::Wrapper->new( $node->{repo_dir} );
    $sha = $node->{sha};
    my $changes = [
        map {
            my $file = $_;
            +{ 
                text       => $file,
                icon       => '/static/images/icons/lc/status-m.gif',
                leaf => \1,
             }
        }
        grep { length }
        map { my $s = $_; $s =~ s/^\s+//g; $s }
        $git->show( { pretty => 'format:', name_only => 1 }, $sha )
    ];
    $c->stash->{json} = $changes;
    # TODO not implemented actually
}

sub branch : Local  {
    my ($self, $c, $repo, $sha) = @_;
    my $node = $c->req->params;
    my $git  = Git::Wrapper->new( $node->{repo_dir} );

    $c->stash->{prefix} = $node->{prefix};
    $c->stash->{branch} = $node->{branch};
    $c->stash->{form} = {
        description => 'some branch',     
    };
    $c->stash->{commits} = [
        map {
            my ( $rev_sha, $rev_txt ) = $_ =~ /^(.+?) (.*)/;
            my $sha6 = substr( $rev_sha, 0, 6 );
            +{ 
                name    =>  $rev_txt,
                sha     =>  $rev_sha,
             }
        } $git->rev_list( { pretty => 'oneline' }, $node->{branch} )
    ];
    $c->stash->{template} = '/git/branch.html'; 
}

sub show_file : Local  {
    my ($self, $c, $repo, $sha) = @_;
    my $node = $c->req->params;
    my $git  = Git::Wrapper->new( $node->{repo_dir} );
    $sha = $node->{sha};
    # TODO get file contents 
    # $git->show( { pretty => 'format:', name_only => 1 }, $sha )
    $c->stash->{template} = '/git/commit.html'; 
}

1;
