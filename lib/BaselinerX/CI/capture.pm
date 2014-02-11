package BaselinerX::CI::capture;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'capture' }
sub has_bl { 0 }

has regex         => qw(is rw isa Str);
has regex_options => qw(is rw isa Str default xmsi);
has timeout       => qw(is rw isa Num default 10);
has parse_type    => qw(is rw isa Str default Source);

#service 'parse' => 'Parse a file' => \&parse;

sub parse {
    my ($self,$item) = @_; 
    my $file = $item->path; 
    my $source = $item->source; 
    my $tmout = $self->timeout;
    my $regex = $self->regex; 
    $regex = eval( 'qr{' . $regex . '}'. $self->regex_options );
    Util->_fail( 'Missing or invalid regex: %1', $@ ) unless $regex;

    my $path_mode = $self->parse_type =~ /Path/i;
    $source = "$file" if $path_mode;
    # index line numbers
    my @newline;
    my $i=0;
    my $last=0;
    while( $source =~ /(\r?\n)/g ) {
        push @newline => { from=>$last, to=>$-[0], lin=>++$i };
        $last = $+[0];
    }
    
    # TODO allow for more options, to run just %+ (run once) and %- (keep last)
    my %tree;
    my @found;
    while( $source =~ /$regex/g ) {
        my %caps = %+;
        my $lin = [ map { $_->{lin} } grep { ( $_->{from} <= $-[0] ) && ( $+[0] <= $_->{to} ) } @newline ]->[0];
        push @found => { %caps, line=>($lin//0) } if %caps;
        Util->_debug( \%caps );
        while( my($k,$v) = each %caps ) {
            $tree{ $k } = [] unless exists $tree{$k}; 
            push @{ $tree{ $k } }, $v;
        }
    }
    Util->_debug( Util->_loc("CAPTURE for item %1 with regex %2", $item->path, $regex ) );
    Util->_debug( \@found );
    if( %tree ) {
        $item->add_parse_tree( \@found );
        return \%tree;
    } else {
        return {};
    }
}

1;

