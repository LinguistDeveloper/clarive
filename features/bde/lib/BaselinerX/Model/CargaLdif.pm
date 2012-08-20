package BaselinerX::Model::CargaLdif;
use strict;
use warnings;
use 5.010;
use Baseliner::Utils;
use Baseliner::Plug;
use Try::Tiny;
use utf8;
BEGIN { extends 'Catalyst::Model' }

sub db { BaselinerX::CA::Harvest::DB->new }

sub all_users {
  my $self  = shift;
  my $query = qq{
    SELECT TRIM (username) usr, TRIM (usergroupname) grp
      FROM haruser u, harusergroup g, harusersingroup ug
     WHERE u.usrobjid = ug.usrobjid AND ug.usrgrpobjid = g.usrgrpobjid
     ORDER BY 1, 2
  };
  my $db         = $self->db();
  my @usergroups = $db->db->array_hash($query);
  my %user_group;
  push @{$user_group{$_->{usr}}}, $_->{grp} foreach @usergroups;
  %user_group;
}

sub groups_inf_rpt {
  my $self  = shift;
  my $model = Baseliner->model('Inf::InfRpt');
  my $rs = $model->search({'substr (usergroupname, 1, 1)' => {'<>' => '\$'},
                           wingroupname                   => {'!=' => undef}},
                          {select => [qw/usergroupname wingroupname/]});
  rs_hashref($rs);
  map { $_->{usergroupname} => $_->{wingroupname} } $rs->all;
}

sub group_count {
  my ($self, $grpname) = @_;
  my $query = qq{
    SELECT COUNT (*)
      FROM harusergroup
     WHERE trim(usergroupname) = '$grpname'
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub group_id {
  my $self  = shift;
  my $query = qq{
    SELECT harusergroupseq.NEXTVAL
      FROM DUAL
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub new_group {
  my ($self, %p) = @_;
  my $group_id     = $p{group_id};
  my $group_name   = $p{group_name};
  my $h_group_name = $p{h_group_name};
  my $query        = "
    INSERT INTO harusergroup
                (usrgrpobjid, usergroupname, creationtime, creatorid,
                 modifiedtime, modifierid, note
                 )
         VALUES ( $group_id , '$group_name' , SYSDATE, 1,
                 SYSDATE, 1, '$h_group_name' 
                 )
  ";
  my $db = $self->db();
  try { $db->db->do($query) } catch {return};
  return;
}

sub user_count {
  my ($self, $user) = @_;
  my $query = qq{
    SELECT COUNT (*)
      FROM haruser
     WHERE UPPER (TRIM (username)) = UPPER('$user')
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub user_id {
  my ($self, $user) = @_;
  my $query = qq{
    SELECT usrobjid
      FROM haruser
     WHERE UPPER (TRIM (username)) = UPPER ( '$user' )
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub update_user {
  my ($self, $user) = @_;
  my $query = qq{
    UPDATE haruser
       SET email = '$user\@correo.interno'
     WHERE UPPER (TRIM (username)) = UPPER ('$user')
  };
  my $db = $self->db();
  $db->db->do($query);
}

sub count_admins {
  my ($self, $user_id) = @_;
  my $query = qq{
    SELECT COUNT (*)
      FROM harusersingroup
     WHERE usrobjid = $user_id AND usrgrpobjid = 1
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub del_harusersingroup {
  my ($self, $user_id, $user_group) = @_;
  my $query = qq{
    DELETE FROM harusersingroup
     WHERE usrobjid = $user_id
       AND usrgrpobjid NOT IN (SELECT usrgrpobjid
      FROM harusergroup
     WHERE usergroupname IN ( $user_group ))
  };
  my $db = $self->db();
  $db->db->do($query);
}

sub count_harusersingroup {
  my ($self, $user_id, $group_name) = @_;
  $group_name =~ s/'//g;
  my $query = qq{
    SELECT COUNT (*)
      FROM harusersingroup uig, harusergroup ug
     WHERE uig.usrobjid = $user_id
       AND uig.usrgrpobjid = ug.usrgrpobjid
       AND ug.usergroupname = '$group_name'
  };
  my $db = $self->db();
  $db->db->value($query);
}

sub insert_harusersingroup {
  my ($self, $user_id, $group_name) = @_;
  my $query = qq{
    INSERT INTO harusersingroup
                (usrobjid, usrgrpobjid)
        SELECT $user_id , usrgrpobjid
          FROM harusergroup
         WHERE usergroupname = $group_name
  };
  _log $query;
  my $db = $self->db();
  $db->db->do($query);
}

sub harusers {
  my $self  = shift;
  my $query = qq{
    SELECT DISTINCT usrobjid, TRIM (username), TRIM (realname)
      FROM haruser u
     WHERE u.usrobjid > 1
       AND NOT EXISTS (
                       SELECT *
                         FROM harusersingroup ug, harusergroup g
                        WHERE u.usrobjid = ug.usrobjid
                          AND ug.usrgrpobjid = g.usrgrpobjid
                          AND TRIM (UPPER (g.usergroupname)) IN
                                     ('ADMINISTRATOR', 'ADMINISTRADOR',
                                      'DEPARTAMENTOS_USUARIOS'))
  };
  my $db = $self->db();
  $db->db->hash($query);
}

sub delete_haruser {
  my ($self, $harvest_user) = @_;
  my $query = qq{
    DELETE FROM haruser
     WHERE UPPER (username) = '$harvest_user' 
  };
  my $db = $self->db();
  $db->db->do($query);
}

sub add_users_to_group2 {
  my $self  = shift;
  my $query = qq{
    INSERT INTO harusersingroup
                (usrobjid, usrgrpobjid)
        SELECT hu.usrobjid, 2
          FROM haruser hu
         WHERE NOT EXISTS (
             SELECT 'x'
               FROM harusersingroup huig
              WHERE huig.usrobjid = hu.usrobjid
                AND huig.usrgrpobjid = 2)
  };
  my $db = $self->db();
  $db->db->do($query);
}

sub sync_inf_data {
  my $self = shift;
  my $db   = $self->db();
  $db->db->do("BEGIN inf_data_update; END;");
}

1
