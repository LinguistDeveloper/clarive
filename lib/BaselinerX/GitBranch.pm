package BaselinerX::GitBranch;
use Moose;

has repo_dir => qw/is rw isa Str required 1/;
has repo_name => qw/is rw isa Str required 1/;
has project => qw/is rw isa Str required 1/;
has bl => qw/is rw isa Any/;
has head => qw/is rw isa Any required 1/, 
    #handles => qr/.*/;
    ;
has name => qw/is rw isa Str required 1/;
has bl_to => qw/is rw isa Any/;
has bl_from => qw/is rw isa Any/;
has promotable => qw/is rw isa Bool default 0/;
has demotable => qw/is rw isa Bool default 0/;
has status => qw/is rw isa Str default trunk/;   # trunk, merged, pending (merge)
has description => qw/is rw isa Any /, default => '';
has repo_mid => qw/is rw isa Any/;

with 'Baseliner::Role::LC::Changeset';

sub text {
    my $self = shift;
    $self->name . ( $self->description ? ' (' . $self->description . ')' : '' );
}

sub node_id {
    my $self = shift;
    #$self->head->sha1;
}

sub node_url { '/gittree/branch' }

sub node_menu {
    my $self = shift;
    my @menu;
    my $sha = ''; #try { $self->head->{commit}->id } catch {''};
    push @menu,
        {
        text => 'Deploy',
        eval => { url => '/comp/git/deploy.js', title => 'Deploy' },
        icon => '/static/images/silk/arrow_right.gif'
        };
    $self->promotable and push @menu,
        {
        text => 'To Promote',
        eval => { url => '/comp/git/promote.js', title => 'Promote' },
        icon => '/static/images/silk/arrow_down.gif'
        };
    $self->demotable and push @menu,
        {
        text => 'Demote',
        eval => { url => '/comp/git/demote.js', title => 'Demote' },
        icon => '/static/images/silk/arrow_up.gif'
        };
    push @menu,
        {
        text => 'Create Tag...',
        eval => { url => '/comp/git/tag_commit.js', title => 'Create Tag...' },
        icon => '/static/images/icons/tag.gif',
        data => { sha => $sha },
        };
    \@menu;
}

sub _click {
    my $self = shift;
    +{
            url      => sprintf( '/gitweb.cgi?p=%s;a=shortlog;h=%s', $self->repo_dir, $self->name ),
            type     => 'iframe',
            #url      => '/gitpage/branch',
            #type     => 'html',
            repo_dir => $self->repo_dir,
            title    => $self->name,
            repo_mid => $self->repo_mid,
     }
}
sub node_data { 
    my $self = shift;
    +{  repo_dir   => $self->repo_dir,
        name       => $self->name,
        branch     => $self->name,
        bl_to      => $self->bl_to,
        bl_from    => $self->bl_from,
        promotable => $self->promotable,
        demotable  => $self->demotable,
        provider   => 'Git Revision',
        icon       => $self->icon,
        repo_name  => $self->repo_name,
        project    => $self->project,
        ns         => sprintf( "git.revision/%s@%s:%s", $self->name, $self->project, $self->repo_name ),
        click      => $self->_click,
        tab_icon => $self->icon,
        repo_mid => $self->repo_mid,
    }
}

1;
