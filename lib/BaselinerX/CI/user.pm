package BaselinerX::CI::user;
use Moose;
with 'Baseliner::Role::CI::Internal';

sub icon { '/static/images/icons/user.gif' }

sub storage { 'BaliUser' }
sub has_description { 0 }

around table_update_or_create => sub {
    my ($orig, $self, $rs, $mid, $data, @rest ) = @_;
    $data->{username} = delete $data->{name};
    $self->$orig( $rs, $mid, $data, @rest );
};

1;
