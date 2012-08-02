update bali_master m set m.name = (select p.name from bali_project p where p.mid = m.mid ) 
where exists ( select 1 from bali_project e where e.mid=m.mid ) and m.name=NULL;

update bali_master m set m.name = (select p.filename from bali_file_version p where p.mid = m.mid ) 
where exists ( select 1 from bali_file_version e where e.mid=m.mid ) and m.name=NULL;

update bali_master m set m.name = (select p.username from bali_user p where p.mid = m.mid ) 
where exists ( select 1 from bali_user e where e.mid=m.mid ) and m.name=NULL;

