/*
name: Projects
params:
    html: '/fields/system/html/field_projects.html'
    js: '/fields/system/js/list_projects.js'
    relation: 'system'    
    get_method: 'get_projects'    
    set_method: 'set_projects'
    field_order: 9
    section: 'details'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	var projects = new Array();
	
	if(data && eval('data.' + meta.bd_field)){
		var eval_projects = eval('data.' + meta.bd_field);
		for(i=0; i<eval_projects.length;i++){
			projects.push(eval_projects[i].mid);
		}
	}else{
		projects = [];
	}
	
    var project_box_store = new Baseliner.store.UserProjects({ id: 'id', baseParams: { include_root: true } });
	
    var project_box = new Baseliner.model.Projects({
        fieldLabel: _(meta.name_field),
        name: meta.id_field,
        hiddenName: meta.id_field,			
        store: project_box_store,
		disabled: meta ? meta.readonly : true
    });
	
    project_box_store.on('load',function(){
        project_box.setValue (projects) ;            
    });
    

// Habria que ver como tratar dependencias entre campos	
//    project_box.on('blur',function(obj){
//        var projects = new Array();
//        projects = (obj.getValue()).split(",");
//		var form = params.form.getForm();
//
//		var user_box = form.findField("users");
//		if (user_box){
//			user_box.store.load({
//				params:{ projects: projects}
//			});
//		}
//    });	
	
    var pb_panel = new Ext.Panel({
        layout: 'form',
        enableDragDrop: true,
        border: false,
        items: [ project_box ]
    });
	
    pb_panel.on( 'afterrender', function(){
        var el = pb_panel.el.dom; //.childNodes[0].childNodes[1];
        var project_box_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                //var s = project_box.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    var swOk = true;
                    projects = (project_box.getValue()).split(",");
                    for(var i=0; i<projects.length; i++) {
                        if (projects[i] == data.id_project){
                            swOk = false;
                            break;
                        }
                    }
                    if(swOk){
                        projects.push(data.id_project);
                        project_box.setValue( projects );
                    }else{
                        Baseliner.message( _('Warning'), _('Project %1 is already assigned', data.project));  
                    }
                };
                var attr = n.attributes;
                if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
                    Baseliner.message( _('Error'), _('Node is not a project'));
                } else {
                    add_node(n);
                }
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
    });
	
	
	return [
		pb_panel
    ]
})