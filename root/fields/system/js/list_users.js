/*
name: Users
params:
    html: '/fields/system/html/field_users.html'
    js: '/fields/system/js/list_users.js'
    relation: 'system'
    get_method: 'get_users'    
    set_method: 'set_users'
    field_order: 10
    section: 'details'    
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	var users = new Array();
	var eval_users = eval('data.' + meta.bd_field);
	if(data && eval('data.' + meta.bd_field)){
		for(i=0; i<eval_users.length;i++){
			users.push(eval_users[i].mid);
		}
	}else{
		users = [];
	}
	
    var user_box_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true,
        baseParams: {projects:[]}
    });
    
    var user_box = new Baseliner.model.Users({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        hiddenName: meta.id_field,		
        store: user_box_store,
		disabled: meta ? meta.readonly : true
		
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( users ) ;            
    });
	
	return [
		user_box
    ]
})