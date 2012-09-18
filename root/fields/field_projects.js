/*
name: projects
params:
    id_field: 'projects'
    origin: 'rel'
    html: '/fields/field_projects.html'
    js: '/fields/field_projects.js'
    field_order: 9
    section: 'details'
    set_method: 'set_projects'
    rel_field: 'projects'
    method: 'get_projects'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	var projects = new Array();
	if(data && data.projects){
		for(i=0; i<data.projects.length;i++){
			projects.push(data.projects[i].mid);
		}
	}else{
		projects = [];
	}
	
    var project_box_store = new Baseliner.store.UserProjects({ id: 'id' });
	
    var project_box = new Baseliner.model.Projects({
        store: project_box_store,
		disabled: meta ? meta.readonly : true
    });
	
    project_box_store.on('load',function(){
        project_box.setValue (projects) ;            
    });
    
    project_box.on('blur',function(obj){
        var projects = new Array();
        projects = (obj.getValue()).split(",");
		var form = params.form.getForm();
		//**************************************************Ojo con esto, puede que compartan el name cuando se duplica
		var user_box = form.findField("users");
		if (user_box){
			user_box.store.load({
				params:{ projects: projects}
			});
		}
    });	
	
    var pb_panel = new Ext.Panel({
        layout: 'form',
        enableDragDrop: true,
        border: false,
        //hidden: rec.fields_form.show_projects ? false : true,
        //style: 'border-top: 0px',
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