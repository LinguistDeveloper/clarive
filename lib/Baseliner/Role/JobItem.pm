package Baseliner::Role::JobItem;
use Moose::Role;

requires 'can_job';

has 'why_not' => ( is=>'rw', isa=>'Str', );  ## if it cannot be included, why not? 
has '_can_job' => ( is=>'rw', isa=>'Bool', default=>1 );  ## cached value 

sub icon_job {
    my $self = shift;
    return $self->_can_job ? $self->icon_on : $self->icon_off;
}

sub is_contained {
    my $self = shift;
    return defined Baseliner->model('Baseliner::BaliReleaseItems')
        ->search({ 'me.ns'=>$self->ns },{ prefetch=>'id_rel' })->first;
}

sub containers {
    my $self = shift;
    my $rs = Baseliner->model('Baseliner::BaliReleaseItems')->search({ 'me.ns'=>$self->ns },{ prefetch=>'id_rel' });
    my @ret;
    while( my $r = $rs->next ) {
        my $ns = $r->release->item;
        my $n = Baseliner->model('Namespaces')->get( $ns );
        next unless ref $n;
        push @ret, $n;
    } 
    return wantarray ? @ret : \@ret;
}

1;
