package BaselinerX::CI::matcher;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Parser';

sub collection { 'matcher' }
sub has_bl { 0 }

has regex               => qw(is rw isa Str);
has regex_options       => qw(is rw isa Str default xmsi);
has timeout             => qw(is rw isa Num default 10);
has parse_type          => qw(is rw isa Str default Path);
has_cis 'cis';
has_cis 'topics';

sub rel_type {
    {
    topics  => [from_mid => 'parser_topic'],
    cis     => [from_mid => 'parser_ci'],
    }
}

use Baseliner::Utils;
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
    my $path_mode = $self->parse_type =~ /Path/i;
    if( ( $path_mode && $i->path =~ /$regex/ ) 
        || ( !$path_mode !~ /Path/i && $source =~ /$regex/ ) ) {
        $item->save;
        for my $topic ( _array $self->topics ) {
            DB->BaliMasterRel->create({ from_mid=>$topic->mid, to_mid=>$item->mid, rel_type=>'topic_item' });
        }
    }

    _log \%tree ;
    
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


