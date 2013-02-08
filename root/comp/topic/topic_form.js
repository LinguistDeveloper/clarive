(function(rec){
    var form_is_loaded = false;
    var data = rec.topic_data;
    if( data == undefined ) data = {};
    var on_submit_events = [];
    
    var unique_id_form = Ext.getCmp('main-panel').getActiveTab().id + '_form_topic';
    
    var form_topic = new Ext.FormPanel({
        url:'/topic/update',
        bodyStyle: {
          'padding': '5px 90px 5px 90px'
        },
        id: unique_id_form,
        border: false,
        defaults: { anchor:'98%'},
        items: [
            { xtype: 'hidden', name: 'topic_mid', value: data ? data.topic_mid : -1 }
        ]
    });

    form_topic.on_submit = function(){
        Ext.each( on_submit_events, function(ev) {
            ev();
        });
    };
    
   
    // if we have an id, then async load the form
    form_topic.on('afterrender', function(){
        form_topic.body.setStyle('overflow', 'auto');

    });

    ///*****************************************************************************************************************************
    if (rec.topic_meta != undefined){
        var fields = rec.topic_meta;

        for( var i = 0; i < fields.length; i++ ) {
            if(fields[i].body) {
                var comp = Baseliner.eval_response(
                    fields[i].body,
                    {form: form_topic, topic_data: data, topic_meta: fields[i], value: '', _cis: rec._cis, id_panel: rec.id_panel, admin: rec.can_admin }
                );
                
                if( comp.items ) {
                    if( comp.on_submit ) on_submit_events.push( comp.on_submit );
                    form_topic.add (comp.items );
                } else {
                    form_topic.add (comp );
                }
            }
        }  // for fields

        form_topic.on( 'afterrender', function(){
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
        });
        form_topic.doLayout();
    } // if rec.meta
    ///******************************************************************************************************************************
            
    return form_topic;
})


