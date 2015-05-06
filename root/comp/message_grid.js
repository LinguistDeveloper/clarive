(function(){
    var username = '<% $c->stash->{username} %>';
    var fields = [ 'id', 'id_message', 'subject',
        'body', 'sender', 'to', 'cc', 'sent', 'created', 'schedule_time', 'received', 'type', 'swreaded'
    ];
    var store=new Baseliner.JsonStore({
        url: '/message/inbox_json',
        root: 'data' , 
        remoteSort: true,
        totalProperty: 'totalCount', 
        id: 'id', 
        baseParams: { username: username },
        fields: fields
    });

    ///////////////// Message Single Row
    var message_data_store=new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id', 
        url: '/message/detail',
        fields: fields 
    });

Ext.override(Ext.form.HtmlEditor, {
    /**
     * Set a readonly mask over the editor
     * @param {Boolean} readOnly - True to set the read only property, False to switch to the editor
     */
    setReadOnly: function(readOnly){
        if(readOnly){
            this.syncValue();			
            this.el.dom.readOnly = true;
        } else {
            if(this.rendered){
                this.wrap.unmask();
            }
            this.el.dom.readOnly = false;
        }
        
    },
   // private
    onRender : function(ct, position){
        Ext.form.HtmlEditor.superclass.onRender.call(this, ct, position);
        this.el.dom.style.border = '0 none';
        this.el.dom.setAttribute('tabIndex', -1);
        this.el.addClass('x-hidden');
        if(Ext.isIE){ // fix IE 1px bogus margin
            this.el.applyStyles('margin-top:-1px;margin-bottom:-1px;')
        }
        this.wrap = this.el.wrap({
            cls:'x-html-editor-wrap', cn:{cls:'x-html-editor-tb'}
        });

        this.createToolbar(this);
        
        this.tb.hide();
        var iframe = document.createElement('iframe');
        iframe.name = Ext.id();
        iframe.frameBorder = 'no';

        iframe.src=(Ext.SSL_SECURE_URL || "javascript:false");

        this.wrap.dom.appendChild(iframe);

        this.iframe = iframe;

        if(Ext.isIE){
            iframe.contentWindow.document.designMode = 'on';
            this.doc = iframe.contentWindow.document;
            this.win = iframe.contentWindow;
        } else {
            this.doc = (iframe.contentDocument || window.frames[iframe.name].document);
            this.win = window.frames[iframe.name];
            this.doc.designMode = 'on';
        }
        this.doc.open();
        this.doc.write(this.getDocMarkup())
        this.doc.close();

        var task = { // must defer to wait for browser to be ready
            run : function(){
                if(this.doc.body || this.doc.readyState == 'complete'){
                    Ext.TaskMgr.stop(task);
                    this.doc.designMode="on";
                    this.initEditor.defer(10, this);
                }
            },
            interval : 10,
            duration:10000,
            scope: this
        };
        Ext.TaskMgr.start(task);

        if(!this.width){
            this.setSize(this.el.getSize());
        }

        this.setReadOnly(this.readOnly);

    }
});
    
    var message_body = new Ext.Component({
       fieldLabel: _('Message'),
        autoEl: {
            tag:'iframe',
            width: 850,
            height: 250,
            border: '0px',
            frameborder: 0,
            style: { 'background-color': '#fff' },
            src: '' 
        }
     });
    
    var show_message_body = function(id_message) {
        var iframe = Ext.getDom( message_body.getId() );
        iframe.src = '/message/body/' + id_message;
        iframe.height = 280;
    };
    var message_form = new Ext.FormPanel({
        //url: '/role/update',
        title: _('Message'),
        region: 'south',
        collapsible: true,
        split: true,
        resizeable: true,
        height: 350,
        frame: true,
        labelWidth: 100, 
        defaults: { width: 850 },
        items: [
            {  xtype: 'hidden', name: 'id', value: -1 }, 
            {  xtype: 'textfield', name: 'subject', fieldLabel: _('Subject'), readOnly: true }, 
            message_body
            //{  xtype: 'htmleditor', name: 'body', readOnly: true, height: 220, fieldLabel: _('Message') }
        ]
    });

    var message_view = function(id, id_message) {
        //////////////// Single message Data Load Event
        message_data_store.on('load', function(obj, rec, options ) {
            try {
                var rec = message_data_store.getAt(0);
                var ff = message_form.getForm();
                ff.loadRecord( rec );
            } catch(e) {
                Ext.Msg.alert(_('Error'), _('Could not load message form data: %1', e.description ) );
            }
        });
        message_data_store.load({ params:{ id: id }});
        show_message_body( id_message );
    };

        var ps = 30; //page_size
        store.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>' }});

        var render_subject = function(value, metadata, rec, rowIndex, colIndex, store) {
            if(rec.get('swreaded') == '1'){
                return value;
            }else{
                return "<div style='font-weight:bold;font-size: 12px;'>" + value + "</div>" ;				
            }
        };


        var check_sm_events = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        // create the grid
        var grid = new Ext.grid.GridPanel({
            region: 'center',
            title: _('Inbox'),
            header: false,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            iconCls: 'icon-inbox',
            store: store,
            viewConfig: [{
                    forceFit: true
            }],
            selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
            sm: check_sm_events,
            loadMask:'true',
            columns: [
                check_sm_events,
                { header: _('Id'), width: 80, dataIndex: 'id', hidden: true, sortable: true },	
                { header: _('Message Id'), width: 80, dataIndex: 'id_message', hidden: true, sortable: true },	
                { header: _('From'), width: 200, dataIndex: 'sender', sortable: true },	
                { header: _('Subject'), width: 300, dataIndex: 'subject', sortable: true, renderer: render_subject },	
                { header: _('To'), width: 150, dataIndex: 'to', sortable: true, hidden: true },	
                { header: _('Message'), width: 300, dataIndex: 'body', sortable: true, hidden: true },
                { header: _('Created'), width: 150, dataIndex: 'created', sortable: true },
                { header: _('Scheduled'), width: 150, dataIndex: 'schedule_time', sortable: true },	
                { header: _('Sent'), width: 150, dataIndex: 'sent', sortable: true } ,
                { header: _('Received'), width: 150, dataIndex: 'received', sortable: true, hidden: true }	
            ],
            autoSizeColumns: true,
            deferredRender:true,
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: _('Rows {0} - {1} de {2}'),
                                emptyMsg: _('There are no rows available')
                        }),        
            tbar: [ 
                new Baseliner.SearchField({
                    store: store,
                    params: {start: 0, limit: ps},
                    emptyText: _('<Enter your search string>')
                }),
                new Ext.Toolbar.Button({
                    text: _('View'),
                    icon:'/static/images/icons/drop-view.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection()) {
                            if(sm.selections.length == '1'){
                                var sel = sm.getSelected();
                                message_view(sel.data.id, sel.data.id_message);
                            }else{
                                Ext.Msg.alert('Error', _('Select only one row'));    
                            }
                        } else {
                            Ext.Msg.alert('Error', _('Select one row'));	
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
                                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the message') + ' <b>' + sel.data.subject + '</b>?', 
                                    function(btn){ 
                                        if(btn=='yes') {
                                            var conn = new Ext.data.Connection();
                                            conn.request({
                                                url: '/message/delete',
                                                params: { id_message: sel.data.id_message, id_queue: sel.data.id },
                                                success: function(resp,opt) { grid.getStore().remove(sel); },
                                                failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not delete the message')); }
                                            }); 
                                        }
                                    } );
                            }else if (sm.selections.length > '1'){
                                Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the ') + ' <b>' + sm.selections.length + '</b> selected messages?',
                                    function(btn){ 
                                        if(btn=='yes') {
                                            var error_items = 0;
                                            var total_items = sm.selections.length;
                                            for( var x=0; x < total_items ; x++ ) {
                                                var conn = new Ext.data.Connection();
                                                conn.request({
                                                    url: '/message/delete',
                                                    params: { id_message: sm.selections.items[x].data.id_message, id_queue: sm.selections.items[x].data.id},
                                                    success: function(resp,opt) { 
                                                        grid.getStore().remove(sm.selections.items[error_items]);
                                                        store.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>' }});
                                                    },
                                                    failure: function(resp,opt) { error_items++; Ext.Msg.alert(_('Error'), _('Could not delete the message')); }
                                                });
                                            }
                                        }
                                    } );
                            }
                        }else{
                            Ext.Msg.alert('Error', _('Select at least one row'));
                        }   

                    }                    
                }),
                new Ext.Toolbar.Button({
                    text: _('Delete all'),
                    icon:'/static/images/del.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete all the inbox messages?'),
                        function(btn){ 
                            if(btn=='yes') {
                                var conn = new Ext.data.Connection();
                                conn.request({
                                    url: '/message/delete_all',
                                    params: { username: username},
                                    success: function(resp,opt) { store.load({params:{start:0 , limit: ps, query_id: '<% $c->stash->{query_id} %>' }});},
                                    failure: function(resp,opt) { Ext.Msg.alert(_('Error'), _('Could not delete all the inbox messages')); }
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
           message_view( row.get('id'), row.get('id_message') );
           // var cell = grid.getView().getCell(rowIndex,3);
           // if(row.get('swreaded') == '0'){
           //     Ext.fly(cell).update('<div style="padding-left: 5px;padding-top: 3px">' + row.get('subject') + '</div>', false);				
           // }
    });
    
    var panel = new Ext.Panel({
        layout: 'border',
        items: [ grid, message_form ]
    });

    panel.setTitle(_("Inbox for %1", username) );
    return panel;
})();



