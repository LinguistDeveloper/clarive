package Baseliner::Role::CI::Item;
use Moose::Role;
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/page.png' }

has name         => qw(is rw isa Maybe[Str]);              # basename
has dir          => qw(is rw isa Str default /);           # my parent
has path         => qw(is rw isa Str default /);           # fullpath, with project, prefix
has path_rel     => qw(is rw isa Str);                     # with prefix only 
has path_in_repo => qw(is rw isa Str);                     # in case someone changes path, set this here
has size         => qw(is rw isa Num default -1);
has mask         => qw(is rw isa Maybe[Num] default 777);
has is_dir       => qw(is rw isa Maybe[Bool]);
has status       => qw(is rw isa Maybe[Str] default A);    # used by jobs to determine create, delete, etc (A,M,D)
has basename     => qw(is rw isa Str lazy 1), default => sub {
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

sub filepath {
    my ($self)=@_;
    return $self->path;
}

sub rename {
    my ($self, $expr)=@_;
    if( ref $expr eq 'CODE' ) {
        local $_ = $self->path;
        $expr->();
        $self->path( $_ );
    } else {
        $self->path( $expr );
    }
    my $name = Util->_file($self->path)->basename;
    $self->name( $name );
    return $self->path;
}

sub path_cut {
    my ($self, $regex)=@_;
    my $path = $self->path;
    my ($part) = $path =~ /$regex/;
    return $part;
}

sub path_tail {
    my ($self, $head)=@_;
    $self->path_cut( qr/^$head(.*)$/ );
}

sub add_parse_tree {
    my ($self,$new_tree) = @_;
    return $new_tree unless defined $new_tree;
    my @tree = Util->_array( $self->parse_tree );
    for my $entry ( Util->_array( $new_tree ) ) {
        push @tree, $entry;
    }
    my %uniq;
    my @uniq_tree;
    for my $entry ( @tree ) {
        if( ref $entry eq 'HASH' ) {
            my $k = join ';', sort values %$entry;
            next if exists $uniq{$k};
            $uniq{ $k } = 1;
            push @uniq_tree, $entry;
        } else {
            push @uniq_tree, $entry;
        }
    }
    $self->parse_tree( \@uniq_tree );
}

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
            my $doc = { from_mid=>''.$self->mid, to_mid=>"$mid", rel_type=>$p{rel_type} // $self->item_relationship };
            DB->BaliMasterRel->find_or_create($doc); 
            mdb->master_rel->find_or_create($doc);
        }
    }
}

=head2 tree_resolve

Go over an items parse_tree and detect parse_tree relationships
to topics and among dependencies.

Saves item in the process.

=cut
sub tree_resolve {
    my ($self,%p) = @_;
    my $tag_relationship = $p{tag_relationship} // $self->tag_relationship; 
    my $item_relationship = $p{item_relationship} // $self->item_relationship; 
    my @rel_cis;
    my @rel_topics;
    for my $t ( Util->_array( $self->parse_tree ) ) {
        # moniker should be a modulename
        if( my $module = $t->{module} ) {
            $self->moniker( $module ) ;
            Util->_error( "---------------------------------> $module ");
            Util->_error( Util->_whereami );
            $self->save;
        }
        # tags for topics, etc
        if( my $tag = $t->{tag} ) {
            my @targets =  map { $_->{mid} } DB->BaliMaster->search({ -bool=>\['lower(moniker)=?', lc($tag) ], collection=>{ '='=>'topic' } }, { select=>'mid' })->hashref->all;
            push @rel_topics, @targets;
            for my $mid ( @targets ) {
                Baseliner->cache_remove( qr/:$mid:/ );
                # XXX missing rel_field...
                DB->BaliMasterRel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$tag_relationship });
                mdb->master_rel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$tag_relationship });
            }
        }
        # item_item relationships
        if( my $tag = $t->{depend} // $t->{depends} ) {
            my @targets =  map { $_->{mid} } DB->BaliMaster->search({ -bool=>\['lower(moniker)=?', lc($tag) ], collection=>{ '!='=>'topic' } }, { select=>'mid' })->hashref->all;
            push @rel_cis, @targets;
            for my $mid ( @rel_cis ) {
                Baseliner->cache_remove( qr/:$mid:/ );
                # XXX missing rel_field...
                DB->BaliMasterRel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$item_relationship });
                mdb->master_rel->find_or_create({ to_mid=>$self->mid, from_mid=>$mid, rel_type=>$tag_relationship });
            }
        }
        # XXX compare my parse tree (functions, etc) with other parse trees
        # XXX consider having a function/procedure CI, prepended by its source name
    }
    return { rels=>[ @rel_cis, @rel_topics ], cis=>\@rel_cis, topics=>\@rel_topics };
}

sub scan {
    my($self,$stash)=@_;

    # get natures
    my @natures = Baseliner::Role::CI::Nature->all_cis;

    $self->parse_tree([]);

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


=head2 moniker_from_tree_or_name

Check if we have a 'module' in the parse tree.

If we do, don't do anything.

If we don't, set moniker from filename


=cut
sub moniker_from_tree_or_name {
    my ($self)=@_;

    # first check if we have a module in the tree
    my $module;
    for my $entry ( @{ $self->parse_tree } ) {
        $module = $entry->{module} if defined $entry->{module}; 
    }

    # determine module name 
    if( ! defined $module ) {
        $module = $self->basename;
        if( my $fb = $self->path_capture ) {
            $module = $+{module} if $self->path =~ qr/$fb/ && length $+{module};
        } else {
            $module = $self->moniker // $self->basename;
        }
        $module = $self->change_case( $module );
        $self->moniker( $module );
        return $module;
    }
    elsif ( ! length $self->moniker ) {
        # we dont have a moniker but we have a module, keep it
        return $self->moniker( $module );
    }
    return $module;
}

1;

