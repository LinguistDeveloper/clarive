(function(){
    /* var combo_viewpath = new Ext.form.ComboBox({
           name: 'viewpath', 
           hiddenName: 'viewpath',
           fieldLabel: _('View Path'), 
           mode: 'remote', 
           store: store_viewpath, 
           valueField: 'viewpath',
           value: '',
           typeAhead: false,
           minChars: 1,
           displayField:'viewpath', 
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false,
           width: 300
    }); */
    var style_cons = 'background: #eee; background-image: none; color: #101010; font-family: "DejaVu Sans Mono", "Courier New", Courier';
    var output = new Ext.form.TextArea({
        name: 'output',
        fieldLabel: _('Harvest Log'),
        style: style_cons,
        width: 700,
        height: 200
    });
    var combo_project = new Ext.form.ComboBox({
           fieldLabel: _("Project"),
           name: 'envobjid', 
           hiddenName: 'envobjid',
           valueField: 'envobjid',
           typeAhead: false,
           minChars: 1,
           mode: 'remote', 
           store: new Ext.data.JsonStore({
                    root: 'data' , 
                    remoteSort: true,
                    autoLoad: true,
                    totalProperty:"totalCount", 
                    baseParams: { },
                    id: 'package', 
                    url: '/harvest/projects',
                    fields: [ 
                        {  name: 'envobjid' },
                        {  name: 'environmentname' }
                    ]
                }),
           displayField:'environmentname', 
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false
    });
    var output_show = function() {
        if( output.getEl() == undefined ) { 
            form.add( output );
            form.getEl().fadeIn();
            form.doLayout();
        }
    };
    var form = new Ext.FormPanel({
        frame: true, 
        width: 700,
        defaults: { width: 550 },
        title: _('Create Harvest Package'),
        items: [
            combo_project,
            { xtype: 'textfield', name: 'packagename', fieldLabel: _('Package Name'), required: true }
        ],
        buttons: [
            { text: _('Create'),
                handler: function(){
                    output.setValue('');
                    form.getForm().submit({
                        url: '/harvest/create_package',
                        //params: { selected: sels.ns, names: sels.name },
                        waitMsg: _('Creating Harvest Package...'),
                        success: function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            output.setValue( output.getValue() + o.result.output );
                            output_show();
                        },
                        failure:  function(fp, o){
                            var res = Ext.util.JSON.decode(o.response.responseText);
                            output.setValue( output.getValue() + o.result.output );
                            Ext.MessageBox.show({
                                title: _('Error during create package'),
                                msg: res.msg,
                                buttons: Ext.MessageBox.OK,
                                icon: Ext.MessageBox.ERROR
                            });
                            output_show();
                        }
                    });
                }
            }
        ]
    });
    return form;
})()
