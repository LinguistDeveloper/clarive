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

		Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
		    Ext.applyIf(this.options, {
			submitEmptyText:false
		    });
		});
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
          { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/refresh.gif', handler:function(){ cal.fullCalendar("refetchEvents") } } ,

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

        var event_new_url = c.url_new || '/calendar/event/add';  // this should be the controller that creates events
        var event_new = function( data ) {
            Baseliner.ajaxEval( event_new_url, data, function(res) { 
                if( res && res.success ) {
                    //var allday = res.allday!=undefined ? res.allday : true;
                    // create the event
                    cal.fullCalendar('renderEvent',
                        Ext.apply({
                            title: _('[untitled]'),
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

// quick CI Select Box generator
//   usage:
//      Baseliner.ci_box({ name:'repo', class:'BaselinerX::CI::GitRepository', fieldLabel:_('Git Repository'), value: data.repo })

Baseliner.ci_box = function(c) {
    var value = c.value; delete c.value;
    var role = c.role; delete c.role;
    var cl = c.class; delete c.class;
    var bp = {};
    if( cl !=undefined ) bp.class = cl;
    else bp.role = role;
    if( c.hiddenName == undefined ) c.hiddenName = c.name;
    var store = new Baseliner.store.CI({ baseParams: bp });
    var ci_box = new Baseliner.model.CISelect(Ext.apply({
        store: store, 
        singleMode: true, 
        fieldLabel: _('CI'),
        name: 'ci',
        hiddenName: 'ci', 
        allowBlank: false
    }, c )); 
    store.on('load',function(){
        if( value != undefined ) 
            ci_box.setValue( value ) ;           
    });
    return ci_box;
};

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

Baseliner.model.SelectBaseline = function(c) {
    var self = this;
    var tpl_list = new Ext.XTemplate(
        '<tpl for="."><div class="search-item">',
        '<span id="boot"><strong>{[ values.bl == "*" ? _("Common") : values.bl ]}</strong> {name}</span>',
        '</div></tpl>'
    );
    var tpl_field = new Ext.XTemplate( '<tpl for=".">{[ values.bl == "*" ? _("Common") : values.bl ]}</tpl>' );
    var store = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: {}, //{ no_common: true },
        id: 'id', 
        url: '/baseline/json',
        fields: ['id','bl','name','description', 'active'] 
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
    var revision_box_store = new Ext.data.JsonStore({
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
        var revision_box_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
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
                        { name: ci.name, class: ci.class, ns: ci.ns, ci_json: Ext.util.JSON.encode( ci.data ) },
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
          },

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
        var revision_box_dt = new Ext.dd.DropTarget(el, {
            ddGroup: 'lifecycle_dd',
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
                        { name: ci.name, class: ci.class, ns: ci.ns, ci_json: Ext.util.JSON.encode( ci.data ) },
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
Baseliner.flot.Base = function(c) {
    if( c==undefined ) c={};
    var data = c.data;
    delete c.data;
    var w = c.width == undefined ? 200 : c.width;
    var h = c.height == undefined ? 200 : c.height;
    Baseliner.flot.Base.superclass.constructor.call(this,
        Ext.apply({ style:{width: w, height: h, background:'white'} }, c)
    );
    this.on('afterrender',function(){
        $.plot(	$(this.el.dom ), data, c.plotConfig );
    });
};
Ext.extend( Baseliner.flot.Base, Ext.Container ); 

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
