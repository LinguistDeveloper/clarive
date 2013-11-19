/*
name: labels
params:
    id_field: 'labels'
    origin: 'rel'
    html: '/fields/field_labels.html'
    js: '/fields/field_labels.js'
    field_order: 11
    section: 'head'
    set_method: 'set_labels'
    method: 'get_labels'
    meta_type: 'label'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	
	var labels = new Array();
	if(data && data.users){
		for(i=0; i<data.labels.length;i++){
			labels.push(data.labels[i].id);
		}
	}else{
		labels = [];
	}
	
    var label_box_store = new Baseliner.Topic.StoreLabel({
        autoLoad: true
    });
	
    label_box_store.on('load',function(){
        label_box.setValue( labels ) ;            
    });	
    
    var label_box = new Baseliner.model.Labels({
        //hidden: rec.fields_form.show_labels ? false : true,
        store: label_box_store
    });
	
	return [
		label_box
    ]
})
