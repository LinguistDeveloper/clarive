/*
name: status_new
params:
    id_field: 'id_category_status'
    origin: 'system'
    html: '/fields/field_status.html'
    js: '/fields/field_status.js'
    field_order: 3
    section: 'body'
    relation: 'status'
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
    var store_category_status = new Baseliner.Topic.StoreCategoryStatus({
        url:'/topic/list_admin_category'
    });
	
    var combo_status = new Ext.form.ComboBox({
        value: data ? data.name_status : '',
        mode: 'local',
        forceSelection: true,
        autoSelect: true,
        triggerAction: 'all',
        emptyText: 'select a status',
        fieldLabel: _('Status'),
        name: 'status_new',
        hiddenName: 'status_new',
        displayField: 'name',
        valueField: 'id',
		readOnly: meta ? meta.readonly : true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        store: store_category_status
    });
	
	return [
		{ xtype: 'hidden', name: 'status', value: data ? data.id_category_status : -1 },		
		combo_status
    ]
})