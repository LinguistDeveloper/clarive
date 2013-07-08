/*
name: Topics
params:
    html: '/fields/system/html/field_topics.html'
    js: '/fields/system/js/list_topics.js'
    relation: 'system'
    type: 'listbox'    
    get_method: 'get_topics'    
    set_method: 'set_topics'
    field_order: 14
    section: 'details'
    page_size: 20
    filter: 'none'
    single_mode: 'false'    
---
*/
(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
	var topics = new Array();
    var ps = meta.page_size || 20;
	
	if(data && data[ meta.bd_field] ){
		var eval_topics = data[ meta.bd_field ];
		for(i=0; i<eval_topics.length;i++){
			topics.push(eval_topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var topic_box;
    var topic_box_store = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0, filter: meta.filter ? meta.filter : ''} });
    if( meta.list_type == 'grid' ) {
        // Grid
        topic_box = new Baseliner.TopicGrid({ 
            fieldLabel:_( meta.name_field ), 
            combo_store: topic_box_store,
            columns: meta.columns,
            name: meta.id_field, 
            height: meta.height || 250,
            value: data[ meta.id_field ]
        });

    } else {
        var topic_box = new Baseliner.TopicBox({
            fieldLabel: _(meta.name_field),
            pageSize: ps,
            name: meta.id_field,
            hiddenName: meta.id_field,          
            emptyText: _( meta.emptyText ),
            allowBlank: meta.allowBlank==undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true ),          
            store: topic_box_store,
            disabled: meta ? meta.readonly : true,
            singleMode: meta.single_mode == 'false' || !meta.single_mode ? false : true
        });
        
        topic_box_store.on('load',function(){
            topic_box.setValue(topics) ;            
        });
    }
	return [
		topic_box
    ]
})
