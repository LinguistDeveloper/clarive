package BaselinerX::GitTag;
use Moose;
extends 'BaselinerX::GitBranch';
sub icon {
    my $self = shift;
    return sprintf '/static/images/icons/tag_%s.gif', $self->status;
}

sub _click {
    my $self = shift;
    +{
            url      => '/gitpage/branch',
            type     => 'html',
            tab_icon => $self->icon,
            repo_dir => $self->repo_dir,
            repo_mid => $self->repo_mid,
            data => {  prefix => 'Tag' },
            prefix   => 'Tag',
            title    => $self->name,
     }
}

1;
