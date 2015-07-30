package Baseliner::Controller::Git;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use Path::Class;

BEGIN { extends 'Catalyst::Controller' }

#register 'menu.tools.git' => {
#    label    => 'Git Repositories',
#    url      => '/git/main',
#    title    => 'Git',
#    icon     => '/gitweb/images/icons/git.png',
#    actions  => [ 'action.git.view_repo' ]
#};

sub main : Local {
    my ($self, $c) = @_;
    my $config = config_get 'config.git';
    $c->stash->{repositories} = [ map {
        +{
            name=>$_,
        }
    } glob "$config->{home}/*" ];
    $c->stash->{template} = '/site/git/main.html';
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
