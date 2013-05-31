package Baseliner::Role::CI::Item;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/page.png' }

has name       => qw(is rw isa Maybe[Str]);    # basename
has dir        => qw(is rw isa Str default /);  # my parent
has path       => qw(is rw isa Str default /);  # fullpath
has is_dir     => qw(is rw isa Maybe[Bool]);
has basename   => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    $self->name =~ /^(.*)\.(.*?)$/ ? $1 : $self->name;
};
has extension  => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    lc( $self->name =~ /^(.*)\.(.*?)$/ ? $2 : '' );
};

1;

