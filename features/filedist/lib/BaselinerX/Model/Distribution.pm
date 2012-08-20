package BaselinerX::Model::Distribution;
use strict;
use warnings;
use 5.010;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Memoize;
use Moose;

has 'id'   => (is => 'ro', isa => 'Int', required => 1);
has 'name' => (is => 'rw', isa => 'Str', required => 1);
has 'path' => (is => 'rw', isa => 'Str', required => 1);

sub get_maps {
  my ($self) = @_;
  my %ret;
  for my $ns ( repo->list( provider=>'filedist' ) ) {
    my $map = repo->get( ns=>$ns );
    push @{ $ret{ $map->{from} } }, {
        path =>$map->{to},
        host =>$map->{host},
        mask =>$map->{mask},
        os   =>$map->{os},
        user =>$map->{user},
        group=>$map->{group}
    };
  }
  return %ret;
}

sub yaml_to_hashref {
  my ($self, $data) = @_;
  _load($data) }

sub item_list_iterator {
  my ($self, $item_list) = @_;
  my @items = @{$item_list};
  sub { my $element = shift @items;
        $self->yaml_to_hashref($element->{data}) 
        || {} } }  # Empty hash or crash!

sub iterate_items_by {
  # Sugar for item_list_iterator(), useful when you just
  # want to return one single item attribute.  Note that
  # this is not useful for building arrays, as a map
  # function will be faster and less verbose.
  my ($self, $item_list, $attr) = @_;
  my $iterator = $self->item_list_iterator($item_list);
  sub { my $hashref = $iterator->();
        exists $hashref->{$attr}
          ? $hashref->{$attr} 
          : 0 } }

sub map_item_list_by {
  # Builds a list given an list of items and the attribute you want it
  # to be based on.
  my ($self, $item_list, $attr) = @_;
  my @packages = map { $self->yaml_to_hashref($_->{data})->{$attr} } 
                       @{$item_list};
  \@packages }

sub build_item_list {
  my ($self, $suffix, $package_ref) = @_;
  my @package_ids = @{$package_ref};
  my $package_id_list = '(' . join(',', @package_ids) . ')';
  my $mega_query      = <<END_MEGA_QUERY
SELECT   v.versionobjid versionid, TRIM (i.itemname) itemname,
         UPPER (NVL (SUBSTR (i.itemname, 1, INSTR (i.itemname, '.') - 1),
                     i.itemname
                    )
               ) itemname_short,
         TRIM (p.packagename) PACKAGE,
         SUBSTR (l.pathfullname,
                 INSTR (l.pathfullname, '\\', 1, 3) + 1
                ) AS LIBRARY,
         UPPER (TRIM (SUBSTR (i.itemname, INSTR (i.itemname, '.') + 1))
               ) extension,
         (CASE
             WHEN (v.versionstatus = 'D')
                THEN 'D'
             WHEN (EXISTS (
                      SELECT *
                        FROM harversions vs
                       WHERE vs.itemobjid = n.itemobjid
                         AND vs.packageobjid IN $package_id_list
                         AND vs.versionstatus <> 'R')
                  )
                THEN 'D'
             ELSE 'N'
          END
         ) tag,
         TRIM (v.mappedversion) VERSION,
         REPLACE (l.pathfullname, '\\', '/') PATH, i.itemobjid iid,
         n.itemobjid nid, TRIM (e.environmentname) project,
         TRIM (s.statename) statename,
         TRIM (hu.username) || ' (' || TRIM (hu.realname) || ')' username,
         TO_CHAR
            (  v.modifiedtime
             + (  TO_NUMBER (SUBSTR (REPLACE (REPLACE (SESSIONTIMEZONE,
                                                       '+',
                                                       ''
                                                      ),
                                              ':00',
                                              ''
                                             ),
                                     2,
                                     1
                                    )
                            )
                / 24
               ),
             'YYYY-MM-DD HH24:MI'
            ) modifiedtime
    FROM harpackage p,
         harstate s,
         harallusers hu,
         harversions v,
         harenvironment e,
         haritems i,
         harpathfullname l,
         haritemrelationship n
   WHERE p.packageobjid = v.packageobjid
     AND p.stateobjid = s.stateobjid
     AND v.modifierid = hu.usrobjid
     AND v.versionstatus <> 'R'
     AND p.envobjid = e.envobjid
     AND i.itemobjid = v.itemobjid
     AND n.refitemid(+) = i.itemobjid
     AND i.parentobjid = l.itemobjid
     AND SUBSTR (l.pathfullname,
                 INSTR (l.pathfullname || '\\', '\\', 1, 2) + 1,
                   INSTR (l.pathfullname || '\\', '\\', 1, 3)
                 - INSTR (l.pathfullname || '\\', '\\', 1, 2)
                 - 1
                ) = '$suffix'
     AND UPPER (i.itemname) NOT LIKE '%.VS_SCC'
     AND i.itemtype = 1
     AND p.packageobjid IN $package_id_list
     AND v.versionobjid =
            (SELECT MAX (vs.versionobjid)
               FROM harversions vs
              WHERE vs.itemobjid = v.itemobjid
                AND vs.packageobjid IN $package_id_list
                AND vs.versionstatus <> 'R')
UNION
SELECT   v2.versionobjid versionid, TRIM (ni.itemname) itemname,
         UPPER (NVL (SUBSTR (i.itemname, 1, INSTR (i.itemname, '.') - 1),
                     i.itemname
                    )
               ) itemname_short,
         TRIM (p.packagename) PACKAGE,
         SUBSTR (l.pathfullname,
                 INSTR (l.pathfullname, '\\', 1, 3) + 1
                ) AS LIBRARY,
         UPPER (TRIM (SUBSTR (i.itemname, INSTR (i.itemname, '.') + 1))
               ) extension,
         (CASE
             WHEN (v.versionstatus = 'D')
                THEN 'D'
             WHEN (EXISTS (
                      SELECT *
                        FROM harversions vs
                       WHERE vs.itemobjid = n.itemobjid
                         AND vs.packageobjid IN $package_id_list
                         AND vs.versionstatus <> 'R')
                  )
                THEN 'D'
             ELSE 'N'
          END
         ) tag,
         TRIM (v.mappedversion) VERSION,
         REPLACE (l.pathfullname, '\\', '/') PATH, i.itemobjid iid,
         n.itemobjid nid, TRIM (e.environmentname) project,
         TRIM (s.statename) statename,
         TRIM (hu.username) || ' (' || TRIM (hu.realname) || ')' username,
         TO_CHAR
            (  v.modifiedtime
             + (  TO_NUMBER (SUBSTR (REPLACE (REPLACE (SESSIONTIMEZONE,
                                                       '+',
                                                       ''
                                                      ),
                                              ':00',
                                              ''
                                             ),
                                     2,
                                     1
                                    )
                            )
                / 24
               ),
             'YYYY-MM-DD HH24:MI'
            ) modifiedtime
    FROM harpackage p,
         harstate s,
         harallusers hu,
         harversions v,
         harversions v2,
         harenvironment e,
         haritems i,
         haritems ni,
         harpathfullname l,
         haritemrelationship n
   WHERE p.packageobjid = v.packageobjid
     AND p.stateobjid = s.stateobjid
     AND v.modifierid = hu.usrobjid
     AND v.versionstatus <> 'R'
     AND p.envobjid = e.envobjid
     AND i.itemobjid = v.itemobjid
     AND ni.itemobjid = n.refitemid
     AND n.itemobjid = i.itemobjid
     AND v2.itemobjid = ni.itemobjid
     AND v2.versionobjid =
                     (SELECT MAX (versionobjid)
                        FROM harversions
                       WHERE itemobjid = n.refitemid AND versionstatus <> 'R')
     AND NOT EXISTS (
            SELECT *
              FROM harversions vs
             WHERE vs.versionobjid = v2.versionobjid
               AND vs.packageobjid IN $package_id_list
               AND vs.versionstatus <> 'R')
     AND i.parentobjid = l.itemobjid
     AND SUBSTR (l.pathfullname,
                 INSTR (l.pathfullname || '\\', '\\', 1, 2) + 1,
                   INSTR (l.pathfullname || '\\', '\\', 1, 3)
                 - INSTR (l.pathfullname || '\\', '\\', 1, 2)
                 - 1
                ) = '$suffix'
     AND i.itemtype = 1
     AND p.packageobjid IN $package_id_list
     AND v.versionobjid =
            (SELECT MAX (vs.versionobjid)
               FROM harversions vs
              WHERE vs.itemobjid = v.itemobjid
                AND vs.packageobjid IN $package_id_list
                AND vs.versionstatus <> 'R')
ORDER BY 11
END_MEGA_QUERY
  ;
  my $har_db = BaselinerX::Ktecho::Harvest::DB->new;
  my @data   = $har_db->db->array_hash($mega_query);
  \@data }

sub iterate_element_by {
  my ($self, $data, $attr) = @_;
  my @elements = @{$data};
  sub { my $element = shift @elements;
        exists $element->{$attr} ? $element->{$attr} : 0 } }

sub nature_in_elements {
  # Checks if a given nature is contained in any element of the list.
  my ($self, $nature, $element_list) = @_;
  my $path_iterator = $self->iterate_element_by($element_list, 'path');
  while (1) { my $path = $path_iterator->() || last;
              return 1 if $self->path_to_nature($path) eq $nature }
  0 }

# As of now, the structure is '/{CAM}/{NATURE}/{OS}/{...}', so we'd pick
# the second element of the path.  Please note that the application is
# restricted to 3 characters since we're supossedly working with the CAM
sub path_to_nature {       #                    _._ _..._ .-',     _.._(`))
  # Returns the nature     #     OINK !!       '-. `     '  /-._.-'    ',/
  # contained in the path  #        OINK !!       )         \            '.
  my ($self, $path) = @_;  #                     / _    _    |             \
  $path =~ m:              #                    |  a    a    /              |
             .{3}          # CAM (!)            \   .-.                     ;  
             \/            # Separator           '-('' ).-'       ,'       ; 
             (.+?)         # Nature (captured)      '-;           |      .'
             \/            # Separator                 \           \    /
            :x;            #                           | 7  .__  _.-\   \
  $1 }                     # Return captured value     | |  |  ``/  /`  /
                           #                          /,_|  |   /,_/   /
                           #                            /,_/      '`-' 

sub map_elements_type_os {
  # Maps elements according to their operating system and tag
  # (whether it's a new file or a deleted one) for a given list of
  # elements.
  my ($self, $params) = @_;
  my $list = $params->{list};
  my $tag  = $params->{tag};   # (D)elete or (N)ew
  my $os   = $params->{os};    # WIN or UNIX
  my @data = grep(   $self->os_from_path($_->{path}) =~ /$os/ 
                  && $_->{tag} eq $tag, 
                    @{$list});
  \@data }

sub os_from_path {
  my ($self, $path) = @_;
  $path =~ m/
              \/
              .+?    # CAM
              \/
              .+?    # Nature
              \/
              (.+?)  # Capture Operating System
              \/
             /x;
  $1 }

sub which_os {
  my ($self, $hashref) = @_;
  exists $hashref->{user} 
    ? 'UNIX'
    : 'WIN' }

sub map_elements {
  my ($self, $params) = @_;
  my $env          = $params->{env};
  my $package_list = $params->{package};
  my $mode         = $params->{mode};
  my $s            = BaselinerX::CA::Harvest::Sync->new;
  my @data         = $s->elements(env     => $env,
                                  package => $package_list,
                                  mode    => $mode);
  \@data }

sub new_win_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->map_elements_type_os({list => $self->promoted_elements($job),
                               os   => 'WIN',
                               tag  => 'N'}) }

sub del_win_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->map_elements_type_os({list => $self->promoted_elements($job),
                               os   => 'WIN',
                               tag  => 'D'}) }

sub new_unix_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->map_elements_type_os({list => $self->promoted_elements($job),
                               os   => 'UNIX',
                               tag  => 'N'}) }

sub del_unix_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->map_elements_type_os({list => $self->promoted_elements($job),
                               os   => 'UNIX',
                               tag  => 'D'}) }

sub create_tar {
  # Creates a tar file if there are elements ready to be distributed.
  my ($self, $path, $element_list) = @_;
  if (@{$element_list}) {
    $self->create_file($path, $element_list, 'new');
    $self->tar_it($path) unless $self->exists_tar($path) } }

sub create_file {
  # This is the file used to compose the tar. It contains
  # all elements ready to be distributed.
  # It also contains the list of elements to be deleted...
  my ($self, $path, $element_list, $type) = @_;
  open my $fh, '>', "$path/${type}_element_list";
  for my $element (@{$element_list}) {
    print $fh "$element\n" }
  return }

sub tar_it {
  # This is the one that actually creates the tar.
  my ($self, $path, $type) = @_;
  `cd $path ; tar -cv -f ${type}_files.tar --files-from='new_element_list' 2>&1` }

sub exists_tar {
  # Is there any tar in the given path? 1 : 0
  my ($self, $path) = @_;
  `ls $path` =~ /\.tar/xi ? 1 : 0 }

sub list_job_items {
  # A YAML of all items for a given job.
  my $self   = shift;
  my $job_id = shift || $self->id;
  my $where  = {id_job => $job_id};
  my $args   = {select => ['id', 'data']};
  my $rs = Baseliner->model('Baseliner::BaliJobItems')->search($where, $args);
  rs_hashref($rs);
  my @items = $rs->all;
  \@items }

sub job_item_something {
  my ($self, $job, $attr) = @_;
  my $item_list = $self->list_job_items($job);
  Baseliner->model('Distribution')->map_item_list_by($item_list, $attr) }

memoize('job_package_list');

sub job_package_list {
  # All packagenames for a given job.
  my $self = shift;
  my $job  = shift || $self->id;
  $self->job_item_something($job, 'packagename') }

sub harvest_sync_elements {
  my ($self, $params) = @_;
  my $s = BaselinerX::CA::Harvest::Sync->new;
  $s->elements(env     => $params->{env},
               package => $params->{package_list},
               mode    => $params->{mode}) }

memoize('demoted_elements');

sub demoted_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  my @data = $self->harvest_sync_elements({env          => $self->job_env($job),
                                           package_list => $self->job_package_list($job),
                                           mode         => 'demote'});
  \@data }

memoize('promoted_elements');

sub promoted_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  my @data = $self->harvest_sync_elements({env          => $self->job_env($job),
                                           package_list => $self->job_package_list($job),
                                           mode         => 'promote'});
  \@data }

memoize('job_env');

sub job_env {
  # Environmentname.
  my $self = shift;
  my $job  = shift || $self->id;
  my $package = shift @{$self->job_package_list($job)};
  substr($package, 0, 3) }

sub has_nature {
  # Checks if a job has a given nature.
  my ($self, $job, $nature) = @_;
  my $elements = $self->promoted_elements($job);
  for my $element (@{$elements}) {
    return 1 if $self->path_to_nature($element->{path}) =~ m/^$nature/i }
  0 }

sub win_tar_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->tar_friendly_elements($job, 'win') }

sub unix_tar_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  $self->tar_friendly_elements($job, 'unix') }

sub tar_friendly_elements {
  my ($self, $job, $os) = @_;
  my @elements = $os =~ m/win/i  ? @{$self->new_win_elements($job)}
               : $os =~ m/unix/i ? @{$self->new_unix_elements($job)}
               : die 'wrong OS!';
  my %kv = %{$self->get_maps()};
  my %map;
  for my $key (keys %kv) {
    for my $hash_ref (@{$kv{$key}}) {
      @{$hash_ref->{elements}} = map { $_->{fullpath} =~ m/$key\/(.+)/ } 
                                   grep($_->{path} =~ m/^$key/i, @elements);
      push @{$map{$key}}, $hash_ref if @{$hash_ref->{elements}}; } }
  \%map }

memoize('unix_del_elements');

sub unix_del_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  return }

memoize('win_del_elements');

sub win_del_elements {
  my $self = shift;
  my $job  = shift || $self->id;
  return }

# Oops! There is only one env for each job!

# sub multiple_promoted_elements {
#   my ($self, $job, $type) = @_;
#   my @envs     = @{$self->job_envs($job)};
#   my @packages = @{$self->job_package_list($job)};
#   my @data;
#   for my $env (@envs) {
#     my @env_packages = @{$self->filter_env_packages($env, \@packages)};
#     $type eq 'promote'
#       ? push @data, $self->promoted_elements($env, \@env_packages)
#       : $type eq 'demote'
#           ? push @data, $self->demoted_elements($env, \@env_packages)
#           : die 'unknow option'; }
#   \@data }

# memoize('job_promoted_elements');

# sub job_promoted_elements {
#   my ($self, $job) = @_;
#   $self->multiple_promoted_elements($job, 'promote') }

# memoize('job_demoted_elements');

# sub job_demoted_elements {
#   my ($self, $job) = @_;
#   $self->multiple_promoted_elements($job, 'demote') }

# sub filter_env_packages {
#   # Given a package list, give me only the elements that correspond
#   # to the given environment.
#   my ($self, $env, $package_list) = @_;
#   my @data;
#   for my $package (@{$package_list}) {
#     push @data, $package if substr($package, 0, 3) eq $env }
#   \@data }

# memoize('job_envs');

# sub job_envs {
#   # A list of job environment names.
#   my ($self, $job) = @_;
#   my $package_name_list = $self->job_package_list($job);
#   my @cams = map { /(\D{3})/ } @{$package_name_list};
#   $self->kill_duplicates(\@cams) }

1
