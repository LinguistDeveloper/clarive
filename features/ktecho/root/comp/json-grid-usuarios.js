(function(){

	var mistore=new Ext.data.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/usuarios/cargar_usuarios_grid',
		fields: [ 
			{  name: 'id'       },
			{  name: 'username' },
			{  name: 'password' },
			{  name: 'realname' },
			{  name: 'avatar'   },
			{  name: 'alias'    }			
		]
	});
	
	var grid = new Ext.grid.GridPanel({
			title: 'Pruuueba',
			header: false,
            stripeRows: true,
			autoScroll: true,
			autoWidth: true,
			store: mistore,
						autoSizeColumns: true,
						deferredRender:true,

			height: 300,
			selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
			loadMask:'true',
			columns: [
				{ header: _('id'),       width: 150, dataIndex: 'id',       sortable: true },	
				{ header: _('username'), width: 200, dataIndex: 'username', sortable: true },
				{ header: _('password'), width: 200, dataIndex: 'password', sortable: true },
				{ header: _('realname'), width: 200, dataIndex: 'realname', sortable: true },
				{ header: _('avatar'),   width: 150, dataIndex: 'avatar',   sortable: true },
				{ header: _('alias'),    width: 200, dataIndex: 'alias',    sortable: true }
			],
						bbar: new Ext.PagingToolbar({
											store:       mistore,
											pageSize:    10,
											displayInfo: true,
											displayMsg:  'Rows {0} - {1} of {2}',
											emptyMsg:    "No hay registros disponibles"
						})
	});
		
	mistore.load();

	return grid;

})()
