package Baseliner::Role::Parser;
use Moose::Role;
requires 'parse';

has modules => qw(is rw isa HashRef), default=>sub{{}};

=head1 Baseliner::Parser::Perl

A Parser should filter extensions and then search content...?

=cut
package Baseliner::Parser::Perl;
use Baseliner::Moose;
with 'Baseliner::Role::Parser';

sub parse {
    my($self,%p)=@_;
    $p{items}->each( sub {
        my $item = $_;
        return if $item->is_dir;
        return unless $item->path =~ /(pm|pl)$/;
        my $ext = $item->extension;
        if( my $s = $item->slurp ) {
            my $module = $ext eq 'pm' 
               ? do {
                 my $found;
                 for my $lin ( split /\n/, $s ) {
                     if( $lin =~ /^\s*package\s+([\w|:]+)/g ) {
                        $found = $1;
                        last;
                     }
                 }
                 $found // $item->basename;
               }
               : $item->name;
            $item->{module} = $module;
            $item->moniker( $module );
            my %deps;
            for my $use ( $s =~ /use\s+([\w|:]+)/gm ) { 
                next if $use ~~ [qw(base lib strict vars warnings threads)];
                next if $use =~ /^v[0-9]/;
                $deps{ $use } = 1;
            }
            for my $req ( $s =~ /require\s+([\w|:]+)/gm ) { 
                $req =~ s/'"//g;
                $deps{ $req } = 1;
            }
            $item->module_dependencies( [ keys %deps ] );
        } else {
            _error( _loc('Could not scan file %1', $item->path) );
        }
    });
}

=pod

    use Baseliner::Scan;
    my $repo = BaselinerX::CI::filesys_repo->new( root_path=>'/home/apst/scm/servidor/udp' ); 
    my $pp = Baseliner::Parser::Perl->new;
    my $sc = Baseliner::Scan->new( repos=>[$repo], parsers=>[ $pp ] );
    $sc->scan;
    $sc->items;

=cut

package Baseliner::Scan;
use Baseliner::Moose;
has repos     => qw(is rw isa ArrayRef[Baseliner::Role::CI::Repository]);
has parsers   => qw(is rw isa ArrayRef[Baseliner::Role::Parser]);

has ignore_dirs  => qw(is rw isa Bool default 1);
has items => qw(is rw isa ArrayRef[Baseliner::Role::CI::Item]), default=>sub{[]};

has tag_relationship => qw(is rw isa Str default topic_item);

sub scan {
    my ($self, %p)=@_;
    my @items;
    for my $repo ( Util->_array($self->repos) ) {
        for my $parser ( Util->_array( $self->parsers ) ) {
            $parser->parse( items=>$repo->items );
        }
        $repo->items->each( sub {
            my $it = $_;
            return if $self->ignore_dirs && $it->is_dir;
            $self->tagger( item=>$it );
            push @items, $it;
            $_->done_slurping;
        });
    }
    $self->items( \@items );
}

sub commit {
    my ($self,%p) = @_;
    # save items
    for my $it ( Util->_array( $self->items ) ) {
        $it->save;
    }
    # commit relationships
    my $cache = {}; # create a global cache for this
    for my $it ( Util->_array( $self->items ) ) {
        $it->save_relationships( cache=>$cache );
    }
    # update master and master_rel
    # import tags
    my $tag_relationship = $self->tag_relationship;
    for my $it ( Util->_array( $self->items ) ) {
        for my $tag ( Util->_array( $it->{tags} ) ) {
            next unless length $tag;
            my @targets = mdb->master->find({ moniker=>$tag })->fields({ mid=>1 })->all;
            for my $mid ( map { $_->{mid} } @targets ) {
                my $rdoc = { to_mid=>''.$it->mid, from_mid=>"$mid", rel_type=>$tag_relationship };
                mdb->master_rel->find_or_create($rdoc);
            }
        }
    }
}

sub tagger {
    my($self,%p) = @_;
    my $item = $p{item} or Util->_throw( 'Missing param item');
    my %tags;
    my $body = $_->slurp;
    return unless defined $body;
    for my $tag ( $body =~ /#:(\w+):/gm ) { 
        $tags{ $tag }=1;
        $item->{tags}{ $tag } = 1;
    }
    return keys %tags;
}

1;

