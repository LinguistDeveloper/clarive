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
    meta_type: 'release'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;

	var topic_mid = data.topic_mid || undefined;
	var ps = meta.page_size || 10;  // for combos, 10 is a much nicer on a combo
    var display_field = meta.display_field || undefined;

    var release_box_store = new Baseliner.store.Topics({ baseParams: {  limit: ps, mid: topic_mid, show_release: 1, filter: meta.filter ? meta.filter : ''}, display_field: display_field });

	var release_box = new Baseliner.TopicBox({
		fieldLabel: _(meta.name_field),
		pageSize: ps,
		name: meta.id_field,
		hiddenName: meta.id_field,          
		emptyText: _( meta.emptyText ),
		allowBlank: meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true ),          
		store: release_box_store,
		disabled: meta ? meta.readonly : true,
		singleMode: meta.single_mode == 'false' || !meta.single_mode ? false : true,
		hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        display_field: display_field
	});	
	
//    release_box_store.on('load',function(){
		release_box.setValue (data ? (eval('data.' + meta.id_field + ' && data.' + meta.id_field + ' != undefined && data.' + meta.id_field + '.mid' ) ? eval('data.' + meta.id_field + '.mid') : '') : '');
//    });

	return [
		release_box
    ]
})
