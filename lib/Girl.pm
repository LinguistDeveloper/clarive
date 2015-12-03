package Girl;
use Any::Moose;
use Girl::Repo;

sub unquote {
    my $class = shift;
    my $str = shift;

    sub unq {
        my $seq = shift;
        my %es  = (        # character escape codes, aka escape sequences
            't' => "\t",      # tab            (HT, TAB)
            'n' => "\n",      # newline        (NL)
            'r' => "\r",      # return         (CR)
            'f' => "\f",      # form feed      (FF)
            'b' => "\b",      # backspace      (BS)
            'a' => "\a",      # alarm (bell)   (BEL)
            'e' => "\e",      # escape         (ESC)
            'v' => "\013",    # vertical tab   (VT)
        );

        if ( $seq =~ m/^[0-7]{1,3}$/ ) {

            # octal char sequence
            return chr( oct($seq) );
        } elsif ( exists $es{$seq} ) {

            # C escape sequence, aka character escape code
            return $es{$seq};
        }

        # quoted ordinary character
        return $seq;
    }

    if ( $str && $str =~ m/^"(.*)"$/ ) {

        # needs unquoting
        $str = $1;
        $str =~ s/\\([^0-7]|[0-7]{1,3})/unq($1)/eg;
    }
    return $str;
}

1;
