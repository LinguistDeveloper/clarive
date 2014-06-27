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
    my $tmout = $self->timeout;
    my $regex = $self->regex; 
    $regex = eval 'qr{' . $regex . '}'. $self->regex_options;
    Util->_fail( 'Missing or invalid regex: %1', $@ ) unless $regex;

    _debug ( _loc "Matcher scanning file %1...", $file );
    
    # TODO allow for more options, to run just %+ (run once) and %- (keep last)

    my $tree = [];
    my $path_mode = $self->parse_type =~ /Path/i;
    my $has_match = 0;
    if( $path_mode ) {
        $has_match = $file =~ /$regex/;
    } 
    else {
        my $source = $item->source; 
        # index line numbers
        my @newline;
        my $i=0;
        my $last=0;
        while( $source =~ /(\r?\n)/g ) {
            push @newline => { from=>$last, to=>$-[0], lin=>++$i };
            $last = $+[0];
        }
        $has_match = $source =~ /$regex/;
    }

    _debug _loc "%1 has match? %2", $file, $has_match;

    if( $has_match ) {
        $item->save;
        for my $topic ( _array $self->topics ) {
            push @$tree, { tag => $topic->moniker };
            #mdb->master_rel->update_or_create({ from_mid=>''.$topic->mid, to_mid=>''.$item->mid, rel_type=>'topic_item' });
        }
        for my $ci ( _array $self->cis ) {
            push @$tree, { tag => $ci->moniker };
            #my $coll = $ci->collection || 'ci';
            #mdb->master_rel->update_or_create({ from_mid=>''.$ci->mid, to_mid=>''.$item->mid, rel_type=> $coll . '_item' });
        }
        cache->clear;
    }

    if( @$tree ) {
        $tree = $self->process_item_tree( $item, $tree ); 
        $tree = $item->add_parse_tree( $tree );
        return $tree;
    } else {
        return {};
    }
}

1;


