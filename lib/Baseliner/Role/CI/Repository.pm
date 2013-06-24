package Baseliner::Role::CI::Repository;
use Moose::Role;
with 'Baseliner::Role::CI';

requires 'list_elements';
requires 'checkout';
requires 'update_baselines';
requires 'list_elements';
requires 'checkout';
requires 'repository';

sub method_scan {
    my($self,$stash)=@_;

    # get natures
    my @natures;
    for my $natclass ( Util->packages_that_do( 'Baseliner::Role::CI::Nature' ) ) {
        my $coll = $natclass->collection;
        DB->BaliMaster->search({ collection=>$coll })->each( sub {
            my ($row)=@_;
            Util->_log( $row->mid );
            push @natures, Util->_ci( $row->mid );
        });
    }

    _fail _loc('No natures available to scan. Please, define some nature CIs before continuing.') unless @natures;
    my $its = $self->load_items;
    my @items = @{ $its->children };

    for my $nat ( @natures ) {
        # should return/update nature accepted items
        $nat->scan( items=>\@items );   
    }
    $_->save for @items;
    return @items;
}

1;



