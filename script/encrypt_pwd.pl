use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Baseliner;
use 5.010;
require Crypt::Blowfish::Mod;

my $username =  shift @ARGV // do {
  print "Username: ";
  <STDIN>;
};
chomp $username;
my $key = Baseliner->config->{decrypt_key} // Baseliner->config->{dec_key};
my $encrypt = Crypt::Blowfish::Mod->new($key);
my $pwd = do {
  print "New Password: ";
  <STDIN>;
};
chomp $pwd;
my $encrypted_password = $encrypt->encrypt($pwd);
say '*' x 80;
say "* Username: $username";
say "* Encrypted DB password: $encrypted_password";
say "* Encrypted login password: " .  Baseliner->model('Users')->encrypt_password( $username, $pwd );
say '*' x 80;
say "Have a nice day.";
