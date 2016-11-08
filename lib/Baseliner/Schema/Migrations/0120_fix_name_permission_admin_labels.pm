package Baseliner::Schema::Migrations::0120_fix_name_permission_admin_labels;
use Moose;

sub upgrade {
    my @roles = mdb->role->find( { actions => { '$ne' => '' } } )->all;

    foreach my $role (@roles) {
        my ($old_name_action) =
          grep { $_->{action} eq 'action.labels.admin' } @{ $role->{actions} };
        my ($new_name_action) =
          grep { $_->{action} eq 'action.admin.labels' } @{ $role->{actions} };

        if ($old_name_action) {
            if ($new_name_action) {
                @{ $role->{actions} } = grep { $_->{action} ne 'action.labels.admin' } @{ $role->{actions} };
            }
            else {
                foreach my $action ( @{ $role->{actions} } ) {
                    $action->{action} = 'action.admin.labels' if $action->{action} eq 'action.labels.admin';
                }
            }
            mdb->role->update( { id => $role->{id} }, { '$set' => { actions => $role->{actions} } } );
        }
    }
}

sub downgrade {

}

1;
