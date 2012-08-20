(function(params) {
    if( params==undefined ) params={};
    Baseliner.help_push({ title: _('Manual Deploy'), path: '/manualdeploy' });
    var store_roles = new Baseliner.JsonStore({
        root: 'data', remoteSort: true, autoLoad: true,
        totalProperty:"totalCount", baseParams: {}, id: 'id', 
        url: '/role/all', fields: ['id','role','role_hash','description', 'role_name'] 
    });
 
    var tpl = new Ext.XTemplate(
        '<tpl for="."><div class="search-item {recordCls}">',
        '<span>{role_name}</span>',
        '</div></tpl>'
    );
    var tpl2 = new Ext.XTemplate( '<tpl for=".">{role}</tpl>' );

    var combo_roles = new Ext.ux.form.SuperBoxSelect({
        allowBlank: true,
        msgTarget: 'under',
        allowAddNewData: true,
        addNewDataOnBlur: true, 
        //emptyText: _('Enter or select the category tags'),
        triggerAction: 'all',
        resizable: true,
        store: store_roles,
        mode: 'remote',
        fieldLabel: _('Roles'),
        typeAhead: true,
        name: 'role',
        displayField: 'role',
        hiddenName: 'role',
        valueField: 'id',
        displayFieldTpl: tpl2,
        value: params.role_hash,
        extraItemCls: 'x-tag',
        listeners: {
            newitem: function(bs,v, f){
                v = v.slice(0,1).toUpperCase() + v.slice(1).toLowerCase();
                var newObj = {
                    id: v,
                    name: v
                };
                bs.addItem(newObj);
            }
        }
     });
    /* var combo2 = new Ext.form.ComboBox({
           fieldLabel: _("Role"),
           name: 'role',
           hiddenName: 'role',
           valueField: 'id',
           displayField: 'role',
           typeAhead: false,
           minChars: 1,
           mode: 'remote', 
           store: store_roles,
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false
    }); */

    
    var form = new Ext.FormPanel({
        frame: true,
        //style: 'margin: 20px 200px 200px 20px',
        //style: 'padding: 20px 20px 20px 20px',
        defaults: {
            width: 450
        },
        tab_icon: '/static/images/icons/keyboard.png',
        items: [
            { xtype:'hidden', value: params.ns, name: 'id' },
            { xtype:'hidden', value: params.ns, name: 'ns' },
            { xtype:'hidden', value: params.action, name: 'action_last' },
            { xtype:'hidden', value: params.role, name: 'role_last' },
            { xtype:'container', height: 50, width: 500, autoEl: { tag: 'div', html: _('Manual Deployment Setup')}, cls: 'form-label-1'},
            //Baseliner.combo_project({ request: { include_root: true }, value: params.project, hiddenName: 'project'  }),
            { xtype:'textfield', name: 'action', fieldLabel: _('Action ID'), allowBlank: false, value: params.action },
            { xtype:'textfield', name: 'name', fieldLabel: _('Activity Name'), allowBlank: false, value: params.name },
            { xtype:'textarea', name: 'paths', fieldLabel: _('Paths'), allowBlank: false, value: params.paths,
                allowBlank: false, minLength: 1, maxLength: 32, minLengthText: _('Minimum %1 characters', 6) },
            { xtype:'container', autoEl: { tag: 'div', html: _('Use regex and forward slashes, separate by comma: ^/files/, ^/xml/') },
                style: 'padding: 0 0 30px 120px' },
            combo_roles,
            { xtype:'container', autoEl: { tag: 'div', html: '&nbsp;' } },
            { xtype:'textarea', height: 280, name: 'description', fieldLabel: _('Activity Description'), value: params.description }
        ]
    });
    var panel = new Ext.Panel({
        height: '100%',
        width: 600,
        autoScroll:true,
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
        items: [ form ]
    });
    return panel;
})

