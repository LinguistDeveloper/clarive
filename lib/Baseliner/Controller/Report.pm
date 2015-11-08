package Baseliner::Controller::Report;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  

sub get_ci_columns : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;

    my $root = 'BaselinerX::CI::';
    my $collection = $root . $p->{collection};
    my $collection_extends = $root . $p->{collection_extends} if $p->{collection_extends} ;

    my @columns;
    my @columns_extends_ci;
    my @columns_ci = map { +{ name => $_->name}} grep {$_->associated_class->get_meta_instance->_class_name eq $collection} $collection->meta->get_all_attributes;
    
    if ($collection_extends) {
        my @columns_extends_ci = map { +{ name => $_->name}} grep {$_->associated_class->get_meta_instance->_class_name eq $collection_extends} $collection_extends->meta->get_all_attributes;
        push @columns_ci, @columns_extends_ci;
    }

    
    $c->stash->{json} = { data => \@columns_ci, totalCount => scalar @columns_ci };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

