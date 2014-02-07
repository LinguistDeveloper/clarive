=head1 NAME

Transcoding tools - encription, cypher, hashes

=head1 USAGE

    cla trans-password -u username -p password
    cla trans-md5 -s 'string to encode'

=cut
package Clarive::Cmd::trans;
use Mouse;
extends 'Clarive::Cmd';
use v5.10;
use strict;

our $CAPTION = 'conversion tool, password encryption';

sub run_password {
    my ($self,%opts)=@_;
    my $username = $opts{u} // die "Missing -u <user>\n";
    my $password = $opts{p};
    if( !defined $password ) {
        print "PASSWORD: ";
        require Term::ReadKey;
        Term::ReadKey::ReadMode( 3 );
        my @password;
        while(my $ks = Term::ReadKey::ReadKey()){
            my $val = ord $ks;
            push @password, $ks unless $val == 8 || $val == 13 || $val == 10;
            last if $val == 13 || $val == 10;
            print "*" unless $val == 8;
        } 
        Term::ReadKey::ReadMode( 'original' );
        say '';
        $password = join '', @password;
    }
    my $key = $self->app->config->{decrypt_key} // $self->app->config->{dec_key} 
        // do { my $ba = $self->app->config->{baseliner}; $ba->{decrypt_key} // $ba->{dec_key} };
    die "ERROR: decrypt_key not defined. Environment set?\n" unless length $key; 
    my $user_key = $key . reverse( $username );
    require Crypt::Blowfish::Mod;
    my $b = Crypt::Blowfish::Mod->new( $user_key );
    require Digest::MD5;
    say Digest::MD5::md5_hex( $b->encrypt($password) );    
}

sub run_md5 {
    my ($self,%opts)=@_;
    my $s = $opts{s};
    if( !defined $s ) {
        $s = <STDIN>;
    }
    require Digest::MD5;
    say Digest::MD5::md5_hex( $s );
}

sub run_encrypt {
    my ($self,%opts)=@_;
    my $s = $opts{s};
    if( !defined $s ) {
        $s = <STDIN>;
    }
    my $key = $opts{key} // $self->app->config->{decrypt_key} // $self->app->config->{dec_key} 
        // do { my $ba = $self->app->config->{baseliner}; $ba->{decrypt_key} // $ba->{dec_key} };
    die "ERROR: decrypt_key not defined. Environment set?\n" unless length $key; 
    require Crypt::Blowfish::Mod;
    my $b = Crypt::Blowfish::Mod->new( $key );
    say $b->encrypt( $s );
}

1;
