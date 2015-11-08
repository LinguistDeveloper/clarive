package Baseliner::Controller::Gitalist;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

# register 'menu.tools.git' => {
#     label    => 'Git',
#     title    => 'Git',
#     url_iframe => 'http://localhost:7070/',
#     icon     => '/gitweb/images/icons/git.png',
#     tab_icon     => '/gitweb/images/icons/git.png',
#     #actions  => [ 'action.git.cgit_view_repo' ]
# };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
