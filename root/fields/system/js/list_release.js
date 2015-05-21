/*
name: Release
params:
    html: '/fields/system/html/field_release.html'
    js: '/fields/system/js/list_release.js'
    relation: 'system'
    type: 'listbox'    
    get_method: 'get_release'    
    set_method: 'set_release'
    field_order: 7
    section: 'body'
    filter: 'none'
    release_field: '' 
    allowBlank: true
    single_mode: true
    rel_type: 'topic_topic'
    meta_type: 'release'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;

	var topic_mid = data.topic_mid || undefined;
	var ps = meta.page_size || 10;  // for combos, 10 is a much nicer on a combo
    var display_field = meta.display_field || undefined;
    var tpl_cfg = meta.tpl_cfg || undefined;

    var release_box_store = new Baseliner.store.Topics({ baseParams: {  limit: ps, mid: topic_mid, show_release: 1, filter: meta.filter ? meta.filter : ''}, display_field: display_field, tpl_cfg: tpl_cfg });

	var release_box = new Baseliner.TopicBox({
		fieldLabel: _(meta.name_field),
		pageSize: ps,
		name: meta.id_field,
		hiddenName: meta.id_field,          
		emptyText: _( meta.emptyText ),
		allowBlank: Baseliner.eval_boolean(meta.allowBlank),          
		store: release_box_store,
		disabled: Baseliner.eval_boolean(meta.readonly),
		singleMode: Baseliner.eval_boolean(meta.single_mode),
		hidden: Baseliner.eval_boolean(meta.hidden),
        display_field: display_field,
        tpl_cfg: tpl_cfg,
        hidden_value : data ? (eval('data.' + meta.id_field + ' && data.' + meta.id_field + ' != undefined && data.' + meta.id_field + '.mid' ) ? eval('data.' + meta.id_field + '.mid') : '') : ''
	});	
 	release_box.value = data ? (eval('data.' + meta.id_field + ' && data.' + meta.id_field + ' != undefined && data.' + meta.id_field + '.mid' ) ? eval('data.' + meta.id_field + '.mid') : '') : '';

	return [
		release_box
    ]
})
