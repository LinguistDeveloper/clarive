(function(){
    var fields = [ 
            {  name: 'id' },
            {  name: 'bl' },
            {  name: 'name' },
            {  name: 'description' },
            {  name: 'active' }
    ];
    
    var store=new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/baseline/list',
        fields: fields
    });

    ///////////////// Baseline Single Row
    var request_data_store=new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/baseline/detail',
        fields: fields 
    });

    var form = new Ext.FormPanel({
        url: '/baseline/update',
        frame: true,
        items: [
            { xtype: 'hidden', name: 'id', value: -1 },
            //{ xtype: 'textfield', name: 'bl', fieldLabel: _('Baseline') },
            //{ xtype: 'textfield', name: 'name', fieldLabel: _('Name') },
           {
            // column layout with 2 columns
            layout:'column'
            ,defaults:{
                //columnWidth:0.5
                layout:'form'
                ,xtype:'panel'
                ,bodyStyle:'padding:0 15px 0 0'
            }
            ,items:[{
                // left column
                columnWidth:0.40,
                defaults:{anchor:'100%'}
                ,items:[
                    { xtype: 'textfield', name: 'bl', fieldLabel: _('Baseline') }
                    ]
                },
                {
                columnWidth:0.60,
                // right column
                defaults:{anchor:'100%'},
                items:[
                    { xtype: 'textfield', name: 'name', fieldLabel: _('Name') }
                ]
                }
            ]
            },            
            { xtype: 'textarea', anchor: '98%', name: 'description', height: 100, fieldLabel: _('Description') }
        ],
        fbar: {
            items: [
                {
                    text: _('Save'), handler: function(){
                        var action = form.getForm().getValues()['id'] >= 0 ? 'update' : 'add';
                        form.getForm().submit({
                            params: { action: action },
                            success: function(f,a){
                                Baseliner.message('Success', a.result.msg );
                                win.close();
                                store.load();
                            },
                            failure: function(f,a){
                                Ext.Msg.alert('Warning', a.result.msg);
                            }
                        });
                    }
                },
                { text: 'Reset', handler: function(){ form.getForm().reset(); } }
            ]
        }
    });

  
    var btn_cerrar = new Ext.Toolbar.Button({
        icon:'/static/images/icons/door_out.png',
        cls: 'x-btn-text-icon',
        text: _('Close'),
        handler: function() {

        }
    })
    
    var btn_grabar_baseline = new Ext.Toolbar.Button({
        icon:'/static/images/icons/database_save.png',
        cls: 'x-btn-text-icon',
        text: _('Save'),
        handler: function(){

        }
    }) 		

    var column1 = {
        xtype:'panel',
        flex: 2,
        layout:'form',
        defaults:{anchor:'100%'},
        items:[
            { xtype: 'hidden', name: '_id', value: -1 },
            { xtype:'textfield', name:'bl', fieldLabel:_('Baseline'), allowBlank:false, emptyText:_('Key baseline') },
            { xtype:'textfield', name:'name', fieldLabel:_('Name'), emptyText:_('Name of the baseline') },
            { xtype:'textarea', name:'description', fieldLabel:_('Description'), emptyText:_('A brief description of the baseline'), height:130 }
        ]
    };

    var column2 = {
        xtype:'panel',
        flex: 1//,
        //items: grid_baseline
    };
 
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
  
    var win = new Ext.Window({
        title: _('Baseline'),
        width: 600,
        autoHeight: true,
        closeAction: 'hide',
        items: form_baseline
        //items: form
    });










    var add_new = function() {
        win.show();
    };

    var baseline_view = function(rec) {
        var ff = form.getForm();
        ff.loadRecord( rec );
        win.show();
    };

    <& /comp/search_field.mas &>

        var ps = 30; //page_size
        store.load({params:{start:0 , limit: ps}}); 

        // create the grid
        var grid = new Ext.grid.GridPanel({
            region: 'center',
            header: false,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            tab_icon: '/static/images/icons/baseline.gif',
            store: store,
            viewConfig: {
                forceFit: true
            },
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask:'true',
            columns: [
                { header: _('Baseline'), width: 200, dataIndex: 'bl', sortable: true },    
                { header: _('Name'), width: 200, dataIndex: 'name', sortable: true },    
                { header: _('Description'), width: 300, dataIndex: 'description', sortable: true },  
                { header: _('Active'), width: 150, dataIndex: 'active', sortable: true, hidden: true }
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: '<% _loc('Rows {0} - {1} of {2}') %>',
                                emptyMsg: "No hay registros disponibles"
                        }),        
            tbar: [ 'Buscar: ', ' ',
                new Ext.app.SearchField({
                    store: store,
                    params: {start: 0, limit: ps},
                    emptyText: '<% _loc('<Enter your search string>') %>'
                }),
                new Ext.Toolbar.Button({
                    text: _('New'),
                    icon:'/static/images/icons/add.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() { add_new(); }
                }),
                new Ext.Toolbar.Button({
                    text: _('Edit'),
                    icon:'/static/images/icons/edit.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            var sel = sm.getSelected();
                            baseline_view(sel);
                        } else {
                            Baseliner.message('Error', _('Select at least one row'));    
                        };
                    }
                }),
                new Ext.Toolbar.Button({
                    text: _('Delete'),
                    icon:'/static/images/icons/delete.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        var sel = sm.getSelected();
                        Ext.Msg.confirm('<% _loc('Confirmation') %>', '<% _loc('Are you sure you want to delete the baseline') %>' + ' <b>' + sel.data.subject + '</b>?', 
                            function(btn){ 
                                if(btn=='yes') {
                                    var conn = new Ext.data.Connection();
                                    conn.request({
                                        url: '/baseline/update?action=delete',
                                        params: { id: sel.data.id },
                                        success: function(resp,opt) { grid.getStore().remove(sel); },
                                        failure: function(resp,opt) { Ext.Msg.alert(_('Error'), '<% _loc('Could not delete the baseline') %>'); }
                                    }); 
                                }
                            } );
                    }
                }),
                '->'
                ]
        });

    grid.getView().forceFit = true;

    grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var row = grid.getStore().getAt(rowIndex);
            baseline_view( row );
    });     
    
    return grid;
})();



