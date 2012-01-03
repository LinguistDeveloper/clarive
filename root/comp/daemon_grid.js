(function(){
	var ps = 100; //page_size
	var store=new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/daemon/list',
		fields: [ 
			{  name: 'id' },
			{  name: 'service' },
			{  name: 'pid' },
			{  name: 'hostname' },
			{  name: 'exists' },
			{  name: 'active' },
			{  name: 'config' },
			{  name: 'params' }
		]
	});

	<& /comp/search_field.mas &>
	
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
					function(res){
						Baseliner.message(_('Daemons'), _('Service daemon %1 started', rec.data.service ) );
						store.load();
					}
				);
			} else {
				Ext.Msg.alert('Error', 'Falta seleccionar una fila');	
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
			var service = sel.data.service;
			Ext.Msg.confirm( _('Confirmation'), '<% _loc('Are you sure you want to turn off the daemon') %> ' + service + '?', 
				function(btn){ 
					if(btn=='yes') {
						var conn = new Ext.data.Connection();
						conn.request({
							url: '/daemon/stop',
							params: { action: 'stop', id: sel.data.id },
							success: function(resp,opt) {
								Baseliner.message( _('Daemons'), _('Service %1 stopped.', service ) );
								store.load();
							}, 
							failure: function(resp,opt) { Ext.Msg.alert('<% _loc('Error') %>', _('Could not stop the daemon.') ); }
						});	
					}
				}
			);
		}
        });


        var btn_add = new Ext.Toolbar.Button({
                text: _('New'),
                icon:'/static/images/icons/add.gif',
                cls: 'x-btn-text-icon',
        	handler: function() {
			//add_edit()
		}
        });
	
        var btn_edit = new Ext.Toolbar.Button({
		text: _('Edit'),
                icon:'/static/images/icons/edit.gif',
                cls: 'x-btn-text-icon',
		disabled: true,
                handler: function() {
			//var sm = grid_proyectos.getSelectionModel();
			//if (sm.hasSelection()) {
			//	var sel = sm.getSelected();
			//	add_edit(sel);
			//} else {
			//	Baseliner.message( _('ERROR'), _('Select at least one row'));    
			//};
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
						Baseliner.ajaxEval( '/daemon/delete',
							{ id: sel.data.id
							},
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


	// create the grid
	var grid = new Ext.grid.GridPanel({
		title: _('Daemons'),
		header: false,
		stripeRows: true,
		autoScroll: true,
		autoWidth: true,
		store: store,
		viewConfig: [{
			forceFit: true
		}],
		selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		loadMask:'true',
		columns: [
			{ width: 40, sortable: false, renderer: render_icon },	
			{ header: _('Service'), width: 300, dataIndex: 'service', sortable: true, renderer: render_name },	
			{ header: _('Config'), width: 200, dataIndex: 'config', sortable: true },	
			{ header: _('Active'), width: 100, dataIndex: 'active', sortable: true, renderer: render_active },	
			{ header: _('Running'), width: 100, dataIndex: 'exists', sortable: true, renderer: render_running },	
			{ header: _('Last Process ID'), width: 100, dataIndex: 'pid', sortable: true },	
			{ header: _('Hostname'), width: 200, dataIndex: 'hostname', sortable: true }	
		],
		autoSizeColumns: true,
		deferredRender:true,
		bbar: new Ext.PagingToolbar({
			store: store,
			pageSize: ps,
			displayInfo: true,
			displayMsg: _('Rows {0} - {1} of {2}'),
			emptyMsg: "No hay registros disponibles"
		}),
		tbar: [ '<% _loc('Search') %>: ', ' ',
				new Ext.app.SearchField({
				store: store,
				params: {start: 0, limit: ps},
				emptyText: '<% _loc('<Enter your search string>') %>'
			}),
<%doc>
			{
			text: _('Verify'),
			icon:'/static/images/verify.gif',
			cls: 'x-btn-text-icon',
			handler: function() {
				var sm = grid.getSelectionModel();
				if (sm.hasSelection()) {
					var sel = sm.getSelected();
					Baseliner.addNewTab('/daemon/new?id_rel=' + sel.data.id , '<% _loc('New Daemon') %>' );
				} else {
					Baseliner.addNewTab('/daemon/new' , '<% _loc('New Daemon') %>' );
				};
			}
			},
</%doc>
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

	grid.on("rowdblclick", function(grid, rowIndex, e ) {
	    var r = grid.getStore().getAt(rowIndex);
	    Baseliner.addNewTab('/daemon/edit?id_rel=' + r.get('id') , r.get('name') );
	});		
    
	// Después de que cargue la página:
	store.load({params:{start:0 , limit: ps}}); 

	return grid;
})()




