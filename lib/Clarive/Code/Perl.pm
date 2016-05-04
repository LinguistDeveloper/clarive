package Clarive::Code::Perl;
use Moose;
BEGIN { extends 'Clarive::Code::Base' }

sub eval_code {
    my $self = shift;
    my ( $code, $stash ) = @_;

    $stash ||= {};

    my $preamble = '';

    $preamble .= "use strict; use warnings;" if $self->strict_mode;

    $preamble .= <<'EOF';
use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use Baseliner::Utils;
EOF

    my $filename = $self->filename;
    $preamble .= qq{\n# line 1 "$filename"\n};

    $code = $preamble . $code;

    my $ret = eval $code or die $@;

    return $ret;
}

1;
