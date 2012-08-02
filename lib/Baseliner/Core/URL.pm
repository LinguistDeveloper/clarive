package Baseliner::Core::URL;
use Moose;

has 'type' => (is=>'rw', isa=>'Str', default=>'comp');
has 'title' => (is=>'rw', isa=>'Str', default=>'');
has 'url' => (is=>'rw', isa=>'Str', default=>'');

sub stringify {
    my ($self)=@_;
    my $title = $self->title;
    $title=~s{\:}{.}g;
    $title=~s{\"}{´}g;
    $title=~s{\'}{´}g;
    return join':', $self->type, $title, $self->url;
}

1;
