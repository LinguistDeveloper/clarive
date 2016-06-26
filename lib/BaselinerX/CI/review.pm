package BaselinerX::CI::review;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Internal';
with 'Baseliner::Role::CI::Asset';

use Baseliner::Core::Registry ':dsl';

sub icon { '/static/images/icons/post.svg' }

has created_on => qw(is rw isa Any), default => sub { mdb->ts };
has file       => qw(is rw isa Any);
has line       => qw(is rw isa Any);
has action     => qw(is rw isa Any);

has_ci 'rev';
has_ci 'repo';

register 'event.review.create' => {
    text => '%1 posted a review: %3',
    description => 'User posted a review',
    vars => ['username', 'ts', 'review'],
    notify => {
        #scope => ['project', 'category', 'category_status', 'priority','baseline'],
        template => '/email/generic_post.html',
        scope => ['project', 'category', 'category_status'],
    },
};

sub rel_type {
    {
        rev  => [ to_mid => 'rev_review' ],
        repo => [ to_mid => 'repo_review' ]
    };
}

sub text {
    my $self = shift;

    my $d = $self->get_data;
    return '' unless $d;

    my $txt = $d->slurp;

    return Encode::decode( 'UTF-8', $txt );
}

1;
