my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
my $username = 'infroox';
my @a = $db->array_hash( "select * from haruser where trim(username)=? ", $username );
\@a
__END__
--- 
- 
  creationtime: 2006-05-09 10:56:31
  creatorid: 1
  email: infroox@correo.interno
  encryptpsswd: ~
  extension: ~
  faxnumber: ~
  lastlogin: 2010-09-15 15:35:19
  loggedin: 'N'
  logindate: 2010-09-16 10:57:09
  modifiedtime: 2007-06-06 13:10:14
  modifierid: 5
  note: ~
  passwdattrs: 0
  phonenumber: ~
  realname: "INFROOX - RODRIGO DE OLIVEIRA GONZALEZ                                                                                          "
  username: "infroox                         "
  usrobjid: 5

