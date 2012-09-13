(function(params){
	var data = params.topic_data;
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