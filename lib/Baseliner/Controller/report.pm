package Baseliner::Controller::Report;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Baseliner::Core::DBI;
use DateTime;
use Try::Tiny;
use v5.10;

BEGIN {  extends 'Catalyst::Controller' }

$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  

sub get_ci_columns : Local {
    my ($self, $c) = @_;
    my $p = $c->req->params;
    
    my $collection = 'BaselinerX::CI::' . $p->{collection};
    my @columns_ci = map { +{ name => $_->name} } grep {$_->associated_class->get_meta_instance->_class_name eq $collection} $collection->meta->get_all_attributes;

    $c->stash->{json} = { data => \@columns_ci, totalCount => scalar @columns_ci };

    $c->forward('View::JSON');
}


1;

