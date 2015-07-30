package BaselinerX::Job::Elements;
use Moose;
use Baseliner::Utils;
use Try::Tiny;

has 'elements' => (
               is=>'rw', isa=>'ArrayRef', default=>sub{ [] },
               traits  => ['Array'],
               handles => { count=>'count', all=>'elements' }
             );

=head2 push_elements [@elements|$element]

Pushes an array or a single element into the collection. 
    
    my $es = new BaselinerX::Job::Elements;
    # either like this:
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    # or this:
    $es->push_elements( @elements );

=cut
sub push_element { push_elements(@_) }

sub push_elements {
    my $self = shift;
    $self->elements( [ _array($self->elements) , @_ ] )
        if( scalar @_ );
}

sub recent_elements {
    my ( $self ) = @_;
    my @elements;
    my %hash = $self->hash;
    for my $element ( @_ ) {
        if( $hash{ $element->long_path } ) {
            if( $self->is_more_recent( $element ) ) { 
                push @elements, $element;
            }
        } else {
            push @elements, $element;
        }
    }
    return @elements;
}

sub hash_by_path {
    my ( $self ) = @_;
    my %hash;
    for my $element ( _array $self->elements ) {
        my $key = $element->long_path;
        $hash{ $key } = $element;	
    }
    return %hash;
}

sub hash_by_version {
    my ( $self ) = @_;
    my %hash;
    for my $element ( _array $self->elements ) {
        my $key = $element->long_path;
        $hash{ $key } = $element;	
    }
    return %hash;
}

sub paths {
    my $self = shift;
    map { $_->filepath } $self->all;
}

=head2 exclude_regex

Returns a new instance of elements
that do not match a given path regex.

    my $list = $elements->exclude_regex( '^/app/folder', ... );

=cut
sub exclude_regex {
    my $self = shift;
    my $split = $self->split_on_regex( @_ );
    return __PACKAGE__->new( elements=>$split->{dont} );
}

sub include_regex {
    my $self = shift;
    my $split = $self->split_on_regex( @_ );
    return __PACKAGE__->new( elements=>$split->{match} );
}

=head2 split_on_regex

Returns 2 arrays of elements, one for
the elements that match any of the regexes, and
one array with elements that didn't match any.

    my $res = $elements->split_on_regex( '^/app/folder', ... );
    
    say "Matches: "     . @{ $res->{matches} };
    say "Don't match: " . @{ $res->{dont} };

=cut
sub split_on_regex {
    my $self = shift;
    my @match;
    my @dont;
    my @regexes = map { ref $_ eq 'Regexp' ? $_ : qr/$_/ } @_;
    for my $e ( @{ $self->elements } ) {
        ( grep { $e->filepath =~ $_ } @regexes )
            ? push( @match, $e )
            : push( @dont , $e );
    }
    return { match=>\@match, dont=>\@dont };
}

=head2 cut_to_path_regex

Returns a new clone of elements that match a given path regex.

    my $list = $elements->cut_to_path_regex( '^/app/folder' );

=cut
sub cut_to_path_regex {
    my ( $self, $regex ) = @_;
    _throw 'Missing argument regex' unless $regex;
    my @ok;
    $regex = qr/$regex/ unless ref $regex eq 'Regexp';
    for my $e ( @{ $self->elements } ) {
        push @ok, $e if $e->filepath =~ $regex;
    }
    return __PACKAGE__->new( elements=>\@ok );
}

sub extract_variables {
    my ( $self, $regex ) = @_;
    _throw 'Missing argument regex' unless $regex;
    my @ok;
    my %vars = ();
    $regex = qr/$regex/ unless ref $regex eq 'Regexp';
    for my $e ( @{ $self->elements } ) {
        %vars = ( %vars, %+ ) if $e->filepath =~ $regex;
    }
    return %vars;
}


=head2 list_part

Returns an array of unique path parts based on the part name passed as argument.

    my $es = new BaselinerX::Job::Elements;
    $es->push_element(  new BaselinerX::Job::Element(path=>'/xx/yy/ww', mask=>'/app/nat/sub' ) );
    my @applications = $es->list_part('app');
    my @natures = $es->list_part('nat');

=cut
sub list_part {
    my $self = shift;
    my $part = shift;
    if( $part) {
        my @list;
        for my $e ( @{ $self->elements } ) {
            my %parts = $e->path_parts;
            push @list, $parts{$part} if $parts{$part};
            try {  ## may die if method $part doesn't exist
                if( $e->meta->has_method($part) ) {
                    push @list, $e->$part;
                }
            } catch {};
        }
        return _unique @list; 
    } else {
        return @{ $self->elements || [] };
    }
}
sub list { list_part(@_) }

=head2 cut_to_subset (part, value)

Returns a new Elements collective reduced to a subset.

    my $elements = new BaselinerX::Job::Elements;
    $elements->cut_to_subset( 'nature', 'J2EE' );
    
=cut
sub cut_to_subset {
    my $self = shift;
    my $part = shift;
    my $value = shift;
    return __PACKAGE__->new( elements=>[ $self->subset( $part, $value ) ] );
}

=head2 count
    
Returns the number of elements.

=cut

# count by delegation

=head2 subset (part, value)

Returns an array of elements. 

=cut
sub subset {
    my ($self, $part, $value ) = @_;
    my @subset;
    for my $e ( @{ $self->elements } ) {
        my %parts = $e->path_parts;
        if( $parts{$part} eq $value ) {
            push @subset, $e;
        } else {
            next unless $e->meta->has_method($part);
            eval {  ## may die if method $part doesn't exist
                push @subset, $e if $e->$part eq $value;
            };
        }
    }
    return @subset;
}

=head2 split_by_extension

Given an array of extensions (without the dot), returns 2 lists,
the matching one, and the no-matching.

my( $elems_con, $elems_sin ) = $elements->split_by_extension( 'java', 'jar' );
if( $elems_con->count > 0 ) { hay ear }
elsif( $elems_sin->count > 0 ) { hay parcial }


=cut 

sub split_by_extension {
    my ($self, @exts ) = @_;
    my (@match,@unmatch);
    my $exts_str = '(.' . join( '$)|(.', @exts ) . ')';
    my $re = qr/$exts_str/;
    for my $e ( _array $self->elements ) {
        if( $e->name =~ $re ) { push( @match, $e ); next }
        push @unmatch, $e;
    }
    my $matching = __PACKAGE__->new( elements=>\@match );
    my $unmatching = __PACKAGE__->new( elements=>\@unmatch );
    return $matching, $unmatching;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
