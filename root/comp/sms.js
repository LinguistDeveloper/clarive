(function(params){
    Cla.help_push({
        title: _('System Messages'),
        path: 'admin/system-messages'
    });
    var form = new Baseliner.FormPanel({
        defaults:{ anchor:'100%' },
        bodyStyle: 'padding: 10px 10px 10px 10px;',
        items:[
            { xtype:'textfield', fieldLabel:_('Title'), name:'title', maxLength: 80, allowBlank: false },
            { xtype:'textarea', fieldLabel:_('Text'), height: 60, maxLength: 255, allowBlank: false, name:'text' },
            { xtype:'textfield', fieldLabel:_('Expires'), name:'expires', allowBlank: false, value:'24h' },
            new Baseliner.model.Users({ fieldLabel: _('Users'), name:'users', store: new Baseliner.Topic.StoreUsers({ autoLoad: true }), singleMode: false, }),
            new Baseliner.CLEditor({ name:'more', fieldLabel:_('More Info'), height:340 })
        ]
    });
    var btn_new = new Ext.Button({ icon:IC('action_save.svg'), text:_('Publish'), hidden: true, handler:function(){
        if( !form.getForm().isValid() ) return;
        var d = form.getValues();
        var m = d.users
            ? _('Are you sure you want to broadcast this message?')
            : _('Are you sure you want to broadcast this message to all users?');
        Baseliner.confirm(m, function(){
            Baseliner.ajax_json('/systemmessages/sms_create', d, function(res){
                Baseliner.message(_('SMS'), _('Created message with id %1', res._id) );
                card_show(true);
            });
        });
    }});
    var btn_del = new Ext.Button({ icon:IC('delete.svg'), hidden: false, text:_('Delete'), handler:function(){
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var sel = sm.getSelected();
            Baseliner.ajax_json('/systemmessages/sms_del', { _id:sel.data._id, action:'del' }, function(res){
                Baseliner.message(_('SMS'), _('Deleted message with id %1', sel.data._id) );
                Baseliner.showLoadingMask( grid.getEl());
                grid.store.reload();
            });
        }
    } });
    var btn_cancel = new Ext.Button({ icon:IC('close.svg'), hidden: false, text:_('Cancel'), handler:function(){
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var sel = sm.getSelected();
            Baseliner.ajax_json('/systemmessages/sms_del', { _id:sel.data._id, action:'cancel' }, function(res){
                Baseliner.message(_('SMS'), _('Cancelled message with id %1', sel.data._id) );
                Baseliner.showLoadingMask( grid.getEl());
                grid.store.reload();
            });
        }
    } });
    var btn_clone = new Ext.Button({ text:_('Clone'), hidden: false, icon:IC('copy.svg'), handler:function(){
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var sel = sm.getSelected();
            form.getForm().setValues({ title: sel.data.title, text: sel.data.text, more: sel.data.more });
            card_show(false);
        }
    } });

    var card_show = function(is_grid){
        if( is_grid ) {
            grid.store.load();
            btn_grid.hide();
            btn_new.hide();
            btn_del.show();
            btn_cancel.show();
            btn_clone.show();
            btn_compose.toggle(false);
            btn_compose.show();
            card.getLayout().setActiveItem( grid );
            form.getForm().reset();
        } else {
            btn_del.hide();
            btn_cancel.hide();
            btn_clone.hide();
            btn_new.show();
            btn_grid.show();
            btn_grid.toggle(false);
            btn_compose.hide();
            card.getLayout().setActiveItem( form );
        }
    };
    var btn_grid = new Ext.Button({
        text: _('View Messages'),
        icon: IC('sms.svg'),
        hidden: true,
        pressed: false,
        toggleGroup: 'sms-btn',
        handler: function() {
            card_show(true)
        }
    });
    var btn_compose = new Ext.Button({
        text: _('Compose'),
        icon: IC('edit.svg'),
        pressed: false,
        toggleGroup: 'sms-btn',
        handler: function() {
            card_show(false)
        }
    });

    var btn_close = new Ext.Button({ icon:IC('close.svg'), hidden: false, text:_('Close'), handler: function(){
        win.close();
    } });

    Baseliner.sms_read = function(ix,grid_id){
        var gr = Ext.getCmp(grid_id);
        if( gr ) {
            var row = gr.store.getAt(ix);
            if( !Ext.isArray(row.data.read) ) return;
            var html = function(){/*
                <div id="boot">
                <ul class="unstyled">
                [% for( var i=0; i<read.length; i++ ) { %]
                    <li><code>[%= read[i].ts %]</code> <b>[%= read[i].u %]</b> [%= read[i].add %]</li>
                [% } %]
                </ul>
                </div>
            */}.tmpl(row.data);
            new Baseliner.Window({ bodyStyle:'background: #fff; padding: 10px 10px 10px 10px; overflow:auto', html:html, width:400, height:400, layout:'fit' }).show();
        }
    };
    var render_msg = function(v,m,row,ix){
        return String.format('<b>{0}</b><br>{1}', row.data.title, row.data.text );
    };
    var render_read = function(v,m,row,ix){
        return String.format('<a href="javascript:Baseliner.sms_read({0},\'{1}\')">{2}</a>', ix, grid.id, _('Read (%1)',v?v.length:0) );
    };
    var first_load = true;
    var ps = 60;
    var sms_store =  new Baseliner.JsonStore({ 
            url:'/systemmessages/sms_list', root: 'data' , totalProperty:"totalCount", id:'_id', autoLoad: true,
            fields:['_id','title','text','more','read','t','expires','expired', 'users']
        });
    var grid = new Ext.grid.GridPanel({ 
        store: sms_store,
        width:800,
        height:600,
        header: false,
        stripeRows: true,
        autoScroll: true,
        autoWidth: true,
        viewConfig: { forceFit: true },
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        columns: [
            { header: _('ID'), width: 50, dataIndex: '_id', sortable: true, 
                renderer: function(v,m,row){ 
                    return row.data.expired 
                        ?'<span style="color:#ccc;text-decoration:line-through">'+v+'</span>'
                        :'<span style="font-weight:bold">'+v+'</span>'
                }
            },	
            { header: _('Message'), width: 200, dataIndex: 'text', sortable: true, renderer: render_msg  },
            { header: _('More'), width: 200, hidden: true, dataIndex: 'more', sortable: true },
            { header: _('Expires'), width: 80, dataIndex: 'expires', sortable: true, renderer:function(v,m,row){
                  return row.data.expired ? '<span style="text-decoration: line-through;">'+Cla.user_date(v)+'</span>' : Cla.user_date(v);
            }},
            { header: _('Read'), width: 40, dataIndex: 'read', sortable: true, renderer: render_read }
        ],
        autoSizeColumns: true
    });
    var card = new Ext.Panel({ layout:'card', items:[ grid,form ], activeItem:0 });
    var win = new Baseliner.Window({
        title:_('System Messages'),
        layout:'fit',
        width:800,
        height:600,
        tbar: [ btn_grid, btn_compose,'->', btn_clone, btn_del, btn_cancel, btn_new, btn_close ],
        items: card
    });


    grid.on("activate", function() {
        Baseliner.showLoadingMask( grid.getEl());
    });

    sms_store.on("load", function() {
        Baseliner.hideLoadingMaskFade(grid.getEl());
    });

    win.show();
    return;
})
