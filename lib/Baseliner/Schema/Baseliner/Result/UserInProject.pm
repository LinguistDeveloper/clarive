package Baseliner::Schema::Baseliner::Result::UserInProject;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('bali_user_project');
 
__PACKAGE__->add_columns(
  id_project => { data_type => "integer", is_nullable => 0 },
  id_user    => { data_type => "integer", is_nullable => 0 },
);

__PACKAGE__->belongs_to( user    => 'Baseliner::Schema::Baseliner::Result::BaliUser', 'id_user' );
__PACKAGE__->belongs_to( project => 'Baseliner::Schema::Baseliner::Result::BaliProject', 'id_project' );

1;
