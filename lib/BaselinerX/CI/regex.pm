package BaselinerX::CI::regex;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'regex' }
sub has_bl { 0 }

has regex          => qw(is rw isa Str);
has regex_options    => qw(is rw isa Str default xmsi);
has timeout          => qw(is rw isa Num default 10);

#service 'parse' => 'Parse a file' => \&parse;

sub parse {
    my ($self,$item) = @_; 
    my $file = $item->path; 
    my $source = $item->source; 
    my $tmout = $self->timeout;
    my $regex = $self->regex; 
    $regex = eval "qr/$regex/". $self->regex_options;
    Util->_fail( 'Missing regex' ) unless $regex;

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
        my $lin = [ map { $_->{lin} } grep { ( $_->{from} <= $-[0] ) && ( $+[0] <= $_->{to} ) } @newline ]->[0];
        push @found => { %+, line=>$lin } if %+;
        while( my($k,$v) = each %+ ) {
            $tree{ $k } = [] unless exists $tree{$k}; 
            push @{ $tree{ $k } }, $v;
        }
    }
    if( %tree ) {
        $item->{parse_tree} ||= [];
        push @{ $item->{parse_tree} } => @found;
        #$item->{parse_tree} = { %{ $item->{parse_tree} || {} }, %tree };
        return \%tree;
    } else {
        return { msg=>'not found' };
    }
}

1;

