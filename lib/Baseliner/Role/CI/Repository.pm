package Baseliner::Role::CI::Repository;
use Moose::Role;
with 'Baseliner::Role::CI';

has rel_path => qw(is rw isa Str);   # checkout path prefix

requires 'list_elements';
requires 'checkout';
requires 'update_baselines';
requires 'list_elements';
requires 'checkout';
requires 'repository';

sub content_url { '/lifecycle/branches' }   # TODO should be list_repo_contents, migrate Git, SVN

sub method_scan {
    my($self,$stash)=@_;

    $Baseliner::CI::_no_sync = 1; # don't refresh index until the end

    # get natures
    my @natures = Baseliner::Role::CI::Nature->all_cis;

    _fail _loc('No natures available to scan. Please, define some nature CIs before continuing.') unless @natures;
    my $its = $self->load_items;
    my @items = @{ $its->children };

    # cleanup parse trees for items, but no commit
    for my $it ( @items ) {
        $it->parse_tree([]);
    }

    # scan 
    for my $nat ( @natures ) {
        $nat->scan( items=>\@items );   
        # TODO should return/update nature accepted items, and filter on that if nature has the option
    }

    # commit items 
    for my $it( @items ) {
        $it->save;  
    }

    # tie into related cis
    for my $it( @items ) {
        $it->tree_resolve; 
    }

    return @items;
}

1;



