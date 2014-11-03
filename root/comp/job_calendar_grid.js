<%args>
    $can_edit => 0
</%args>
(function(){
    var store=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty: "totalCount", 
        id: 'id', 
        url: '/job/calendar_grid_json',
        fields: [ 
            {  name: 'id' },
            {  name: 'name' },
            {  name: 'description' },
            {  name: 'seq' },
            {  name: 'bl' },
            {  name: 'bl_desc' },
            {  name: 'ns' },
            {  name: 'ns_desc' }
        ]
    });

        var ps = 30; //page_size
        store.load({params:{start:0 , limit: ps}}); 

        //Seleccion multiple con checkboxes		
        var checkSelectionModel = new Ext.grid.CheckboxSelectionModel();

        var render_bl = function(v,metadata,rec,rowIndex,colIndex,store) {
            return v == null || v == '*' ? '['+_('Global')+']' : String.format('<b>{0} ({1})</b>', v, rec.data.bl );
        };

        var render_ns = function(v,metadata,rec,rowIndex,colIndex,store) {
            return v == null || v == '/' ? '['+_('Global')+']' : String.format('{0} ({1})', v, rec.data.ns_desc );
        };

        var render_cal = function(v,metadata,rec,rowIndex,colIndex,store) {
            return String.format('<a href="javascript:Baseliner.edit_calendar(\'{1}\', \'{2}\')" style="font-size: 13px;">{0}</a>',
                v, grid.id, rowIndex );
        };

        Baseliner.edit_calendar = function( id_or_rec, ix ) {
            var r = ( typeof id_or_rec == 'object' ) ? id_or_rec : Ext.getCmp( id_or_rec ).getStore().getAt( ix );
            Baseliner.addNewTabComp('/job/calendar?id_cal=' + r.get('id') , r.get('name'), { tab_icon:'/static/images/icons/calendar_view_month.png' } );
        };
        
        var btn_add = new Baseliner.Grid.Buttons.Add({    
            handler: function() {
                //Window
                var ns_store = new Ext.data.SimpleStore({ 
                   fields: ['value', 'name', 'type' ], 
                   data : <% js_dumper( $c->stash->{namespaces} ) %>
                }); 
                var bl_store = new Ext.data.SimpleStore({ 
                   fields: ['value', 'name'], 
                   data : <% js_dumper( $c->stash->{baselines} ) %>
                }); 						
                var sm = grid.getSelectionModel();
                var copyof = sm.hasSelection() ? sm.getSelected().get('id') : _('[Select a calendar]');
                var new_cal = new Ext.FormPanel({
                    url: '/job/calendar_update?newAction=create',
                    frame: true,
                    labelWidth: 150, 
                    defaults: { width: 350 },
                    buttons: [
                        {  text: _('OK'),
                            handler: function(){ 
                                var ff = new_cal.getForm();
                                var comboCopy = ff.findField('copyof');
                                if(!comboCopy.disabled){
                                    if(comboCopy.getValue().search(/^\d+$/)>=0){
                                        ff.submit({
                                            success: function(form, action) { 
                                                grid.getStore().load();
                                                win.close(); 
                                            },
                                            failure: function(form, action) { Ext.Msg.alert(_('Failure'), action.result.msg); }
                                        });
                                    }else{
                                        Ext.Msg.alert(_('Failure'), "Si quiere realizar una copia de un calendario, debe seleccionar al menos uno de la lista.");
                                    }
                                }else{
                                    ff.submit({
                                        success: function(form, action) { 
                                            grid.getStore().load();
                                            win.close(); 
                                        },
                                        failure: function(form, action) { Ext.Msg.alert(_('Failure'), action.result.msg); }
                                    });										
                                }
                            }
                        },
                        {  text: _('Cancel') , handler: function(){  win.close() } }
                    ],
                    items: [
                        {  xtype: 'hidden', name: 'action', value: 'create' },
                        {  xtype: 'textfield', name: 'name', fieldLabel: _('Calendar Name'), allowBlank: false }, 
                        {  xtype: 'textarea', name: 'description', fieldLabel: _('Description') }, 
                        {  xtype: 'textfield', name: 'seq', fieldLabel: _('Precedence'), allowBlank: false, value: 100 }, 
                        {
                            xtype: 'radiogroup',
                            fieldLabel: 'Modo de creacion',
                            items: [
                                {boxLabel: 'Crear como nuevo', name: 'rbMode', inputValue: '1', checked: true},
                                {boxLabel: 'Crear como copia de otro', name: 'rbMode', inputValue: '2'}
                            ],
                            listeners: {
                                'change': function(rg,checked){
                                    var flag = (checked.getGroupValue() == '1');
                                    var ff = new_cal.getForm();
                                    var comboCopy = ff.findField('copyof');
                                    comboCopy.setDisabled(flag);
                                }
                            }
                        },								
                        {  xtype: 'combo', 
                                   name: 'copyof', 
                                   hiddenName: 'copyof',
                                   fieldLabel: _('Copy of'), 
                                   disabled: true,
                                   mode: 'local', 
                                   editable: false,
                                   forceSelection: true,
                                   triggerAction: 'all',
                                   store: store,
                                   value: copyof,
                                   valueField: 'id',
                                   displayField:'name', 
                                   allowBlank: false
                        },								
                        {  xtype: 'combo', 
                                   name: 'bl', 
                                   hiddenName: 'bl',
                                   fieldLabel: _('Baseline'),
                                   mode: 'local', 
                                   editable: false,
                                   forceSelection: true,
                                   triggerAction: 'all',
                                   store: bl_store, 
                                   valueField: 'value',
                                   value: '*',
                                   displayField:'name', 
                                   allowBlank: false
                        },	
                        Baseliner.ci_box({ name:'ns', role:'Project', fieldLabel:_('Namespace'), emptyText: _('Global') })
                    ]
                });
                var win = new Ext.Window({
                    autoHeight: true,
                    width: 550,
                    title: _('Create Calendar'),
                    items: new_cal
                });
                win.show();
            }
        });	        
        
        // create the grid
        var grid = new Ext.grid.GridPanel({
            title: _('Job Calendars'),
            header: false,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            store: store,
            viewConfig: { forceFit: true,
                enableRowBody: true,
                getRowClass : function(rec, index, p, store){
                    var s = rec.data.description;
                    if( s ) {
                        s = s.replace( /\<br\>/g , ', ');
                        p.body = String.format(
                            '<div style="padding: 0px 0px 0px 30px; color:#999">{0}</div>'
                            , s );
                        return ' x-grid3-row-expanded';
                    } else {
                        p.body = '';
                        return ' ';
                    }
                }
            },
            selModel: checkSelectionModel, //new Ext.grid.RowSelectionModel({singleSelect:true}),
            loadMask:'true',
            columns: [
                checkSelectionModel,
                { header: _('Calendar'), width: 200, dataIndex: 'name', sortable: true, renderer: render_cal },	
                { header: _('Precedence'), width: 80, dataIndex: 'seq', sortable: true },	
                { header: _('Baseline'), width: 100, dataIndex: 'bl_desc', sortable: true, renderer: render_bl },	
                { header: _('Namespace'), width: 150, dataIndex: 'ns', sortable: true, renderer: render_ns },	
                { header: _('Description'), width: 200, dataIndex: 'description', sortable: true, hidden: true, renderer: Baseliner.render_wrap },	
                { header: _('Namespace Description'), width: 200, dataIndex: 'ns_desc', hidden: true, sortable: true }	
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: 'Rows {0} - {1} de {2}',
                                emptyMsg: "No hay registros disponibles"
                        }),        
            tbar: [ _('Search')+': ', ' ',
                new Baseliner.SearchField({
                    store: store,
                    params: {start: 0, limit: ps}
                }),
% if( $can_edit ) {
                btn_add,
                //new Ext.Toolbar.Button({
                //    text: _('Add'),
                //    icon:'/static/images/icons/add.gif',
                //    cls: 'x-btn-text-icon',
                //    handler: function() {
                //        //Window
                //        var ns_store = new Ext.data.SimpleStore({ 
                //           fields: ['value', 'name', 'type' ], 
                //           data : <% js_dumper( $c->stash->{namespaces} ) %>
                //        }); 
                //        var bl_store = new Ext.data.SimpleStore({ 
                //           fields: ['value', 'name'], 
                //           data : <% js_dumper( $c->stash->{baselines} ) %>
                //        }); 						
                //        var sm = grid.getSelectionModel();
                //        var copyof = sm.hasSelection() ? sm.getSelected().get('id') : _('[Select a calendar]');
                //        var new_cal = new Ext.FormPanel({
                //            url: '/job/calendar_update',
                //            frame: true,
                //            labelWidth: 150, 
                //            defaults: { width: 350 },
                //            buttons: [
                //                {  text: _('OK'),
                //                    handler: function(){ 
                //                        var ff = new_cal.getForm();
                //                        var comboCopy = ff.findField('copyof');
                //                        if(!comboCopy.disabled){
                //                            if(comboCopy.getValue().search(/^\d+$/)>=0){
                //                                ff.submit({
                //                                    success: function(form, action) { 
                //                                        grid.getStore().load();
                //                                        win.close(); 
                //                                    },
                //                                    failure: function(form, action) { Ext.Msg.alert(_('Failure'), action.result.msg); }
                //                                });
                //                            }else{
                //                                Ext.Msg.alert(_('Failure'), "Si quiere realizar una copia de un calendario, debe seleccionar al menos uno de la lista.");
                //                            }
                //                        }else{
                //                            ff.submit({
                //                                success: function(form, action) { 
                //                                    grid.getStore().load();
                //                                    win.close(); 
                //                                },
                //                                failure: function(form, action) { Ext.Msg.alert(_('Failure'), action.result.msg); }
                //                            });										
                //                        }
                //                    }
                //                },
                //                {  text: _('Cancel') , handler: function(){  win.close() } }
                //            ],
                //            items: [
                //                {  xtype: 'hidden', name: 'action', value: 'create' },
                //                {  xtype: 'textfield', name: 'name', fieldLabel: _('Calendar Name'), allowBlank: false }, 
                //                {  xtype: 'textarea', name: 'description', fieldLabel: _('Description') }, 
                //                {  xtype: 'textfield', name: 'seq', fieldLabel: _('Precedence'), allowBlank: false, value: 100 }, 
                //                {
                //                    xtype: 'radiogroup',
                //                    fieldLabel: 'Modo de creacion',
                //                    items: [
                //                        {boxLabel: 'Crear como nuevo', name: 'rbMode', inputValue: '1', checked: true},
                //                        {boxLabel: 'Crear como copia de otro', name: 'rbMode', inputValue: '2'}
                //                    ],
                //                    listeners: {
                //                        'change': function(rg,checked){
                //                            var flag = (checked.getGroupValue() == '1');
                //                            var ff = new_cal.getForm();
                //                            var comboCopy = ff.findField('copyof');
                //                            comboCopy.setDisabled(flag);
                //                        }
                //                    }
                //                },								
                //                {  xtype: 'combo', 
                //                           name: 'copyof', 
                //                           hiddenName: 'copyof',
                //                           fieldLabel: _('Copy of'), 
                //                           disabled: true,
                //                           mode: 'local', 
                //                           editable: false,
                //                           forceSelection: true,
                //                           triggerAction: 'all',
                //                           store: store,
                //                           value: copyof,
                //                           valueField: 'id',
                //                           displayField:'name', 
                //                           allowBlank: false
                //                },								
                //                {  xtype: 'combo', 
                //                           name: 'bl', 
                //                           hiddenName: 'bl',
                //                           fieldLabel: _('Baseline'),
                //                           mode: 'local', 
                //                           editable: false,
                //                           forceSelection: true,
                //                           triggerAction: 'all',
                //                           store: bl_store, 
                //                           valueField: 'value',
                //                           value: '*',
                //                           displayField:'name', 
                //                           allowBlank: false
                //                },	
                //                Baseliner.ci_box({ name:'ns', role:'Project', fieldLabel:_('Namespace'), emptyText: _('Global') })
                //            ]
                //        });
                //        var win = new Ext.Window({
                //            layout: 'fit',
                //            height: 300, width: 550,
                //            title: _('Create Calendar'),
                //            items: new_cal
                //        });
                //        win.show();
                //    }
                //}),
                new Ext.Toolbar.Button({
                    text: _('Edit'),
                    icon:'/static/images/icons/edit.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            var sel = sm.getSelected();
                            Baseliner.edit_calendar( sel );
                        } else {
                            Ext.Msg.alert('Error', _('Select at least one row'));	
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
                        if (sm.hasSelection()) {
                            if(sm.selections.length == '1'){
                                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the calendar') + ' ' + sel.data.name + '?', 
                                    function(btn){ 
                                        if(btn=='yes') {
                                            var conn = new Ext.data.Connection();
                                            conn.request({
                                                url: '/job/calendar_update',
                                                params: { action: 'delete', id_cal: sel.data.id },
                                                success: function(resp,opt) { grid.getStore().remove(sel); },
                                                failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not delete the calendar.')); }
                                            });	
                                        }
                                    }
                                );
                            }else{
                                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the ') + ' <b>' + sm.selections.length + '</b> selected calendars?',
                                    function(btn){ 
                                        if(btn=='yes'){
                                            var total_items = sm.selections.length;
                                            for( var x=0; x < total_items ; x++ ) {
                                                var conn = new Ext.data.Connection();
                                                conn.request({
                                                    url: '/job/calendar_update',
                                                    params: { action: 'delete', id_cal: sm.selections.items[x].data.id},
                                                    success: function(resp,opt) {grid.getStore().remove(sm.selections.items[0]);},
                                                    failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not delete the calendar')); }
                                                });
                                            }
                                        }
                                    }
                                );
                            }
                        }else{
                            Ext.Msg.alert('Error', _('Select at least one calendar'));
                        }
                    }
                }),
% }
                new Ext.Toolbar.Button({
                    text: _('Previsualizar'),
                    icon:'/static/gui/extjs/resources/images/default/shared/calendar.gif',
                    hidden: true,  // Eric -- We won't need this once the project namespace is disabled from calendar creation.
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var lastBL = "";
                            var commonBL = "";
                            var sel = sm.getSelections();
                            var idsSelected ="";
                            var nsSelected ="";
                            var _namespaces ="";
                            for(var i=0;i<sel.length;i++){
                                idsSelected = idsSelected + ((idsSelected=="")?"":",") + sel[i].data.id;
                                nsSelected = nsSelected + ((nsSelected=="")?"":",") + sel[i].data.ns;
                                _namespaces = _namespaces + ((_namespaces=="")?"":" + ") + sel[i].data.name;
                                if(lastBL!=""){
                                    if(lastBL != sel[i].data.bl && i>0 && sel[i].data.bl != "*"){
                                        Ext.Msg.alert('Error', 'No se pueden previsualizar calendarios si tienen entornos diferentes.');
                                        return;
                                    }
                                }
                                lastBL = (sel[i].data.bl != "*") ? sel[i].data.bl : "";
                                commonBL = sel[i].data.bl;
                            }
                            var _d = new Date();
                            var fechaTexto = _d.getDate() + "/" + (_d.getMonth()+1) + "/" + _d.getFullYear();
                            Baseliner.addNewTabComp('/job/preview_calendar?ns=' + nsSelected + '&bl=' + commonBL + '&date=' + fechaTexto, _('Previsualizar Calendario') + ' ['+_namespaces+']');
                        } else {
                            Ext.Msg.alert('Error', _('Select at least one row'));	
                        };
                    }
                }),				
                '->'
                ]
        });

    grid.getView().forceFit = true;

% if( $can_edit ) {
    grid.on("rowdblclick", function(grid, rowIndex, e ) {
        Baseliner.edit_calendar( grid.id, rowIndex );
    });		
% }
        
    return grid;
})();

