package Baseliner::Tail;
use Moose;

use Baseliner::Utils qw(_fail);

has 'file', is => 'ro', required => 1;
has 'fh',   is => 'rw';
has 'pos',  is => 'rw', default  => 0;

sub BUILD {
    my $self = shift;

    _fail sprintf "Can't open file `%s`: $!", $self->file unless open my $fh, '<', $self->file;

    $self->fh($fh);
}

sub read {
    my $self = shift;

    my $fh = $self->fh;

    if ( !$fh ) {
        open $fh, '<', $self->file or return;
    }

    seek $fh, $self->pos, 0;

    my $rcount = read $fh, my $buf, 8096, 0;
    return unless defined $rcount;

    return '' unless $rcount;

    if ( $buf =~ m/\033/ ) {
        my @seq = split /\033/, $buf;

        my $last = pop @seq;

        if ( length $last > 6 || $last =~ m/^\[\d(?:;\d+)?m/ ) {
            push @seq, $last;
        }

        $buf = join "\033", @seq;
    }

    $self->pos( $self->pos + length $buf );

    if ( !-e $self->file ) {
        close $fh;
        $self->fh(undef);
    }

    return $buf;
}

1;
