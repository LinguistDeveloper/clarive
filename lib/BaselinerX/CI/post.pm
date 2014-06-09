package BaselinerX::CI::post;
use Baseliner::Moose;
with 'Baseliner::Role::CI::Internal';
with 'Baseliner::Role::CI::Asset';

sub icon { '/static/images/icons/post.png' }

has content_type => qw(is rw isa Any default text);
has created_on   => qw(is rw isa Any), default=>sub{ mdb->ts };

has_ci 'topic';

sub rel_type {
    { 
        topic => [ to_mid => 'topic_post' ] ,
    };
}

sub text { 
    my ($self)=@_;
    my $d = $self->get_data;
    return $d ? $d->slurp : '';
} 

1;

