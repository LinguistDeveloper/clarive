package Baseliner::Role::Approvable;
use Moose::Role;

sub approve {
    my ($self) = @_;
}

sub is_approval_active {
    return Baseliner->model('Request')->approvals_active;
}

sub reject {
    my ($self) = @_;
}

sub is_verified {
    my ($self) = @_;
    my $rm = Baseliner->model('Request');
    return 1 if ! $rm->approvals_active;
    return defined $rm->last_status( ns=>$self->ns );
}

sub request_status {
    my ($self) = @_;
    Baseliner->model('Request')->last_status( ns=>$self->ns,);
}
 
sub is_pending {
    my ($self) = @_;
    my $rm = Baseliner->model('Request');
    return 0 unless $rm->approvals_active;
    'pending' eq $rm->last_status( ns=>$self->ns );
}

sub is_approved {
    my ($self) = @_;
    my $rm = Baseliner->model('Request');
    return 1 unless $rm->approvals_active;
    'approved' eq $rm->last_status( ns=>$self->ns );
}

sub is_rejected {
    my ($self) = @_;
    my $rm = Baseliner->model('Request');
    return 0 unless $rm->approvals_active;
    'rejected' eq $rm->last_status( ns=>$self->ns );
}

sub user_can_approve {
    my ($self) = @_;
}


=head1 DESCRIPTION

Something that can be approved. 

=cut

1;

