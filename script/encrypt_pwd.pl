use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use v5.10;
BEGIN { say "Encrypt Password starting..." }
use Baseliner;
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
