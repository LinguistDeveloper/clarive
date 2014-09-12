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
    my $txt = $d->slurp;
    utf8::decode( $txt ); # probably needed for every GridFS data? or just a slurp thing? maybe use a better file reader
    return $d ? $txt : '';
} 

1;

