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
                my $topic = master_new 'bali_topic' => $p->{title} => sub {
                    $topic_mid = shift;    
                    Baseliner->model('Baseliner::BaliTopic')->create(
                        {   title              => $p->{title},
                            description        => $p->{description},
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
                            my $project_mid = master_new 'bali_project' => $project->name => sub {
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
                        	my $user_mid = master_new 'bali_user' => $user->username => sub {
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
            try {
                $topic_mid = $p->{topic_mid};
                my $topic    = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                $topic->title( $p->{title} );
                $topic->description( $p->{description} );
                $topic->id_category( $p->{category} ) if is_number( $p->{category} ) ;
                $topic->id_category_status( $p->{status_new} ) if is_number( $p->{status_new} );
                $topic->id_priority( $p->{priority} ) if is_number( $p->{priority} );
                $topic->response_time_min( $rsptime[1] );
                $topic->expr_response_time( $rsptime[0] );
                $topic->deadline_min( $deadline[1] );
                $topic->expr_deadline( $deadline[0] );

                # related topics
                if( my @topics = _array( $p->{topics} ) ) {
                    #my @curr_topics = $topic->topics;
                    my @all_topics = Baseliner->model('Baseliner::BaliTopic')->search({mid =>\@topics});
                    #$topic->remove_from_topics( $_ ) for @curr_topics;
                    $topic->set_topics( \@all_topics, { rel_type=>'topic_topic'});
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
                            my $project_mid = master_new 'bali_project' => $project->name => sub {
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
                        	my $user_mid = master_new 'bali_user' => $user->username => sub {
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
                $return = 'Topic modified';
            } ## end try
            catch {
                _throw _loc( 'Error modifying Topic: %1', shift() );
            }
        } ## end when ( 'update' )
        when ( 'delete' ) {
            $topic_mid = $p->{topic_mid};
            try {
                my $row = Baseliner->model( 'Baseliner::BaliTopic' )->find( $topic_mid );
                #my $row2 = Baseliner->model( 'Baseliner::BaliMaster' )->find( $row->mid );
                $row->delete;
                $topic_mid    = $topic_mid;
                
                $return = 'Topic deleted';
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
        $_->{name} = $_->{categories}->{name} . ' #' . $_->{mid};
        $_->{color} = $_->{categories}->{color};
        $_
    } @topics;
}

1;
