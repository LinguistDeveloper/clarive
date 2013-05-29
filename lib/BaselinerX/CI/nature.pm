package BaselinerX::CI::nature;
use Baseliner::Moose;
use Baseliner::Utils;
use namespace::autoclean;

with 'Baseliner::Role::CI::Internal';
sub icon { '/static/images/icons/nature.gif' }

has_ci 'server';
has_cis 'items';
sub rel_type {
    { items => [ from_mid => 'nature_items' ] };
}

sub has_bl { 0 }

sub run_scan {
    my ($self)=@_;
    my $stash = {};
    # run loaders
    
    # run rules
    
}

1;
