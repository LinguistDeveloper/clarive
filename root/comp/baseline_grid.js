(function(){
    var ps = 30; //page_size
   
    var fields = [ 
            {  name: 'id' },
            {  name: 'bl' },
            {  name: 'name' },
            {  name: 'description' }
    ];
    
    var store=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/baseline/list',
        fields: fields
    });

    ///////////////// Baseline Single Row
    var store_baseline=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/baseline/list',
        fields: fields
    });
    
    store.load({params:{start:0 , limit: ps}}); 
    
    <& /comp/search_field.mas &>
    
    var init_buttons = function(action) {
	    eval('btn_edit.' + action + '()');
	    eval('btn_delete.' + action + '()');
    }

    var add_edit = function(rec) {
	    var win;
	    var title = 'Create baseline';
        
        store_baseline.load({params:{start:0 , limit: ps}});
        
        var grid_baseline = new Ext.grid.GridPanel({
            header: false,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store_baseline,
            enableDragDrop : true,
            ddGroup : 'mygrid-dd',
            height: 182,
            viewConfig: {
                forceFit: true
            },
            selModel: new Ext.grid.RowSelectionModel({
                singleSelect: true
            }),
            loadMask:'true',
            columns: [
                { dataIndex: 'id', hidden: true },
                { header: _('Order (Drag & Drop)'), width: 280, dataIndex: 'bl' }
            ]
        });
     
          
        grid_baseline.on('afterrender', function(grid, rowIndex, columnIndex, e) {
            var ddrow = new Ext.dd.DropTarget(grid_baseline.getView().mainBody, {  
               ddGroup : 'mygrid-dd',  
               notifyDrop : function(dd, e, data){  
                   var sm = grid_baseline.getSelectionModel();  
                   var rows = sm.getSelections();  
                   var cindex = dd.getDragData(e).rowIndex;  
                   if (sm.hasSelection()) {  
                       for (i = 0; i < rows.length; i++) {  
                           store_baseline.remove(store_baseline.getById(rows[i].id));  
                           store_baseline.insert(cindex,rows[i]);  
                       }  
                       sm.selectRecords(rows);
                       btn_grabar_baseline.enable();
                   }
               }
            }); 
        });

 
        var txtname = new Ext.form.TextField({
            name: 'name',
            enableKeyEvents: true,
            fieldLabel: _('Name'),
            allowBlank:false,
            emptyText: _('Name of the baseline')
        });
        
        txtname.on('keypress', function(TextField, e) {
            btn_grabar_baseline.enable();
        });                 

        var ta = new Ext.form.TextArea({
            name: 'description',
            height: 130,
            enableKeyEvents: true,
            fieldLabel: _('Description'),
            emptyText: _('A brief description of the baseline')
        });

        ta.on('keypress', function(TextField, e) {
            btn_grabar_baseline.enable();
        }); 

       
        var column1 = {
           xtype:'panel',
           flex: 2,
           layout:'form',
           defaults:{anchor:'100%'},
           items:[
               { xtype: 'hidden', name: 'id', value: -1 },
               { xtype:'textfield', name:'bl', fieldLabel:_('Baseline'), allowBlank:false, emptyText:_('Key baseline') },
               txtname,
               ta
           ]
        };
   
        var column2 = {
           xtype:'panel',
           flex: 1,
           items: grid_baseline
        };
 
        var btn_cerrar = new Ext.Toolbar.Button({
            icon:'/static/images/icons/door_out.png',
            cls: 'x-btn-text-icon',
            text: _('Close'),
		    handler: function() {
			    win.close();
			    //grid.getSelectionModel().clearSelections();
            }
        });
        
        var btn_grabar_baseline = new Ext.Toolbar.Button({
            icon:'/static/images/icons/database_save.png',
            cls: 'x-btn-text-icon',
            text: _('Save'),
            handler: function(){
			    var form = form_baseline.getForm();
			    var action = form.getValues()['id'] >= 0 ? 'update' : 'add';
                
                var st = grid_baseline.getStore();  
                var sequence_baseline = new Array();
                st.each(function(rec){
                    sequence_baseline.push(rec.get('id'));
                });                

			    if (form.isValid()) {
                        form.submit({
                            params: {action: action, sq: sequence_baseline },
                            success: function(f,a){
                                Baseliner.message(_('Success'), a.result.msg );
                                form.findField("id").setValue(a.result.baseline_id);
                                form.findField("bl").getEl().dom.setAttribute('readOnly', true);
                                btn_grabar_baseline.disable();
                                win.setTitle(_('Edit baseline'));
                                store.load();
                                store_baseline.load();
                            },
                            failure: function(f,a){
                                Ext.Msg.show({  
                                title: _('Information'), 
                                msg: a.result.msg , 
                                buttons: Ext.Msg.OK, 
                                icon: Ext.Msg.INFO
                                }); 						
                            }
                        });
			    }    
            }
        });

	    //Para cuando se envia el formulario no coja el atributo emptytext de los textfields
	    Ext.form.Action.prototype.constructor = Ext.form.Action.prototype.constructor.createSequence(function() {
	        Ext.applyIf(this.options, {
		    submitEmptyText:false
	        });
	    });

        var form_baseline = new Ext.FormPanel({
            url: '/baseline/update',
            frame: true,
            layout: {
                type: 'hbox',
                padding: '5'
            },
            bbar: [
                btn_grabar_baseline,
                btn_cerrar
            ]				    
            ,
            defaults:{
                margins: '0 5 0 0'
            },
            items:[
                column1,
                column2
            ]
        });       

	    if(rec){
		    var ff = form_baseline.getForm();
		    ff.loadRecord( rec );
		    title = 'Edit baseline';
	    }
    
 
        win = new Ext.Window({
            title: _(title),
            width: 600,
            autoHeight: true,
            closeAction: 'hide',
            items: form_baseline
        });
 
	    win.show();
    };
    
    var btn_add = new Ext.Toolbar.Button({
        text: _('New'),
        icon:'/static/images/icons/add.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            add_edit();
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
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the baseline') + ' <b>' + sel.data.bl + '</b>?', 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/baseline/update?action=delete',{ id: sel.data.id },
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
	    title: _('Baseline'),
	    header: false,
	    stripeRows: true,
	    autoScroll: true,
	    autoWidth: true,
	    store: store,
	    viewConfig: {forceFit: true},
	    selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
	    loadMask:'true',
	    columns: [
            { header: _('Baseline'), width: 200, dataIndex: 'bl', sortable: true },    
            { header: _('Name'), width: 200, dataIndex: 'name', sortable: true },    
            { header: _('Description'), width: 300, dataIndex: 'description', sortable: true }  
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
		    btn_add,
		    btn_edit,
		    btn_delete,
		    '->'
	    ]
    });
    
    grid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
	    init_buttons('enable');
    });    
    
    return grid;
})



