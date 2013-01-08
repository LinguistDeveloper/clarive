package Baseliner::Schema::Inf::Result::InfPeticionForm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("inf_peticion_form");
__PACKAGE__->add_columns(

  "idform", { data_type => "NUMBER", default_value => undef, is_nullable => 0, },
  "env", { data_type => "VARCHAR2", default_value => undef, is_nullable => 0, size => 1, },
  "ts", { data_type     => "datetime", default_value => \"SYSDATE", is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "html", { data_type => "blob", is_nullable => 1 },
  "html_size", { data_type => "number", is_nullable => 0 },
);

__PACKAGE__->set_primary_key( qw(idform env) );

1;

