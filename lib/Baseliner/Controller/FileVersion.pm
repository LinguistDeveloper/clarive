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

    my (@tree, @folders, @files);
    
    if($p->{id_directory}){
        my $query = {id_project => $p->{id_project}, id_parent => $p->{id_directory}};
        @folders = get_folders($query);
        
        foreach my $folder (@folders){
            push @tree, build_item_directory($folder, $p->{id_project});
        }
        
        @files = $c->model('Baseliner::BaliProjectDirectoriesFiles')->
                    search( {id_directory => $p->{id_directory}},{ join => ['file_directory'], 
                    select=> [qw(file_directory.mid file_directory.filename file_directory.versionid)], 
                    as=>[qw(mid filename versionid)]} )->hashref->all;        
        
        foreach my $file (@files){
            push @tree, build_item_file($file, $p->{id_directory});
        }        
        
    }
    else{
        my $query = {id_project => $p->{id_project}, id_parent => undef};
        @folders = get_folders($query);
        
        foreach my $folder (@folders){
            push @tree, build_item_directory($folder, $p->{id_project});
        }
        
        my $rs_files_directories = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({'directory.id_project' => $p->{id_project}},{join =>['directory'], select=>['id_file']});
        @files = $c->model('Baseliner::BaliProject')->find( $p->{id_project} )->files->search( {mid => { 'not in' => $rs_files_directories->as_query}},{select=> [qw(mid filename versionid)]} )->hashref->all;        

        foreach my $file (@files){
            push @tree, build_item_file($file, undef);
        }
    }
    $c->stash->{json} = \@tree;
    $c->forward('View::JSON');
}

sub new_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $action = 'add';
    my $project_id = $p->{project_id};
    my $parent_id = $p->{parent_id};
    my $folder_name = $p->{folder};
    
    given ($action) {
        
        when ('add') {
            try{
                my $directory = $c->model('Baseliner::BaliProjectDirectories')->create({
                                                                                    id_project => $project_id,
                                                                                    id_parent =>  $parent_id,
                                                                                    name =>  $folder_name,
                                                                                });
                $c->stash->{json} = { msg=>_loc('Folder added'), success=>\1, folder => $folder_name, directory_id => $directory->id};
            }
            catch{
                $c->stash->{json} = { msg=>_loc('Error adding folder: %1', shift()), failure=>\1 }
            }                   
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
        $directories->delete();
        my $directories_files = $c->model("Baseliner::BaliProjectDirectoriesFiles")->search({id_directory => \@directories});
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

sub get_folders(){
    my $query = shift;
    my @folders = Baseliner->model('Baseliner::BaliProjectDirectories')->search( $query )->hashref->all;
    
    return @folders;
}

sub build_item_directory(){
    my $folder = shift;
    my $id_project = shift;
    my @menu_folder = get_menu_folder();
 
    return  {
                text    => $folder->{name} ,
                leaf    =>\0,
                data    => {
                    id_directory => $folder->{id},
                    id_project => $id_project,
                    type => 'directory',
                    on_drop => {
                        handler => 'move_item'
                    }
                },
                menu    => \@menu_folder,
            };
}

sub build_item_file(){
    my $file = shift;
    my $id_directory = shift;
 
    return  {
                text    => $file->{filename} . '(v' . $file->{versionid} . ')',
                leaf    =>\1,
                data    => {
                    id_file => $file->{mid},
                    id_directory => $id_directory,
                    type => 'file',
                    on_drop => {
                        handler => 'move_item'
                    }                   
                },   
            };
}

sub get_menu_folder(){
    my @menu_folder;
    my $item_new_folder = { text => _loc('New Folder'),
                            icon => '/static/images/icons/folder_new.gif',
                            eval => {
                                handler => 'new_folder'
                            }
                        };
    
    my $item_delete_folder = {  text => _loc('Delete Folder'),
                                icon => '/static/images/icons/folder_delete.gif',
                                eval => {
                                    handler => 'delete_folder'
                                }
                            };    
    push @menu_folder, $item_new_folder;
    push @menu_folder, $item_delete_folder;
    
    return @menu_folder;
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
        
    }else{
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->create({
                                                                            id_file => $p->{from_file},
                                                                            id_directory =>  $p->{to_directory},
                                                                        });        
    }
    $c->stash->{json} = { success=>\1, msg=>_loc('File moved') };
    $c->forward('View::JSON');
}

sub move_topic : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{from_topic_mid} || _fail _loc 'Missing %', 'from_topic_mid';
    
    if($p->{from_directory}){
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->search({ id_file => $topic_mid,
                                                                               id_directory =>  $p->{from_directory},
                                                                        })->first;
        $rs->id_directory( $p->{to_directory} );
        $rs->update();        
        
    }else{
        my $rs = $c->model('Baseliner::BaliProjectDirectoriesFiles')->create({
                                                                            id_file => $topic_mid,
                                                                            id_directory =>  $p->{to_directory},
                                                                        });        
    }
    $c->stash->{json} = { success=>\1, msg=>_loc('OK') };
    $c->forward('View::JSON');
}

1;
