(function(){
    var ps = 100; //page_size
    var store=new Baseliner.JsonStore({
	    root: 'data' , 
	    remoteSort: true,
	    totalProperty:"totalCount", 
	    id: 'id', 
	    url: '/daemon/list',
	    fields: [ 
		    {  name: 'id' },
		    {  name: 'service' },
		    {  name: 'pid' },
		    {  name: 'instances' },
		    {  name: 'active_instances' },
		    {  name: 'exists' },
		    {  name: 'active' },
		    {  name: 'config' },
		    {  name: 'params' },
	    ]
    });

    <& /comp/search_field.mas &>
    
    var render_instances = function(value,metadata,rec,rowIndex,colIndex,store) {
    	var instances = '';
    	if ( value ) {
	    	Ext.each(value, function(row){
	            instances += '<li>' + row.instance + '</li>';
	        });
    	}
	    return instances ;
    };

    var render_active_instances = function(value,metadata,rec,rowIndex,colIndex,store) {
    	var instances = '';
    	if ( value ) {
	    	Ext.each(value, function(row){
	            instances += '<li>(' + row.pid + ') ' + row.disp_id +  '</li>';
	        });
    	}
	    return instances ;
    };

    var render_name = function(value,metadata,rec,rowIndex,colIndex,store) {
	    return "<div style='font-weight:bold; font-size: 16px;'>" + value + "</div>" ;
    };

    var render_icon = function(value,metadata,rec,rowIndex,colIndex,store) {
	    return "<img alt='"+value+"' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/daemon.gif' />" ;
    };

    var render_running = function(value,metadata,rec,rowIndex,colIndex,store) {
	    var img =
		    value == '1' ? 'icons/bulb/green.gif' 
		    : ( value == -1 ? 'indicator.gif'
		    : 'icons/bulb/gray.gif' );
		    return "<img alt='"+value+"' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/"+img+"' />" ;
    };

    var render_active = function(value,metadata,rec,rowIndex,colIndex,store) {
	    var img =
		    value == '1' ? 'drop-yes.gif' : 'close-small.gif';
		    return "<img alt='"+value+"' border=0 style='vertical-align: top; margin: 0 0 10 2;' src='/static/images/"+img+"' />" ;
    };


    var init_buttons = function(action) {
	    eval('btn_start.' + action + '()');
	    eval('btn_stop.' + action + '()');
	    eval('btn_edit.' + action + '()');
	    eval('btn_delete.' + action + '()');
    } 
 
        var btn_start = new Ext.Toolbar.Button({
	    text: _('Start'),
	    icon:'/static/images/start.gif',
	    disabled: true,
	    cls: 'x-btn-text-icon',
	    handler: function() {
		    var sm = grid.getSelectionModel();
		    if (sm.hasSelection()) {
			    var rec = sm.getSelected();
			    var id = rec.data.id;
			    Baseliner.ajaxEval( '/daemon/start', { id: id },
				    function(resp){
					    Baseliner.message( _('Success'), resp.msg );
					    store.load();
				    }
			    );
		    } else {
			    Baseliner.message( _('ERROR'), _('Select at least one row'));	
		    };
	    }
        });

        var btn_stop = new Ext.Toolbar.Button({
	    text: _('Stop'),
	    icon:'/static/images/stop.gif',
	    disabled: true,
	    cls: 'x-btn-text-icon',
	    handler: function() {
		    var sm = grid.getSelectionModel();
		    var sel = sm.getSelected();
		    Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to turn off the daemon') + ' <b>' + sel.data.service  + '</b>?', 
			    function(btn){ 
				    if(btn=='yes') {
					    Baseliner.ajaxEval( '/daemon/stop', { id: sel.data.id },
						    function(resp){
							    Baseliner.message( _('Success'), resp.msg );
							    store.load();
						    }
					    );
				    }
			    }
		    );
	    }
        });


//        var btn_add = new Ext.Toolbar.Button({
//			text: _('New'),
//			icon:'/static/images/icons/add.gif',
//			cls: 'x-btn-text-icon',
//            handler: function() {
//				add_edit()
//			}
//        });

		var btn_add = new Baseliner.Grid.Buttons.Add({    
			handler: function() {
				add_edit()
			}
		});
    
        var btn_edit = new Ext.Toolbar.Button({
	    text: _('Edit'),
                icon:'/static/images/icons/edit.gif',
                cls: 'x-btn-text-icon',
	    disabled: true,
                handler: function() {
		    var sm = grid.getSelectionModel();
		    if (sm.hasSelection()) {
			    var sel = sm.getSelected();
			    add_edit(sel);
		    } else {
			    Baseliner.message( _('ERROR'), _('Select at least one row'));    
		    };
	    }
        });
    
        var btn_delete = new Ext.Toolbar.Button({
		    text: _('Delete'),
		    icon:'/static/images/icons/delete.gif',
		    cls: 'x-btn-text-icon',
		    disabled: true,
		    handler: function() {
			    var sm = grid.getSelectionModel();
			    var sel = sm.getSelected();
			    Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the daemon') + ' <b>' + sel.data.service + '</b>?', 
			    function(btn){ 
				    if(btn=='yes') {
					    Baseliner.ajaxEval( '/daemon/update?action=delete',{ id: sel.data.id },
						    function(response) {
							    if ( response.success ) {
								    grid.getStore().remove(sel);
								    Baseliner.message( _('Success'), response.msg );
								    init_buttons('disable');
							    } else {
								    Baseliner.message( _('ERROR'), response.msg );
							    }
						    }
					    
					    );
				    }
			    } );
		    }
        });


    var add_edit = function(rec) {
	    var win;
	    var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, widht:10});
	    
	    var schedule_service = Baseliner.combo_services({ hiddenName: 'service' });

	    // var combo_host = new Ext.form.ComboBox({
		   //  mode: 'local',
		   //  value: 'localhost',
		   //  triggerAction: 'all',
		   //  forceSelection: true,
		   //  editable: true,
		   //  fieldLabel: _('Host'),
		   //  name: 'hostname',
		   //  hiddenName: 'hostname',
		   //  displayField: 'name',
		   //  valueField: 'value',
		   //  //En un futuro se cargaran los distintos Host
		   //  store: 	new Baseliner.JsonStore({
				 //    fields : ['name', 'value'],
				 //    data   : [{name : 'localhost',   value: 'localhost'}]
			  //   })
	    // });

// 		var instances = new Ext.form.TextField({
//             name: 'instances',
//             fieldLabel: _('Active instances'),
//             width: 150,
// //            value: rec.instances,
//             labelWidth: 250
//         });
		var tf = Baseliner.cols_templates['textfield'];

		var instances = new Baseliner.GridEditor({
		    title: _('Active instances'),
		    height: 200,
		    witdth: 400,
		    name: 'instances',
		    records: rec && rec.data ? rec.data.instances: [],
		    preventMark: false,        
		    columns: [
		        Ext.apply({ dataIndex:'instance', header: _('Instance') }, tf() )
		    ],
		    viewConfig: { forceFit: true }
		});

	    var title = 'Create daemon';
	    
	    var form_daemon = new Baseliner.FormPanel({
		    frame: true,
		    url:'/daemon/update',
		    buttons: [
			    {
			    text: _('Accept'),
			    type: 'submit',
			    handler: function() {
				    var form = form_daemon.getForm();
    
				    if (form.isValid()) {
				    	var params = form_daemon.getValues();
					    if(form.getValues()['id'] == -1){
					    	params.action = 'add';
					    }else{
					    	params.action = 'update';
					    }

				    	Baseliner.ajax_json('/daemon/update', params , function(f,a){
					           Baseliner.message(_('Success'), f.msg );
					           store.load();
					           win.close();
				        });
				    }

			    }
			    },
			    {
			    text: _('Close'),
			    handler: function(){ 
					    win.close();
				    }
			    }
		    ],
		    defaults: { width: 400 },
		    items: [
			    { xtype: 'hidden', name: 'id', value: -1 },
			    schedule_service,
				instances,
			    {
			    xtype: 'radiogroup',
			    id: 'stategroup',
			    fieldLabel: _('State'),
			    defaults: {xtype: "radio",name: "state"},
			    items: [
				    {boxLabel: _('Active'), inputValue: 1},
				    {boxLabel: _('Not Active'), inputValue: 0, checked: true}
			    ]
			    }
		    ]
	    });

	    if(rec){
		    var ff = form_daemon.getForm();
		    ff.loadRecord( rec );
		    var rb_state = Ext.getCmp("stategroup");
		    rb_state.setValue(rec.data.active);
		    title = 'Edit daemon';
		    schedule_service.disable();
	    }
	    
	    win = new Ext.Window({
		    title: _(title),
		    width: 550,
		    autoHeight: true,
		    items: form_daemon
	    });
	    win.show();		
    };
    
    // create the grid
    var grid = new Ext.grid.GridPanel({
	    title: _('Daemons'),
	    header: false,
	    stripeRows: true,
	    autoScroll: true,
	    autoWidth: true,
	    store: store,
	    viewConfig: {forceFit: true	},
	    selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
	    loadMask:'true',
	    columns: [
		    { width: 40, sortable: false, renderer: render_icon },	
		    { header: _('Service'), width: 300, dataIndex: 'service', sortable: true, renderer: render_name },	
		    { header: _('Config'), width: 200, dataIndex: 'config', sortable: true, hidden: true },	
		    { header: _('Active'), width: 100, dataIndex: 'active', sortable: true, renderer: render_active },	
		    // { header: _('Running'), width: 100, dataIndex: 'exists', sortable: true, renderer: render_running },	
		    // { header: _('Last Process ID'), width: 100, dataIndex: 'pid', sortable: true },	
		    { header: _('Instances'), width: 200, dataIndex: 'instances', sortable: true, renderer: render_instances },
		    { header: _('Active instances'), width: 200, dataIndex: 'active_instances', sortable: true, renderer: render_active_instances }	
	    ],
	    autoSizeColumns: true,
	    deferredRender:true,
	    bbar: new Ext.PagingToolbar({
		    store: store,
		    pageSize: ps,
		    displayInfo: true,
		    displayMsg: _('Rows {0} - {1} of {2}'),
		    emptyMsg: _('There are no rows available')
	    }),
	    tbar: [ _('Search') + ': ', ' ',
			    new Ext.app.SearchField({
			    store: store,
			    params: {start: 0, limit: ps},
			    emptyText: _('<Enter your search string>')
		    }),
		    btn_start,
		    btn_stop,
		    btn_add,
		    btn_edit,
		    btn_delete,
		    '->'
	    ]
    });

    grid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
	    init_buttons('enable');
    });

    //grid.on("rowdblclick", function(grid, rowIndex, e ) {
    //    var r = grid.getStore().getAt(rowIndex);
    //    Baseliner.addNewTab('/daemon/edit?id_rel=' + r.get('id') , r.get('name') );
    //});		
    
    // Después de que cargue la página:
    store.load({params:{start:0 , limit: ps}}); 

    return grid;
})()




