package Clarive::Code;
use Moose;

use Time::HiRes qw(gettimeofday tv_interval);
use Moose::Util::TypeConstraints qw(enum);
use Baseliner::Utils qw(_fail _loc _file);
use Clarive::Code::JS;

has lang => qw(default js is rw isa), enum( [qw(js perl)] );
has benchmark    => qw(is rw isa Bool default 0);
has elapsed      => qw(is rw isa Num default 0);
has current_file => qw(is rw isa Str), default => 'EVAL';
has app          => qw(is rw isa Maybe[Clarive::App] weak_ref 1);
has options      => qw(is rw isa HashRef), default => sub { +{} };

sub run_file {
    my $self = shift;
    my ( $file, $stash ) = @_;

    my ($ext) = _file($file)->basename =~ /\.(\w+)$/;
    my $lang = { pl => 'perl', t => 'perl' }->{$ext} // $ext;
    $self->lang($lang);

    $self->current_file("$file");

    my $code = _file($file)->slurp( iomode => '<:utf8' );

    return $self->eval_code( $code, $stash );
}

sub eval_code {
    my $self = shift;
    my ( $code, $stash, $opts ) = @_;

    my $js =
      Clarive::Code::JS->new( app => $self->app, options => $self->options, current_file => $self->current_file );

    my $t0;
    if ( $self->benchmark ) {
        $t0 = [ gettimeofday() ];
    }

    my $ret = ( $js->eval_code( $code, $stash, $opts ) );

    if ( $self->benchmark ) {
        $self->elapsed( tv_interval($t0) );
    }

    return $ret;
}

1;
