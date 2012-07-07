package BaselinerX::Namespace::Changeset;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use Catalyst::Exception;

with 'Baseliner::Role::Namespace::Package';
with 'Baseliner::Role::JobItem';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Approvable';

sub can_job {
    my ( $self, %p ) = @_;
    #return $self->_can_job(1);
    return 1;
}

sub bl {
    my $self = shift;
    #TODO
    return '*';
}

sub created_on {
    my $self = shift;
    return _now();
}

sub created_by {
    my $self = shift;
    return 'root';
}

sub checkout { }

sub transition {
    my $self = shift;
    _throw 'TODO';
}

sub promote {
    my $self = shift;
    _throw 'TODO';
}

sub demote {
    my $self = shift;
    _throw 'TODO';
}

sub nature {
    my $self = shift;
    #_log '*********************** dump ************************\n'._dump $self;
    return undef;
}

sub approve { }
sub reject { }
sub is_approved { }
sub is_rejected { }
sub user_can_approve { }

sub find {
    my $self = shift;
    _throw 'TODO';
}

sub path {
    my $self = shift;
    _throw 'TODO';
}

sub state {
    my $self = shift;
    _throw 'TODO';
}

sub get_row {
    my $self = shift;
    _throw 'TODO';
}

sub project {
    my $self = shift;
    $self->ns_data->{project};
}

sub application {
    my $self = shift;
    'application/' . $self->ns_data->{project};
}

sub rfc {
    my $self = shift;
    _throw 'TODO';

}

sub parents {
    my $self = shift;
    _throw 'TODO';
}

sub more_info {
    my $self = shift;
    return "";
}

1;

