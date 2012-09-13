package Baseliner::Controller::Role;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::Baseline;
use JSON::XS;
use Try::Tiny;
use utf8;
use Encode;
use 5.010;

BEGIN {  extends 'Catalyst::Controller' }

register 'action.admin.role' => { name=>'Admin Roles' };
register 'menu.admin.role' => { label => 'Roles', url_comp=>'/role/grid', actions=>['action.admin.role'], title=>'Roles', index=>81,
    icon=>'/static/images/icons/users.gif' };

sub role_detail_json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    if( defined $id ) {
        my $r = $c->model('Baseliner::BaliRole')->search({ id=>$id })->first;
        if( $r ) {
            my @actions;
            my $rs_actions = $r->bali_roleactions;
            while( my $ra = $rs_actions->next ) {
                my $desc = $ra->action;
                eval { # it may fail for keys that are not in the registry
                    my $action = $c->model('Registry')->get( $ra->action );
                    $desc = $action->name;
                }; 
                push @actions,{ action=>$ra->action, description=>$desc, bl=>$ra->bl };
            }
            $c->stash->{json} = { data=>[{  id=>$r->id, name=>$r->role, description=>$r->description, mailbox=>$r->mailbox, actions=>[ @actions ] }]  };
            $c->forward('View::JSON');
        }
    }
}

sub json : Local {
    my ($self,$c) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = ( @{$p}{qw/start limit query dir sort/}, 0 );
    
    $sort ||= 'role';
    $dir ||= 'asc';

    $start ||= 0;
    $limit ||= 60;
    
    my $page = to_pages( start => $start, limit => $limit );
    
    my $rs = $c->model('Baseliner::BaliRole')->search(undef, { order_by => $sort ? { "-$dir" => "$sort" } : undef,
        page => $page, rows => $limit });
    my @rows;

    my $pager = $rs->pager;
    $cnt = $pager->total_entries;    

    while( my $r = $rs->next ) {
        # related actions
        my $rs_actions = $r->bali_roleactions;
        my @actions;
        while( my $ra = $rs_actions->next ) {
            try {
                my $action = $c->model('Registry')->get( $ra->action );
                #my $str = _loc($action->name) . " (" . $ra->action . ")";
                my $str = { name=>$action->name,  key=>$ra->action };
                $str->{bl} = $ra->bl if $ra->bl ne '*';
                push @actions, $str;
            } catch {
                push @actions, { name=>$ra->action, key=>'' };
            };
        }
        my $actions_txt = \@actions;
        #_log _dump $actions_txt;
#        # related users
#        my $rs_users = $r->bali_roleusers;
#        my @users;
#        while( my $ru = $rs_users->next ) {
#            push @users, $ru->username;
#        }
#        my $users_txt = @users ? join(', ', sort(unique(@users))) : '-';
        # produce the grid
        next if( $query && !query_array($query, $r->role, $r->description, $r->mailbox, $actions_txt
#            , $users_txt 
          ));
#        _log $users_txt;

        push @rows,
          {
            id          => $r->id,
            role        => $r->role,
            actions     => $actions_txt,
#            users       => $users_txt,
            description => $r->description,
            mailbox => $r->mailbox
          }
    }
    $c->stash->{json} = { data => \@rows, totalCount => $cnt };     
    $c->forward('View::JSON');
}

sub action_tree : Local {
    my ( $self, $c ) = @_;
    my @actions = $c->model('Actions')->list;
    my %tree;
    foreach my $a ( @actions ) {
        my $key = $a->{key};
        ( my $folder = $key ) =~ s{^(\w+\.\w+)\..*$}{$1}g;
        push @{ $tree{ $folder } }, { id=>$a->{key}, text=>_loc_decoded($a->name), leaf=>\1 }; 
    }
    $c->stash->{json} = [ map { { id=>$_, text=>$_, leaf=>\0, children=>$tree{$_} } } sort keys %tree ];
    $c->forward("View::JSON");
}

sub update : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $role_actions = decode_json(encode('UTF-8', $p->{role_actions}));
        my $row = {  role=>$p->{name}, description=>$p->{description}, mailbox=>$p->{mailbox} };
        $row->{id} = $p->{id} if $p->{id} >= 0;
        my $role = $c->model('Baseliner::BaliRole')->find_or_create( $row );
        $role->role( $p->{name} );
        $role->description( $p->{description} );
        $role->mailbox( $p->{mailbox} );
        $role->bali_roleactions->delete_all;
        foreach my $action ( @{ $role_actions || [] } ) {
            $role->bali_roleactions->find_or_create({ action=> $action->{action}, bl=>$action->{bl} || '*' });  #TODO bl from action list
        }
        $role->update();
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error modifying the role ").$@  };
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    $c->forward('View::JSON');  
}

sub delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $rs = $c->model('Baseliner::BaliRole')->search({ id=>$p->{id_role} });
        while ( my $r = $rs->next ) { $r->delete }
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    $c->forward('View::JSON');  
}

sub duplicate : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    eval {
        my $r = $c->model('Baseliner::BaliRole')->find({ id=>$p->{id_role} });
        if( $r ) {
            my %orig =$r->get_columns; 
            delete $orig{id};
            my $role = $c->model('Baseliner::BaliRole')->create({ %orig });
            $role->role( $role->role . "-" . $role->id );
            $role->update;
            my $rs_actions = $r->bali_roleactions;
            while( my $ra = $rs_actions->next ) {
                $role->bali_roleactions->find_or_create({ action=>$ra->action });
            }
            $role->update;
        }
    };
    if( $@ ) {
        warn $@;
        $c->stash->{json} = { success => \0, msg => _loc("Error deleting the role ").$@  };
    } else { 
        $c->stash->{json} = { success => \1, msg => _loc("Role '%1' modified", $p->{name} ) };
    }
    $c->forward('View::JSON');  
}

sub grid : Local {
    my ( $self, $c ) = @_;
    #$c->forward('/namespace/load_namespaces');
    $c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/role_grid.mas';
}

sub all : Local {
    my ( $self, $c ) = @_;
    my $rs = $c->model('Baseliner::BaliRole')->search({});
    rs_hashref( $rs );
    my @roles = map {
        $_->{role_name} = "$_->{description} ($_->{role})";
        $_
    } $rs->all;
    $c->stash->{json} = { data=>\@roles, totalCount=>scalar @roles };
    $c->forward('View::JSON');  
}


1;
