package BaselinerX::CI::CASCMPackage;
use Baseliner::Moose;

with 'Baseliner::Role::CI::Revision';

sub collection { 'CASCMPackage' }
sub icon       { '/scm/package.gif' }

has packageobjid  => qw(is rw isa Num required 1);

=head2 items

Typical row data:

  compressed: Y
  currversion: '1892560'
  datasize: '78937'
  environmentname: SCM
  fileaccess: ve-ve-ve-
  itemname: pase.pm
  itemobjid: '400492'
  itemtype: '1'
  lastversion: '1891742'
  mappedversion: '1'
  modifiedtime: 2013-06-11 13:14
  modifytime: 2013-06-11 12:54:56
  nid: '63277'
  oldver: \SCM\FICHEROS\UNIX\udp|pase.pm|0|1|400492|SCM.N.000001|5115|N|789147|63471|Y|ve-ve-ve-|0|2011-08-31
    18:55:43|1889777|2013-06-10 15:55|1891742||harvest|Superusuario de Harvest|SCM|Pruebas|overwritten
  packagename: SCM.N.0000002 modificaciones1
  packageobjid: '5116'
  path: \SCM\FICHEROS\UNIX\udp
  pathid: '1889777'
  realname: Superusuario de Harvest
  statename: Desarrollo
  textfile: '0'
  username: harvest
  versiondataobjid: '789553'
  versionstatus: N

=cut

sub items {
    my ($self)=@_;
    my $hpkg = Baseliner->model('Harvest::Harpackage');
    my @versions = BaselinerX::CA::Harvest::Sync->new->versions( packageobjid=>$self->packageobjid );
    my @items = map {
        my $r = $_;
        my $vp = $r->{path};
        $vp =~ s{\\}{/}g;
        my $path = "$vp/$r->{itemname}";
        BaselinerX::CI::CASCMVersion->new(
            name             => $r->{itemname},
            basename         => $r->{itemname},
            size             => $r->{datasize},
            dir              => $vp,
            path             => $path,
            is_dir           => $r->{itemtype} != 1,
            itemobjid        => $r->{itemobjid},
            viewpath         => $vp,
            versionobjid     => $r->{currversion},
            versiondataobjid => $r->{versiondataobjid},
            versionid        => $r->{mappedversion},
            compressed       => $r->{compressed} eq 'Y',
            ns               => 'harversion/' . $r->{currversion}
        );
    } @versions;
}

1;
