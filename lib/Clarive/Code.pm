package Clarive::Code;
use Moose;

use Time::HiRes qw(gettimeofday tv_interval);
use Try::Tiny;
use Class::Load qw(load_class);
use Baseliner::Utils qw(_file _fail);

has strict_mode => qw(is rw isa Bool default 1);
has benchmark   => qw(is rw isa Bool default 0);

my %LANGS = (
    js   => 'JS',
    perl => 'Perl',
    sql  => 'SQL',
);

sub eval_file {
    my $self = shift;
    my ( $file, %options ) = @_;

    my ($lang) = delete $options{lang} || $file =~ m/\.(.*?)/;
    $lang ||= 'js';

    my $code = _file($file)->slurp( iomode => '<:utf8' );

    return $self->eval_code( $code, filename => $file, lang => $lang, %options );
}

sub eval_code {
    my $self = shift;
    my ( $code, %options ) = @_;

    my $lang  = delete $options{lang}  || 'js';
    my $stash = delete $options{stash} || {};

    my $evaler = $self->_build_evaler( $lang, strict_mode => $self->strict_mode, %options );

    my ( $t0, $elapsed );
    if ( $self->benchmark ) {
        $t0 = [ gettimeofday() ];
    }

    my $error;

    my $ret;
    try {
        $ret = $evaler->eval_code( $code, $stash )
    } catch {
        $error = $_;
    };

    if ( $self->benchmark ) {
        $elapsed = tv_interval($t0);
    }

    return {
        ret   => $ret,
        error => $error,
        $self->benchmark ? ( elapsed => $elapsed ) : ()
    };
}

sub _build_evaler {
    my $self = shift;
    my ( $lang, %options ) = @_;

    _fail "Unknown language $lang" unless exists $LANGS{$lang};

    my $evaler = __PACKAGE__ . '::' . $LANGS{$lang};
    load_class $evaler;

    return $evaler->new(%options);
}

1;
