use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Baseliner;
use 5.010;
require Crypt::Blowfish::Mod;
my $key = Baseliner->config->{dec_key};
my $encrypt = Crypt::Blowfish::Mod->new($key);
my $pwd = do {
  print "Insert new password: ";
  <STDIN>;
};
chomp $pwd;
my $encrypted_password = $encrypt->encrypt($pwd);
say "Encrypted password: $encrypted_password";
say "Have a nice day.";
