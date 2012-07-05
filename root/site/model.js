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
        id: 'id', 
        url: '/project/all_projects',
        fields: ['mid','ns','name','description'] 
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
        //store: new Baseliner.store.UserProjects({}),
        mode: 'local',
        fieldLabel: _('Projects'),
        typeAhead: true,
        name: 'projects',
        displayField: 'name',
        hiddenName: 'projects',
        valueField: 'mid',
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


Baseliner.model.Users = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{username} - {realname}</div></tpl>' );
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
        tpl: '<tpl for="."><div class="x-combo-list-item">{username} - {realname}</div></tpl>',
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

Baseliner.model.Commits = function(c) {
    var tpl = new Ext.XTemplate( '<tpl for="."><div class="search-item {recordCls}">{name}</div></tpl>' );
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
        fieldLabel: _('Commits'),
        typeAhead: true,
        name: 'commits',
        displayField: 'name',
        hiddenName: 'commits',
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
Ext.extend( Baseliner.model.Commits, Ext.ux.form.SuperBoxSelect );

function returnOpposite(hexcolor) {
    var r = parseInt(hexcolor.substr(0,2),16);
    var g = parseInt(hexcolor.substr(2,2),16);
    var b = parseInt(hexcolor.substr(4,2),16);
    var yiq = ((r*299)+(g*587)+(b*114))/1000;
    return (yiq >= 128) ? '000000' : 'FFFFFF';
}
    
Baseliner.model.Labels = function(c) {
    var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">',
        '<span id="boot" style="width:200px"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: #{[returnOpposite(values.color)]};background: #{color}">{name}</span></span>',
        '</div></tpl>');
    var tpl_field = new Ext.XTemplate( '<tpl for=".">',
        '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;color: #{[returnOpposite(values.color)]};background: #{color}">{name}</span></span>',
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
    var rev_store = new Ext.data.JsonStore({
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

Baseliner.combo_tasks = function(params) {
    if( params == undefined ) params = {};
    var store_tasks =new Ext.data.JsonStore({
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
    var store = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
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
          { xtype:'button', text:'<', handler:function(){ cal.fullCalendar("prev") } },
          { xtype:'button', text:'>', handler:function(){ cal.fullCalendar("next") } }, 
          '-',
          { xtype:'button', text:_('Today'), handler:function(){ cal.fullCalendar("today") } },
          '-',
             { xtype:'button', text:_('Day1'), handler:function(){ cal.fullCalendar("changeView", "basicDay") } } ,
              { xtype:'button', text:_('Day2'), handler:function(){ cal.fullCalendar("changeView", "agendaDay") } } ,
            { xtype:'button', text:_('Week1'), handler:function(){ cal.fullCalendar("changeView", "basicWeek") } } ,
          { xtype:'button', text:_('Week2'), handler:function(){ cal.fullCalendar("changeView", "agendaWeek") } } ,
          { xtype:'button', text:_('Month'), handler:function(){ cal.fullCalendar("changeView", "month") } } ,
          '-',
          { xtype:'button', text:_('( )'), handler:function(){ cal.fullCalendar("refetchEvents") } } ,

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
        var dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
            copy: true,
            notifyEnter: function(ddSource, ev, data) {
                var el = ddSource.getProxy().getGhost();

                $(el.dom).data('eventObject', data );
                var id = el.id;
                //$( el.dom ).css( 'background-color', 'green' );
                $( el.dom ).draggable({
                    addClasses: true,
                    zIndex: 999,
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

        var event_new_url = c.url_new || '/eventnew.js';
        var event_new = function( data ) {
            Baseliner.ajaxEval( event_new_url, data, function(res) { 
                if( res && res.success ) {
                    // create the event
                    cal.fullCalendar('renderEvent',
                        Ext.apply({
                            title: _('[untitled]'),
                            start: date,
                            end: date,
                            allDay: allDay
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
            drop: function( date, allDay, jsEvent, ui  ) {
                 var opts = jsEvent.data;
                 event_new( opts );
            },
            select: function(start, end, allDay) {
                if( c.onSelect ) {
                    c.onSelect( cal, start, end, allDay );
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
   Baseliner.ajaxEval('/events.js', { start: start, end: end }, function(res){
        cb( res.data ); 
   });
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
        fields: ['mid','item', 'name','collection','class','description', 'properties', 'pretty_properties'] 
     }, c));
};
Ext.extend( Baseliner.store.CI, Ext.data.JsonStore );

Baseliner.model.CISelect = function(c) {
    //var tpl_list = new Ext.XTemplate( '<tpl for="."><div class="x-combo-list-item">{name} ({class})</div></tpl>' );
    var tpl_list = new Ext.XTemplate(
        '<tpl for="."><div class="search-item">',
            //'<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{name}</h3>',
        '<span id="boot"><strong>{name}</strong> ({class})</span>',
        '<tpl if="pretty_properties">',
            '<br />{pretty_properties}',
        '</tpl>',
        '</div></tpl>'
    );
    var tpl_field = new Ext.XTemplate( '<tpl for=".">{name}</tpl>' );
    Baseliner.model.CISelect.superclass.constructor.call(this, Ext.apply({
        allowBlank: false,
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
        value: '/',
        extraItemCls: 'x-tag'
    }, c));
};
Ext.extend( Baseliner.model.CISelect, Ext.ux.form.SuperBoxSelect );


Baseliner.model.CICombo = function(c) {
    var resultTpl = new Ext.XTemplate(
        '<tpl for="."><div class="search-item">',
            //'<h3><span>{ns_type}<br />{user}</span><img src="{icon}" />{name}</h3>',
        '<span id="boot"><strong>{name}</strong> ({class})</span>',
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
        typeAhead: false,
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

