/*
name: users
params:
    id_field: 'users'
    origin: 'rel'
    html: '/fields/field_assign_to.html'
    js: '/fields/field_assign_to.js'
    field_order: 10
    section: 'details'
    set_method: 'set_users'
    rel_field: 'users'
    method: 'get_users'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
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
        store: user_box_store,
		disabled: meta ? !meta.write ? meta.write: meta.readonly : true
		
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( users ) ;            
    });
	
	return [
		user_box
    ]
})