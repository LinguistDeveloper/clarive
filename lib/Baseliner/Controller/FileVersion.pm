package Baseliner::Controller::FileVersion;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
use v5.10;
use experimental 'switch', 'autoderef';

BEGIN {  extends 'Catalyst::Controller' }

sub drop : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    #_debug($p);
    
    if( $$p{id_file} ) {
        my $cnt = mdb->master_rel->find({ from_mid=>$$p{id_project}, to_mid=>$$p{id_file} })->count;
        if ($cnt){
            $c->stash->{json} = { success=>\0, msg=>_loc('File already exists') };
        } else {
            mdb->master_rel->insert({ from_mid=>$$p{id_project}, to_mid=>$$p{id_file}, rel_type=>'project_asset', rel_field=>'assets' });
            $c->stash->{json} = { success=>\1, msg=>_loc('File added to project') };
        }
    } elsif( $$p{node1} && $$p{node2} ) {
        mdb->master_rel->remove({ from_mid=>$$p{node1}{parent_folder}, to_mid=>$$p{node1}{id_folder}, rel_type=>'folder_folder' });
        # dropped on a project?
        my $ret = mdb->master_rel->update(
            { from_mid=>$$p{node2}{id_project}, to_mid=>$$p{node1}{id_folder}, rel_type=>'project_folder' },
            { from_mid=>$$p{node2}{id_project}, to_mid=>$$p{node1}{id_folder}, rel_type=>'project_folder' },
            { upsert=>1 },
        ) if !$$p{node2}{id_folder} && $$p{node2}{id_project}; # dropped on a project
        # dropped on a folder?
        mdb->master_rel->update(
            { from_mid=>$$p{node2}{id_folder}, to_mid=>$$p{node1}{id_folder}, rel_type=>'folder_folder' },
            { '$set'=>{ from_mid=>$$p{node2}{id_folder}, to_mid=>$$p{node1}{id_folder}, rel_type=>'folder_folder'} },
            { upsert=>1 },
        ) if !$$ret{n};
        $c->stash->{json} = { success=>\1, msg=>_loc('Folder moved') };
        
    } else {
        $c->stash->{json} = { success=>\0, msg=>_loc('Missing file id') };
    }
    $c->forward('View::JSON');
}

sub gen_tree : Private {
    my ($self, $p ) = @_;
    
    my @tree;
    # show child folders
    my @fids;
    if( $p->{id_folder} ) {
        push @fids, map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>$p->{id_folder}, rel_type=>'folder_folder' })->all;
    } elsif( $p->{id_project} ) {
        push @fids, map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>$p->{id_project}, rel_type=>'project_folder' })->all;
    }
    my @folders = mdb->master_doc->find({ mid=>mdb->in(@fids) })->sort({ name=>1 })->all;
    foreach my $folder (@folders) {
        push @tree, $self->build_item_directory($folder, $p->{id_project}, $p->{id_folder}, $p->{username});
    }
    # show child content
    if( $p->{id_folder} ) {
        my %categories  = map { $_->{id}=>1 } Baseliner::Model::Topic->get_categories_permissions( username => $p->{username}, type => 'view' );
        my $remove_item = {
            text => _loc('Remove from folder'),
            icon => '/static/images/icons/folder_delete.png',
            eval => {
                handler => 'Baseliner.remove_folder_item'
            }
        };
        my @mids = map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>$p->{id_folder}, rel_type=>'folder_ci' })->all;
        my @cis = mdb->master_doc->find({ mid=>mdb->in(@mids) })->sort(mdb->ixhash(name=>1))->all;
            
        my %topics = map { $$_{mid} =>$_ } mdb->topic->find({ mid=>mdb->in(map{ $$_{mid} }grep{ defined }@cis) })->fields({ _txt=>0 })->all;
        foreach my $ci ( @cis ){
            if( $ci->{collection} eq 'topic' && $categories{$ci->{id_category}} ) {
                my $topic = $topics{$ci->{mid}} // _fail _loc 'Topic mid not found: %1', $ci->{mid};
                my @topic_tree = BaselinerX::LcController->build_topic_tree( mid=>$ci->{mid}, topic=>$topic, icon=>'' );
                push @tree, map { 
                    my $i = $_;
                    $i->{menu} ||= [];
                    push @{ $i->{menu} } => $remove_item;
                    $i->{id_folder} = $p->{id_folder};
                    $i;
                } @topic_tree;
            } else {
                push @tree, $self->build_item_file($ci, $p->{id_folder});
            }
        }        
    }
    return @tree;
}

sub tree_file_project : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;

    my @tree = $self->gen_tree({ id_project=>$p->{id_project}, id_folder=>$p->{id_folder}, username=>$c->username });
    
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
            my $folder;
            try{
                $self->folder_length( $folder_name );
                my $prj = ci->find( $project_id ) // _fail _loc 'Project not found';
                $folder = ci->folder->new( name=>$folder_name );
                $folder->parent_folder( $parent_id ) if $parent_id;
                $folder->save;
                if( !$parent_id ) {
                    my $folders = $prj->folders // [];
                    push $folders => $folder;
                    $prj->update( folders=>$folders );
                }
                $c->stash->{json} = {
                    msg     => _loc('Folder added'),
                    success => \1,
                    node    => $self->build_item_directory({ mid=>$folder->mid, name=>$folder_name }, $project_id, $parent_id, $c->username)
                };
            } catch {
                $folder->delete if $folder && $folder->mid;
                $c->stash->{json} = { msg => _loc( 'Error adding folder: %1', shift() ), failure => \1 };
            };
        }
    }

    $c->forward('View::JSON');
}

sub delete_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    my $id_folder = $p->{id_folder};
    my $remove_cis = $p->{remove_cis};  # TODO find children and delete them? consider asking one-by-one, or all

    try{
        # find all children folders that have exactly 1 parent and delete them
        my $del_folder;
        $del_folder = sub {
            my $mid = shift;
            my @chi = 
                # if a folder, only one parent? then delete
                grep { 
                    $_->{rel_type} ne 'folder_folder' 
                    ? 1
                    : mdb->master_rel->find({ to_mid=>$_->{to_mid} })->count == 1 
                }
                # remove cis or only folders?
                grep { $remove_cis ? 1 : $_->{rel_type} eq 'folder_folder' } 
                mdb->master_rel->find({ from_mid=>"$mid" })->all;
            _debug( "DELETE from folder=$mid" );
            ci->delete( $mid );
            $del_folder->($_) for @chi;
        };
        $del_folder->($_) for _array( $id_folder );
        $c->stash->{json} = { msg=>_loc('Folder deleted'), success=>\1};
    } catch {
        $c->stash->{json} = { msg=>_loc('Error deleting folder: %1', shift()), failure=>\1 }
    };                   

    $c->forward('View::JSON');
}

sub build_item_directory {
    my ($self, $folder, $id_project, $parent_folder, $username) = @_;
    my @menu_folder = $self->get_menu_folder($username);
    my $project_name = 'ZZ'; # XXX nooooooooooooooooooooooo
    return  {
        text    => $folder->{name},
        leaf    =>\0,
        url     => '/fileversion/tree_file_project',
        data    => {
            id_folder => $folder->{mid},
            id_project => $id_project,
            parent_folder => $parent_folder,
            project_name => $project_name, 
            doc_url   => '/doc/folder:'. $folder->{mid} . '/',
            doc_title => $folder->{name},
            type => 'directory',
            on_drop => {
                handler => 'Baseliner.move_folder_item'
            }
        },
        menu    => \@menu_folder,
    };
}

sub build_item_file {
    my ($self,$file,$id_folder) = @_;
    return  {
        text    => $file->{name} . ' <span style="color:#999">(v' . $file->{versionid} . ')</span>',
        leaf    =>\1,
        data    => {
            id_file => $file->{mid},
            id_folder => $id_folder,
            id_parent => 0,
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
    my $username = shift;
    my @menu_folder;
    push @menu_folder, {  text => _loc('Topics'),
                                icon => '/static/images/icons/topic.png',
                                eval => {
                                    handler => 'Baseliner.open_topic_grid_from_folder'
                                }
                            };
    my $is_root = Baseliner->model('Permissions')->is_root($username);
    my $has_permission = Baseliner->model('Permissions')->user_has_action( username=> $username, action=>'action.home.generate_docs' );  
    if ( $has_permission || $is_root ) {
        push @menu_folder, {  text => _loc('Doc'),
                                    icon => '/static/images/icons/document.png',
                                    url     => '/comp/lifecycle/report_run.js',
                                    eval => {
                                        url => '/comp/doc_from_tree.js',
                                    }
                                };    
    }
    push @menu_folder, {  text => _loc('Kanban'),
                                icon => '/static/images/icons/kanban.png',
                                eval => {
                                    handler => 'Baseliner.open_kanban_from_folder'
                                }
                            };    
    # push @menu_folder, '-';
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
        
        my $ci = ci->find( $id ); 
        if( $ci ){
            $ci->update( name=>$name );
            # clean cache for topics/cis in this folder
            for my $chi_mid ( map { $_->{to_mid} } mdb->master_rel->find({ from_mid=>"$id" })->all ) {
                cache->remove({ mid=>"$chi_mid" }) if defined $chi_mid; # qr/:$chi_mid:/ ) 
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
    my ($node,$to,$project,$parent_folder) = @{$p}{qw(from_directory to_directory project parent_folder)};
    my $dest_coll = ( mdb->master_doc->find_one({ mid=>"$to" }) // {} )->{collection};
    
    if( $parent_folder ) {
        mdb->master_rel->remove({ from_mid=>"$parent_folder", to_mid=>"$node", rel_type=>'folder_folder' });
    } 
    
    if( $dest_coll eq 'folder' ) {
        # destination is a folder
        my $ret = mdb->master_rel->update(
            { from_mid=>$project, to_mid=>$node, rel_type=>'project_folder' }, 
            { '$set'=>{ from_mid=>"$to", rel_type=>'folder_folder' } }); 
        mdb->master_rel->update(
            { from_mid=>$to, to_mid=>$node, rel_type=>'folder_folder' },
            { '$set'=>{ from_mid=>$to, to_mid=>$node, rel_type=>'folder_folder', rel_field=>'folders' } },
            { upsert=>1 }) if !$ret->{n};
    }
    elsif( $dest_coll eq 'project' ) {
        # destination is a project
        
    }
    else {
        _warn('Invalid drop collection %1', $dest_coll );
    }
    
    $c->stash->{json} = { success=>\1, msg=>_loc('Folder moved') };
    $c->forward('View::JSON');
}

sub move_file : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    
    if($p->{from_directory}){
        mdb->master_rel->remove({ from_mid=>$p->{from_directory}, to_mid=>$p->{from_file} },{ multiple=>1 });
    }
    # now create new location
    my $q = { from_mid=>$p->{to_directory}, to_mid=>$p->{from_file}, rel_type=>'folder_ci', rel_field=>'cis' };
    mdb->master_rel->update($q, $q,{ upsert=>1 });
    cache->remove( qr/:$p->{from_file}:/ );
        
    $c->stash->{json} = { success=>\1, msg=>_loc('File moved') };
    $c->forward('View::JSON');
}

sub move_topic : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $topic_mid = $p->{from_topic_mid} || _fail _loc 'Missing %1', 'from_topic_mid';

    try {
        if($p->{from_directory}){
            mdb->master_rel->update({ to_mid=>$topic_mid, from_mid=>$p->{from_directory} },{ '$set'=>{ from_mid=>$p->{to_directory} } });
            # _fail(_loc('Source topic #%1 does not exist or is not in this folder anymore', $topic_mid )) unless $old_row;
            cache->remove( qr/:$$p{from_directory}:/ );
        } else {
            mdb->master_rel->update(
                { to_mid => $topic_mid, from_mid => $p->{to_directory} },
                { to_mid => $topic_mid, from_mid => $p->{to_directory}, rel_type => 'folder_ci', rel_field => 'cis' },
                { upsert => 1 }
            );
        }
        cache->remove( qr/:$$p{to_directory}:/ );
        cache->remove({ mid=>"$topic_mid" }); # qr/:$topic_mid:/ );
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
    
    if($p->{id_folder}){
        mdb->master_rel->remove({ from_mid=>"$p->{id_folder}", to_mid=>"$topic_mid", rel_type=>'folder_ci' });
        cache->remove({ mid=>"$topic_mid" }); # qr/:$topic_mid:/ );
    }
    $c->stash->{json} = { success=>\1, msg=>_loc('OK') };
    $c->forward('View::JSON');
}

sub topics_for_folder : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    ## XXX list only topics, not all cis... or change sub name to cis_for_folder
    my @topics = map { $_->{mid} } ci->related( mid=>$p->{id_folder}, depth=>-1, rel_type=>['folder_folder','folder_ci'], mids_only=>1 );
    $c->stash->{json} = { success=>\1, topics=>\@topics };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
