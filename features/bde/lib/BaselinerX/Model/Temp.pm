package BaselinerX::Model::Temp;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Ktecho::Utils;
use BaselinerX::Ktecho::CamUtils;
use 5.010;
BEGIN { extends 'Catalyst::Model' }

sub table {'Baseliner::BaliProject'}

# Maybe third level should be called here instead?
sub load {
  # Init.
  my $self = shift;
  $self->load_first_level;
  $self->load_second_level;
  return;
}

sub load_first_level {
  # First level is the project (CAM), which consists in
  # three uppercase characters.
  my $self = shift;
  my @cams = @{$self->cams_harenvironment};
  for my $cam (@cams) { $self->insert_cam($cam) if $cam }
  return;
}

sub load_second_level {
  # Second level is the sub-application (parent being
  # CAM) with forced lowercase.
  my $self         = shift;
  my @current_cams = @{$self->current_cams};
  my @cams         = @{$self->cam_hash};
  for my $cam (@cams) {
    $self->insert_sub_apps($cam)
      if $cam->{name} ~~ @current_cams;
  }
  return;
}

sub load_third_level {
  # Third level is the sub-application with its real
  # name (not forcing lowercase) and its nature.
  my ($self, $sub_apl, $cam) = @_;
  $self->insert_third($sub_apl);
  $self->insert_third_single($sub_apl, $cam);
  return;
}

sub insert_third {
  # Insert third level sub-application into database.
  my ($self, $sub_apl) = @_;
  my @natures = @{$self->check_natures($sub_apl)};
  for my $nature (@natures) {
    my $args = {
      id        => $self->id,
      name      => $sub_apl->{name},
      id_parent => $sub_apl->{id},
      nature    => $nature
    };
    my $key = {key => 'name_nature'};
    Baseliner->model($self->table)->find_or_create($args, $key);
  }
  return;
}

sub insert_third_single {
  # Insert third level sub-application into database
  # with the name of its application.
  my ($self, $sub_apl, $cam) = @_;
  my $inf     = inf $cam;
  my @natures = @{$self->check_natures_simple($inf)};
  for my $nature (@natures) {
    my $args = {
      id        => $self->id,
      name      => $cam,
      id_parent => $sub_apl->{id},
      nature    => $nature
    };
    my $key = {key => 'name_nature'};
    Baseliner->model($self->table)->find_or_create($args, $key);
  }
  return;
}

sub check_natures_simple {
  # A list of all simple natures (the ones that we won't
  # know whether they apply to a very single
  # sub-application, but rather its whole application) that
  # a sub application has.
  my ($self, $inf) = @_;
  my @natures;
  for my $nature (@{$self->possible_natures_simple($inf)}) {
    push @natures, $nature->{value} if $nature->{handler};
  }
  \@natures;
}

sub check_natures {
  # A list of natures for a given sub application.
  my ($self, $sub_apl) = @_;
  my $id   = $sub_apl->{id_parent};
  my $name = $sub_apl->{name};
  my $cam  = $self->find_cam_by_id($id);
  my $inf  = inf $cam->{name};
  my @natures;
  for my $nature (@{$self->possible_natures($inf, $name)}) {
    push @natures, $nature->{value} if $nature->{handler};
  }
  \@natures;
}

sub check_nature_j2ee {
  # Check J2EE nature.
  my ($self, $inf, $sub_apl) = @_;
  if ($inf->sub_apps_java) {
    return 1 if $sub_apl ~~ $inf->sub_apps_java;
  }
  nil;
}

sub check_nature_net {
  # Check .NET nature.
  my ($self, $inf, $sub_apl) = @_;
  if ($inf->sub_apps_net) {
    return 1 if $sub_apl ~~ @{$inf->sub_apps_net};
  }
  nil;
}

sub check_nature_biztalk {
  # Check Biztalk nature.
  my ($self, $inf, $sub_apl) = @_;
  $inf->sub_apps_biztalk($sub_apl);
}

sub check_nature_rs {
  # Check Reporting Services nature.
  my ($self, $inf) = @_;
  $inf->has_rs;
}

sub check_nature_sis {
  # Check systems nature.
  my ($self, $inf) = @_;
  $inf->has_sistemas;
}

sub check_nature_oracle {
  # Check Oracle nature.
  my ($self, $inf) = @_;
  $inf->has_oracle;
}

sub check_nature_vignette {
  # Check Vignette nature.
  my ($self, $inf) = @_;
  $inf->has_vignette;
}

sub possible_natures {
  # A list of natures with a handler (boolean) determining
  # if they belong to the given sub_application and its
  # value.
  my ($self, $inf, $sub_apl) = @_;
  [ { handler => $self->check_nature_j2ee($inf, $sub_apl),
      value   => 'J2EE'
    },
    { handler => $self->check_nature_net($inf, $sub_apl),
      value   => '.NET'
    },
    { handler => $self->check_nature_biztalk($inf, $sub_apl),
      value   => 'BIZTALK'
    },
  ];
}

sub possible_natures_simple {
  # A list of simple natures with a handler (boolean)
  # determining if they belong to the current
  # application and its name.
  my ($self, $inf) = @_;
  [ { handler => $self->check_nature_oracle($inf),
      value   => 'ORACLE'
    },
    { handler => $self->check_nature_vignette($inf),
      value   => 'VIGNETTE'
    },
    { handler => $self->check_nature_rs($inf),
      value   => 'RS'
    },
    { handler => $self->check_nature_sis($inf),
      value   => 'SISTEMAS'
    }
  ];
}

sub find_cam_by_id {
  # The name of an application given its ID.
  my ($self, $id) = @_;
  my $where = {id => $id};
  my $rs = Baseliner->model($self->table)->search($where);
  rs_hashref($rs);
  my $cam = $rs->next;
  $cam;
}

sub cams_harenvironment {
  # Array of cams from Harvest::Harenvironment.
  my $self = shift;
  my $rs   = Baseliner->model('Harvest::Harenvironment')->search(
    {envisactive => 'Y'},
    { select => {distinct => ['substr(environmentname,0,3)']},
      as     => ['name']
    }
  );
  rs_hashref($rs);
  my @data;
  while (my $value = $rs->next) {
    push @data, $value->{name};
  }
  @data = sort(@data);
  shift @data;    # Removes first blank value
  \@data;
}

sub insert_cam {
  # Insert CAM into BaliProject.
  my ($self, $cam) = @_;
  Baseliner->model($self->table)->find_or_create(
    { name => uc($cam),
      id   => $self->id
    },
    {key => 'name'}
  );
  return;
}

sub insert_sub_apps {
  # Insert sub_apps for a given CAM.
  my ($self, $cam) = @_;
  for my $sub_apl (sub_apps $cam->{name}) {
    my $sub_apl_ref = {
      id        => $self->id,
      name      => lc($sub_apl),
      id_parent => $cam->{id}
    };
    Baseliner->model($self->table)
      ->find_or_create($sub_apl_ref, {key => 'name_parent'});
    $sub_apl_ref->{name} = $sub_apl;    # Restore name!
    $self->load_third_level($sub_apl_ref, $cam->{name});
  }
  return;
}

sub current_cams {
  # List of all cams with form.
  my @cams = table_data(
    'Inf::InfForm',
    undef,
    { select => { distinct => 'cam' },
      as     => ['cam']
    }
  );
  my @current_cams = map $_->{cam}, @cams;
  \@current_cams;
}

sub cam_hash {
  # Array of hash-refs with name and if of cam.
  my $self = shift;
  my @cams = table_data(
    $self->table,
    {id_parent => {'=' => undef}},
    { select => ['id', 'name'],
      as     => ['id', 'name']
    }
  );
  \@cams;
}

sub id { shift->new_id->() }

sub new_id {
  # An increment of current max id.
  my $MAX = shift->max_id;
  sub { $MAX++ }
}

sub max_id {
  # Max id for a given table.
  my $self = shift;
  my $rs   = Baseliner->model($self->table)->search(
    undef,
    { select => {max => ['id']},
      as     => ['id']
    }
  );
  rs_hashref($rs);
  my $row = $rs->next;
  my $max_id =
    exists $row->{id}
    ? $row->{id}
    : 0;
  $max_id + 1;
}

1;
