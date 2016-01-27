package Baseliner::GitSmartParser;
use Moose;

my $HEX_RE = qr/^[a-f0-9]{40}$/;

sub parse_fh {
    my $self = shift;
    my ($fh) = @_;

    return () unless $fh && ref $fh;

    my @changes;
    while (1) {
        read( $fh, my $length, 4 );
        last unless $length =~ m/^[a-f0-9]+$/;

        $length = hex $length;

        last unless $length && $length > 4;

        $length -= 4;

        read( $fh, my $text, $length );

        last unless $text;

        my ( $old, $new, $ref ) = split /[ \x00]/, $text;

        next unless $old =~ m/$HEX_RE/ && $new =~ m/$HEX_RE/ && $ref;

        push @changes,
          {
            ref => $ref,
            old => $old,
            new => $new,
          };
    }

    seek $fh, 0, 0;

    return @changes;
}

1;
