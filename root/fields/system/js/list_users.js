/*
name: Users
params:
    html: '/fields/system/html/field_users.html'
    js: '/fields/system/js/list_users.js'
    relation: 'system'
    type: 'listbox'
    get_method: 'get_users'    
    set_method: 'set_users'
    field_order: 10
    section: 'details'
    single_mode: 'false'
    filter: 'manual'
    meta_type: 'user'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
    var allowBlank;
    if (meta.allowBlank == 'false') allowBlank = false;
    if (meta.allowBlank == 'true') allowBlank = true;
    if (meta.allowBlank == undefined) allowBlank = true;

    var single_mode = true;
    if (meta.single_mode == 'false') single_mode = false;
	
    var users = new Array();
	
	if(data && eval('data.' + meta.id_field)){
		var eval_users = eval('data.' + meta.id_field);
		for(i=0; i<eval_users.length;i++){
			users.push(eval_users[i].mid);
		}
	}else{
		users = [];
	}
	
    var user_box_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true,
        baseParams: {projects:[],
					 roles: meta.filter,
                     topic_mid: data.topic_mid
                    }
    });
    
    var user_box = new Baseliner.model.Users({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        hiddenName: meta.id_field,		
        store: user_box_store,
		disabled: meta ? meta.readonly : true,
		singleMode: single_mode,
		allowBlank: allowBlank
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( users ) ;            
    });
	
	return [
		user_box
    ]
})
