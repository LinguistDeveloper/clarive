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
    collection: 'project'
    tree_level: ''
    include_root: 'true'
    meta_type: 'project'
    roles: ''

---
*/
(function(params){
    var data = params.topic_data;
    var meta = params.topic_meta;
    
    var projects = [];
    
    if(data && data[meta.bd_field] ){
        var val_projects = data[meta.bd_field];
        for(i=0; i<val_projects.length;i++){
            var p = val_projects[i];
            if( p==undefined || p.mid == undefined ) continue;
            projects.push(p.mid);
        }
    } else {
        projects = meta.default_value ? [ meta.default_value ] : [];
    }

    var ps = meta.page_size || 20;
    var project_box_store = new Baseliner.store.UserProjects({ id: 'id', baseParams: {
        tree_level: meta.tree_level || '',
        limit: ps, 
        include_root: true, 
        level: meta.level, 
        collection: meta.collection,
        autoLoad: false,
        roles: meta.roles
    } });
    
    var no_items = _('No items found');
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> - ({description})</span></div></tpl>' );
    var project_box = new Baseliner.PagingProjects({
        origin: 'custom',
        fieldLabel: _(meta.name_field),
        pageSize: '',
        tpl: tpl,
        name: meta.id_field,
        hiddenName: meta.id_field,          
        listEmptyText: no_items, 
        emptyText: _( meta.emptyText ),
        field_ready: false,
        allowBlank: meta.allowBlank == 'false' ? false : true,
        disabled: meta.readonly!=undefined ? meta.readonly : false,
        store: project_box_store,
        singleMode: meta.single_mode == 'false' || !meta.single_mode ? false : true
    });
    
    project_box.field_ready = false;
    project_box_store.on('load',function(){
        project_box.field_ready = true;
        project_box.setValue(projects);
    });


    project_box_store.load({});
   
    if( meta.parent_field ) {
        var form = params.form.getForm();
        var parent_field = form.findField( meta.parent_field );
        if( parent_field ) {
            var parent_last = parent_field.value;
            project_box_store.baseParams['root_mid'] = parent_last;
            var parent_foo = function(){ 
                if( !project_box.field_ready || !parent_field.field_ready ) return;
                //Baseliner.message( 'nada', String.format('parent changed = {0}, {1} = {2}', parent_last, parent_field.getValue(), parent_last != parent_field.getValue() ) );
                var cvalue = project_box.getValue();
                if( parent_last != parent_field.getValue() ) {
                    if( cvalue!=undefined && cvalue!='' ) {
                        Baseliner.warning( _('Warning'), _('Field %1 reset due to change in %2', _(meta.name_field), _(parent_field.fieldLabel) ) );
                        project_box.setValue(null);
                        project_box.removeAllItems();
                        project_box.killItems();
                        // FIXME - should reset store everytime, so a new dataview is shown
                    }
                    parent_last = parent_field.getValue();
                    if( parent_last==undefined || parent_last=='' ) {   // parent is unselected, make an impossible query with -1
                        project_box_store.baseParams['root_mid'] = -1;
                        project_box.listEmptyText = _('Select field %1 first or reload', _(parent_field.fieldLabel) );
                    } else {
                        project_box_store.baseParams['root_mid'] = parent_last;
                        project_box_store.removeAll();
                        project_box.listEmptyText = no_items;
                    }
                }
            };
            parent_field.on( 'additem', function(){ return parent_foo.call(this,arguments) } );
            parent_field.on( 'removeitem', function(){ return parent_foo.call(this,arguments) } );
        }
    }

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
