 my $hardb = BaselinerX::CA::Harvest::DB->new;
$hardb->element_from_versionobjid( 1746496 );
$hardb->renamed_version_from_itempath( 
   packages=>[4944,4949], 
   viewpath=> '\GBP.0328\SSRS\PruebaHarvestSLN\PruebaHarvest3.0' ,
   mappedversion=>'3',
   itemname => 'Report7.rdl'
);

__END__
Attribute (tag) does not pass the type constraint because: Validation failed for 'Str' failed with value undef
Stack:
   Moose::Meta::Attribute::_coerce_and_verify (../../perl510/lib/site_perl/5.10.1/i686-linux/Moose/Meta/Attribute.pm:746)
   BaselinerX::CA::Harvest::DB::element_from_versionobjid (DB.pm:140)
   BaselinerX::CA::Harvest::DB::renamed_version_from_itempath (DB.pm:185)
   Baseliner::Controller::REPL::__ANON__ (REPL.pm:45)
   Baseliner::Controller::REPL::eval (REPL.pm:50)
   Baseliner::dispatch (Wrapped.pm:89)


2010-07-13 21:54:59[10558] [BX::CA::Harvest::DB:182] 
		SELECT v.mappedversion, n.ITEMNAME, pathfullname, v.PATHVERSIONID, v.packageobjid, i.itemobjid,  
		(SELECT parentversionid FROM HARVERSIONS v4 WHERE v4.versionobjid =
			(SELECT MIN(versionobjid) FROM HARVERSIONS v3
				WHERE v3.itemobjid = i.itemobjid AND packageobjid IN ( 4944,4949 ) ) ) lastversion
		FROM HARVERSIONS v, HARITEMS i, HARITEMNAME n, HARPATHFULLNAME p, HARVERSIONS v2, HARITEMS i2, HARITEMNAME n2
		WHERE 1=1
		AND n.ITEMNAME = 'Report7.rdl'
		AND n.NAMEOBJID = v.ITEMNAMEID
		AND v.itemobjid = i.itemobjid
		AND v.mappedversion = '3'
		AND v.PATHVERSIONID = v2.versionobjid
		AND v2.itemobjid = i2.itemobjid
		AND i2.parentobjid = p.itemobjid
		AND v2.itemnameid = n2.nameobjid
		AND p.PATHFULLNAME||'\'||n2.itemname = '\GBP.0328\SSRS\PruebaHarvestSLN\PruebaHarvest3.0'
	

