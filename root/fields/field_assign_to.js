(function(params){
	var data = params.topic_data;
	var users = new Array();
	if(data && data.users){
		for(i=0; i<data.users.length;i++){
			users.push(data.users[i].mid);
		}
	}else{
		users = [];
	}
	
    var user_box_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true,
        baseParams: {projects:[]}
    });
    
    var user_box = new Baseliner.model.Users({
        //hidden: rec.fields_form.show_assign_to ? false : true,
        store: user_box_store 
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( users ) ;            
    });
	
	return [
		user_box
    ]
})