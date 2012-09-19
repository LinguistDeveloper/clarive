package BaselinerX::Provider::Changeset;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use BaselinerX::Namespace::Changeset;

with 'Baseliner::Role::Provider';
with 'Baseliner::Role::Namespace::Create';

register 'namespace.changeset' => {
    name    =>_loc('Clarive Changeset'),
    domain  => domain(),
    can_job => 1,
    finder =>  \&find,
    handler =>  \&list,
};

sub namespace { 'BaselinerX::Namespace::Changeset' }
sub domain    { 'changeset' }
sub icon      { '/static/images/icons/changeset.png' }
sub name      { 'Changeset' }

# returns the first rows it finds for a given name
sub get { find(@_) }
sub find {
    my ($self, $nsid ) = @_;
    my ( $mid, $project, $title ) = $self->_break_ns( $nsid );
    my $id_project = try {
        [
            map { $_->{mid} }
            DB->BaliTopic->find( $mid )->projects->hashref->all
        ]->[0];
    } catch {};

    BaselinerX::Namespace::Changeset->new({
            ns       => "changeset/$nsid",
            mid     => $nsid,
            ns_name  => $title,
            ns_info  => $title,
            ns_type  => 'changeset',
            ns_data  => { project=>$project, mid=>$mid, id_project=>$id_project },
            icon     => '/static/images/icons/changeset.gif',
            provider => 'namespace.changeset',
            related  => [],
    });
}

sub _break_ns {
    my ($self, $nsid ) = @_;

    if( $nsid =~ /(.*)\/(.*)$/ ) {
        $nsid = $2;
    }

    if( defined $nsid ) {
        my $mid = $nsid;
        my $topic = Baseliner->model('Baseliner::BaliTopic')->find( $mid );
        my $project = try {
            my $projectid = $topic->projects->search()->first->mid;
            Baseliner::Model::Projects->get_project_name( mid => $projectid );
        } catch { '' };
        return ( $mid, $project, $topic->title );
    } else {
        _throw "Invalid changeset id $nsid";
    }
}

sub list {
    my ( $self, $c, $p ) = @_;
    _log "provider list started...";
    my $bl_next = $p->{bl};

    my $rfc   = $p->{rfc};
    my $query = $p->{query};
    my $start = $p->{start};
    my $limit = $p->{limit};

    $start ||= 0;
    $limit ||= 25;

    _log '########################## '.$query;
    my $re    = qr/$query/i;
    my @ns;
    my $total = 0;
    my $cnt   = 0;

    my @state_names =
        lifecycle->state_names_for_bl( $p->{job_type} eq 'promote' ? 'bl_to' : 'bl_from',
        $bl_next );

    # TODO git here?
    if( ! $c->model('Git') ) {
        return {data => [], total => 0, count => 0};
    }
    #get all repositories
    for my $project ( $c->model( 'Git' )->repositories ) {

        # all repositories for project
        my @all = grep { defined $_->{repo} }
            map {
            my $repoobj = try { Girl::Repo->new( path => $_->{path} ) } catch { undef };
            +{repo => $repoobj, %$_};
            } _array $project->{repositories};

        # for each project
        for my $repo ( @all ) {

            # get tags
            for my $state ( @state_names ) {

                _log "Git getting tags that contain state '$state'";
                my @tags = Baseliner->model( 'Git' )->tags_for_bl(
                    repo_name  => $repo->{name},
                    repo       => $repo->{repo},
                    state_name => $state,
                    project    => $project->{project}
                );
                _log '%%%%%%% ' . join ",", @tags;
                @tags = grep {
                    ($_->name . $_->description) =~ $re;
                } @tags;

                $total += scalar @tags;

                @tags = splice @tags, $start, $limit;

                $cnt   += scalar @tags;

                push @ns, map {

                    #my $nsid = sprintf 'git.revision/%s@%s', $_->name, $repo->path;
                    my $nsid = sprintf 'git.revision/%s@%s:%s', $_->name, $project->{project},
                        $repo->{name};
                        my $title;
                        BaselinerX::Namespace::Changeset->new({
                                ns       => "$nsid",
                                ns_name  => $title,
                                ns_info  => $title,
                                ns_type  => 'changeset',
                                ns_data  => { project=>$project },
                                icon     => '/static/images/icons/changeset.gif',
                                provider => 'namespace.changeset',
                                related  => [],
                        }
                    );
                } @tags;
            } ## end for my $state ( @state_names)
        } ## end for my $repo ( @all )
    } ## end for my $project ( $c->model...)

    _log "****** Dev *******\n" . _dump {data => \@ns, total => $total, count => $cnt};
    return {data => \@ns, total => $total, count => $cnt};
} ## end sub list


sub create {
    my ($self, %p ) = @_;
    
    my $env = Baseliner->model('Harvest::HarEnvironment')->find( $p{envobjid } );
    _throw _loc("Harvest Environment %1 not found", $p{envobjid} ) unless ref $env;
    my $config = config_get 'config.ca.harvest.cli';
    my $cli = new BaselinerX::CA::Harvest::CLI({ broker=>$config->{broker}, login=>$config->{login} });
    my $cp_proc = $config->{package_create_process};
    my $state =  $config->{package_create_state};  #TODO consider using a hashref on BL
    my %args = (
        cmd   =>'hcp',
        -en   => $env->environmentname,
        -st   => $state,
        args  =>$p{packagename},
    );
    $args{-pn} = $cp_proc if $cp_proc;
    my $cp = $cli->run( %args );
    return { rc=>$cp->{rc} , output=>$cp->{msg} };
}

sub create_form_url { '/harvest/create_form' }

1;

