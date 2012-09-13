(function(params){
	var data = params.topic_data;
	
	var topics = new Array();
	if(data && data.topics){
		for(i=0; i<data.topics.length;i++){
			topics.push(data.topics[i].mid);
		}
	}else{
		topics = [];
	}
	
    var topic_box_store = new Baseliner.store.Topics({ baseParams: { mid: data ? data.topic_mid : '', show_release: 0} });
	
    var topic_box = new Baseliner.model.Topics({
        //hidden: rec.fields_form.show_topics ? false : true,
        store: topic_box_store
    });
	
    topic_box_store.on('load',function(){
        topic_box.setValue( topics ) ;            
    });
	
	return [
		topic_box
    ]
})