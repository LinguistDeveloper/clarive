package Baseliner::Model::PromotesAndDemotes;
use Moose;

use experimental 'smartmatch';
use Array::Utils qw(intersect);
use Baseliner::Model::Topic;
use Baseliner::Model::Permissions;
use Baseliner::Utils qw(_fail _loc _unique _array);

sub promotes_and_demotes_menu {
    my ( $self, %p ) = @_;
    my ( $topic, $username, $bl_state, $state_name, $id_status_from, $id_project, $categories ) =
      @p{qw/topic username bl_state state_name id_status_from id_project categories/};

    my @job_transitions = $self->promotes_and_demotes(
        username       => $username,
        topic          => $topic,
        id_status_from => $id_status_from,
        id_project     => $id_project
    );

    my @static  = grep { $_->{job_type} eq 'static' } @job_transitions;
    my @promote = grep { $_->{job_type} eq 'promote' } @job_transitions;
    my @demote  = grep { $_->{job_type} eq 'demote' } @job_transitions;

    my %maps_s = map { $_->{id} => \1 } @static;
    my %maps_p = map { $_->{id} => \1 } @promote;
    my %maps_d = map { $_->{id} => \1 } @demote;
    my $menu_s = $self->_build_menus( \@static );
    my $menu_p = $self->_build_menus( \@promote );
    my $menu_d = $self->_build_menus( \@demote );

    return ( \%maps_s, \%maps_p, \%maps_d, $menu_s, $menu_p, $menu_d );
}

sub promotes_and_demotes {
    my ( $self, %p ) = @_;

    my ( $username, $topic, $id_status_from, $id_project ) =
      @p{qw/username topic id_status_from id_project/};

    my @topics = ($topic);

    if ( $topic->{category}->{is_release} ) {
        my $ci = ci->new( $topic->{mid} );

        my @changesets_mids = map { $_->{mid} } $ci->children(
            mids_only => 1,
            rel_type  => 'topic_topic',
            where     => { collection => 'topic', 'category.is_changeset' => '1' },
            depth     => 1
        );
        my @changesets = mdb->topic->find( { mid => mdb->in(@changesets_mids) }, { _txt => 0 } )->all;
        my %changesets_by_status = map { $_->{id_category_status} => $_ } @changesets;

        @topics = values %changesets_by_status;
    }

    my @all_transitions;
    my %all_transitions_ids;

    foreach my $topic (@topics) {
        my ($transitions) = $self->_promotes_and_demotes(
            username       => $username,
            topic          => $topic,
            id_status_from => $id_status_from,
            id_project     => $id_project
        );

        my %all_transitions_ids = map { $_->{id} => 1 } @all_transitions;

        push @all_transitions, grep { !$all_transitions_ids{ $_->{id} } } @$transitions;

        $all_transitions_ids{ $_->{id} }++ for @$transitions;
    }

    if ( @topics > 1 ) {
        @all_transitions =
          sort { $a->{status_to_seq} <=> $b->{status_to_seq} || $a->{bl_to_seq} <=> $b->{bl_to_seq} } @all_transitions;
    }

    return @all_transitions;
}

sub _promotes_and_demotes {
    my ( $self, %p ) = @_;

    my ( $username, $topic, $id_status_from, $id_project ) = @p{qw/username topic id_status_from id_project/};

    $id_status_from //= $topic->{category_status}{id} // $topic->{id_category_status};
    my %statuses = ci->status->statuses;

    _fail _loc('Missing topic parameter') unless $topic;

    #Personalized _workflow!
    if ( $topic->{_workflow} && $topic->{_workflow}->{$id_status_from} ) {
        my @_workflow;
        my @user_workflow = _unique map { $_->{id_status_to} } Baseliner::Model::Topic->new->user_workflow($username);

        @_workflow = map { _array( values %$_ ) } $topic->{_workflow};

        my %final = map { $_ => 1 } intersect( @_workflow, @user_workflow );

        my @final_key = keys %final;
        map { my $st = $_; delete $statuses{$st} if !( $st ~~ @final_key ); } keys %statuses;
    }

    #end Personalized _workflow!

    my %bls = map { $$_{mid} => { bl => ( $$_{moniker} || $$_{bl} ), seq => $_->{seq} } } ci->bl->find->all;

    my ($cs_project) = ci->new( $topic->{mid} )->projects;
    my @project_bls = map { $_->{bl} } _array $cs_project->bls if $cs_project;

    my @transitions;

    for my $job_type (qw/static promote demote/) {
        my $job_type_transitions = $self->_build_transitions(
            type           => $job_type,
            topic          => $topic,
            username       => $username,
            id_status_from => $id_status_from,
            bls            => \%bls,
            statuses       => \%statuses,
            id_project     => $id_project,
            project_bls    => \@project_bls,
        );

        push @transitions, @$job_type_transitions if @$job_type_transitions;
    }

    return \@transitions;
}

sub status_list {
    my $self = shift;
    my (%params) = @_;

    my $topic    = $params{topic}    || _fail 'topic required';
    my $username = $params{username} || _fail 'username required';
    my $dir      = $params{dir}      || _fail 'dir required';
    my $status   = $params{status}   || $topic->{category_status}->{id};
    my %statuses = $params{statuses} && ref $params{statuses} eq 'HASH' ? %{ $params{statuses} } : ci->status->statuses;

    my @user_roles = Baseliner::Model::Permissions->new->user_roles_ids( $username, topics => $topic->{mid} );

    my @user_workflow = _unique map { $_->{id_status_to} } Baseliner::Model::Topic->new->user_workflow(
        $username,
        categories  => [ $topic->{category}->{id} ],
        status_from => $status,
        topic_mid   => $topic->{mid}
    );

    my @workflow = Baseliner::Model::Topic->new->get_category_workflow(
        id_category => $topic->{category}->{id},
        username    => $username
    );

    my %seen;

    my @available_statuses;
    foreach my $workflow (@workflow) {
        next unless $workflow->{job_type} && $workflow->{job_type} eq $dir;
        next unless grep { $workflow->{id_role} eq $_ } @user_roles;

        next unless $workflow->{id_status_from} eq $status;

        next unless grep { $workflow->{id_status_to} eq $_ } @user_workflow;

        my $transition = join ',', ( map { $_ // '' } $workflow->{id_status_from}, $workflow->{id_status_to} );
        next if $seen{$transition}++;

        push @available_statuses, $statuses{ $workflow->{id_status_to} };
    }

    return sort { $a->{seq} <=> $b->{seq} } @available_statuses;
}

sub _build_menus {
    my $self = shift;
    my ($transitions) = @_;

    my $icons = {
        static  => '/static/images/icons/arrow-right-color.svg',
        promote => '/static/images/icons/arrow-down-short-color.svg',
        demote  => '/static/images/icons/arrow-up-short-color.svg',
    };

    my @menus;
    foreach my $transition (@$transitions) {
        push @menus,
          {
            text => $transition->{text},
            eval => {
                id         => $transition->{id},
                job_type   => $transition->{job_type},
                id_project => $transition->{id_project},
                url        => '/comp/lifecycle/deploy.js',
            },
            id_status_from => $transition->{id_status_from},
            icon           => $icons->{ $transition->{job_type} }
          };
    }

    return \@menus;
}

sub _build_transitions {
    my $self = shift;
    my (%params) = @_;

    my $type           = $params{type};
    my $topic          = $params{topic};
    my $username       = $params{username};
    my $id_status_from = $params{id_status_from};
    my $statuses       = $params{statuses};
    my $bls            = $params{bls};
    my $project_bls    = $params{project_bls};
    my $id_project     = $params{id_project};

    my @statuses = $self->status_list(
        dir      => $type,
        topic    => $topic,
        username => $username,
        status   => $id_status_from,
        statuses => $statuses
    );

    my $transitions = [];

    for my $status (@statuses) {
        my @bls;

        my $bl_to;
        if ( $type eq 'demote' ) {
            @bls = _array $statuses->{$id_status_from}{bls};
            ($bl_to) = _array $statuses->{ $status->{id_status} }{bls};
            $bl_to = $bls->{$bl_to}->{bl};
        }
        else {
            @bls = _array $status->{bls};
        }

        for my $bl ( map { $_->{bl} } sort { $a->{seq} <=> $b->{seq} } map { $bls->{$_} } @bls ) {
            if ( !@$project_bls || $bl ~~ @$project_bls ) {
                my $id = substr( $type, 0, 1 ) . $bl . $status->{id_status};

                my $text = {
                    static  => _loc( 'Deploy to %1 (%2)',      _loc( $status->{name} ), $bl ),
                    promote => _loc( 'Promote to %1 (%2)',     _loc( $status->{name} ), $bl ),
                    demote  => _loc( 'Demote to %1 (from %2)', _loc( $status->{name} ), $bl ),
                };

                $bl_to //= $bl;
                my ($bl_to_ci) = grep { $_->{bl} eq $bl_to } values %$bls;

                push @$transitions,
                  {
                    id             => $id,
                    bl_to          => $bl_to,
                    bl_to_seq      => $bl_to_ci->{seq},
                    job_type       => $type,
                    job_bl         => $bl,
                    id_project     => $id_project,
                    is_release     => $topic->{category}->{is_release},
                    status_to      => $status->{id_status},
                    status_to_seq  => $status->{seq},
                    status_to_name => _loc( $status->{name} ),
                    id_status_from => $id_status_from,
                    text           => $text->{$type}
                  };
            }
        }
    }

    return $transitions;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
