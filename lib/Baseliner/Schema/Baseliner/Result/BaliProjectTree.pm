package Baseliner::Schema::Baseliner::Result::BaliProjectTree;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class("DBIx::Class::ResultSource::View");
__PACKAGE__->table("BaliProjectTree");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q{
	select spn.id as id, p.name AS project_name, sp.name as sp_name, spn.name as spn_name, spn.nature as nature, 'NAT' as tree_level
	from bali_project spn, bali_project sp, bali_project p
	where spn.nature is not null and  
		  spn.id_parent = sp.id and 
          sp.id_parent = p.id 
          
    UNION
     
    select sp.id as id, p.name AS project_name, sp.name as sp_name, NULL as spn_name, NULL as nature, 'SUB'  as tree_level
	from bali_project sp, bali_project p
	where sp.nature is null and
	      sp.id_parent is not null and  
          sp.id_parent = p.id 
    
    UNION
     
    select p.id as id, p.name AS project_name, NULL as sp_name, NULL as spn_name, NULL as nature, 'CAM' as tree_level
	from bali_project p
	where p.id_parent is null
});

__PACKAGE__->add_columns(
	'id','project_name', 'sp_name', 'spn_name', 'nature','tree_level'
);

1;
