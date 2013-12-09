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
    anchor: 30%
    meta_type: status
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
    var store_category_status = new Baseliner.Topic.StoreCategoryStatus({
        url:'/topic/list_admin_category',
        baseParams: { topic_mid: data.topic_mid}
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
//        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
//        store: store_category_status
//    });
	
    var status_box = new Baseliner.model.Status({
        store: store_category_status,
        anchor: data.anchor,
        value: data ? data.name_status : '',
        readOnly: meta ? meta.readonly : true,
        hidden: meta ? (meta.hidden ? meta.hidden : false): true,
        singleMode: true
    });
    
    store_category_status.on('load',function(){
        status_box.setValue( data.name_status ) ;            
    });	
    var comp = status_box;
    
    if( meta.readonly  ) {
        var status_cont = new Ext.Panel({ 
            fieldLabel:_('Status'), 
            allowBlank: false,
            border: false,
            items: status_box, layout:'fit',
                listeners: {
                    'afterrender':function(){
                        if(meta.readonly){
                            var el = this.el;
                            var mask = el.mask();
                            mask.setStyle('opacity', 0.2);
                            mask.setStyle('height', 5000);
                        }
                    }
                }
        });
        comp = status_cont;
    }
	return [
		{ xtype: 'hidden', name: 'status', value: data ? data.id_category_status : -1 },		
		comp
    ]
})
