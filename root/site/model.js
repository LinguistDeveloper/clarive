/*

Baseliner Models - commonly used data classes and functors

Copyright(c) 2006-2011 Authors of baseliner.org
http://baseliner.org/license

*/ 

//Ext.ns('Baseliner.store');
//Ext.ns('Baseliner.model');

Baseliner.SuperBox = Ext.extend( Ext.ux.form.SuperBoxSelect, {
    minChars: 2,
    pageSize: 20,
    typeAhead: false,
    loadingText: _('Searching...'),
    resizable: true,
    allowBlank: true,
    lazyRender: false,
    triggerAction: 'all',
    msgTarget: 'under',
    emptyText: _('Select one'),
    mode: 'remote',
    displayField: 'name',
    hiddenName: 'projects',
    valueField: 'mid',
    extraItemCls: 'x-tag',
    queryValuesDelimiter: ' ', // important, so that the query parameter gets all mids in a searcheable manner, otherwise multivalues do not load
    get_save_data: function(){
         var arr=[];
         this.items.each(function(r){ arr.push(r.value) });
         return arr;
    },
    get_labels: function(){
         var arr=[];
         this.items.each(function(r){ arr.push(r.display) });
         return arr;
    }
});

Baseliner.store.AllProjects = function(c) {
     Baseliner.store.AllProjects.superclass.constructor.call(this, Ext.apply({
        root: 'data' , 
        remoteSort: true,
        autoLoad: false,
        totalProperty:"totalCount", 
        baseParams: {},
        id: 'id', 
        url: '/project/all_projects',
        fields: ['mid','ns','name','description'] 
     }, c));
};
Ext.extend( Baseliner.store.AllProjects, Baseliner.JsonStore );

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
        //store: new Baseliner.store.UserProjects({}),
        mode: 'local',
        fieldLabel: _('Projects'),
        typeAhead: true,
        name: 'projects',
        displayField: 'name',
        hiddenName: 'projects',
        valueField: 'mid',
        tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> {description}</span></div></tpl>',
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

Baseliner.PagingProjects = Ext.extend( Ext.ux.form.SuperBoxSelect, {
    minChars: 2,
    pageSize: 20,
    typeAhead: false,
    loadingText: _('Searching...'),
    resizable: true,
    allowBlank: true,
    lazyRender: false,
    triggerAction: 'all',
    msgTarget: 'under',
    emptyText: _('Select a project'),
    mode: 'remote',
    fieldLabel: _('Projects'),
    displayField: 'name',
    name: 'projects',
    hiddenName: 'projects',
    valueField: 'mid',
    extraItemCls: 'x-tag',
    queryValuesDelimiter: ' ', // important, so that the query parameter gets all mids in a searcheable manner, otherwise multivalues do not load
    initComponent: function(){
        var self = this;
        if( !self.store ) self.store = Baseliner.store.UserProjects(Ext.apply({},self.store_config));
        self.tpl = self.tpl || new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{name}</strong> {description}</span></div></tpl>' );
        self.displayFieldTpl = self.displayFieldTpl || new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
        Baseliner.PagingProjects.superclass.initComponent.call(this);
    }
});

Baseliner.model.Users = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}"><span id="boot" style="background: transparent"><strong>{username}</strong> {realname}</span></div></tpl>' );
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{username}</tpl>' );
    Baseliner.model.Users.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        //store: new Baseliner.store.UserProjects({}),
        mode: 'local',
        fieldLabel: _('Assign to'),
        typeAhead: true,
        name: 'users',
        displayField: 'username',
        hiddenName: 'users',
        valueField: 'id',
        tpl: '<tpl for="."><div class="x-combo-list-item"><span id="boot" style="background: transparent"><strong>{username}</strong> {realname}</span></div></tpl>',
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
Ext.extend( Baseliner.model.Users, Ext.ux.form.SuperBoxSelect );

Baseliner.ComboUsers = Ext.extend( Baseliner.model.Users,{
    disabled: false,
    singleMode: false,
    allowBlank: true,
    name: 'users',
    hiddenName: 'users',		
    initComponent: function(){
        var self = this;
        self.store = new Baseliner.Topic.StoreUsers({
            autoLoad: false,
            baseParams: { projects: self.projects || [], roles: self.roles }
        });
        self.store.on('load',function(){
            if( self.value ) self.setValue( self.value );
        });
        Baseliner.ComboUsers.superclass.initComponent.call(this);
    }
});
/*
Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
    Ext.applyIf(this.options, {
    submitEmptyText:false
    });
});
*/

Baseliner.model.Revisions = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name}</div></tpl>' );
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    Baseliner.model.Revisions.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        emptyText: _('select or drop repository revisions'),
        triggerAction: 'all',
        resizable: true,
        mode: 'local',
        fieldLabel: _('Revisions'),
        typeAhead: true,
        name: 'revisions',
        displayField: 'name',
        hiddenName: 'revisions',
        valueField: 'id',
        tpl: '<tpl for="."><div class="x-combo-list-item">{name}</div></tpl>',
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
Ext.extend( Baseliner.model.Revisions, Ext.ux.form.SuperBoxSelect );

Baseliner.UserAndRoleBox = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name}</div></tpl>' );
    var tpl2 = new Ext.XTemplate( '<tpl for="."><b>{[_loc(values.type)]}</b>: {name}</tpl>' );
    var store = new Baseliner.JsonStore({
        root: 'data' , remoteSort: true, autoLoad: true,
        id: 'id', 
        totalProperty: 'totalCount', 
        //baseParams: c.request || {},
        url: '/message/to_and_cc',
        fields: ['id','ns','name','long', 'type'] 
    });
    if( ! c.hiddenName && c.name ) {
        c.hiddenName = c.name;
    }
    Baseliner.UserAndRoleBox.superclass.constructor.call(this, Ext.apply({
        name: 'to_and_cc',
        hiddenName: 'to_and_cc',
        displayField: 'name',
        valueField: 'ns',
        store: store,
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        emptyText: _('select users or roles'),
        triggerAction: 'all',
        resizable: true,
        mode: 'remote',
        fieldLabel: _('To'),
        typeAhead: true,
        tpl: '<tpl for="."><div class="x-combo-list-item"><b>{[_loc(values.type)]}</b>: {name} - {long}</div></tpl>',
        displayFieldTpl: tpl2,
        value: '',
        extraItemCls: 'x-tag'
    }, c));
};
Ext.extend( Baseliner.UserAndRoleBox, Ext.ux.form.SuperBoxSelect );


function returnOpposite(hexcolor) {
    var r = parseInt(hexcolor.substr(0,2),16);
    var g = parseInt(hexcolor.substr(2,2),16);
    var b = parseInt(hexcolor.substr(4,2),16);
    var yiq = ((r*299)+(g*587)+(b*114))/1000;
    return (yiq >= 128) ? '#000000' : '#FFFFFF';
}
    
Baseliner.model.Labels = function(c) {
    var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
        '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: {[returnOpposite(values.color.substr(1))]};background: {color}">{name}</span></span>',
        '</div></tpl>');
    var tpl_field = new Ext.XTemplate( '<tpl for=".">',
        '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: {[returnOpposite(values.color.substr(1))]};background: {color}">{name}</span></span>',
        '</tpl>');
    
    Baseliner.model.Projects.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        triggerAction: 'all',
        resizable: true,
        mode: 'local',
        fieldLabel: _('Labels'),
        typeAhead: true,
        name: 'labels',
        displayField: 'name',
        hiddenName: 'labels',
        valueField: 'id',
        tpl: tpl_list,
        displayFieldTpl: tpl_field,
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
Ext.extend( Baseliner.model.Labels, Ext.ux.form.SuperBoxSelect );


Baseliner.combo_baseline = function(params) {
    if( params==undefined) params={};
    var store = new Baseliner.JsonStore({
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
           fieldLabel: params.fieldLabel || _("Baseline"),
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
    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: false,
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

// Revisions - ie. packages, etc.
//    options:
//            checkin : true   ( only revisions that can handle a checkin op )
Baseliner.combo_revision = function(params) {
    if( params == undefined ) params = {};
    var base = {};
    if( params.checkin ) {
        base.checkin = true;
        base.does    = 'Baseliner::Role::Namespace::Checkin';
    }
    var rev_store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'ns', 
        url: '/revision/list_simple',
        baseParams: base,
        fields: [ 
            {  name: 'item' },
            {  name: 'ns' }
        ]
    });
    var combo = new Ext.form.ComboBox({
       name: 'ns', 
       hiddenName: 'ns',
       fieldLabel: params.fieldLabel || _('Revision'), 
       mode: 'remote', 
       store: rev_store, 
       valueField: 'ns',
       value: params.value || '',
       typeAhead: true,
       minChars: params.minChars || 2,
       displayField:'item', 
       editable: true,
       forceSelection: true,
       triggerAction: 'all',
       allowBlank: false,
       width: 300
    });
    return combo;
};

// TODO deprecated (controller is gone)
Baseliner.combo_tasks = function(params) {
    if( params == undefined ) params = {};
    var store_tasks =new Baseliner.JsonStore({
        root: 'data', 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/tasks/json',
        fields: [ 'name', 'category', 'assigned', 'description' ]
    });
    
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    var conf;
    Ext.apply( conf, params, {
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: store_tasks,
        mode: 'remote',
        fieldLabel: _('Tasks'),
        typeAhead: true,
        name: 'name',
        displayField: 'name',
        hiddenName: 'name',
        valueField: 'name',
        displayFieldTpl: tpl2,
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
     });
    var combo_tasks = new Ext.ux.form.SuperBoxSelect( conf );
     return combo_tasks;
};

Baseliner.combo_services = function(params) {
    if( params==undefined) params={};
    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: false,
        totalProperty:"totalCount", 
        baseParams: params.request || {},
        id: 'id', 
        url: '/service/combo',
        fields: [ 'id', 'name' ]
    });
    var valueField = params.valueField || 'id';
    var combo = new Ext.form.ComboBox({
           fieldLabel: params.fieldLabel || _("Service"),
           name: params.name || 'service',
           hiddenName: params.hiddenName || 'service',
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

/*

   Baseliner.Calendar - fullcalendar Panel wrapper

   var cal = new Baseliner.Calendar({
        width: 999, height: 999, ...            // panel config
        fullCalendarConfig: {  ... }            // fullcalendar object config
   });

   cal.fullCalendar('renderEvent', { ... } );
  
   Docs: http://arshaw.com/fullcalendar/docs/usage/

*/ 
Baseliner.Calendar =  function(c) {
    var cal_div = new Ext.Container({
      style: { padding: '10px' },
      autoScroll: true
    });
    var cal;
    var tbarr = [
          { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/arrow_left.gif', handler:function(){ cal.fullCalendar("prev") } },
          { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/arrow_right.gif', handler:function(){ cal.fullCalendar("next") } },
          '-',
          { xtype:'button', text:_('Today'), handler:function(){ cal.fullCalendar("today") } },
          '-',
             { xtype:'button', text:_('Day1'), handler:function(){ cal.fullCalendar("changeView", "basicDay") } } ,
          '-',
              { xtype:'button', text:_('Day2'), handler:function(){ cal.fullCalendar("changeView", "agendaDay") } } ,
          '-',
            { xtype:'button', text:_('Week1'), handler:function(){ cal.fullCalendar("changeView", "basicWeek") } } ,
          '-',
          { xtype:'button', text:_('Week2'), handler:function(){ cal.fullCalendar("changeView", "agendaWeek") } } ,
          '-',
          { xtype:'button', text:_('Month'), handler:function(){ cal.fullCalendar("changeView", "month") } } ,
          '-',
          { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/refresh.gif', handler:function(){ cal.fullCalendar("refetchEvents") } }
        ];
    if( c.tbar_end ) tbarr.push( c.tbar_end );
    var panel = new Ext.Panel( Ext.apply({
      layout: 'fit',
      tbar: tbarr,
      items: cal_div
    }, c ));

    cal_div.on('afterrender', function(){
        var date = new Date();
        var d = date.getDate();
        var m = date.getMonth();
        var y = date.getFullYear();
        var el = cal_div.getEl() ;
        var id = el.id ;
        var dt = new Baseliner.DropTarget(el, {
            comp: cal_div,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyEnter: function(ddSource, ev, data) {
                var el = ddSource.getProxy().getGhost();

                $(el.dom).data('eventObject', data );
                var id = el.id;
                //$( el.dom ).css( 'background-color', 'green' );
                $( el.dom ).draggable({
                    addClasses: true,
                    zIndex: 999
                    //revert: true,      // will cause the event to go back to its
                    //revertDuration: 0  //  original position after the drag
                });
                panel.calendar.getView().dragStart(el.dom, ev.browserEvent, null);
                return true;              
            },
            notifyDrop: function(ddSource, ev, data) {
                var el = ddSource.getProxy().getGhost();
                // get drag object data (node or row grid are supported for now)
                var calev; 
                if( data.grid != undefined ) {
                    var row = data.grid.getStore().getAt( data.rowIndex );
                    calev = row.data.calevent != undefined ? row.data.calevent : row.data;
                }
                else if( data.node!=undefined && data.node.attributes!=undefined ) {
                    calev = data.node.attributes.calevent != undefined 
                        ? data.node.attributes.calevent : data.node.attributes;
                }
                else {
                    Baseliner.message( _('Calendar'), _('Calendar object type not allowed') );
                    return false;
                } 
                ev.browserEvent.data = calev;   // store the row data in the event hack
                panel.calendar.getView().dragStop(el.dom, ev.browserEvent, null);  // call the original end of drag event
                return true;
            }
        });

        var event_new_url = c.url_new || '/calendar/event/add';  // this should be the controller that creates events
        var event_new = function( data ) {
            Baseliner.ajaxEval( event_new_url, data, function(res) { 
                if( res && res.success ) {
                    //var allday = res.allday!=undefined ? res.allday : true;
                    // create the event
                    cal.fullCalendar('renderEvent',
                        Ext.apply({
                            title: _('[untitled]')
                            //start: date,
                            //end: date,
                            //allDay: allday
                        }, Ext.apply(data, res.data ) ),
                        true 
                    );
                } else {
                    Baseliner.error( _('Error'), _(res.msg) );
                }
            });
        };

        cal = $( el.dom );
        cal.fullCalendar( Ext.apply({
            height: 300,
            header: false,
            timeFormat: 'H(:mm)',
            dayNames: [_('Sunday'), _('Monday'), _('Tuesday'), _('Wednesday'), _('Thursday'), _('Friday'), _('Saturday')],
            dayNamesShort: [_('Sun'), _('Mon'), _('Tue'), _('Wed'), _('Thu'), _('Fri'), _('Sat')],
            selectable: true,
            selectHelper: true,
            drop: function( date, allday, jsEvent, ui  ) {
                 var opts = jsEvent.data;
                 opts.date = date;
                 opts.allday = allday;
                 event_new( opts );
            },
            eventResizeStop: function( ev, jsEvent, ui, view ) { 
                Baseliner.ajaxEval( '/calendar/event/modify', ev, function(res) { 
                });
            },
            select: function(start, end, allday) {
                if( c.onSelect ) {
                    c.onSelect( cal, start, end, allday );
                }
                cal.fullCalendar('unselect');
            },
            editable: true,
            events: []
        }, c.fullCalendarConfig ));
        panel.calendar = cal.data('fullCalendar'); // new Calendar() in fullcalendar
    });

    panel.fullCalendar = function( p ) {
        return cal.fullCalendar( p );
    };

    panel.on('resize', function(w,w1,h1,w2,h2) { 
      if( cal == undefined ) return;
      cal.fullCalendar('option', 'height', h1 - 80);
      cal.fullCalendar('option', 'width', w1);
      cal.fullCalendar("render");
    });
    return panel;
};

Baseliner.calendar_events = function( start, end, cb ) {
   /* Baseliner.ajaxEval('/events.js', { start: start, end: end }, function(res){
        cb( res.data ); 
   }); */
};

/* 

    Generic CI Store, SuperBox and ComboBox

    var server_store = new Baseliner.store.CI({ baseParams: { role:'Server' } });
    var servers = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('Server'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.server != undefined ) 
            servers.setValue( params.server ) ;            
    });
*/
Baseliner.store.CI = function(c) {
     Baseliner.store.CI.superclass.constructor.call(this, Ext.apply({
        id: 'mid', 
        url: '/ci/store',
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty: 'totalCount', 
        fields: ['mid','item', 'name','collection','class','classname', 'versionid', 'description', 'properties', 'pretty_properties','data', 'icon','moniker'] 
     }, c));
};
Ext.extend( Baseliner.store.CI, Baseliner.JsonStore );

Baseliner.model.CISelect = function(c) {
    //var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">{name} ({class})</div></tpl>' );
    var show_class = c.showClass;
    var tpl_list;

    if ( show_class ) {

        tpl_list = new Ext.XTemplate(
            '<tpl for="."><div class="search-item">',
                //'<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{name}</h3>',
            '<span id="boot" style="background: transparent"><strong>{name}</strong> ({class})</span>',
            '<tpl if="pretty_properties">',
                '<br />{pretty_properties}',
            '</tpl>',
            '</div></tpl>'
        );
    } else {
        tpl_list = new Ext.XTemplate(
            '<tpl for="."><div class="search-item">',
                //'<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{name}</h3>',
            '<span id="boot" style="background: transparent"><strong>{name}</strong></span>',
            '<tpl if="pretty_properties">',
                '<br />{pretty_properties}',
            '</tpl>',
            '</div></tpl>'
        );

    }
    var tpl_field = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    Baseliner.model.CISelect.superclass.constructor.call(this, Ext.apply({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        singleMode: true,
        pageSize: 20,
        loadingText: _('Searching...'),
        resizable: true,
        //emptyText: _('Enter or select topics'),
        triggerAction: 'all',
        itemSelector: 'div.search-item',
        resizable: true,
        mode: 'local',
        fieldLabel: _('CI'),
        typeAhead: true,
            name: 'ci',
            displayField: 'name',
            hiddenName: 'ci',
            valueField: 'mid',
        tpl: tpl_list,
        displayFieldTpl: tpl_field,
        extraItemCls: 'x-tag'
    }, c));
};
Ext.extend( Baseliner.model.CISelect, Baseliner.SuperBox);


Baseliner.model.CICombo = function(c) {
    var resultTpl = new Ext.XTemplate(
        '<tpl for="."><div class="search-item">',
            //'<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{name}</h3>',
        '<span id="boot" style="background: transparent">',
        '<table><tr><td><img src="{icon}" />&nbsp;</td><td><strong>{name}</strong> {[values.classname ? "(" + values.classname + ")" : ""]}</td></tr></table>',
        '</span>',
        '<tpl if="pretty_properties">',
            '<br />{pretty_properties}',
        '</tpl>',
        '</div></tpl>'
    );
    Baseliner.model.CICombo.superclass.constructor.call(this, Ext.apply({
        minChars: 2,
        fieldLabel: _('CI'),
            name: 'ci',
            displayField: 'name',
            hiddenName: 'ci',
            valueField: 'mid',
        msgTarget: 'under',
        forceSelection: true,
        typeAhead: true,
        loadingText: _('Searching...'),
        resizable: true,
        allowBlank: false,
        lazyRender: false,
        pageSize: 20,
        //editable: false,
        //mode: 'local',
        //width: 550,
        //hideTrigger:true,
        triggerAction: 'all',
        tpl: resultTpl,
        itemSelector: 'div.search-item',
        listeners: {
            // delete the previous query in the beforequery event or set
            // combo.lastQuery = null (this will reload the store the next time it expands)
            beforequery: function(qe){
                delete qe.combo.lastQuery;
            }
        }
    }, c));
};
Ext.extend( Baseliner.model.CICombo, Ext.form.ComboBox );

// quick CI Select Box generator
//   usage:
//      Baseliner.ci_box({ name:'repo', class:'BaselinerX::CI::GitRepository', fieldLabel:_('Git Repository'), value: data.repo })

Baseliner.ci_box = function(c) {
    var value = c.value; delete c.value;
    var role = c.role; delete c.role;
    var show_class = c.showClass; delete c.showClass;
    var with_vars = c.with_vars; delete c.with_vars;
    var from_mid = c.from_mid; delete c.from_mid;
    var to_mid = c.to_mid; delete c.to_mid;
	var security = c.security; delete c.security;
    var cl = c['class'] || c['isa'] || c['classname']; delete c['class']; // IE - class is syntax errors due to reserved word
    var bp = {};
    if( cl !=undefined ) bp['class'] = cl;
    if( from_mid != undefined ) bp.from_mid = from_mid;
    if( to_mid != undefined ) bp.to_mid = to_mid;
    else bp.role = role;
    if( with_vars != undefined ) bp.with_vars = with_vars;
    if( c.hiddenName == undefined ) c.hiddenName = c.name;
	if( security != undefined ) bp.security = 1;
    var autoload = c.autoLoad != undefined ? c.autoLoad : true;
    var store = new Baseliner.store.CI({ autoLoad:true, baseParams: bp });
    store.on('load', function(){
        if( c.force_set_value )
           ci_box.setValue( value );
    });
    var ci_box = new Baseliner.model.CISelect(Ext.apply({
        store: store, 
        singleMode: true, 
        mode: 'remote',
        fieldLabel: _('CI'),
        name: 'ci',
        hiddenName: 'ci', 
        allowBlank: true,
        showClass: show_class
    }, c )); 
    if( autoload ) {
        if( value != undefined && value.length > 0 )  {
            store.load({ params: { mids: value } }); 
        } else {
            store.load();
        }
    }
    return ci_box;
};

Baseliner.CIClassCombo = Ext.extend(Baseliner.ComboSingleRemote, {
    fieldLabel: _('CI Class'),
    allowBlank: true,
    field: 'name',
    fields: [ 'classname', 'name' ],
    url: '/ci/classes'
});
    

/* 
     Baseliner.form components
*/
Baseliner.form = {};
Baseliner.form.ComboList = function(c) {
    if( c==undefined ) c={};
    if( c.data==undefined ) c.data=[];
    if( c.name==undefined ) c.name='combo_list';
    if( c.valueField==undefined ) c.valueField=c.name;
    if( c.displayField==undefined ) c.displayField=c.name;

    var arr = [];
    for( var i=0; i<c.data.length; i++) {
        arr.push( [ c.data[i] ] );
    }

    var s=new Ext.data.SimpleStore({
        fields: ['tipo_pet'],
        data:[ arr ]
    });
    
    Baseliner.form.ComboList.superclass.constructor.call(this, Ext.apply({
            store: s,
            displayField: 'tipo_pet',
            valueField: 'tipo_pet',
            name: 'tipo_pet',
            typeAhead: true,
            editable: false,
            mode: 'local',
            forceSelection: true,
            triggerAction: 'all', 
            fieldLabel: 'ComboList',
            emptyText: '',
            selectOnFocus: true
    }, c));
};
Ext.extend( Baseliner.form.ComboList, Ext.form.ComboBox );

Baseliner.model.ComboBaseline = Ext.extend( Ext.form.ComboBox, { 
    mode: 'local',
    fieldLabel: _("Baseline"),
    name: 'bl',
    hiddenName: 'bl',
    valueField: 'bl', 
    displayField: 'bl_name',
    allowBlank: false,
    msgTarget: 'under',
    allowAddNewData: true,
    addNewDataOnBlur: true, 
    singleMode: false,
    loadingText: _('Searching...'),
    resizable: true,
    triggerAction: 'all',
    resizable: true,
    typeAhead: true,
    initComponent: function(){
        var store = new Baseliner.JsonStore({
            root: 'data' , 
            remoteSort: true,
            autoLoad: true,
            totalProperty:"totalCount", 
            baseParams: {}, //{ no_common: true },
            id: 'id', 
            url: '/baseline/json',
            fields: ['id','bl','name','bl_name', 'name_bl', 'description', 'active'] 
        });
        this.store = store;
        var tpl_list = new Ext.XTemplate(
            '<tpl for=".">',
            '<div class="x-combo-list-item"><strong>{[ values.bl == "*" ? _("Common") : values.bl ]}</strong> {[ values.name ? "(" + values.name + ")" : "" ]}</div>',
            '</tpl>'
        );
        this.tpl = tpl_list;
        this.displayFieldTpl = new Ext.XTemplate( '<tpl for=".">{[ values.name ? values.bl + " (" + values.name + ")" : ( values.bl == "*" ? _("Common") : values.bl ) ]}</tpl>' );
        Baseliner.model.ComboBaseline.superclass.initComponent.call(this);
    }
});

Baseliner.store.Baseline = Ext.extend( Baseliner.JsonStore, {
    root: 'data' , 
    remoteSort: true,
    autoLoad: false,
    totalProperty:"totalCount", 
    id: 'id', 
    url: '/baseline/json',
    constructor: function(c){
        Baseliner.store.Baseline.superclass.constructor.call(this,Ext.apply({
            root: 'data', 
            baseParams:{}, 
            fields: ['id','bl','name','bl_name', 'name_bl', 'description', 'active'] 
        }, c) );
    }
});

Baseliner.model.SelectBaseline = function(c) {
    var self = this;
    var tpl_list = new Ext.XTemplate(
        '<tpl for="."><div class="search-item">',
        '<span id="boot"><strong>{[ values.bl == "*" ? _("Common") : values.bl ]}</strong> {name}</span>',
        '</div></tpl>'
    );
    var tpl_field = new Ext.XTemplate( '<tpl for=".">{[ values.bl == "*" ? _("Common") : values.bl ]}</tpl>' );
    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: {}, //{ no_common: true },
        id: 'id', 
        url: '/baseline/json',
        fields: ['id','bl','name','bl_name', 'name_bl', 'description', 'active'] 
    });
    Baseliner.model.SelectBaseline.superclass.constructor.call(this, Ext.apply({
       fieldLabel: _("Baseline"),
           name: 'bl',
           hiddenName: 'bl',
           valueField: 'bl', 
           displayField: 'name',
        store: store,
        allowBlank: false,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        singleMode: false,
        loadingText: _('Searching...'),
        resizable: true,
        //emptyText: _('Enter or select topics'),
        triggerAction: 'all',
        itemSelector: 'div.search-item',
        resizable: true,
        mode: 'local',
        typeAhead: true,
        tpl: tpl_list,
        displayFieldTpl: tpl_field,
        extraItemCls: 'x-tag'
    }, c));
};
Ext.extend( Baseliner.model.SelectBaseline, Ext.ux.form.SuperBoxSelect );

Baseliner.model.Status = function(c) {
    Baseliner.model.Status.superclass.constructor.call(this, Ext.apply({
        allowBlank: false,
        msgTarget: 'under',
        allowAddNewData: false,
        addNewDataOnBlur: false, 
        //emptyText: _('Enter or select topics'),
        triggerAction: 'all',
        resizable: true,
        mode: 'local',
        fieldLabel: _('Status'),
        typeAhead: true,
        name: 'status_new',
        displayField: 'name',
        hiddenName: 'status_new',
        valueField: 'id',
        extraItemCls: 'x-tag'
    }, c));
};
Ext.extend( Baseliner.model.Status, Ext.ux.form.SuperBoxSelect );

Baseliner.ComboStatus = Ext.extend( Baseliner.ComboDoubleRemote, {
    allowBlank: true,
    url: '/ci/status/combo_list', field: 'id_status', displayField: 'name',
    fields: [ 'id_status', 'name' ]
});

/*

A Revision draganddrop superbox inside a form-ready panel.

    var revision_box = new Baseliner.model.RevisionsBoxDD({
        hidden: rec.fields_form.show_revisions ? false : true
    });

    var form = new Ext.form.FormPanel({ items: revision_box });

*/
Baseliner.model.RevisionsBoxDD = function(c) {
    if( c==undefined ) c = {};
    //c.panelConfig = {};
    var revision_box_store = new Baseliner.JsonStore({
        root: 'data' , 
        id: 'id', 
        fields: [
            {  name: 'id' },
            {  name: 'name' }
        ]
    });
    
    var hidden = c.hidden;

    var revision_box = new Baseliner.model.Revisions(Ext.apply({
        store: revision_box_store 
    }, c));
    
    Baseliner.model.RevisionsBoxDD.superclass.constructor.call(this, Ext.apply({
        layout: 'form',
        enableDragDrop: true,
        border: false,
        hidden: hidden,
        style: 'border-top: 0px',
        items: [ revision_box ]
    }, c.panelConfig ));

    var v = c.value;
    revision_box.on('afterrender', function(){
        if( v != undefined ) {
            var s = revision_box.store;
            var revs = v;
            var mids = [];
            for( var i=0; i< revs.length; i++ ) {
                var r = new s.recordType( revs[i], revs[i].mid );
                mids.push( revs[i].mid );
                s.add( r );
                s.commitChanges();
            }
            revision_box.setValue( mids.join(',') );
        }
    });

    revision_box.on('afterrender', function(){
        var el = revision_box.el.dom; 
        var revision_box_dt = new Baseliner.DropTarget(el, {
            comp: revision_box,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var attr = n.attributes;
                var data = attr.data || {};
                var ci = data.ci;
                var mid = data.mid;
                if( mid==undefined && ( ci == undefined || ci.role != 'Revision') ) { 
                    Baseliner.message( _('Error'), _('Node is not a revision'));
                } 
                else if ( mid!=undefined ) { // TODO
                }
                else if ( ci !=undefined ) {
                    Baseliner.ajaxEval('/ci/sync',
                        { name: ci.name, 'class': ci['class'], ns: ci.ns, ci_json: Ext.util.JSON.encode( ci.data ) },
                        function(res) {
                            if( res.success ) {
                                var mid = res.mid ;
                                var s = revision_box.store;
                                var d = { name: attr.text, id: mid };
                                var r = new s.recordType( d, mid );
                                s.add( r );
                                s.commitChanges();
                                //s.loadData( { data: [ d ] }, true );
                                var mids = [ ];
                                var current = revision_box.getValue() ;
                                if( current !=undefined && current != '' ) { mids.push( current ); }

                                s.each(function(sr){
                                    mids.push( sr.id );
                                });
                                //var rec = new Ext.data.Record(, '-1');
                                //var rec = new Ext.data.Record({ name: attr.text, ci: ci, id: mid }, '-1');
                                //s.insert(0,rec);
                                revision_box.setValue( mids.join(',') );
                            }
                            else {
                                Ext.Msg.alert( _('Error'), _('Error adding revision %1: %2', ci.name, res.msg) );
                            }
                        }
                    );
                }
                return (true); 
             }
        });  //droptarget
    });
};
Ext.extend( Baseliner.model.RevisionsBoxDD, Ext.Panel );

/*

A Revision draganddrop grid that is form-ready

    var revision_grid = new Baseliner.model.RevisionsGridDD({
        hidden: rec.fields_form.show_revisions ? false : true
    });

    var form = new Ext.form.FormPanel({ items: revision_grid });

*/
Baseliner.model.RevisionsGridDD = function(c) {
    if( c==undefined ) c = {};
    
    var revision_store = new Ext.data.SimpleStore(Ext.apply({
        fields: ['mid','name','id']
    },c.storeConfig));
    
    var revision_grid = this;
    Baseliner.model.RevisionsGridDD.superclass.constructor.call(this, Ext.apply({
        store: revision_store,
        layout: 'form',
        height: 120,
        fieldLabel: _('Revisions'),
        hideHeaders: true,
        viewConfig: {
            headersDisabled: true,
            enableRowBody: true,
            //scrollOffset: 2,
            forceFit: true
        },
        columns: [
          //{ header: _('ID'), width: 60, hidden: true, dataIndex: 'id' },
          { header: '', width: 20, dataIndex: 'id', renderer: function(){ return '<img style="float:right" src="/static/images/icons/tag.gif" />'} },
          { header: _('Name'), width: 240, dataIndex: 'name',
              renderer: function(v,metadata,rec){
                  return Baseliner.render_wrap( String.format('<span id="boot"><h5>{0}</h5></span>', v ) );
              }
          },
          { width: 20, dataIndex: 'mid',
              renderer: function(v,meta,rec,rowIndex){
                  return '<a href="javascript:Baseliner.delete_revision(\''+revision_grid.id+'\', '+v+')"><img style="float:middle" height=16 src="/static/images/icons/clear.png" /></a>'
              }
          }
        ]
    }, c ));
    
    this.mid_data = {};
    Baseliner.delete_revision = function( id_grid, mid ) {
        var g = Ext.getCmp( id_grid );
        delete g.mid_data[ mid ];
        revision_grid.refreshField();
    };
    // a hidden form field, needed for this to save data in a form
    revision_grid.field = new Ext.form.TextField(Ext.apply({ name:'revisions' },c.fieldConfig));
    revision_grid.refreshField = function(){
        var mids = [];
        var s = revision_grid.getStore();
        s.removeAll();
        s.commitChanges();
        for( var mid in revision_grid.mid_data ) {
            var d = revision_grid.mid_data[ mid ];
            var r = new s.recordType( d, mid );
            s.add( r );
            mids.push( mid );
        }
        s.commitChanges();

        if( mids.length == 0 ) {
            revision_grid.field.setValue( '' );
        } else  {
            revision_grid.field.setValue( mids.join(',') );
        }
    };
    revision_grid.on( 'afterrender', function(){
        if( c.value != undefined ) {
            // TODO no loader from mids yet 
        }
        var el = this.el.dom; 
        var revision_box_dt = new Baseliner.DropTarget(el, {
            comp: this,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                //var s = project_box.store;
                var attr = n.attributes;
                var data = attr.data || {};
                var ci = data.ci;
                var mid = data.mid;
                if( mid==undefined && ( ci == undefined || ci.role != 'Revision') ) { 
                    Baseliner.message( _('Error'), _('Node is not a revision'));
                } 
                else if ( mid!=undefined ) {
                    // TODO
                }
                else if ( ci !=undefined ) {
                    Baseliner.ajaxEval('/ci/sync',
                        { name: ci.name, 'class': ci['class'], ns: ci.ns, ci_json: Ext.util.JSON.encode( ci.data ) },
                        function(res) {
                            if( res.success ) {
                                var mid = res.mid ;
                                var d = { name: attr.text, id: mid, mid: mid };
                                revision_grid.mid_data[ mid ] = d;
                                revision_grid.refreshField()
                            }
                            else {
                                Ext.Msg.alert( _('Error'), _('Error adding revision %1: %2', ci.name, res.msg) );
                            }
                        }
                    );
                }
                return (true); 
             }
        });
    }); 
};
Ext.extend( Baseliner.model.RevisionsGridDD, Ext.grid.GridPanel );

/*

Flot plotting

*/
Baseliner.flot = {};
Baseliner.flot.Base = Ext.extend( Ext.Container, {
    redrawing: 0,
    constructor : function(c){
        if( c==undefined ) c={};
        var data = c.data;
        delete c.data;
        var w = c.width == undefined ? 200 : c.width;
        var h = c.height == undefined ? 200 : c.height;
        Baseliner.flot.Base.superclass.constructor.call(this,
            Ext.apply({ style:{width: w, height: h, background:'white'} }, c)
        );
        var self = this;
        self.on('resize', function(){
            if( self.redrawing ) return;
            if( !self.plot ) return;
            var placeholder = self.plot.getPlaceholder();
            // somebody might have hidden us and we can't plot
            // when we don't have the dimensions
            if (placeholder.width() == 0 || placeholder.height() == 0)
                return;
            ++self.redrawing;
            $.plot(placeholder, self.plot.getData(), self.plot.getOptions());
            --self.redrawing;
        });
        self.on('afterrender',function(){
            self.plot = $.plot( $(self.el.dom ), data, c.plotConfig );
        });
    }
});

Baseliner.flot.Donut = function(c) {
    if( c==undefined ) c={};
    var data = c.data;
    delete c.data;
    // fake data
    if( data == undefined ) {
        var series = 3;
        data=[];
        for( var i = 0; i<series; i++)
        {
            data[i] = { label: "Series "+(i+1), data: Math.floor(Math.random()*100)+1 } 
        }
    }
    Baseliner.flot.Donut.superclass.constructor.call(this, Ext.apply({
        plotConfig: Ext.apply({
           colors: ["#F90", "#222", "#777", "#AAA"],
            series: {
                pie: { 
                    innerRadius: 0.5,
                    show: true
                }
            }
        }, c.plotConfig),
        data: data    
    }, c ));
};
Ext.extend( Baseliner.flot.Donut, Baseliner.flot.Base ); 

Baseliner.flot.Area = function(c) {
    if( c==undefined ) c={};
    var data = c.data;
    delete c.data;
    // fake data
    if( data == undefined ) {
        var data = [], totalPoints = 200;
        function getRandomData() {
            if (data.length > 0)
                data = data.slice(1);
            while (data.length < totalPoints) {
                var prev = data.length > 0 ? data[data.length - 1] : 50;
                var y = prev + Math.random() * 10 - 5;
                if (y < 0)
                    y = 0;
                if (y > 100)
                    y = 100;
                data.push(y);
            }
            var res = [];
            for (var i = 0; i < data.length; ++i)
                res.push([i, data[i]])
            return res;
        }
        data = [ getRandomData() ];
    }
    // setup plot
    var options = {
        yaxis: { min: 0, max: 100 },
        xaxis: { min: 0, max: 100 },
        colors: ["#F90", "#222", "#666", "#BBB"],
        series: {
                   lines: { 
                        lineWidth: 2, 
                        fill: true,
                        fillColor: { colors: [ { opacity: 0.6 }, { opacity: 0.2 } ] },
                        steps: false

                    }
               }
    };
    
    Baseliner.flot.Area.superclass.constructor.call(this, Ext.apply({
        plotConfig: Ext.apply( options, c.plotConfig),
        data: data    
    }, c));
};
Ext.extend( Baseliner.flot.Area, Baseliner.flot.Base ); 

/*

  Kanban Panel 

  There are 3 usage modes:

  topic mids list:
      new Baseliner.Kanban({ topics: [ 1,2,3 ] }).fullscreen();


  topic store:
      new Baseliner.Kanban({ store: store }).fullscreen();

  topic store provided, but filtered:
      new Baseliner.Kanban({ store: store, topics: [ 1,2,3 ] }).fullscreen();

*/

Baseliner.Kanban = Ext.extend( Ext.ux.Portal, {
    //margins:'5 5 5 0',
    height: 400, 
    width: 800,
    is_fullscreen : false,
    is_tab : false,
    background: "#555 url('/static/images/bg/cork.jpg')",
    title: _('Kanban'),
    header: false,
    constructor : function(c) {
        Baseliner.Kanban.superclass.constructor.call(this, Ext.apply({
            mids: [],
            layoutCfg: {
                renderHidden: true
            }
        },c));
    },
    initComponent : function(){
        var self = this;
        self.addEvents( 'tab' );
        self.statuses_hash = {};
        self.column_by_status = {};
        self.status_btn = new Ext.Button({ text:_('Statuses'), menu:[] });
        self.tab_btn = new Ext.Button({ 
            icon:'/static/images/icons/tab.png', iconCls:'x-btn-icon',
            handler: function(){
                if( self.is_tab ) 
                    self.fullscreen();
                else 
                    self.goto_tab();
            }
        });
        self.bodyCfg = { 
            style: {
             'background': self.background,
             'background-repeat': 'repeat'
            }
        };
        self.tbar = [ 
            '<img src="/static/images/icons/kanban.png" />',
            'KANBAN',
            '-',
            { icon:'/static/images/icons/refresh.gif', iconCls:'x-btn-icon', handler: function(){ self.refresh() } },
            self.status_btn,
            '->',
            self.tab_btn,
            { icon:'/static/images/icons/close.png', iconCls:'x-btn-icon', handler: function(){ 
                    if( self.fireEvent('beforeclose') === false ) {
                        return;
                    }
                    self.destroy();
                    if( ! self.is_tab ) {
                        //Baseliner.viewport.remove( kanban );
                        Baseliner.main.getEl().show();
                        Baseliner.viewport.getLayout().setActiveItem( 0 );
                    }
                    self.fireEvent('close');
                }
            }
        ];

        self.on('afterrender', function(cmp){
            // load data
            self.load_data();
        });

        self.on('dragstart', function(e) {
            var portlet = e.panel;
            var mid =  portlet.mid;
            var id_status_current = portlet.id_status;
            var dests = {};
            // reconfigure workflow
            var wk = self.workflow[ mid ];
            if( wk ) {
                for( var i=0; i<wk.length; i++ ) {
                    if( wk[i].id_status_from == id_status_current ) {
                        dests[ wk[i].id_status_to ] = true;
                    }
                }
            }
            // mask columns
            var cols = self.items.items;
            // find the highest column
            var max_height = 0;
            Ext.each( cols, function(c){
                var h = c.el.getHeight();
                if( h > max_height )
                    max_height = h;
            });
            if( self.body.getHeight() -10  > max_height ) {
                max_height = self.body.getHeight() - 10;
            }
            Ext.each( cols, function(c){
                var el = c.getEl();
                el.setHeight( max_height );  // so that the mask have the full length
                var id_status = c.id_status;
                if( dests[ id_status ] != true && id_status != id_status_current ) {
                    var m = el.mask();
                    c.drop_available = false;
                } else {
                    c.drop_available = true;
                }
            });
        });
        self.on('beforedragover', function(e){
            return e.column.drop_available; //==undefined ? false : e.column.drop_available;
        });
        self.on('beforedrop', function(e){
            var col = e.column;
            Ext.each( self.items.items, function(c) {
                var el = c.getEl();
                el.unmask();
                el.setHeight('auto');
                //c.doLayout();
            });
            // send data to server
            var portlet = e.panel;
            portlet.change_status( col.id_status, function(res){
                if( !res.success ) {
                    Baseliner.warning( _('Kanban'), _(res.msg) );
                    // send portlet back to where it came from
                    var old_status = portlet.id_status;
                    var old_column_id = self.column_by_status[ old_status ]; 
                    var old_column = Ext.getCmp( old_column_id );
                    if( old_column ) {
                        old_column.add( portlet );
                        old_column.doLayout();
                    } else {
                        portlet.destroy();
                    }
                } else {
                    // update portlet data
                    var previous_id_status = portlet.id_status;
                    portlet.id_status = e.column.id_status;
                }
            });
            return true;
        });
        /*
        self.on('drop', function(e){
        });
        */

        Baseliner.Kanban.superclass.initComponent.call(this);
    },
    print_hook : function(){
        return { title: this.title, id: this.body.id };
    },
    fullscreen : function(){
        var self = this;
        self.is_fullscreen = true;
        self.is_tab = false;
        Baseliner.viewport.add( self );
        Baseliner.viewport.getLayout().setActiveItem( self );
    },
    goto_tab : function(){
        var self = this;
        self.is_tab = true;
        var params = { tab_icon: '/static/images/icons/kanban.png' };  
        self.tab_info = { type: 'object', params: params }; // XXX this should be simplified
        var id = Baseliner.addNewTabItem( self, self.title, params );
        if( self.is_fullscreen ) {
            Baseliner.viewport.remove( self, false );
            Baseliner.main.getEl().show();
            Baseliner.viewport.getLayout().setActiveItem( 0 );
        }
        self.is_fullscreen = false;
        self.fireEvent( 'tab', id );
    },
    check_column : function(opt){
        var self = this;
        var id_status = opt.id_status;
        self.items.each( function(i){
            if( i.id_status == id_status ) {
                if( opt.checked && ! i.isVisible() ) { // show
                    i.show();
                } else if( i.isVisible() ) { // hide
                    i.hide();
                }
                self.reconfigure_columns();
            }
        });
    },
    refresh : function(){
        var self =this;
        self.removeAll();
        self.store = null;
        self.load_data();
    },
    load_data : function() {
        var self = this;
        self.el.mask( _('Loading...'), 'x-mask-loading');
        if( ! self.store ) {
            if( Ext.isArray( self.topics ) && self.topics.length > 0 ) {
                // create my own store
                self.store = new Baseliner.Topic.StoreList({
                    baseParams: { start: 0, topic_list: self.topics }   // query_id
                });
                self.store.on('load', function(){
                    self.load_workflow( self.topics );
                });
                self.store.load();
            } else {
                // no topics to show
                Baseliner.warning( _('Kanban'), _('No topics available') );
                self.el.unmask();
            }
        }
        else {
            var filtered_mids = {};
            var filtered_mode = Ext.isArray(self.topics) && self.topics.length > 0 ? true : false;
            Ext.each( self.topics, function(mid){ filtered_mids[mid] = true; });
            self.store.each( function(rec) {
                // if we have a list of mids, check if row is in list
                if( filtered_mode && !mids_hash[mid] ) return;
                self.topics.push( rec.data.topic_mid );
            });
            self.load_workflow( self.topics );
        }
    },
    load_workflow : function(topics) {
        var self = this;
        Baseliner.ajaxEval( '/topic/kanban_status', { topics: topics }, function(res){
            if( res.success ) {
                //console.log( res.workflow );
                var statuses = res.statuses;
                var workflow = res.workflow;
                var col_num = statuses.length;
                var col_width = 1 / col_num;
                var btns = [];
                self.workflow = workflow;

                var add_column = function( id_status, name ) {
                   var status_title = '<span style="font-family:Helvetica Neue,Helvetica,Arial,sans-serif; padding: 4px 4px 4px 4px">' + _(name) + '</span>';
                   // create columns
                   var col_obj = new Baseliner.KanbanColumn({
                      xtype: 'kanbancolumn',
                      title: status_title,
                      columnWidth: col_width,
                      id_status: id_status
                   });
                   self.add( col_obj );
                   self.column_by_status[ id_status ] = col_obj.id;
                };
                for( var i=0; i<col_num; i++ ) {
                    add_column( statuses[i].id, statuses[i].name );
                    self.statuses_hash[ statuses[i].name ] = i;  // store colnum for status
                }

                for( var k=0; k< statuses.length; k++ ) {
                    self.status_btn.menu.addMenuItem({ id_status: statuses[k].id, text: statuses[k].name, checked: true, checkHandler: function(opt){ return self.check_column(opt) } });
                }

                self.render_me();
                self.fireEvent( 'ready', res );
            } else {
                Ext.Msg.alert( _('Error'), res.msg );
            }
        });
    },
    reload : function(){  // used by topics when refreshing _parent_grid
        var self = this;
        self.refresh(); 
    },
    create_portlets : function( id_status ){
        var self = this;
        self.store.each( function(rec) {
            var mid = rec.data.topic_mid;
            if( id_status != undefined && rec.data.category_status_id != id_status ) return;
            var t = String.format('{0} #{1}', rec.data.category_name, mid );
            var cat = '<div id="boot"><span class="label" style="float:left;width:95%;background: '+ rec.data.category_color + '">' + rec.data.category_name + ' #' + mid + '</span></div>';
            var txt = String.format('<span id="boot">{0}<br /><h5>{1}</h5></span>', cat, _( rec.data.title ) );
            //var txt = String.format('<span id="boot"><h5>{0}</h5></span>', rec.data.title);
            var col = self.statuses_hash[ rec.data.category_status_name ];
            // portlet contents
            var contents = new Ext.Container({ html: txt, style:'padding: 2px 2px 2px 2px', autoHeight: true, mid: mid });
            contents.on('afterrender', function(){ 
                // double-click on portlet opens either window or tab
                this.ownerCt.body.on('dblclick',function(){ 
                    var title = rec.data.topic_name;
                    var params = { topic_mid: mid, title: _( title ), _parent_grid: self.id };
                    if( self.is_tab ) {
                        Baseliner.add_tabcomp( '/topic/view', _(title), params );
                    } else {
                        params.window_mode = true;
                        Baseliner.ajaxEval( '/topic/view', params, function(topic_panel) {
                            var win = new Baseliner.Window({
                                layout: 'fit', 
                                tabifiable : true,
                                //modal: true,
                                autoScroll: true,
                                style: { overflow: 'hide' },
                                border: false,
                                title: _(title),
                                height: 600, width: 1000, 
                                maximizable: true,
                                items: topic_panel
                            });
                            //topic_panel.on('afterrender', function(){ topic_panel.header.hide() } );
                            topic_panel.title = undefined;
                            topic_panel._parent_window = win.id;
                            win.show();
                        });
                    }
                });
            });
            self.add_portlet({ 
              title: _(t),
              comp: contents, 
              mid: mid,
              id_status: rec.data.category_status_id,
              portlet_type: 'comp',
              col: col,
              url_portlet: 'http://xxxx', url_max: 'http://xxxx'
            });
        });
    },
    // method to reconfigure all columnwidths
    reconfigure_columns :  function(){
        var self = this;
        var cols = self.items.items;
        var col_num = 0;
        for( var i = 0; i<cols.length; i++ ) {
            if( ! cols[i].hidden ) col_num++;
        }
        var col_width = 1/col_num;
        for( var i = 0; i<cols.length; i++ ) {
            cols[i].columnWidth = col_width;
        };
        self.doLayout();
    },
    render_me : function(){
        var self = this;
        self.create_portlets();
        self.doLayout();

        // show/hide tools for the column 
        var cols = self.findByType( 'kanbancolumn' );
        for( var i = 0; i<cols.length; i++ ) {
            cols[i].header.on( 'mouseover', function(ev,obj){
                var col_obj = Ext.getCmp( obj.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                if( col_obj != undefined ) {
                    var t = col_obj.getTool('close');
                    var w = col_obj.el.dom.offsetWidth;
                    t.setStyle('display','block');
                    t.setStyle('position','absolute');
                    t.setStyle('margin-left', w-30 );
                }
            });
            cols[i].header.on( 'mouseout', function(ev,obj){
                var col_obj = Ext.getCmp( obj.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.id );
                if( col_obj == undefined ) col_obj = Ext.getCmp( obj.parentNode.parentNode.parentNode.id );
                if( col_obj != undefined ) col_obj.getTool('close').hide();
            });
        };
        self.el.unmask();
    },
    add_portlet : function( params ) {
        var self = this;
        var col = params.col || 0;
        var comp = params.comp;
        comp.height = comp.height || 350;
        var title = comp.title || params.title || 'Portlet';
        //comp.collapsible = true;
        var cols = self.items.items;
        var column_obj = self.findById( cols[col].id );
        var portlet = {
            height: 50,
            autoHeight: true,
            header: false,
            footer: false,
            //collapsible: true,
            title: _( title ),
            mid: params.mid,
            id_status: params.id_status,
            //headerCfg: { style: 'background: #d44' },
            portlet_type: params.portlet_type,
            footerCfg: { hide: true },
            //url_portlet: params.url_portlet,
            url_max: params.url_max,
            //tools: Baseliner.portalTools,  // tools are visible when header: true
            //collapsed: true,
            items: comp
        };
        var portlet_obj = column_obj.add( portlet );
        portlet_obj.change_status = function(new_status, cb){
            if ( new_status != portlet_obj.id_status ){                
                Baseliner.ajaxEval( '/topic/change_status', { _handle_res: true, mid: portlet_obj.mid, old_status: portlet_obj.id_status, new_status: new_status }, function(res){
                    if( Ext.isFunction(cb) ) cb(res);
                });
            }
        };
        return portlet_obj;
        //column_obj.doLayout();
    }
});

Baseliner.KanbanPortlet = Ext.extend( Ext.util.Observable, {
    height: 50,
    autoHeight: true,
    header: false,
    footer: false
});

// Each column is a Panel (so that we have a title)
Baseliner.KanbanColumn = Ext.extend(Ext.Panel, {
    layout: 'anchor',
    autoEl: 'div',
    border: true,
    resizeable: true,
    tools: [{
        id:'close',
        hidden: true,
        handler: function(e, target, column_panel){
            var kanban = column_panel.ownerCt;
            column_panel.hide();
            //column_panel.ownerCt.remove(column_panel, true);
            kanban.reconfigure_columns();
            // remove check from menu
            var id_status = column_panel.initialConfig.id_status;
            kanban.status_btn.menu.items.each( function(i) {
                if( i.initialConfig.id_status == id_status  )
                    i.setChecked(  false );
            });
        }
    }],
    style: {
        margin: '2px 2px 2px 2px',
        //'border': '2px solid transparent',
        padding: '6px 2px 6px 2px'
    },
    headerCfg: {
        style: {
            'background-color': '#eee', color: '#555', height: '30px', 'text-transform': 'uppercase', 'font-weight':'bold',
            margin: '0px 0px 8px 0px',
            padding: '2px 2px 2px 2px',
            'font-size':'10px'
        }
    },
    bodyCfg: { 
        style: {
            margin: '0px 0px 0px 0px',
            padding: '2px 2px 2px 2px',
            'background': "transparent",
            'background-repeat': 'repeat'
        }
    },
    defaultType: 'portlet',
    cls:'x-portal-column'
});
Ext.reg('kanbancolumn', Baseliner.KanbanColumn);

/*

    Generates a Wizard-like CardLayout Panel.

    var panel = new Baseliner.Wizard({
        done_handler: function(panel) {
        },
        items: [ form1, form2 ]
    });


*/
Baseliner.Wizard = function(config) {
    var self = this;
    self.current = config.current==undefined ? 0 : config.current;
    self.first = config.first==undefined ? 0 : config.first;
    self.last = config.last==undefined ? config.items.length-1 : config.last;
    self.button_setup = function(){
        if( self.current == self.first ) bback.disable();
        if( self.current > self.first ) bback.enable();
        if( self.current == self.last ) {
            bdone.show();
            bnext.hide();
        }
    };
    var navHandler = function(direction){
        self.current += direction;
        if( direction < 0 ) {
            bdone.hide();
            bnext.show();
        }
        self.button_setup();
        this.getLayout().setActiveItem( self.current ); 
    };
    var bback = new Ext.Button({
                text: _('Back'),
                handler: navHandler.createDelegate(this, [-1]),
                disabled: true
            });
    var bnext = new Ext.Button({
                text: _('Next'),
                handler: navHandler.createDelegate(this, [1])
            });
    var bdone = new Ext.Button({
                text: _('Done'),
                hidden: true,
                handler: function(){
                    config.done_handler(this);
                }
            });
    Baseliner.Wizard.superclass.constructor.call(this, Ext.apply({
        layout:'card',
        activeItem: 0, // make sure the active item is set on the container config!
        bodyStyle: 'padding:15px',
        defaults: { border: false },
        bbar: [
            '->', bback, bnext,bdone
        ]
    }, config ));
    this.on( 'afterrender', function(){ self.button_setup() });
};
Ext.extend( Baseliner.Wizard, Ext.Panel ); 

/*

 Baseliner.DataEditor - a Registry like data editor

 Usage:
    
    var tree = new Baseliner.DataEditor({
        data: { aa: 11, bb: [ 'x','y','z' ], cc: [{ mm:99 },{ nn:88 }] },
        metadata: { 
            aa: { value: [ 1, 2, 3 ], read_only: true },
            'cc.mm': { value: { 'Young': 18, 'Old': 70 } }
        }
    });

    var w = new Ext.Window({ layout:'fit',width:400, height:400, items: tree });
    w.show();
    tree.on('destroy', function(){
       // console.log( tree.data );
       w.close();
    });

*/
Baseliner.get_keys = function(obj){
   var keys = [];
   for(var key in obj){
      keys.push(key);
   }
   return keys;
};

Baseliner.DataEditor = function(c) {
    var self = this;
    self.addEvents('save');
    var Record = Ext.data.Record.create([  // Record is a Class
        {name: 'key'},
        {name: 'key_long'},
        {name: 'type'},
        {name: 'value'},
        {name: '_is_leaf', type: 'bool'},
        {name: '_id', type: 'int'},
        {name: '_parent', type: 'int'}
    ]);
    var id;
    var data;
    // recursively flatten data into a adjacency list formatted for the tree
    //   turns input `d` into global store array `data`
    var flatten = function( d, parent, parent_key ) {
       if( Ext.isArray( d ) ) {
         var cnt=0;
         for( var i=0; i<d.length; i++) {
           var myid = id++;
           var v = flatten( d[i], myid, parent_key );
           data.push({ key: '['+i+']', key_long: parent_key, type:v[2], value:v[0], _is_leaf:v[1], _id: myid,_parent:parent });
           cnt++;
         }
         var _is_leaf = cnt > 0 ? false : true;
         return ['',_is_leaf,'Array', cnt];
       } else if( Ext.isObject(d) ) {
         var cnt=0;
         var keys = Baseliner.get_keys(d);
         Ext.each( keys.sort(), function(k){
           var myid = id++;
           var v = flatten(d[k], myid, k);
           var key_long = parent_key ? parent_key + '.' + k : k;
           var row = { key: k, key_long: key_long, type: v[2], value: v[0], _is_leaf: v[1], _id: myid, _parent: parent }; 
           data.push(row);
           cnt++;
         });
         var _is_leaf = cnt > 0 ? false : true;
         return ['',_is_leaf,'Hash',cnt];
       } else {
         return [d,true,'Value',1];
       }
    };
    //console.log( c.data );
    var set_data = function( d) {
        id = 1;
        data=[];
        flatten( d );
        data = data.sort( function(a,b){ return a._id < b._id ? -1 : 1 });
    }

    set_data( c.data );
    
    var ci_mids = [];
    
    var proxy = new Ext.data.MemoryProxy(data);
    var store = new Ext.ux.maximgb.tg.AdjacencyListStore({  
        autoLoad : true,
        reader: new Ext.data.JsonReader({id: '_id'}, Record),
        // WARN: sorting breaks hashing and array rendering
        // remoteSort: false,
        // sortInfo: { field: 'key', direction: 'ASC' },
        proxy: proxy
    });
    self.store = store;

    var textedit_key = new Ext.grid.GridEditor(new Ext.form.TextField(), {
                offsets : [-4, -5],
                realign : function(auto_size) {
                    var size;
                    textedit.boundEl = textedit.boundEl.child('.ux-maximgb-tg-mastercol-editorplace');
                    Ext.grid.GridEditor.prototype.realign.call(this, auto_size);
                    size = this.boundEl.getSize();
                    this.setSize(size.width + 10, size.height);
                }
            });
    var textedit = new Ext.form.TextField();
    var render_key = function(v) {
      return '<b>' + v + '</b>'
    };
    var render_value = function(v,meta,rec){
        var ty = rec.data.type;
        if( ty == 'Value' ) {
            return Baseliner.render_wrap( '<pre>'+v+'</pre>' ); //'<span class="ux-maximgb-tg-mastercol-editorplace">' + v + '</span>'
        } else if( ty == 'CI' ) {
            return v;
        } else {
            return ''; //Ext.encode( v );  // hide 
        }
    };

    var collapse_data = function( rows, id_parent ){
        var ret = {};
        Ext.each( rows, function(rec){
            var row = rec.data;
            if( row._parent == id_parent ) {
                var v = row.value;
                if( row.type == 'Value' ) {
                    ret[ row.key ] = v;
                }
                else if( row.type == 'Array' ) {
                    var chi = [];
                    var arr = collapse_data( rows, row._id );
                    Ext.each( arr, function( arow ) {
                        for( var k in arow ) {
                            chi.push( arow[ k ] );
                        }
                    });
                    ret[ row.key ] = chi;
                }
                else if( row.type == 'Hash' ) {
                    var chi = collapse_data( rows, row._id );
                    ret[ row.key ] = chi;
                }
            }
        });
        return ret;
    };
    var view_editor = function(){
        var v = json_text.getValue() ;
        if( v ) {
            var ret = Ext.util.JSON.decode( v );
            //store.removeAll();
            //store.reload();
            set_data( ret );
            store.proxy = new Ext.data.MemoryProxy( data );
            store.reload();
        }
        self.getLayout().setActiveItem( 0 );
    };
    var btn_editor = new Ext.Button({
        tooltip: _('Edit'), icon:'/static/images/icons/table_edit.png', handler: view_editor,
        pressed: true, allowDepress:false, enableToggle:true, toggleGroup:'dataeditor-btn'});

    var view_json = function(){
        var ret = collapse_data( store.getRange(), 0 );
        json_text.setValue( Ext.util.JSON.encode( ret ) ); 
        self.getLayout().setActiveItem( 1 );
    };
    var btn_json = new Ext.Button({
        tooltip: _('JSON'), icon:'/static/images/icons/script_edit.png', handler: view_json,
        allowDepress:false, enableToggle:true, toggleGroup:'dataeditor-btn'});

    var close_comp = function( saved ){
        self.data = saved ? self.getData() : c.data;
        self.json = Ext.util.JSON.encode( self.data );
        // call onDestroy
        if( c.on_save ) c.on_save( self, self.data, self.json );
        self.fireEvent('save', self, self.data, self.json);
        if( ! c.save_only ) self.destroy();
    };

    self.getData = function(){
        return collapse_data( store.getRange(), 0 );
    };
    self.setData = function(v) {
        set_data( v );
        store.proxy = new Ext.data.MemoryProxy( data );
        store.reload();
    };

    self.addSingle = function(k,v){
        var rec = new Record({ key: k || '???', value: v || '???', type: 'Value', _id: ++id, _is_leaf: true, _parent: 0 });
        store.add( rec );
    }
    var add_row = function(){
        var sel = tree.getSelectionModel().getSelected(); 
        if( sel ) {
            if( sel.data.type == 'Hash' ) {
                var rec = new Record({ key: '???', value: '???', type: 'Value', _id: ++id, _is_leaf: true, _parent: sel.data._id });
                sel.data._is_leaf = false;
                store.add( rec );
                store.expandNode( sel );
            } 
            else if( sel.data.type == 'Array' ) {
                var rec = new Record({ key: '[...]', value: '???', type: 'Value', _id: ++id, _is_leaf: true, _parent: sel.data._id });
                sel.data._is_leaf = false;
                store.add( rec );
                store.expandNode( sel );
            }
            else {
                self.addSingle(sel.data.key, sel.data.value);
            }
        } else {
            self.addSingle();
        }
    };
    self.add_var = function( key, type, value ) {
        var rec = new Record({ key: key, value: value, type: type, _id: ++id, _is_leaf: true, _parent: 0 });
        store.add( rec );
    };

    self.del_row = function(){
       var rec = tree.getSelectionModel().getSelected(); 
       if( rec ) {
          store.remove( rec );
       }
    };
    var tbar = [
        btn_editor,
        btn_json,
        '-',
        { icon:'/static/images/icons/add.gif', handler: add_row },
        { icon:'/static/images/icons/delete.gif', handler: self.del_row },
        '->' 
    ];

    if( c.name || self.name ) {
        self.name = c.name;
        self.get_save_data = function(){ return collapse_data( store.getRange(), 0 ) };
    }

    if( ! c.hide_cancel )  tbar.push( { text:_('Cancel'), icon:'/static/images/icons/close.png', handler: function(){ close_comp(false) } } );
    if( ! c.hide_save )  tbar.push({ text:_('Save'), icon:'/static/images/icons/save.png', handler: function(){ close_comp(true) } } );

    var cols = [];
    cols.push({ id:'key', header: _("Key"), width: c.col_key_width || 50, sortable: false, dataIndex: 'key', editor: textedit, renderer: render_key });
    if( ! c.hide_type )
        cols.push({header: _("Type"), width: 35, sortable: false, dataIndex: 'type', renderer: function(v){ return _(v) }});
    cols.push({header: _("Value"), width: c.col_value_width || 150, sortable: true, dataIndex: 'value', editor: textedit, renderer: render_value });

    if( c.cols ) {
        cols.push( c.cols );
    }

    var cm = new Ext.grid.ColumnModel({
      columns: cols,      
      getCellEditor: function( col, row) {
        //config[col].setCellEditor( textedit );
        var editor;
        var read_only = false;
        if( col == 2 && self.metadata ) {
           var rec = store.getAt(row);
           var key_meta = self.metadata[ rec.data.key_long ];

           if( key_meta ) {
              var v = key_meta.value;
              if( key_meta.read_only ) {
                 read_only = key_meta.read_only;
              }
              if( key_meta.value ) {
                 if( Ext.isArray( v ) ) {
                     var arr=[];
                     Ext.each( v, function(i){ arr.push([ i,i ]); } );
                     editor = new Ext.form.ComboBox({
                        typeAhead: true, triggerAction:"all", lazyRender: true,
                        readOnly: read_only,
                        store: arr
                     });
                 }
                 else if( Ext.isObject(v) ) {
                     var arr=[];
                     for( var k in v){  arr.push([ k, v[k] ]) }
                     editor = new Ext.form.ComboBox({
                        typeAhead: true, triggerAction:"all", lazyRender: true,
                        readOnly: read_only,
                        store: arr
                     });
                 }
              } 
           }
        }
        if( ! editor ) {
            if( col == 0 ) {
                var rec = store.getAt(row);
                editor = new Ext.form.TextField({ value: rec.get('key'), selectOnFocus: true });
            } 
            else if( col == 1 ) {
                var rec = store.getAt(row);
                editor = new Baseliner.ComboSingle({ value: rec.get('type'), data:['Value', 'Hash','Array', 'CI'] });
            }
            else if( col == 2 ) {
                var rec = store.getAt(row);
                if( rec.get('type') == 'Value' ) {
                    editor = new Ext.form.TextArea({ value: rec.get('value'),
                        style:{ 'font-family':'Consolas, Courier New' }, 
                        selectOnFocus: true, readOnly: read_only });
                } else {
                    (function(){
                    var st = new Baseliner.store.CI({ baseParams:{ role: 'Infrastructure' } });
                    editor = new Baseliner.model.CICombo({ 
                        store: st, value: rec.get('value'), singleMode: true, allowBlank: false
                    });
                    })();
                }
            }
        }
        this.setEditor( col, editor );
        return Ext.grid.ColumnModel.prototype.getCellEditor.call(this, col, row);
      },
      isCellEditable: function(col, row) {
          if( col == 0 ) return true; // the key is always editable
          if( col == 1 ) return true; // not sure about the type
          var rec = store.getAt(row);
          if( rec.data.type=='Value' || rec.data.type=='CI' ) return true;
             else return false;
          return Ext.grid.ColumnModel.prototype.isCellEditable.call(this, col, row);
      }
    });
    var tree = new Ext.ux.maximgb.tg.EditorGridPanel( Ext.apply({
        store: store,
        colModel: cm,
        master_column_id : 'key',
        stripeRows: true,
        cls: 'de-grid',
        autoExpandColumn: 'key',
        //plugins: expander,
        viewConfig : {
            forceFit: true,
            enableRowBody : true,
            getRowClass: function(record, rowIndex, rowParams, store){
                return 'de-grid'; 
            }
        }
    }, c.editorConfig ));
	
    self.editor = tree;

    var json_text = new Ext.form.TextArea({ });

    Baseliner.DataEditor.superclass.constructor.call(this, Ext.apply({
        layout: 'card',
        tbar: tbar,
        activeItem: 0,
        items: [ tree, json_text ]
    }, c));

    /* tree.on('beforeedit', function(e){
        Baseliner.xxx = tree;
        //var ed = tree.colModel.getCellEditor( e.col, e.row );
        //console.log( ed );
        return true;
    }); */
    /* tree.on('afteredit', function(e){
        e.record.commit();
        store.commitChanges();
        //console.log( store.getRange() );
        return true;
    }); */
};
Ext.extend( Baseliner.DataEditor, Ext.Panel ); 

Baseliner.AutoGrid = Ext.extend( Ext.grid.EditorGridPanel, {
    open_win: function(){
        var sm = this.getSelectionModel();
        if( ! sm.hasSelection() ) return;
        var cell = sm.getSelectedCell();
        var fieldName = this.getColumnModel().getDataIndex( cell[1] );
        var rec = this.store.getAt( cell[ 0 ] );
        var v = rec.get( fieldName );
        var ta = new Ext.form.TextArea({ value: v,
            style:{ 'font-family':'Consolas, Courier New' } });
        var win = new Ext.Window({ modal:true, width: 600, height: 350,
            layout:'fit', items:[ ta ], maximizable: true
        });
        win.on('afterrender', function(){ ta.focus() });
        win.on('close', function(){
            rec.set( fieldName, ta.getValue() );
        });
        win.show();
    },
    initComponent : function(){
        var self = this;
        var cols = [];
        var fields = [];
        var keys = {};
        Ext.each( self.data, function(row){ // find all data keys, unique
            for( var k in row ) {
                keys[k] = null;
            }
        });
        var te = new Ext.form.TextArea();
        for( var k in keys ) {
           cols.push({ name:k, header:k, dataIndex:k, sortable:true, editor:te  });
           fields.push({ name:k });
        }
        var s = new Ext.data.SimpleStore({ fields: fields });
        Ext.each( self.data, function(row){
             var rt = new s.recordType( row, Ext.id() );
             s.add( rt );
        });
        s.commitChanges();
        self.store = s;
        self.columns = cols;
        self.viewConfig = Ext.apply( { forceFit: true }, self.viewConfig );
        var tbar = [
           { xtype:'button', text:_('Edit'), icon:'/static/images/icons/edit.png', handler: function(){ self.open_win.call(self) } } ,
           new Baseliner.button.CSVExport({ grid: self, store: s })
        ];
        self.tbar = self.tbar ? self.tbar.push( tbar ) : tbar; 
        Baseliner.AutoGrid.superclass.initComponent.call(self);
    }
});

Baseliner.CBTreeNodeUI = function () {
    Baseliner.CBTreeNodeUI.superclass.constructor.apply(this, arguments);
};

Ext.extend(Baseliner.CBTreeNodeUI, Ext.tree.TreeNodeUI, {
    renderElements: function (n, a, targetNode, bulkRender) {
        // add some indent caching, this helps performance when rendering a large tree
        this.indentMarkup = n.parentNode ? n.parentNode.ui.getChildIndent() : '';
        a.checked3 = a.checked3 ? a.checked3 : a.checked ? 1 : 0;
        a.checked = a.checked ? a.checked : ( a.checked3 == 0 ? false : true );

        var cb = Ext.isBoolean(a.checked),
            nel,
            href = this.getHref(a.href),
            c3class = 'styledCheckboxWrap' + (a.checked3 != 0 ? (a.checked3 == -1 ? ' wrapPartial' : ' wrapChecked') : ''),
            buf = ['<li class="x-tree-node"><div ext:tree-node-id="', n.id, '" class="x-tree-node-el x-tree-node-leaf x-unselectable ', a.cls, '" unselectable="on">',
                '<span class="x-tree-node-indent">', this.indentMarkup, "</span>",
                '<img src="', this.emptyIcon, '" class="x-tree-ec-icon x-tree-elbow" />',
                '<img src="', a.icon || this.emptyIcon, '" class="x-tree-node-icon', (a.icon ? " x-tree-node-inline-icon" : ""), (a.iconCls ? " " + a.iconCls : ""), '" unselectable="on" />',
            cb ? ('<span class="' + c3class + '"><input class="x-tree-node-cb styledCheckbox" type="checkbox" ' + (a.checked ? 'checked="checked" />' : '/>') + '</span>') : '',
                '<a hidefocus="on" class="x-tree-node-anchor" href="', href, '" tabIndex="1" ',
            a.hrefTarget ? ' target="' + a.hrefTarget + '"' : "", '><span unselectable="on">', n.text, "</span></a></div>",
                '<ul class="x-tree-node-ct" style="display:none;"></ul>',
                "</li>"].join('');

        if (bulkRender !== true && n.nextSibling && (nel = n.nextSibling.ui.getEl())) {
            this.wrap = Ext.DomHelper.insertHtml("beforeBegin", nel, buf);
        } else {
            this.wrap = Ext.DomHelper.insertHtml("beforeEnd", targetNode, buf);
        }

        this.elNode = this.wrap.childNodes[0];
        this.ctNode = this.wrap.childNodes[1];
        var cs = this.elNode.childNodes;
        this.indentNode = cs[0];
        this.ecNode = cs[1];
        this.iconNode = cs[2];
        var index = 3;
        if (cb) {
            this.checkbox = cs[3];
            // fix for IE6
            this.checkbox.defaultChecked = this.checkbox.checked;
            index++;
        }
        this.anchor = cs[index];
        this.textNode = cs[index].firstChild;
    },

    toggleCheck: function ( c3 ) {
        var cb = this.checkbox;
        if (cb) {
            //c3++;
            //c3 = c3 > 1 ? -1 : c3;
			c3 == 0 ? c3 = 1 : c3 == 1 ? c3 = -1 : c3 = 0;
            cb.checked = ( c3 == 0 ? false : true );
            cb.className = 'styledCheckboxWrap' + ( c3 == 0 ? '' : ( c3 == -1 ? ' wrapPartial' : ' wrapChecked') );
            this.onCheckChange();
            this.node.attributes.checked3 = c3;
        }
    }
});


Baseliner.CBTreeNodeUI_system = function () {
    Baseliner.CBTreeNodeUI_system.superclass.constructor.apply(this, arguments);
};

Ext.extend(Baseliner.CBTreeNodeUI_system, Ext.tree.TreeNodeUI, {
    renderElements: function (n, a, targetNode, bulkRender) {

        // add some indent caching, this helps performance when rendering a large tree
        this.indentMarkup = n.parentNode ? n.parentNode.ui.getChildIndent() : '';
        //a.checked3 = a.checked3 ? a.checked3 : a.checked ? 1 : 0;
        //a.checked = a.checked ? a.checked : ( a.checked3 == 0 ? false : true );

        var cb = Ext.isBoolean(a.checked),
            nel,
            href = this.getHref(a.href),
            c3class = 'styledCheckboxWrap' + (a.checked ? ' wrapChecked' : ''),
            buf = ['<li class="x-tree-node"><div ext:tree-node-id="', n.id, '" class="x-tree-node-el x-tree-node-leaf x-unselectable ', a.cls, '" unselectable="on">',
                '<span class="x-tree-node-indent">', this.indentMarkup, "</span>",
                '<img src="', this.emptyIcon, '" class="x-tree-ec-icon x-tree-elbow" />',
                '<img src="', a.icon || this.emptyIcon, '" class="x-tree-node-icon', (a.icon ? " x-tree-node-inline-icon" : ""), (a.iconCls ? " " + a.iconCls : ""), '" unselectable="on" />',
            cb ? ('<span class="' + c3class + '"><input class="x-tree-node-cb styledCheckbox" type="checkbox" ' + (a.checked ? 'checked="checked" />' : '/>') + '</span>') : '',
                '<a hidefocus="on" class="x-tree-node-anchor" href="', href, '" tabIndex="1" ',
            a.hrefTarget ? ' target="' + a.hrefTarget + '"' : "", '><span unselectable="on">', n.text, "</span></a></div>",
                '<ul class="x-tree-node-ct" style="display:none;"></ul>',
                "</li>"].join('');

        if (bulkRender !== true && n.nextSibling && (nel = n.nextSibling.ui.getEl())) {
            this.wrap = Ext.DomHelper.insertHtml("beforeBegin", nel, buf);
        } else {
            this.wrap = Ext.DomHelper.insertHtml("beforeEnd", targetNode, buf);
        }

        this.elNode = this.wrap.childNodes[0];
        this.ctNode = this.wrap.childNodes[1];
        var cs = this.elNode.childNodes;
        this.indentNode = cs[0];
        this.ecNode = cs[1];
        this.iconNode = cs[2];
        var index = 3;
        if (cb) {
            this.checkbox = cs[3];
            // fix for IE6
            this.checkbox.defaultChecked = this.checkbox.checked;
            index++;
        }
        this.anchor = cs[index];
        this.textNode = cs[index].firstChild;
    },

    toggleCheck: function ( value ) {
        var cb = this.checkbox;
        if (cb) {

            cb.checked = (value === undefined ? !cb.checked : value);
            cb.className = 'styledCheckboxWrap' + (  cb.checked ? ' wrapChecked' : '');
            this.onCheckChange();
        }
    }
});

/*
    MetaForm : dynamic form for arbitrary data and standard metadata    

    var mf = new Baseliner.MetaForm({
        meta: [
            { id:'var1', type:'value', default:'xxx' },
            { id:'var2', type:'ci', role:'Infrastructure', default:'xxx', field_attributes:{ singleMode:false } }
        ],
        data: {
            var1 : 100,
            var2 : 200
        }
    });

    meta attributes:
    ===============

        id: data hash key
        label: field label (defaults to id)
        default: default value
        type: value|ci|combo
        field_attributes: attributes to be applied to the field component
        anchor: '100%' - field anchor

        options: [...] array of options for combo
        role: '' ci role name 
        classname: '' ci class name (has precedence over role)
*/
Baseliner.MetaForm = Ext.extend( Ext.Panel, {
    layout: 'form',
    border: false,
    frame: false,
    labelWidth: 160,
    bodyStyle: 'padding: 10px 10px 10px 10px',
    constructor: function(c){
        Baseliner.MetaForm.superclass.constructor.call(this, Ext.apply({
        }, c));
    },
    initComponent: function(){
        var self = this;
        if( !self.data ) self.data = {};
        self.items = self.items || [];
        self.addEvents('field_changed', 'save', 'delete_field');
        self.fields_destroyed = {};
        if( self.tbar === false ) {
            self.tbar = null;
        } else {
            self.tbar = [];
            if( ! self.hide_save )
                self.tbar.push({ text:_('Save'), icon:'/static/images/icons/save.png', handler: function(){ self.done(true) } } );
            if( ! self.hide_cancel )
                self.tbar.push( { text:_('Cancel'), icon:'/static/images/icons/close.png', handler: function(){ self.done(false) } } );
        }
        Baseliner.MetaForm.superclass.initComponent.call(this);
        
        // add fields, if any
        Ext.each( self.meta, function(meta){
            self.add_field_from_meta( meta );
        });
        self.doLayout();
    },
    // turn the form into a hash
    serialize : function(){
        var self = this;
        self.cascade( function(obj){
            if( Ext.isFunction( obj.getValue ) ) {
                self.data[ obj.name ] = obj.getValue();
            }
        });
        return self.data;
    },
    // on close
    done : function(saving){
        var self = this;
        if( saving ) {
            self.data = self.serialize();
            self.fireEvent('save', self, self.data );
        }
        self.fireEvent('done', self, saving, self.data );
    },
    // converts a short meta entry into a form field with a delete button
    to_field : function(meta){
        var self = this;
        var field;
        var bl = meta.bl || self.bl;
        var id = meta.id || meta.label; //Baseliner.name_to_id( meta.id || meta.label );
        if( !meta.type || meta.type == 'value' ) {
            field = new Ext.form.TextField(Ext.apply({
                fieldLabel: _( meta.label || id),
                id: Ext.id(),
                name: id,
                submitValue: false,
                anchor: meta.anchor || '100%',
                value: self.data[id]
            }, meta.field_attributes ));
        }
        else if( meta.type == 'password' ) {
            field = new Ext.form.TextField(Ext.apply({
                fieldLabel: _( meta.label || id),
                id: Ext.id(),
                name: id,
                submitValue: false,
                inputType: 'password',
                anchor: meta.anchor || '100%',
                value: self.data[id]
            }, meta.field_attributes ));
        }
        else if( meta.type == 'textarea' ) {
            field = new Ext.form.TextArea(Ext.apply({
                fieldLabel: _( meta.label || id),
                id: Ext.id(),
                name: id,
                submitValue: false,
                height: '80',
                anchor: meta.anchor || '100%',
                value: self.data[id]
            }, meta.field_attributes ));
        }
        else if( meta.type == 'ci' ) {
            var bp = { _whoami:'MetaForm', bl: bl };
            if( meta.role && meta.role != 'CI' ) bp.role = meta.role;
            else if( meta.classname ) bp.classname = meta.classname;
            else bp.role = 'CI';  // avoids a bad store call
            var store = new Baseliner.store.CI({ baseParams: bp });
            store.on('load', function(){
                if( self.data && self.data[id]!== undefined )
                    field.setValue( self.data[id] );
            });
            field = new Baseliner.model.CISelect(Ext.apply({
                store: store, 
                anchor: meta.anchor || '100%',
                submitValue: false,
                singleMode: true, 
                fieldLabel: _( meta.label || id),
                id: Ext.id(),
                name: id,
                hiddenName: id,
                value: self.data[id],
                allowBlank: false
            }, meta.field_attributes )); 
        }
        else if( meta.type == 'combo' ) {
            field = new Baseliner.ComboSingle(Ext.apply({ 
                anchor: meta.anchor || '100%',
                fieldLabel: _( meta.label || id),
                id: Ext.id(),
                name: id,
                allowBlank: false,
                submitValue: false,
                value: self.data[id],
                data: meta.options 
            }, meta.field_attributes ));
        }
        else if( meta.type == 'array' ) {
            var vv = self.data[id];
            field = new Baseliner.ArrayGrid({ 
                height: 150,
                fieldLabel: _( meta.label || id),
                name: id,
                value: vv || [],
                description: '',
                default_value:'???' 
            }); 
        }
        if( field ) {
            field.on('blur', function(){
                self.fireEvent('field_changed', self, field );
            });
        }
        return field;
    },
    to_field_container : function(field){
        var self = this;
        //return field;
        var pn = new Ext.Panel({ 
            layout:'column',
            width: '100%',
            frame: false,
            border: false,
            items:[
                { layout:'form', border: false, columnWidth:.9, items:[field],
                    labelWidth: 200, labelAlign: 'right'
                },
                { columnWidth:.1, border: false, padding: '0 0 0 10px', items: new Ext.Button({ 
                        icon:'/static/images/icons/delete.gif',
                        handler: function(){
                            self.deleting = true;
                            self.remove( pn );
                            delete self.data[ field.name ];
                            self.deleting = false;
                            self.fireEvent('delete_field', self, field.name );
                        }
                    })
                }
            ]
        });
        field.pn = pn.id;
        return pn;
    }, 
    clear_form : function(){
        var self =this;
        self.removeAll();
    },
    // adds a field to the form
    add_field_from_meta : function(meta){
        var self = this;
        
        // set default data
        if( ! self.data ) self.data = {};
        if( self.data[meta.id]===undefined ) { 
            // set default value, othewise a null
            self.data[meta.id] = meta['default']!==undefined ? meta['default'] : null;
        }

        // create field
        var field = self.to_field( meta );
        if( field ) {
            field.on('beforedestroy', function(){ 
                if( self.deleting ) return;  // no need to rebuild data on field delete
                self.serialize(); 
            });
            var field_container = self.to_field_container( field );
            self.add( field_container );
            //self.add( field );
            self.doLayout();
            return field;
        }
    }, 
    remove_field : function(id){
        var self = this;
        self.cascade( function(obj){
            if( obj && obj.name == id ) {
                if( obj.pn ) self.remove( obj.pn );
                else self.remove( obj );
                delete self.data[id];
            }
        });
    }
});

Baseliner.VariableForm = Ext.extend( Ext.Panel, {
    bl: '*', 
    layout: 'card',
    activeItem: 0,
    show_tbar: true,
    constructor: function(c){
        Baseliner.VariableForm.superclass.constructor.call(this, Ext.apply({
        }, c));
    },
    initComponent: function(){
        var self = this;
        if( !self.data ) {
            self.data = {};
        } else if( !Ext.isObject(self.data) ) {
            Baseliner.error( 'VariableForm', _('Invalid or corrupt data for variables') );
            self.data = {};
        }
        self.vars_cache = {};
        self.store_vars = new Baseliner.store.CI({ baseParams: { role:'Variable', with_data: 1, order_by:'lower(name)' } });
        self.combo_vars = new Ext.form.ComboBox({ 
               width: 350,
               submitValue: false,
               id: self.id + '-combo',
               name: self.id + '-combo-name',
               valueField: 'name', 
               hiddenField: 'name', 
               displayField: 'name',
               mode:'remote',
               emptyText: _('<select variable>'),
               typeAhead: false,
               minChars: 1, 
               store: self.store_vars, 
               editable: false, forceSelection: true, triggerAction: 'all',
               allowBlank: true
        });
        // adds variable on combo click
        self.combo_vars.on('select', function(cb,rec){
            self.add_field_from_rec( rec );
        });
        self.btn_add = new Ext.Button({ icon:'/static/images/icons/add.gif', handler:function(){
            var ix = self.combo_vars.view.getSelectedIndexes()[0];
            if( ix!==undefined ) {
                var rec = self.store_vars.getAt(ix);
                self.add_field_from_rec( rec );
            }
        }});
        self.btn_del = new Ext.Button({ icon:'/static/images/icons/delete.gif', handler:function(){
            var ix = self.combo_vars.view.getSelectedIndexes()[0];
            if( ix!==undefined ) {
                var rec = self.store_vars.getAt(ix);
                self.del_field_from_rec( rec );
            }
        }});
        
        if( self.show_tbar ) self.tbar = [ self.combo_vars, self.btn_add, self.btn_del ];
        else self.tbar = [];
        
        Baseliner.VariableForm.superclass.initComponent.call(this);

        // load baselines
        var bls = new Baseliner.store.Baseline(); 
        bls.load({
            callback: function(records){
                var tbar = self.getTopToolbar();
                tbar.add('->');
                if( self.force_bl ) {
                    records=[];
                    Ext.each( self.force_bl, function(fbl){
                        records.push({ id: fbl });
                    });
                }
                var def_bl = self.force_bl || '*';
                Ext.each(records, function(bl){
                    var name = bl.id == '*' ? 'Common' : bl.id; 
                    // create metaform
                    var mf = new Baseliner.MetaForm({ 
                        bl: bl.id,
                        data: self.data[bl.id] || {}, 
                        tbar: false
                    });
                    mf.on('beforedestroy', function(){ 
                        self.data[bl.id] = mf.serialize();
                    });
                    mf.on('field_changed', function(mf, fi){ 
                        self.data[bl.id] = mf.serialize();
                        //self.combo_vars.reset();
                    });
                    mf.on('delete_field', function(mf){ 
                        self.data[bl.id] = mf.serialize();
                        //self.combo_vars.reset();
                    });
                    // add to card
                    self.add( mf ); 
                    // add to toolbar
                    tbar.add({ xtype:'button', enableToggle: true, 
                        pressed: (bl.id==def_bl ?true:false), 
                        width: '30',
                        bl_id: bl.id,
                        toggleGroup: 'vf-bls-'+self.id, 
                        handler: function(btn){
                            self.getLayout().setActiveItem( mf );
                        },
                        text: _(name)
                    });
                    if( bl.id == def_bl ) self.getLayout().setActiveItem( mf );
                    // load form
                    self.meta_for_data( mf, bl.id );
                });
                tbar.doLayout();
                self.doLayout();
            }
        });
        
        // get metadata from data variable names
    },
    add_field_from_rec : function(rec){
        var self = this;
        var id = rec.data.name;
        var mf = self.current_mf();
        var bl = mf.bl;
        if( mf.data==undefined || mf.data[ id ] === undefined ) {
            var d = Ext.apply({}, rec.data);
            d = Ext.apply(d, rec.data.data );
            var meta = self.var_to_meta( d );
            var field = mf.add_field_from_meta( meta );
            var value = field.getValue() || meta['default'];
            if( !self.data[bl] ) self.data[bl]={};
            self.data[bl][id] = value;
            
            //self.data[bl.id] = mf.serialize();
            //mf.serialize();
            //self.data[ bl ] = meta['default'];
        } else {
            Baseliner.message( _('Variables'), _('Variable `%1` already exists', id) );
        }
    },
    del_field_from_rec : function(rec){
        var self = this;
        var id = rec.data.name;
        var mf = self.current_mf();
        mf.remove_field( id );
    },
    current_bl : function(){
        var self = this;
        return self.current_mf.bl;
    },
    current_mf : function(){
        var self = this;
        return self.getLayout().activeItem;
    },
    get_save_data : function(bl){
        var self = this;
        return self.getData();
    },
    var_to_meta : function( ci, bl ){
        var self = this;
        var meta = {
            id: ci.name,
            type: ci.var_type,
            description: ci.description,
            'default': ci.var_default,
            classname: ci.var_ci_class,
            role: ci.var_ci_role,
            field_attributes: { allowBlank: !ci.var_ci_mandatory, singleMode: !ci.var_ci_multiple },
            options: ci.var_combo_options
        };
        return meta;
    },
    add_var_ci_field : function(mf,bl, var_ci){
        var self = this;
        var meta = self.var_to_meta(var_ci, bl);
        return mf.add_field_from_meta( meta );
    },
    meta_for_data : function(mf,bl){
        var self = this;
        var vars=[];
        if( !self.data ) return;
        var bl_data = self.data[bl];
        mf.data = bl_data;
        // get variable names from hash keys
        for( v in bl_data ) {
            vars.push( v ); 
        }
        if( vars.length > 0 ) {
            /*
            var vars_no_cache = [];
            Ext.each( vars, function(v) {
                if( self.vars_cache[v] !== undefined ) 
                    self.add_var_ci_field( mf, bl, self.vars_cache[v] );
                else 
                    vars_no_cache.push(v);
            });
            */
            // get variable CI metadata 
            Baseliner.ci_call('variable', 'list_by_name', { names: vars, bl: bl }, function(res){
                Ext.each( res, function(var_ci){
                    self.add_var_ci_field( mf, bl, var_ci );
                });
            });
        }
    },
    getData : function(bl){
        var self = this;
        Ext.each( self.items.items, function(mf) {
            if( bl && mf.bl != bl ) return;
            self.data[ mf.bl ] = mf.serialize();
        });
        return self.data;
    }, 
    getValue : function(){
        alert( 'ggg' );
    }
});



