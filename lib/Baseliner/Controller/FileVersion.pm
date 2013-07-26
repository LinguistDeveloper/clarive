package Baseliner::Controller::FileVersion;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

sub drop : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my @files = $c->model('Baseliner::BaliProject')->find( $p->{id_project} )->files->search( {mid=>$p->{id_file} },{select=> [qw(mid)]})->hashref->all;
    
    my $project = $c->model('Baseliner::BaliProject')->find( $p->{id_project} );
    my $file = $project->files->search( {mid=>$p->{id_file} },{select=> [qw(mid)]})->all;
    if ($file){
        $c->stash->{json} = { success=>\0, msg=>_loc('File already exists') };
    }else{
        my $file = $c->model('Baseliner::BaliFileVersion')->find($p->{id_file});
        $project->add_to_files( $file, { rel_type=>'project_file_version' });
        $c->stash->{json} = { success=>\1, msg=>_loc('File added to project') };
    }
    $c->forward('View::JSON');
}

sub tree_file_project : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my (@tree, @folders);
    
    if($p->{id_directory}){
        my $query = {id_project => $p->{id_project}, id_parent => $p->{id_directory}};
        @folders = get_folders($query);
        
        foreach my $folder (@folders){
            push @tree, $self->build_item_directory($folder, $p->{id_project});
        }
        
        my @files = $c->model('Baseliner::BaliProjectDirectoriesFiles')->
                    search( {id_directory => $p->{id_directory}},{ join => ['file_directory'], 
                    select=> [qw(file_directory.mid file_directory.filename file_directory.versionid)], 
                    as=>[qw(mid filename versionid)]} )->hashref->all;        
        
        foreach my $file (@files){
            push @tree, $self->build_item_file($file, $p->{id_directory});
        }        
        
        # get topics XXX consider using CI groups for folders and master_rel for topics
        my @categories  = map { $_->{id}} Baseliner::Model::Topic->get_categories_permissions( username => $c->username, type => 'view' );

        my @topics = $c->model('Baseliner::BaliProjectDirectoriesFiles')->
                    search( {id_directory => $p->{id_directory}, 'categories.id' => \@categories },
                        { prefetch => ['topic', {'topic'=>'categories'}] } )->hashref->all;        
        
        my $remove_item = {   
            text => _loc('Remove from folder'),
            icon => '/static/images/icons/folder_delete.png',
            eval => {
                handler => 'Baseliner.remove_folder_item'
            }
        };
        foreach my $topic (@topics){
            my @topic_tree = BaselinerX::LcController->build_topic_tree( 
                    mid      => $topic->{topic}{mid},
                    topic    => $topic->{topic},
                    icon     => ''
                );

            push @tree, map { 
                my $i = $_;
                $i->{menu} ||= [];
                push @{ $i->{menu} } => $remove_item;
                $i->{id_directory} = $p->{id_directory};
                $i;
            } @topic_tree;
        }
    }
    else{
        my $query = {id_project => $p->{id_project}, id_parent => undef};
        @folders = get_folders($query);
        
        foreach my $folder (@folders){
            push @tree, $self->build_item_directory($folder, $p->{id_project});
        }
        
        my $rs_files_directories = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({'directory.id_project' => $p->{id_project}},{join =>['directory'], select=>['id_file']});
        my @files = $c->model('Baseliner::BaliProject')->find( $p->{id_project} )->files->search( {mid => { 'not in' => $rs_files_directories->as_query}},{select=> [qw(mid filename versionid)]} )->hashref->all;        

        foreach my $file (@files){
            push @tree, $self->build_item_file($file, undef);
        }
    }
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub folder_length {
    length $_[1] > 255 and _fail _loc 'Folder name cannot be longer than %1 characters', 255; 
}

sub new_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $action = 'add';
    my $project_id = $p->{project_id};
    my $parent_id = $p->{parent_id};
    my $folder_name = $p->{name};
    
    given ($action) {
        when ('add') {
            try{
                $self->folder_length( $folder_name );
                my $directory = $c->model('Baseliner::BaliProjectDirectories')->create(
                    {
                                                                                    id_project => $project_id,
                                                                                    id_parent =>  $parent_id,
                                                                                    name =>  $folder_name,
            }
                );
                $c->stash->{json} = {
                    msg     => _loc('Folder added'),
                    success => \1,
                    node    => $self->build_item_directory({ id => $directory->id, name => $folder_name }, $project_id)
                };
            }                   
            catch {
                $c->stash->{json} = { msg => _loc( 'Error adding folder: %1', shift() ), failure => \1 };
            };
        }
    }

    $c->forward('View::JSON');
}

sub delete_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $directory_id = $p->{id_directory};
    my $db = Baseliner::Core::DBI->new( {model => 'Baseliner'} );
    my $dbh = $db->dbh;
    my $SQL;
    my @directories;    
    
    try{
        if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
            $SQL = "SELECT ID FROM BALI_PROJECT_DIRECTORIES START WITH ID = ? CONNECT BY PRIOR ID = ID_PARENT";
            @directories = $db->array_hash( $SQL, $directory_id );
        }
        else{
            $SQL = "WITH N(ID) AS (SELECT ID FROM BALI_PROJECT_DIRECTORIES WHERE ID = ?
                            UNION ALL
                            SELECT NPLUS1.ID FROM BALI_PROJECT_DIRECTORIES AS NPLUS1, N WHERE N.ID = NPLUS1.ID_PARENT)
                            SELECT N.ID FROM N ";
            @directories = $db->array_hash( $SQL, $directory_id );
        }
        @directories = map {$_->{id} } @directories;
        my $directories = $c->model("Baseliner::BaliProjectDirectories")->search({id => \@directories});
        my $directories_files = $c->model("Baseliner::BaliProjectDirectoriesFiles")->search({id_directory => \@directories});
        for my $row_file( $directories_files->all ) {
            my $mid = $row_file->id_file;
            $c->cache_remove( qr/:$mid:/ );
        }
        $directories->delete();
        $directories_files->delete();
        #$sth->bind_param( 1, $directory_id );
        #$sth->execute();
        
        $c->stash->{json} = { msg=>_loc('Folder deleted'), success=>\1};
    }
    catch{
        $c->stash->{json} = { msg=>_loc('Error deleting folder: %1', shift()), failure=>\1 }
    };                   

    $c->forward('View::JSON');
}

sub get_folders {
    my $query = shift;
    my @folders = Baseliner->model('Baseliner::BaliProjectDirectories')->search( $query )->hashref->all;
    
    return @folders;
}

sub build_item_directory {
    my ($self, $folder, $id_project) = @_;
    my @menu_folder = $self->get_menu_folder();
 
    return  {
                text    => $folder->{name} ,
                leaf    =>\0,
                url     => '/fileversion/tree_file_project',
                data    => {
                    id_directory => $folder->{id},
                    id_project => $id_project,
                    type => 'directory',
                    on_drop => {
                        handler => 'Baseliner.move_folder_item'
                    }
                },
                menu    => \@menu_folder,
            };
}

sub build_item_file{
    my ($self,$file,$id_directory) = @_;
 
    return  {
                text    => $file->{filename} . ' <span style="color:#999">(v' . $file->{versionid} . ')</span>',
                leaf    =>\1,
                data    => {
                    id_file => $file->{mid},
                    id_directory => $id_directory,
                    type => 'file',
                    on_drop => {
                        handler => 'Baseliner.move_folder_item'
                    }                   
                },   
            };
}

=head2 get_menu_folder 

Right click menu on a folder.

=cut
sub get_menu_folder {
    my $self = shift;
    my @menu_folder;
    push @menu_folder, {  text => _loc('Topics'),
                                icon => '/static/images/icons/topic.png',
                                eval => {
                                    handler => 'Baseliner.open_topic_grid_from_folder'
                                }
                            };    
    push @menu_folder, {  text => _loc('Kanban'),
                                icon => '/static/images/icons/kanban.png',
                                eval => {
                                    handler => 'Baseliner.open_kanban_from_folder'
                                }
                            };    
    push @menu_folder, { text => _loc('New Folder'),
                            icon => '/static/images/icons/folder_new.gif',
                            eval => {
                                handler => 'Baseliner.new_folder'
                            }
                        };
    push @menu_folder, { text => _loc('Rename Folder'),
                            icon => '/static/images/icons/folder_edit.png',
                            eval => {
                                handler => 'Baseliner.rename_folder'
                            }
                        };
    
    push @menu_folder, {  text => _loc('Delete Folder'),
                                icon => '/static/images/icons/folder_delete.gif',
                                eval => {
                                    handler => 'Baseliner.delete_folder'
                                }
                            };    
    
    return @menu_folder;
}

sub rename_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    try {
        my $id = $p->{parent_id} // _fail _loc('Missing parent_id');
        my $name = $p->{name} ;
        $self->folder_length( $name );
        length $name or _fail _loc('Invalid name');
        
        my $row = $c->model('Baseliner::BaliProjectDirectories')->search({id => $id})->first;
        if( $row ){
            $row->update({ name => $name });    
            for my $row_file ( $row->files->hashref->all ) {
                my $mid = $row_file->{id_file};
                $c->cache_remove( qr/:$mid:/ ) if defined $mid;
            }
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('Folder renamed'), name=>$name };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>shift };
    };
    
    $c->forward('View::JSON');
}

sub move_directory : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $rs = $c->model('Baseliner::BaliProjectDirectories')->search({id => $p->{from_directory}})->first;
    $rs->id_parent( $p->{to_directory} );
    $rs->update();    
    
    
    $c->stash->{json} = { success=>\1, msg=>_loc('Folder moved') };
    $c->forward('View::JSON');
}

sub move_file : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    if($p->{from_directory}){
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({ id_file => $p->{from_file},
                                                                               id_directory =>  $p->{from_directory},
                                                                        })->first;
        $rs->id_directory( $p->{to_directory} );
        $rs->update();        
        $c->cache_remove( qr/:$p->{from_file}:/ );
        
    }else{
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->create({
                                                                            id_file => $p->{from_file},
                                                                            id_directory =>  $p->{to_directory},
                                                                        });        

        $c->cache_remove( qr/:$p->{from_file}:/ );
    }
    $c->stash->{json} = { success=>\1, msg=>_loc('File moved') };
    $c->forward('View::JSON');
}

sub move_topic : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{from_topic_mid} || _fail _loc 'Missing %1', 'from_topic_mid';

    try {
        if($p->{from_directory}){
            $c->cache_remove( qr/:$topic_mid:/ );
            my $old_row = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({ id_file => $topic_mid,
                                                                                   id_directory =>  $p->{from_directory},
                                                                            })->first;

            _fail(_loc('Source topic #%1 does not exist or is not in this folder anymore', $topic_mid )) unless $old_row;

            my $new_row = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({ id_file => $topic_mid,
                                                                                   id_directory =>  $p->{to_directory},
                                                                            })->first;
            if( $new_row ) {
                # if already in dest dir, silenty delete old row
                $old_row->delete;
            } else {
                $old_row->id_directory( $p->{to_directory} );
                $old_row->update();        
            }
            
        }else{
            my $row = $c->model('Baseliner::BaliProjectDirectoriesFiles')->find_or_create({
                                                                                id_file => $topic_mid,
                                                                                id_directory =>  $p->{to_directory},
                                                                            });        
            $c->cache_remove( qr/:$topic_mid:/ );
        }
        $c->stash->{json} = { success=>\1, msg=>_loc('OK') };
    } catch {
        $c->stash->{json} = { success=>\0, msg=>shift() };
    };
    $c->forward('View::JSON');
}

sub remove_topic : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{topic_mid} || _fail _loc 'Missing %1', 'topic_mid';
    
    if($p->{id_directory}){
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({ id_file => $topic_mid,
                                                                           id_directory =>  $p->{id_directory},
                                                                    })->first;
        $rs->delete if $rs;
        $c->cache_remove( qr/:$topic_mid:/ );
    }
    $c->stash->{json} = { success=>\1, msg=>_loc('OK') };
    $c->forward('View::JSON');
}

sub topics_for_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my @topics = map { $_->{id_file} } 
            $c->model('Baseliner::BaliProjectDirectoriesFiles')->
                search( {id_directory => $p->{id_directory}},
                    { prefetch => ['topic'] } )->hashref->all;        
    $c->stash->{json} = { success=>\1, topics=>\@topics };
    $c->forward('View::JSON');
}

1;
