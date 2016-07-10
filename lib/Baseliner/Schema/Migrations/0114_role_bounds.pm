package Baseliner::Schema::Migrations::0114_role_bounds;
use Moose;

use Encode ();
use Baseliner::Utils qw(_name_to_id);

my $BACKUP_COLLECTION = 'role_0114';

sub upgrade {
    my $self = shift;

    my $map_category_name_id_to_id = {};

    my @categories = mdb->category->find->all;
    foreach my $category (@categories) {
        my $category_name_id = _name_to_id( $category->{name} );

        if ( exists $map_category_name_id_to_id->{$category_name_id} ) {
            die sprintf
              "Category '%s' collides with $category_name_id ($map_category_name_id_to_id->{$category_name_id})",
              Encode::encode( 'UTF-8', $category->{name} );
        }

        $map_category_name_id_to_id->{$category_name_id} = $category->{id};
    }

    my $map_status_name_id_to_id = {};

    my @statuses = ci->status->find->all;
    foreach my $status (@statuses) {
        my $status_name_id = _name_to_id( $status->{name} );

        if ( exists $map_status_name_id_to_id->{$status_name_id} ) {
            die sprintf "Status '%s' collides with $status_name_id ($map_status_name_id_to_id->{$status_name_id})",
              Encode::encode( 'UTF-8', $status->{name} );
        }

        $map_status_name_id_to_id->{$status_name_id} = $status->{id_status};
    }

    mdb->$BACKUP_COLLECTION->drop;
    mdb->role->clone($BACKUP_COLLECTION);

    my @roles = mdb->role->find->all;
    foreach my $role (@roles) {
        my $actions = $role->{actions};

        my $hide_repos = 0;

        my $actions_map = {};

        foreach my $action (@$actions) {
            my $bl = delete $action->{bl};

            my $action_key = $action->{action};

            if ( $action->{action} =~ m/^action\.topics\.(.*?)\.(.*?)$/ ) {
                my $category_name_id = $1;
                my $subaction        = $2;

                $action_key = "action.topics.$subaction";

                my $id_category = $map_category_name_id_to_id->{$category_name_id};

                if ( !$id_category ) {
                    warn "Cannot map back '$category_name_id'. Skipping";
                    next;
                }

                if ( grep { $_->{id_category} eq $id_category } @{ $actions_map->{$action_key}->{bounds} || [] } ) {
                    warn "Bound '$id_category' already exists. Skipping";
                    next;
                }

                if (
                    $subaction =~ m/^(?:create|edit|view)$/
                    && !grep {
                             $_->{id_category}
                          && $_->{id_category} eq $id_category
                          && !$_->{id_status}
                          && !$_->{id_field}
                    } @{ $actions_map->{'action.topicsfield.read'}->{bounds} }
                  )
                {
                    push @{ $actions_map->{'action.topicsfield.read'}->{bounds} }, { id_category => $id_category };
                }

                push @{ $actions_map->{$action_key}->{bounds} }, { id_category => $id_category };
            }
            elsif ( $action->{action} =~ m/^action\.topicsfield\.([^\.]+)\.([^\.]+)\.([^\.]+)$/ ) {
                my $category_name_id = $1;
                my $id_field         = $2;
                my $subaction        = $3;

                $action_key = "action.topicsfield.$subaction";

                my $id_category = $map_category_name_id_to_id->{$category_name_id};

                if ( !$id_category ) {
                    warn "Cannot map back '$category_name_id'. Skipping";
                    next;
                }

                push @{ $actions_map->{$action_key}->{bounds} },
                  {
                    id_category => $id_category,
                    id_field    => $id_field,
                    $subaction eq 'read' ? ( _deny => 1 ) : ()
                  };
            }
            elsif ( $action->{action} =~ m/^action\.topicsfield\.([^\.]+)\.([^\.]+)\.([^\.]+)\.([^\.]+)$/ ) {
                my $category_name_id = $1;
                my $id_field         = $2;
                my $status_name_id   = $3;
                my $subaction        = $4;

                $action_key = "action.topicsfield.$subaction";

                my $id_category = $map_category_name_id_to_id->{$category_name_id};

                if ( !$id_category ) {
                    warn "Cannot map back '$category_name_id'. Skipping";
                    next;
                }

                my $id_status = $map_status_name_id_to_id->{$status_name_id};

                if ( !$id_status ) {
                    warn "Cannot map back '$status_name_id'. Skipping";
                    next;
                }

                push @{ $actions_map->{$action_key}->{bounds} },
                  {
                    id_category => $id_category,
                    id_status   => $id_status,
                    id_field    => $id_field,
                    $subaction eq 'read' ? ( _deny => 1 ) : ()
                  };
            }
            elsif ( $action->{action} =~ m/^action\.ci\.admin\.(.*?)\.(.*?)$/ ) {
                push @{ $actions_map->{'action.admin.ci'}->{bounds} }, { role => $1, collection => $2 };
            }
            elsif ( $action->{action} =~ m/^action\.ci\.view\.(.*?)\.(.*?)$/ ) {
                push @{ $actions_map->{'action.view.ci'}->{bounds} }, { role => $1, collection => $2 };
            }
            elsif ( $action->{action} eq 'action.home.hide_project_repos' ) {
                $hide_repos++;
            }
            else {
                $actions_map->{$action_key} //= {};

                if ( $action->{action} =~ m/^action\.job\.(.*?)$/ ) {
                    my $type = $1;

                    if ($bl && $bl ne '*') {
                        push @{ $actions_map->{$action_key}->{bounds} }, { bl => $bl };
                    }
                    else {
                        push @{ $actions_map->{$action_key}->{bounds} }, { };
                    }
                }
                elsif ( $action->{action} eq 'action.ci.admin' ) {
                    push @{ $actions_map->{$action_key}->{bounds} }, { };
                }
                elsif ( $action->{action} eq 'action.admin.rules' ) {
                    push @{ $actions_map->{$action_key}->{bounds} }, { };
                }
            }
        }

        my $new_actions = [ map { { action => $_, %{ $actions_map->{$_} } } } keys %$actions_map ];

        if ( !$hide_repos && grep { $_->{action} eq 'action.home.show_lifecycle' } @$new_actions ) {
            push @$new_actions, { action => 'action.home.view_project_repos' };
        }

        mdb->role->update( { id => $role->{id} }, { '$set' => { actions => $new_actions } } );
    }
}

sub downgrade {
    mdb->role->drop;
    mdb->$BACKUP_COLLECTION->clone('role');
}

1;
