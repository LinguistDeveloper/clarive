(function(params) {
    var form = new Ext.FormPanel({
        frame: true,
        width: 600,
        height: 600,
        //style: 'margin: 20px 200px 200px 20px',
        //style: 'padding: 20px 20px 20px 20px',
        defaults: {
            width: 300
        },
        tab_icon: '/static/images/icons/keyboard.png',
        items: [
            { xtype:'hidden', value: params.ns, name: 'ns' },
            { xtype:'container', height: 50, width: 500, autoEl: { tag: 'div', html: _('Manual Deployment Setup')}, cls: 'form-label-1'},
            //Baseliner.combo_project({ request: { include_root: true }, value: params.project, hiddenName: 'project'  }),
            { xtype:'textfield', name: 'action', fieldLabel: _('Action ID'), allowBlank: false, value: params.action },
            { xtype:'textfield', name: 'name', fieldLabel: _('Activity Name'), allowBlank: false, value: params.name },
            { xtype:'textarea', name: 'paths', fieldLabel: _('Paths'), allowBlank: false, value: params.paths,
                allowBlank: false, minLength: 6, maxLength: 32, minLengthText: _('Minimum %1 characters', 6) },
            { xtype:'container', autoEl: { tag: 'div', html: _('Use regex and forward slashes, separate by comma: ^/files/, ^/xml/') },
                style: 'padding: 0 0 30px 120px' },
            { xtype:'textarea', height: 150, name: 'description', fieldLabel: _('Activity Description'), value: params.description }
        ]
    });
    var panel = new Ext.Panel({
        tbar: [ Baseliner.button(_('Save'), '/static/images/icons/keyboard_add.png', function(){
            form.getForm().submit({
                url: '/manualdeploy/save',
                waitMsg: _('Saving...'),
                success: function(fp, o){
                    var res = Ext.util.JSON.decode(o.response.responseText);
                    Baseliner.message( _('Manual Deploy'), _('Data stored') );
                    Baseliner.close_parent(panel);
                    //output.setValue( output.getValue() + o.result.output );
                    //output_show();
                },
                failure:  function(fp, o){
                    var res = Ext.util.JSON.decode(o.response.responseText);
                    //output.setValue( output.getValue() + o.result.output );
                    Ext.MessageBox.show({
                        title: _('Error while writing to catalog'),
                        msg: res.msg,
                        buttons: Ext.MessageBox.OK,
                        icon: Ext.MessageBox.ERROR
                    });
                }
            });
        } ), { xtype: 'button', text:_('Close'), handler:function(){ Baseliner.close_parent(panel) } } ],
        items: form
    });
    return panel;
})

