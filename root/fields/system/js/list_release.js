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
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;

	var ff = params.form.getForm();
	var topic_mid = ff.findField("topic_mid").getValue();

    var release_box_store = new Baseliner.store.Topics({ baseParams: { mid: topic_mid, show_release: 1, filter: meta.filter ? meta.filter : ''} });

    var release_box = new Baseliner.model.Topics({
        hiddenName: meta.id_field,
        name: meta.id_field,
        fieldLabel: _(meta.name_field),
        singleMode: true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        disabled: meta.readonly!=undefined ? meta.readonly : false,
        store: release_box_store
    });
	
    release_box_store.on('load',function(){
		release_box.setValue (data ? (eval('data.' + meta.bd_field + '.mid') ? eval('data.' + meta.bd_field + '.mid') : '') : '');
		
    });


	return [
		release_box
    ]
})