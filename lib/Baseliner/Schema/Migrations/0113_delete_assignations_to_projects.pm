package Baseliner::Schema::Migrations::0113_delete_assignations_to_projects;
use Moose;

use Baseliner::Utils qw(_array);

sub upgrade {
    my $self = shift;

    my $users = mdb->master_doc->find( { collection => 'user' } );
    foreach my $user ( $users->all ) {
        my $project_security = $user->{project_security};
        if ( $project_security && ref($project_security) eq 'HASH' ) {
            foreach my $user_role ( keys %$project_security ) {
                my $role_mids = $project_security->{$user_role};
                if ( $role_mids && ref($role_mids) eq 'HASH' ) {
                    foreach my $security_dimension ( keys %$role_mids ) {
                        my @new_security_dimension;
                        my $mids = $role_mids->{$security_dimension};
                        foreach my $mid ( _array $mids) {
                            if ( mdb->master_doc->find_one( { collection => $security_dimension, mid => $mid } ) ) {
                                push @new_security_dimension, $mid;
                            }
                            else {
                                warn( "$security_dimension not found: " . $mid );
                            }
                        }
                        if ( !@new_security_dimension ) {
                            delete $role_mids->{$security_dimension};
                        }
                        else {
                            $role_mids->{$security_dimension} = \@new_security_dimension;
                        }
                    }
                    if ( !keys %{$role_mids} ) {
                        delete $project_security->{$user_role};
                    }
                }
            }
            my $yaml = Util->_dump($user);
            mdb->master_doc->update( { mid => $user->{mid} }, $user, { upsert => 1, safe => 1 } );
            mdb->master->update( { mid => $user->{mid} }, { '$set' => { yaml => $yaml } }, { upsert => 1, safe => 1 } );
        }
    }
}

sub downgrade {
}

1;
