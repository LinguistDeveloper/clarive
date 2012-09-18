/*
name: category
params:
    id_field: 'id_category'
    origin: 'system'
    html: '/fields/field_category.html'
    js: '/fields/field_category.js'
    field_order: 1
    section: 'body'
    relation: 'categories'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	var store_category = new Baseliner.Topic.StoreCategory({
		fields: ['category', 'category_name' ]  
    });

	//TODO -> Ojo si se puede cambiar categoria, tratar a parte de los estados las prioridades.
    var combo_category = new Ext.form.ComboBox({
        value: data ? data.name_category : '',
        mode: 'local',
        forceSelection: true,
        emptyText: 'select a category',
        triggerAction: 'all',
        fieldLabel: _('Category'),
        name: 'category',
        valueField: 'category',
        hiddenName: 'category',
        displayField: 'category_name',
        store: store_category,
        allowBlank: false,
		readOnly: meta ? meta.write ? meta.write: meta.readonly : true,
        //hidden: rec.fields_form.show_category  ? false : true,
        listeners:{
            'select': function(cmd, rec, idx){
                var ff;
                ff = params.form.getForm();
				var obj_combo_status = ff .findField("status_new");
				if (obj_combo_status) {
					obj_combo_status.clearValue();
					if(ff.findField("txtcategory_old").getValue() == this.getValue()){
						obj_combo_status.store.load({
							params:{ 'categoryId': this.getValue(), 'statusId': ff.findField("status").getValue() }
						});                   
					}else{
						obj_combo_status.store.load({
							params:{ 'change_categoryId': this.getValue(), 'statusId': ff.findField("status").getValue() }
						});                    
					}
				}
            }
        }
    });
	
    return [
		{ xtype: 'hidden', name: 'txtcategory_old' },
		combo_category
	]
})