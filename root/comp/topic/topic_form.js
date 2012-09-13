(function(rec){
    var form_is_loaded = false;
    var data = rec.topic_data;
    
    var main_fieldset = new Ext.form.FieldSet({
        collapsible: false,
        border: false,
        autoHeight : true,
        items: [
            { xtype: 'hidden', name: 'topic_mid', value: data ? data.topic_mid : -1 }
        ]
    });
    
    var form_topic = new Ext.FormPanel({
        url:'/topic/update',
        bodyStyle:'padding: 10px 0px 0px 15px',
        defaults: { anchor:'70%'},
        items: main_fieldset
    });

    // if we have an id, then async load the form
    form_topic.on('afterrender', function(){
        form_topic.body.setStyle('overflow', 'auto');

    });

    ///*****************************************************************************************************************************
    if (rec.topic_meta != undefined){

        var fields = rec.topic_meta;
        
        var load_all = function( i ) {
            if( fields[i] == undefined ) {
                var form2 = form_topic.getForm();
                var id_category = rec.new_category_id ? rec.new_category_id : data.id_category;

                var obj_combo_category = form2.findField("category");
                var obj_store_category;
                if(obj_combo_category){
                    obj_store_category = form2.findField("category").getStore();
                    obj_store_category.on("load", function() {
                       obj_combo_category.setValue(id_category);
                    });
                    obj_store_category.load();
                }

                var obj_combo_status = form2.findField("status_new");
                var obj_store_category_status;                
                
                if( rec.new_category_id != undefined ) {
                    if(obj_combo_status){
                        obj_store_category_status = obj_combo_status.getStore();
                        obj_store_category_status.on('load', function(){
                            if( obj_store_category_status != undefined && obj_store_category_status.getAt(0) != undefined )
                                obj_combo_status.setValue( obj_store_category_status.getAt(0).id );
                        });
                        obj_store_category_status.load({
                            params:{ 'change_categoryId': id_category }
                        });                         
                    }
                    form2.findField("topic_mid").setValue(-1);
                }else {
                    if(obj_combo_status){
                        obj_store_category_status = obj_combo_status.getStore();
                        obj_store_category_status.on("load", function() {
                            obj_combo_status.setValue( data ? data.id_category_status : '' );
                        });
                        obj_store_category_status.load({
                                params:{ 'categoryId': id_category, 'statusId': data ? data.id_category_status : '', 'statusName': data ? data.name_status : '' }
                        });                         
                    }
                }
                
                var obj_combo_priority = form2.findField("priority");
                var obj_store_category_priority;

                if(obj_combo_priority){
                    obj_store_category_priority = obj_combo_priority.getStore();
                    obj_store_category_priority.on("load", function() {
                        obj_combo_priority.setValue(data ? data.id_priority : '');                            
                    });                    
                    obj_store_category_priority.load({params:{'active':1, 'category_id': id_category}});
                }
                
                return;
            }
            
            if(fields[i].js){
                Baseliner.ajaxEval (fields[i].js, {form: form_topic, topic_data: rec.topic_data, topic_meta: rec.topic_meta, value: ''}, function(res){
                    main_fieldset.add (res);
                    form_topic.doLayout();
                    load_all( i + 1 );
                });
            }else{
                load_all( i + 1 );
            }
        };
        
        load_all( 0 );
        
    }
    ///******************************************************************************************************************************    
    return form_topic;
})


