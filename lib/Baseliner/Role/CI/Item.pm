package Baseliner::Role::CI::Item;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/page.png' }

has name       => qw(is rw isa Maybe[Str]);    # basename
has dir        => qw(is rw isa Str default /);  # my parent
has path       => qw(is rw isa Str default /);  # fullpath
has size       => qw(is rw isa Num default -1);  
has mask       => qw(is rw isa Num default 777);  
has is_dir     => qw(is rw isa Maybe[Bool]);
has basename   => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    $self->name =~ /^(.*)\.(.*?)$/ ? $1 : $self->name;
};
has extension  => qw(is rw isa Str lazy 1), default => sub {
    my ($self)=@_;
    lc( $self->name =~ /^(.*)\.(.*?)$/ ? $2 : '' );
};
has module_dependencies => qw(is rw isa ArrayRef), default=>sub{[]};

has tag_relationship => qw(is rw isa Str default topic_item); # rel_type
has item_relationship => qw(is rw isa Str default item_item); # rel_type

has variables => qw(is rw isa HashRef), default=>sub{ +{} };
has parse_tree => qw(is rw isa ArrayRef), default=>sub{ [] };

sub save_relationships {
    my($self, %p)=@_;
    my $cache = $p{cache} // {};
    for my $module ( Util->_array( $self->module_dependencies ) ) {
        my $mid = $cache->{ $module };
        if( !defined $mid ) {
            my $row = DB->BaliMaster->search({ moniker=>$module })->first;
            if( $row ) {
                $mid = $row->mid;
                $cache->{ $module } = $mid;
            }
        }
        if( defined $mid ) {
            DB->BaliMasterRel->find_or_create({ from_mid=>$self->mid, to_mid=>$mid, rel_type=>$p{rel_type} // $self->item_relationship }); 
        }
    }
}

=head2 tree_resolve

Go over an items parse_tree and detect parse_tree relationships
to topics and among dependencies.

=cut
sub tree_resolve {
    my ($self,%p) = @_;
    my $tag_relationship = $p{tag_relationship} // $self->tag_relationship; 
    my $item_relationship = $p{item_relationship} // $self->item_relationship; 
    my @topics;
    for my $t ( Util->_array( $self->parse_tree ) ) {
        # moniker should be a modulename
        if( my $module = $t->{module} ) {
            $self->moniker( $module ) ;
            $self->save;
        }
        # tags for topics, etc
        if( my $tag = $t->{tag} ) {
            my @targets =  map { $_->{mid} } DB->BaliMaster->search({ moniker=>$tag }, { select=>'mid' })->hashref->all;
            push @topics, @targets;
            for my $mid ( @targets ) {
                DB->BaliMasterRel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$tag_relationship });
            }
        }
        # item_item relationships
        if( my $tag = $t->{depend} ) {
            my @targets =  map { $_->{mid} } DB->BaliMaster->search({ moniker=>$tag }, { select=>'mid' })->hashref->all;
            for my $mid ( @topics ) {
                DB->BaliMasterRel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$item_relationship });
            }
        }
    }
    return { topics=>\@topics };
}


sub scan {
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

    my @nature_items;
    _fail _loc('No natures available to scan. Please, define some nature CIs before continuing.') unless @natures;
    for my $nat ( @natures ) {
        # should return/update nature accepted items
        push @nature_items, $nat->scan( items=>[ $self ] );   
    }
    _fail _loc('No natures included this item path: %1', $self->path ) unless @nature_items;
    $self->save;  # save my parse tree
    return { parse_tree=>$self->parse_tree  }
}


1;

