(function(node) {
    if( node == undefined ) node = {};
    var form = new Ext.FormPanel({
        frame: true, 
        width: 700,
        defaults: { width: 550 },
        items: [
            { xtype: 'textfield', name: 'name', fieldLabel: _('Name'), required: true },
            { xtype: 'textfield', name: 'agent', fieldLabel: _('Agent'), required: true },
            { xtype: 'textfield', name: 'user', fieldLabel: _('User'), required: true },
            { xtype: 'textfield', name: 'password', inputType: 'password', fieldLabel: _('Password'), required: true },
            { xtype: 'textfield', name: 'remote', fieldLabel: _('Remote Dir'), required: true }
        ],
        buttons: [
            { text: _('Create'),
                handler: function(){
                    form.getForm().submit({
                        url: '/gittree/tag_new',
                        //params: { selected: sels.ns, names: sels.name },
                        waitMsg: _('Creating Tag...'),
                        success: function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            Baseliner.message( _('Create Tag'), res.msg );
                            win.close();
                        },
                        failure:  function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            Ext.MessageBox.show({
                                title: _('Error during tag create'),
                                msg: res.msg,
                                buttons: Ext.MessageBox.OK,
                                icon: Ext.MessageBox.ERROR
                            });
                        }
                    });
                }
            }
        ]
    });
    var win = new Ext.Window({ 
        title: _('New Workspace'),
        closeAction: 'destroy',
        items: [ form ]
    });
    win.show();
})


