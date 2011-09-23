/*

Baseliner Models - commonly used data classes and functors

Copyright(c) 2006-2011 Authors of baseliner.org
http://baseliner.org/license

*/ 

Ext.ns('Baseliner.store');
Ext.ns('Baseliner.model');

Baseliner.store.AllProjects = function(c) {
     Baseliner.store.AllProjects.superclass.constructor.call(this, Ext.apply({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: {},
        id: 'ns', 
        url: '/project/all_projects',
        fields: ['ns','name','description'] 
     }, c));
};
Ext.extend( Baseliner.store.AllProjects, Ext.data.JsonStore );

Baseliner.store.UserProjects = function(c) {
    Baseliner.store.UserProjects.superclass.constructor.call(this, Ext.apply({
        url: '/project/user_projects'
    },c));
};
Ext.extend( Baseliner.store.UserProjects, Baseliner.store.AllProjects );

Baseliner.model.Projects = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name} - {description}</div></tpl>' );
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    Baseliner.model.Projects.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: new Baseliner.store.AllProjects({}),
        mode: 'remote',
        fieldLabel: _('Projects'),
        typeAhead: true,
        name: 'projects',
        displayField: 'name',
        hiddenName: 'projects',
        valueField: 'ns',
        tpl: '<tpl for="."><div class="x-combo-list-item">{name} - {description}</div></tpl>',
        displayFieldTpl: tpl2,
        value: '/',
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    id: v,
                    name: v
                };
                bs.addItem(newObj);
            }
        }
    }, c));
};
Ext.extend( Baseliner.model.Projects, Ext.ux.form.SuperBoxSelect );

Baseliner.combo_baseline = function(params) {
    if( params==undefined) params={};
    var store = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: params.request || {},
        id: 'id', 
        url: '/baseline/json',
        fields: ['id','name','description', 'active'] 
    });
    var valueField = params.valueField || 'id';
    var combo = new Ext.form.ComboBox({
           fieldLabel: _("Baseline"),
           name: params.name || 'bl',
           hiddenName: params.hiddenName || 'bl',
           valueField: valueField, 
           displayField: params.displayField || 'name',
           typeAhead: false,
           minChars: 1,
           mode: 'remote', 
           store: store,
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false
    });
    if( params.select_first ) {
        combo.store.on('load',function(store) {
            combo.setValue(store.getAt(0).get( valueField ));
        });
    } else if( params.value ) {
        combo.store.on('load',function(store) {
            var ix = store.find( valueField, params.value ); 
            if( ix > -1 ) combo.setValue(store.getAt(ix).get( valueField ));
        });
    }
    if( params.on_select ) {
        combo.on( 'select', params.on_select );
    }
    return combo;
};

/* Load first element in a combo on store load */
Baseliner.load_first = function( combo ) {
    combo.store.on('load',function(store) {
        combo.setValue(store.getAt(0).get( combo.initialConfig.valueField ));
    });
};

Baseliner.project_select_trees = function(params) {
    var Tree = Ext.tree;
    
    // yui-ext tree
    var tree = new Tree.TreePanel({
        columnWidth: .50,
        animate:true, 
        autoScroll:true,
        loader: new Tree.TreeLoader({dataUrl:'get-nodes.php'}),
        enableDD:true,
        containerScroll: true,
        dropConfig: {appendOnly:true}
    });
    
    // add a tree sorter in folder mode
    new Tree.TreeSorter(tree, {folderSort:true});
    
    // set the root node
    var root = new Tree.AsyncTreeNode({
        text: 'Ext JS', 
        draggable:false, // disable root node dragging
        id:'source'
    });
    tree.setRootNode(root);
    
    // render the tree
    //tree.render();
    
    root.expand(false, /*no anim*/ false);
    
    //-------------------------------------------------------------
    
    var tree2 = new Tree.TreePanel({
        columnWidth: .50,
        animate:true,
        autoScroll:true,
        //rootVisible: false,
        loader: new Ext.tree.TreeLoader({
            dataUrl:'get-nodes.php',
            baseParams: {lib:'yui'} // custom http params
        }),
        containerScroll: true,
        enableDD:true,
        dropConfig: {appendOnly:true}
    });
    
    // add a tree sorter in folder mode
    new Tree.TreeSorter(tree2, {folderSort:true});
    
    // add the root node
    var root2 = new Tree.AsyncTreeNode({
        text: 'My Files', 
        draggable:false, 
        id:'yui'
    });

    tree2.setRootNode(root2);
    //tree2.render();
    
    root2.expand(false, /*no anim*/ false);
    var panel = new Ext.Panel({
        layout: 'column',
        items: [ tree, tree2 ]
    });
    var trigger = new Ext.form.TriggerField();
    trigger.onTriggerClick = function() {
        alert( 'ok' )
    } ;
    return trigger;
};

/*

    Baseliner.combo_project({ value:'project/11221' });

*/
Baseliner.combo_project = function(params) {
    if( params==undefined) params={};
    var store = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: params.request || {},
        id: 'ns', 
        url: '/project/user_projects',
        fields: ['ns','name','description'] 
    });
    var valueField = params.valueField || 'ns';
    var combo = new Ext.form.ComboBox({
           fieldLabel: _("Project"),
           name: params.name || 'ns',
           hiddenName: params.hiddenName || 'ns',
           valueField: valueField, 
           displayField: params.displayField || 'name',
           typeAhead: false,
           minChars: 1,
           mode: 'remote', 
           store: store,
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false
    });
    if( params.select_first ) {
        combo.store.on('load',function(store) {
            combo.setValue(store.getAt(0).get( valueField ));
        });
    } else if( params.value ) {
        combo.store.on('load',function(store) {
            var ix = store.find( valueField, params.value ); 
            if( ix > -1 ) combo.setValue(store.getAt(ix).get( valueField ));
        });
    }
    if( params.on_select ) {
        combo.on( 'select', params.on_select );
    }
    return combo;
};

