(function(node) {
    if( node == undefined ) node = {};
    var form = new Ext.FormPanel({
        frame: true, 
        width: 700,
        defaults: { width: 550 },
        items: [
            { xtype: 'textfield', name: 'name', fieldLabel: _('Workspace Name'), required: true },
            Baseliner.ci_box({ fieldLabel:_('Server'), role:'Server', name:'server' }),
            { xtype: 'textfield', name: 'user', fieldLabel: _('User'), required: true },
            { xtype: 'textfield', name: 'password', inputType: 'password', fieldLabel: _('Password'), required: true },
            { xtype: 'textfield', name: 'remote', fieldLabel: _('Remote Dir'), required: true }
        ],
        buttons: [
            { text: _('Create'),
                handler: function(){
                    var fdata = form.getForm().getValues();
                    Baseliner.ci_call('user', 'workspace_create', fdata, function(res){
                        Baseliner.message( _('Workspace'), res.msg ); 
                        win.close();
                    });
                }
            }
        ]
    });
    var win = new Baseliner.Window({ 
        title: _('New Workspace'),
        closeAction: 'destroy',
        items: [ form ]
    });
    win.show();
})


