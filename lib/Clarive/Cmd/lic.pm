package Clarive::Cmd::lic;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;

my $ss = join '', qw(l i c e n s e);
our $CAPTION = $ss . ' verification';

our $t0;

with 'Clarive::Role::Baseliner';

sub run {
    my ($self, %opts) = @_;
    say "Clarive - License data:" ; 
    if( my $site = $self->app->config->{ $ss } ) {
        eval { require Clarive::Util::TLC; };
        my $lic = Clarive::Util::TLC::check( $site, verbose=>1 );
        if( $opts{verbose} ) {
            say $self->app->yaml( $lic );
        }
    } else {
        die "ERROR: no license data found";
    }
}

1;

