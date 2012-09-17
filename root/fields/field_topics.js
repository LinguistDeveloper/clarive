/*
name: topics
params:
    id_field: 'topics'
    origin: 'rel'
    html: '/fields/field_topics.html'
    js: '/fields/field_topics.js'
    field_order: 14
    section: 'details'
    set_method: 'set_topics'
    rel_field: 'topics'
    method: 'get_topics'
    is_clone: 1
    filter: none
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
	var topics = new Array();
	if(data && data.topics){
		for(i=0; i<data.topics.length;i++){
			topics.push(data.topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var topic_box_store = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0, filter: meta.filter ? meta.filter : ''} });
	
    var topic_box = new Baseliner.model.Topics({
        //hidden: rec.fields_form.show_topics ? false : true,
		fieldLabel: _(meta.name_field),
		name: meta.name_field,
        store: topic_box_store,
		disabled: meta ? meta.readonly: false
    });
	
    topic_box_store.on('load',function(){
        topic_box.setValue( topics ) ;            
    });
	
	return [
		topic_box
    ]
})