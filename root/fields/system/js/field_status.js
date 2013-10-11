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
	
//    var combo_status = new Ext.form.ComboBox({
//        value: data ? data.name_status : '',
//        mode: 'local',
//        forceSelection: true,
//        autoSelect: true,
//        triggerAction: 'all',
//        emptyText: 'select a status',
//        fieldLabel: _('Status'),
//        name: 'status_new',
//        hiddenName: 'status_new',
//        displayField: 'name',
//        valueField: 'id',
//		readOnly: meta ? meta.readonly : true,
//        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
//        store: store_category_status
//    });
	
    Baseliner.model.Status = function(c) {
	    Baseliner.model.Status.superclass.constructor.call(this, Ext.apply({
		    allowBlank: false,
		    msgTarget: 'under',
		    allowAddNewData: true,
		    addNewDataOnBlur: false, 
		    //emptyText: _('Enter or select topics'),
		    triggerAction: 'all',
		    resizable: true,
		    mode: 'local',
		    fieldLabel: _('Status'),
		    typeAhead: true,
		    name: 'status_new',
		    displayField: 'name',
		    hiddenName: 'status_new',
		    valueField: 'id',
		    value: data ? data.name_status : '',
		    extraItemCls: 'x-tag'
			
	    }, c));
    };
    Ext.extend( Baseliner.model.Status, Ext.ux.form.SuperBoxSelect );
	
	var status_box = new Baseliner.model.Status({
		store: store_category_status,
		readOnly: meta ? meta.readonly : true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
		singleMode: true
	});
	
	store_category_status.on('load',function(){
		status_box.setValue( data.name_status ) ;            
	});	
	
	return [
		{ xtype: 'hidden', name: 'status', value: data ? data.id_category_status : -1 },		
		status_box
    ]
})