(function(){
    var ps = 40;
    var store = new Baseliner.JsonStore({
	    root: 'data',
	    remoteSort: true,
	    totalProperty:"totalCount",
	    id: 'id',
	    url: '/tasks/json',
	    fields: [ 'name', 'category', 'assigned', 'description' ]
    });
    var render_category = function(v,metadata,rec) {
        return Baseliner.render_tags( [v], metadata, rec );
    };
    var render_bold = function(value,metadata,rec,rowIndex,colIndex,store) {
        return '<b>'+value+'</b>';
    };
    store.load();

    var ptool = new Baseliner.PagingToolbar({
        store: store,
        pageSize: ps,
        listeners: {
            pagesizechanged: function(pageSize) {
                searchField.setParam('limit', pageSize);
             }
        }
    });

    var searchField =   new Baseliner.SearchField({
        store: store,
        params: {start: 0, limit: ptool.pageSize },
        emptyText: _('<Enter your search string>')
    });


    var grid = new Ext.grid.EditorGridPanel({
		    title: _('Tasks'),
		    header: false,
		    autoScroll: true,
		    autoWidth: true,
		    store: store,
		    clicksToEdit: 'auto',
		    stripeRows: true,
		    viewConfig: {
                forceFit: true
		    },
		    selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
		    loadMask: true,
		    columns: [
			    { header: _('Tarea'), width: 200, dataIndex: 'name', sortable: true, renderer: render_bold },	
			    { header: _('Category'), width: 200, dataIndex: 'category', sortable: true, renderer: render_category },	
			    { header: _('AssignedTo'), width: 150, dataIndex: 'assigned', sortable: true },
			    { header: _('Description'), width: 350, dataIndex: 'description', sortable: true }
		    ],
		    autoSizeColumns: true,
		    deferredRender:true,
		    bbar: ptool,
		    tbar: [ _('Search')+': ', ' ', searchField,
			    new Ext.Toolbar.Button({
				    text: _('Add'),
				    icon:'/static/images/icons/add-green.svg',
				    cls: 'x-btn-text-icon',
				    handler: function(){ alert('add') }				}),
			    new Ext.Toolbar.Button({
				    text: _('Delete'),
				    icon:'/static/images/icons/del_all.svg',
				    cls: 'x-btn-text-icon',
				    handler: function() {
					    var sm = grid.getSelectionModel();
					    var sel = sm.getSelected();
					    Ext.Msg.confirm('<% _loc('Confirmation') %>', 'Are you sure you want to delete the project ' + sel.data.name + '?', 
						    function(btn){ 
							    if(btn=='yes') {
								    var conn = new Ext.data.Connection();
								    conn.request({
									    url: '/tasks/delete',
									    params: { action: 'delete', id: sel.data.id },
									    success: function(resp,opt) { grid.getStore().remove(sel); },
									    failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not delete the release.')); }
								    });	
							    }
						    } );
				    }
			    }),
			    '->'
            ]
    });
    return grid;
})
