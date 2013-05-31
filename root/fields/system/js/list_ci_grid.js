/*
name: CI Grid
params:
    html: '/fields/system/html/field_ci_grid.html'
    js: '/fields/system/js/list_ci_grid.js'
    relation: 'system'
    rel_type: topic_ci
    type: 'listbox'
    get_method: 'get_cis'    
    set_method: 'set_cis'
    field_order: 100
    section: 'details'
    single_mode: 'false'    
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
    
    var ci_meta = {};
    if( meta.ci_role ) ci_meta['role'] = meta.ci_role;
    
    var value = data[ meta.id_field ];
    var cis = new Baseliner.CIGrid({ title:_( meta.name_field ), ci: ci_meta,
        title: null,
        labelAlign: 'top', 
        fieldLabel: meta.name_field,
        value: value , name: meta.id_field });
	return [
        cis
    ]
})

