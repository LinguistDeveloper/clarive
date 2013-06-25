/*
name: CI Grid
params:
    origin: 'template'
    relation: 'system'
    js: '/fields/templates/js/ci_grid.js'
    html: '/fields/templates/html/ci_grid.html'
    get_method: 'get_cis'    
    set_method: 'set_cis'
    section: 'head'
    field_order: 100
    field_order_html: 100
    rel_type: topic_ci
    ci_role: 'ci'
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;

    var ci_meta = {};
    if( meta.ci_role ) ci_meta['role'] = meta.ci_role;
    if( meta.ci_class ) ci_meta['class'] = meta.ci_class;
    
    var value = data[ meta.id_field ];
    var cis = new Baseliner.CIGrid({ 
        ci: ci_meta,
        title: null,
        //labelAlign: 'top', 
        readOnly: ( meta.readOnly == 'true' ? true : false ),
        style: 'margin-top: 20px', 
        height: meta.height || 200,
        fieldLabel: meta.name_field,
        value: value , 
        name: meta.id_field 
    });
	return [
        cis
    ]
})


