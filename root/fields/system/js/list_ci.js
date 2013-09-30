/*
name: CIs
params:
    js: '/fields/system/js/list_ci.js'
    html: '/fields/templates/html/ci_grid.html'
    relation: 'system'
    type: 'listbox'
    get_method: 'get_cis'    
    set_method: 'set_cis'
    field_order: 100
    field_order_html: 1000
    section: 'head'
    single_mode: false
    ci_role: 'Server'
    ci_class: ''
    rel_type: topic_ci
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
  console.dir(data);
    var ci = {};
    if( meta.ci_role ) ci['role'] = meta.ci_role;
    else if( meta.ci_class ) ci['class'] = meta.ci_class;
	
	return [
       Baseliner.ci_box(Ext.apply({
           fieldLabel: _(meta.name_field),
           name: meta.id_field,
           singleMode: meta.single_mode,
           force_set_value: true,
           value: data[meta.id_field],
           disabled: meta.readonly!=undefined ? meta.readonly : false
       }, ci) )
    ]
})

