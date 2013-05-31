package Baseliner::Role::Parser;
use Moose::Role;
requires 'parse';

=head1 Baseliner::Parser::Perl

A Parser should filter extensions and then search content...?

=cut
package Baseliner::Parser::Perl;
use Baseliner::Moose;
with 'Baseliner::Role::Parser';

sub parse {
    my($self,%p)=@_;
    $p{items}->each( sub {
       return if $_->is_dir;
       return unless $_->path =~ /(pm|pl)$/;
       my $ext = $_->extension;
       if( my $s = $_->slurp ) {
          my $module = $ext eq 'pm' 
             ? do {
             my $found;
             for my $lin ( split /\n/, $s ) {
                 if( $lin =~ /^\s*package\s+([\w|:]+)/g ) {
                    $found = $1;
                    last;
                 }
             }
             $found // $_->basename;
          }
          : $_->name;
          for my $use ( $s =~ /use\s+([\w|:]+)/gm ) { 
              next if $use ~~ [qw(base lib strict vars warnings threads)];
              next if $use =~ /^v[0-9]/;
              $_->{dependencies}{ $module }{ $use } = 1;
          }
          for my $req ( $s =~ /require\s+([\w|:]+)/gm ) { 
              $req =~ s/'"//g;
              $_->{dependencies}{ $module }{ $req } = 1;
          }
       } else {
          _error( _loc('Could not scan file %1', $_->path) );
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

has dependencies => qw(is rw isa HashRef);
has items => qw(is rw isa ArrayRef[Baseliner::Role::CI::Item]), default=>sub{[]};

sub scan {
    my ($self, %p)=@_;
    my @items;
    for my $repo ( Util->_array($self->repos) ) {
        for my $parser ( Util->_array( $self->parsers ) ) {
            $parser->parse( items=>$repo->items );
        }
        $repo->items->each( sub {
            $self->tagger( item=>$_ );
            push @items, $_;
            $_->done_slurping;
        });
        #$self->dependencies( \%deps );
    }
    $self->items( \@items );
}

sub tagger {
    my($self,%p) = @_;
    my $item = $p{item} or Util->_throw( 'Missing param item');
    my %tags;
    my $body = $_->slurp;
    return unless defined $body;
    for my $tag ( $body =~ /#tag:(\w+)/gm ) { 
        $item->{tags}{ $tag } = 1;
    }
}

1;

