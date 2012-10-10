/*
name: Topics
params:
    html: '/fields/system/html/field_topics.html'
    js: '/fields/system/js/list_topics.js'
    relation: 'system'
    get_method: 'get_topics'    
    set_method: 'set_topics'
    field_order: 14
    section: 'details'
    filter: 'none'
    singleMode: 'false'    
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
	var topics = new Array();
	
	if(data && eval('data.' + meta.bd_field)){
		var eval_topics = eval('data.' + meta.bd_field);
		for(i=0; i<eval_topics.length;i++){
			topics.push(eval_topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var topic_box_store = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0, filter: meta.filter ? meta.filter : ''} });
	
    var topic_box = new Baseliner.model.Topics({
		fieldLabel: _(meta.name_field),
		name: meta.name_field,
        hiddenName: meta.id_field,
        store: topic_box_store,
		disabled: meta ? meta.readonly : true,
		singleMode: meta.singleMode
    });
	
    topic_box_store.on('load',function(){
        topic_box.setValue( topics ) ;            
    });
	
	return [
		topic_box
    ]
})