package Baseliner::Encryptor;
use strict;
use warnings;

use Crypt::Blowfish::Mod;

sub config { Clarive->config }

sub encrypt_key { $_[0]->decrypt_key(@_) }

sub decrypt_key {
    my $class = shift;

    my $key = $class->config->{decrypt_key} // $class->config->{dec_key};

    Util->_fail("Error: missing 'decrypt_key' config parameter") unless length $key;

    return $key;
}

sub encrypt {
    my ( $class, $str, $key ) = @_;

    $key //= $class->encrypt_key;

    my $b = $class->_build_encryptor($key);
    return $b->encrypt($str);
}

sub decrypt {
    my ( $class, $str, $key ) = @_;

    $key //= $class->decrypt_key;

    my $b = $class->_build_encryptor($key);
    return $b->decrypt($str);
}

sub _build_encryptor {
    my $class = shift;
    my ($key) = @_;

    return Crypt::Blowfish::Mod->new($key);
}

1;
