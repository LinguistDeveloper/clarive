package Baseliner::Schema::Baseliner::Result::BaliProjectBak;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("bali_project_bak");

__PACKAGE__->add_columns("id",
                         {data_type     => "NUMBER",
                          default_value => undef,
                          is_nullable   => 0,
                          size          => 38},
                         "id_project",
                         {data_type      => "NUMBER",
                          default_value  => undef,
                          is_foreign_key => 1,
                          is_nullable    => 1,
                          size           => 38},
                         "id_job",
                         {data_type      => "NUMBER",
                          default_value  => undef,
                          is_foreign_key => 1,
                          is_nullable    => 1,
                          size           => 38},
                         "bl",
                         {data_type      => "VARCHAR2",
                          default_value  => '*',
                          is_foreign_key => 0,
                          is_nullable    => 1,
                          size           => 20},
                         "bak_type",
                         {data_type      => "VARCHAR2",
                          default_value  => undef,
                          is_foreign_key => 0,
                          is_nullable    => 1,
                          size           => 20},
                         "filename",
                         {data_type      => "VARCHAR2",
                          default_value  => undef,
                          is_foreign_key => 0,
                          is_nullable    => 1,
                          size           => 300},
                         "root_path",
                         {data_type      => "VARCHAR2",
                          default_value  => undef,
                          is_foreign_key => 0,
                          is_nullable    => 1,
                          IIsize         => 300},
                         "bak_data",
                         {data_type     => "CLOB",
                          default_value => undef,
                          is_nullable   => 1,
                          size          => 2147483647});

__PACKAGE__->set_primary_key("id");

1;
