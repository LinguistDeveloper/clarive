/*
name: Projects
params:
    html: '/fields/system/html/field_projects.html'
    js: '/fields/system/js/list_projects.js'
    relation: 'system'
    type: 'listbox'    
    get_method: 'get_projects'    
    set_method: 'set_projects'
    field_order: 9
    section: 'details'
    single_mode: 'false'
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
    } else {
        projects = meta.default_value ? [ meta.default_value ] : [];
    }
    
    var ps = meta.page_size || 20;
    var project_box_store = new Baseliner.store.UserProjects({ id: 'id', baseParams: {
        tree_level: meta.tree_level || '',
        limit: ps, include_root: true, level: meta.level 
    } });
    
    Baseliner.PagingProjects = Ext.extend( Ext.ux.form.SuperBoxSelect, {
        minChars: 2,
        //forceSelection: true,
        typeAhead: false,
        loadingText: _('Searching...'),
        resizable: true,
        allowBlank: true,
        lazyRender: false,
        triggerAction: 'all',
        pageSize: 20,
        //allowBlank: true,
        msgTarget: 'under',
        emptyText: _('Select a project'),
        //store: new Baseliner.store.UserProjects({}),
        //mode: 'remote',
        fieldLabel: _('Projects'),
        name: 'projects',
        displayField: 'name',
        hiddenName: 'projects',
        valueField: 'mid',
        extraItemCls: 'x-tag',
        initComponent: function(){
            var self = this;
            self.tpl = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> {description}</span></div></tpl>' );
            self.displayFieldTpl = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
            Baseliner.PagingProjects.superclass.initComponent.call(this);
        }
    });

    var project_box = new Baseliner.PagingProjects({
        fieldLabel: _(meta.name_field),
        pageSize: ps,
        name: meta.id_field,
        hiddenName: meta.id_field,          
        emptyText: _( meta.emptyText ),
        allowBlank: meta.allowBlank==undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true ),          
        store: project_box_store,
        disabled: meta ? meta.readonly : true,
        singleMode: meta.single_mode == 'false' || !meta.single_mode ? false : true
    });
    
    project_box_store.on('load',function(){
        project_box.setValue (projects ) ;            
    });
    

// Habria que ver como tratar dependencias entre campos 
//    project_box.on('blur',function(obj){
//        var projects = new Array();
//        projects = (obj.getValue()).split(",");
//      var form = params.form.getForm();
//
//      var user_box = form.findField("users");
//      if (user_box){
//          user_box.store.load({
//              params:{ projects: projects}
//          });
//      }
//    });   
    
    var pb_panel = new Ext.Panel({
        layout: 'form',
        enableDragDrop: true,
        anchor: meta.anchor || '100%',
        border: false,
        items: [ project_box ]
    });
    
    pb_panel.on( 'afterrender', function(){
        var el = pb_panel.el.dom; //.childNodes[0].childNodes[1];
        var project_box_dt = new Baseliner.DropTarget(el, {
            comp: pb_panel,
            ddGroup: 'explorer_dd',
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
