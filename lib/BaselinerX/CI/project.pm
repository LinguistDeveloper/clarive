package BaselinerX::CI::project;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/project.png' }

has_cis 'repositories';
has_ci 'parent_project';

has_cis 'assets';
has_cis 'folders';

sub rel_type { 
    { 
        repositories   => [ from_mid => 'project_repository'],
        parent_project => [ from_mid => 'project_project'] ,
        assets         => [ from_mid => 'project_asset' ],
        folders        => [ from_mid => 'project_folder' ],
    },
}

service 'scan' => 'Run Scanner' => sub {
    return 'Project scanner disabled';   
};

method user_has_action( :$username, :$action=undef ) {
    return scalar grep { $_ == $self->mid } Baseliner->model( 'Permissions' )
        ->user_projects_with_action( username=>$username, action=>$action );
}

1;
