package BaselinerX::CI::project;
use Baseliner::Moose;
use Baseliner::Utils;

with 'Baseliner::Role::CI::Project';
with 'Baseliner::Role::CI::VariableStash';

sub icon { '/static/images/icons/project.png' }

has_cis 'bls';
has_cis 'repositories';
has_ci 'parent_project';

has_cis 'assets';
has_cis 'folders';

sub rel_type { 
    { 
        bls            => [ from_mid => 'project_bl'],
        repositories   => [ from_mid => 'project_repository'],
        parent_project => [ from_mid => 'project_project'] ,
        assets         => [ from_mid => 'project_asset' ],
        folders        => [ from_mid => 'project_folder' ]
    },
}

service 'scan' => 'Run Scanner' => sub {
    return 'Project scanner disabled';   
};

method user_has_action( :$username, :$action=undef ) {
    return scalar grep { $_ == $self->mid } Baseliner->model( 'Permissions' )
        ->user_projects_with_action( username=>$username, action=>$action );
}

after save_data => sub {
    my ($self, $master_row, $data, $opts, $old ) = @_;
    # update jobs with new project name, TODO this can be potentially very slow, put this in a queue
    if( $$opts{changed}{name} && defined $$old{name} ) {
        map { 
            _debug "Updating project name in job " . $_->mid; 
            $_->build_job_contents(1);
        } ci->job->search_cis( projects=>mdb->in($self->mid) );

    }
    # create relationships with variables
    _debug( $self->variables );
    my $allvars = $self->variables || {};
    mdb->master_rel->remove({ from_mid=>$self->mid, rel_field=>'variables', rel_type=>'project_variable' });
    my @var_cis;
    for my $bl ( keys %$allvars ) {
        my $vars = $allvars->{$bl} || {};
        for my $var ( %$vars ) {
            if( my $meta = ci->variable->search_ci( name=>$var ) ) {
                push @var_cis, grep { length } _array( split /,/, $vars->{$var} ) if $meta->is_ci;  # TODO while are we still splitting this?? 
            }
        }
    }
    mdb->master_rel->insert({ from_mid=>$self->mid, to_mid=>$_, rel_type=>'project_variable', rel_field=>'variables' }) for _unique( @var_cis );
};
    
sub merged_variables {
    my ($self, $bl)=@_;
    $bl //= '*';
    my $vars = BaselinerX::CI::variable->default_hash($bl);
    my $variables = ref $self->variables ? $self->variables->{$bl//'*'} : {};

    for my $key ( keys %$variables ) {
        $vars->{$key} = $variables->{$key}; 
    }

    return $vars;
}

1;
