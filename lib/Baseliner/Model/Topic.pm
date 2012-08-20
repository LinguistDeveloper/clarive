package Baseliner::Model::Topic;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use Proc::Exists qw(pexists);
use v5.10;

BEGIN { extends 'Catalyst::Model' }

sub update {
    my ( $self, $p ) = @_;
    my $action = $p->{action};

    #_log "====================== \n" . _dump $p;

    my $return;
    my $topic_mid;
    my $status;
    my @rsptime = ();
    my @deadline = ();
    
    if( length $p->{priority} ) {
        @rsptime = split('#', $p->{txt_rsptime_expr_min});
        @deadline = split('#', $p->{txt_deadline_expr_min});
    }
    given ( $action ) {
        when ( 'add' ) {
            event_new 'event.topic.create' => { username=>$p->{username} } => sub {
                my $topic = master_new 'topic' => $p->{title} => sub {
                    $topic_mid = shift;    
                    Baseliner->model('Baseliner::BaliTopic')->create(
                        {   title              => $p->{title},
                            description        => $p->{description},
                            progress           => $p->{progress},
                            created_by         => $p->{username},
                            mid                => $topic_mid,
                            id_category        => $p->{category},
                            id_category_status => $p->{status_new},
                            id_priority        => $p->{priority},
                            response_time_min  => $rsptime[1],
                            expr_response_time => $rsptime[0],
                            deadline_min       => $deadline[1],
                            expr_deadline      => $deadline[0]

                        }
                    );
                };

                # files topics

                #if( my @files_uploaded_mid = split(",", $p->{files_upload_mid}) ) 
                if( my @files_uploaded_mid = split(",", $p->{files_uploaded_mid}) ) {
                    my $rs_files = Baseliner->model('Baseliner::BaliFileVersion')->search({mid =>\@files_uploaded_mid});
                    while(my $rel_file = $rs_files->next){
                        # tie file to topic
                        event_new 'event.file.create' => {
                            username => $p->{username},
                            mid      => $topic_mid,
                            id_file  => $rel_file->mid,
                            filename     => $rel_file->filename,
                        };                        
                        $topic->add_to_files( $rel_file, { rel_type=>'topic_file_version' });
                    }
                }
                
                
                # related topics
                if( my @topics = _array( $p->{topics} ) ) {
                    my $rs_topics = Baseliner->model('Baseliner::BaliTopic')->search({mid =>\@topics});
                    while(my $rel_topic = $rs_topics->next){
                        $topic->add_to_topics($rel_topic, { rel_type=>'topic_topic'});
                    }
                }
                
                # revisions
                if( my @revs = _array( $p->{revisions} ) ) {
                    @revs = split /,/, $revs[0] if $revs[0] =~ /,/ ;
                    my $rs_revs = Baseliner->model('Baseliner::BaliMaster')->search({mid =>\@revs});
                    while(my $rev = $rs_revs->next){
                        $topic->add_to_revisions($rev, { rel_type=>'topic_revision'});
                    }
                }
                
                # release
                if( my @releases = _array( $p->{release} ) ) {
                    my $row_release = Baseliner->model('Baseliner::BaliTopic')->find( $releases[0] );
                    $row_release->add_to_topics($topic, { rel_type=>'topic_topic'});
                }
                
                # projects assigned to 
                my @projects = _array( $p->{projects} );
                
                if (@projects) {
                    my $project;
                    my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({mid =>\@projects});
                    while($project = $rs_projects->next){
                        my $mid;
                        if($project->mid){
                            $mid = $project->mid
                        }
                        else{
                            my $project_mid = master_new 'project' => $project->name => sub {
                                my $mid = shift;
                                $project->mid($mid);
                                $project->update();
                            };
                        }
                        $topic->add_to_projects($project, { rel_type=>'topic_project'});
                    }

                }
                
                # users assigned to
                my @users = _array( $p->{users});
                
                if (@users){
                    my $user;
                    my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({id =>\@users});
                    while($user = $rs_users->next){
                        my $mid;
                        if($user->mid){
                            $mid = $user->mid
                        }
                        else{
                            my $user_mid = master_new 'user' => $user->username => sub {
                                my $mid = shift;
                                $user->mid($mid);
                                $user->update();
                            };
                        }
                        $topic->add_to_users( $user, { rel_type=>'topic_users' });
                    }
                }
                
                # labels
                foreach my $label_id (_array $p->{labels}){
                    Baseliner->model('Baseliner::BaliTopicLabel')->create( {    id_topic    => $topic_mid,
                                                                                id_label    => $label_id,
                                                                    });     
                }
                
                #$topic_mid    = $topic->mid;
                $status = $topic->id_category_status;
                $return = 'Topic added';
               { mid=>$topic->mid, topic=>$topic->title }   # to the event
            } 
            => sub { # catch
                _throw _loc( 'Error adding Topic: %1', shift() );
            }; # event_new
        } ## end when ( 'add' )
        when ( 'update' ) {
            event_new 'event.topic.modify' => { username=>$p->{username} } => sub {
                my @field;
                $topic_mid = $p->{topic_mid};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                if ($topic->title ne $p->{title}){ push @field, _loc('title');}
                $topic->title( $p->{title} );
                if ($topic->description ne $p->{description}){ push @field, _loc('description');}
                $topic->description( $p->{description} );
                if ($topic->id_category ne $p->{category}){ push @field, _loc('category');}
                $topic->id_category( $p->{category} ) if is_number( $p->{category} ) ;
                if ($topic->id_category_status ne $p->{status_new}){ push @field, _loc('status');}
                $topic->id_category_status( $p->{status_new} ) if is_number( $p->{status_new} );
                if ($topic->id_priority ne $p->{priority}){ push @field, _loc('priority');}
                $topic->id_priority( $p->{priority} )          if is_number( $p->{priority} );
                $topic->response_time_min( $rsptime[1] );
                $topic->expr_response_time( $rsptime[0] );
                $topic->deadline_min( $deadline[1] );
                $topic->expr_deadline( $deadline[0] );
                $topic->progress( $p->{progress} ) if $p->{progress};

                # TODO create event data for all the fields changed

                # related topics
                if( my @topics = _array( $p->{topics} ) ) {
                    #my @curr_topics = $topic->topics;
                    my @all_topics = Baseliner->model('Baseliner::BaliTopic')->search({mid =>\@topics});
                    #$topic->remove_from_topics( $_ ) for @curr_topics;
                    $topic->set_topics( \@all_topics, { rel_type=>'topic_topic'});
                }

                # revisions
                if( my @revs = _array( $p->{revisions} ) ) {
                    @revs = split /,/, $revs[0] if $revs[0] =~ /,/ ;
                    my @rs_revs = Baseliner->model('Baseliner::BaliMaster')->search({mid =>\@revs});
                    $topic->set_revisions( \@rs_revs, { rel_type=>'topic_revision'});
                } else {
                    $topic->revisions->delete;
                }
                
                # release
                if( my @releases = _array( $p->{release} ) ) {
                    my $row_release = Baseliner->model('Baseliner::BaliTopic')->find( $releases[0] );
                    my @topics = Baseliner->model('Baseliner::BaliTopic')->search({mid =>$topic->mid });
                    $row_release->set_topics( \@topics, { rel_type=>'topic_topic'});
                }
                
                # projects
                my $projects = Baseliner->model('Baseliner::BaliMasterRel')->search({from_mid => $p->{topic_mid}, rel_type => 'topic_project'})->delete;
                my @projects = _array( $p->{projects} );
                if (@projects){
                    my $project;
                    my $rs_projects = Baseliner->model('Baseliner::BaliProject')->search({mid =>\@projects});
                    while($project = $rs_projects->next){
                        my $mid;
                        if($project->mid){
                            $mid = $project->mid
                        }
                        else{
                            my $project_mid = master_new 'project' => $project->name => sub {
                                my $mid = shift;
                                $project->mid($mid);
                                $project->update();
                            }
                        }
                        $topic->add_to_projects( $project, { rel_type=>'topic_project' } );
                    }
                }
                
                # users
                my $users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $p->{topic_mid}, rel_type => 'topic_users'})->delete;
                my @users = _array( $p->{users} );
                if (@users){
                    #my $users =  Baseliner->model('Baseliner::BaliMasterRel')->search( {from_mid => $p->{mid}, rel_type => 'topic_users'})->delete;
                    my $user;
                    my $rs_users = Baseliner->model('Baseliner::BaliUser')->search({id =>\@users});
                    while($user = $rs_users->next){
                        my $mid;
                        if($user->mid){
                            $mid = $user->mid
                        }
                        else{
                            my $user_mid = master_new 'user' => $user->username => sub {
                                my $mid = shift;
                                $user->mid($mid);
                                $user->update();
                            };
                        }
                        $topic->add_to_users( $user, { rel_type=>'topic_users' });
                    }                    
                }
                
                # labels
                Baseliner->model("Baseliner::BaliTopicLabel")->search( {id_topic => $topic_mid} )->delete;
                
                foreach my $label_id (_array $p->{labels}){
                    Baseliner->model('Baseliner::BaliTopicLabel')->create( {    id_topic    => $topic_mid,
                                                                                id_label    => $label_id,
                                                                    });     
                }                

                $topic->update();
                $topic_mid    = $topic->mid;
                $status = $topic->id_category_status;
                
              
                event_new 'event.topic.modify' => {
                    username => $p->{username},
                    mid      => $topic_mid,
                    field  => @field ? 'topic' : '',
                    
                };                   
                
                $return = 'Topic modified';
               { mid=>$topic->mid, topic=>$topic->title }   # to the event
            } ## end try
            => sub {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            };
        } ## end when ( 'update' )
        when ( 'delete' ) {
            $topic_mid = $p->{topic_mid};
            try {
                my $row = ref $topic_mid eq 'ARRAY'
                    ? Baseliner->model( 'Baseliner::BaliTopic' )->search({ mid=>$topic_mid })
                    : Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                _fail _loc('Topic not found') unless ref $row;
                #my $row2 = Baseliner->model( 'Baseliner::BaliMaster' )->find( $row->mid );
                $row->delete;
                $topic_mid    = $topic_mid;
                
                $return = '%1 topic(s) deleted';
            } ## end try
            catch {
                _throw _loc( 'Error deleting topic: %1', shift() );
            }
        } ## end when ( 'delete' )
        when ( 'close' ) {
            try {
                my $topic_mid = $p->{topic_mid};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                $topic->status( 'C' );
                $topic->update();

                $topic_mid    = $topic->mid;
                $return = 'Topic closed'
            } ## end try
            catch {
                _throw _loc( 'Error closing Topic: %1', shift() );
            }
        } ## end when ( 'close' )
    } ## end given
    return ( $return, $topic_mid, $status );
} ## end sub update

sub append_category {
    my ($self, @topics ) =@_;
    return map {
        $_->{name} = $_->{categories}->{name} ? $_->{categories}->{name} . ' #' . $_->{mid}: $_->{name} . ' #' . $_->{mid} ;
        $_->{color} = $_->{categories}->{color} ? $_->{categories}->{color} : $_->{color};
        $_
    } @topics;
}

sub next_status_for_user {
    my ($self, %p ) = @_;
    my $user_roles;
    my $where = { id_category => $p{id_category} };
    $where->{id_status_from} = $p{id_status_from} if defined $p{id_status_from};
    if( $p{username} ) {
        $user_roles = Baseliner->model('Baseliner::BaliRoleUser')->search({ username => $p{username} },{ select=>'role' } )->as_query;
        $where->{role} = { -in => $user_roles };
    }
    my @to_status = Baseliner->model('Baseliner::BaliTopicCategoriesAdmin')->search(
        $where,
        {   join     => [ 'roles', 'statuses_to' ],
            distinct => 1,
            +select => [ 'id_status_to', 'statuses_to.name', 'id_category' ],
            +as     => [ 'id_status',    'status_name',             'id_category' ]
        }
    )->hashref->all;

    return @to_status;
}

1;
