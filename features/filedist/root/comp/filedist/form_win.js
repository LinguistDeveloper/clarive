(function(params) {
    //alert( JSON.stringify( params ) );
    Baseliner.help_push({ title: _('Windows File Help'), path: '/filedist/form', os: 'win' });

    <& /comp/filedist/form.js &>

    // Host combo
    var store_host = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        baseParams: { os: 'win' },
        url: '/filedist/hosts',
        fields: [ 'host' ]
    });
    var combo_host = new Ext.form.ComboBox({
        disabled: true,
        required: true,
        name: 'host', hiddenName: 'host', valueField: 'host', displayField:'host', 
        fieldLabel: _('Host'), 
        mode: 'remote', 
        store: store_host, 
        value: params.host,
        typeAhead: false,
        minChars: 1,
        editable: true,
        forceSelection: true,
        triggerAction: 'all',
        allowBlank: false,
        width: 300
    });
    Baseliner.load_first( combo_host );

    // Load paths only when combo selected
    var project_selected = false;
    var load_bl = function() {
        project_selected = true; 
    };
    var load_paths = function() {
        if( !project_selected ) return;
        var project = combo_ns.getRawValue();
        store_from.baseParams = { prefix : '/' + project
                                , os     : 'win' 
                                };
        //store_from.load(); //({ params: { prefix: '/' + project } });
        combo_from.enable();
        combo_host.enable();
    };
    if( params.to != undefined ) {
        combo_from.enable();
        combo_host.enable();
    }

    var combo_ns = Baseliner.combo_project({
        request: { include_root: true }, value: params.ns, hiddenName: 'ns',
        on_select: load_bl  });
    var combo_bl = Baseliner.combo_baseline({ value: params.bl, hiddenName: 'bl', on_select: load_paths });

    var form = new Ext.FormPanel({
        frame: true,
        width: 600,
        height: 600,
        //style: 'margin: 20px 200px 200px 20px',
        //style: 'padding: 20px 20px 20px 20px',
        defaults: { width: 400 },
        tab_icon: '/static/images/icons/keyboard.png',
        items: [
            { xtype:'hidden', value: params.os, name: 'id', value: params.id },
            { xtype:'hidden', value: params.os, name: 'os', value: 'win' },
            { xtype:'container', height: 50, width: 500, autoEl: { tag: 'div', html: _('%1 File Deployment Setup', 'Windows')}, cls: 'form-label-1'},
            combo_ns,
            combo_bl,
            combo_from,
            //{ xtype:'textfield', name: 'from', fieldLabel: _('From Path'), allowBlank: false, value: params.action },
            //{ xtype:'container', autoEl: { tag: 'div', html: _('Use regex and forward slashes, ie: ^/files/') },
             //   style: 'padding: 0 0 30px 120px' },
            { xtype:'textfield', name: 'to', fieldLabel: _('To Path'), allowBlank: false, value: params.to },
            combo_host,
            { xtype:'container', autoEl: { tag: 'div', html: _('Destination dir with forward slashes, ie: /tmp/file') },
                style: 'padding: 0 0 30px 120px' },
            { xtype:'textarea', height: 150, name: 'description', fieldLabel: _('Mapping Description'), value: params.description }
        ]
    });
    var panel = new Ext.Panel({
        width: 600,
        height: 600,
        tbar: [ Baseliner.button(_('Save'), '/static/images/icons/keyboard_add.png', function(){
            form.getForm().submit({
                url: '/filedist/save',
                waitMsg: _('Saving...'),
                success: function(fp, o){
                    var res = Ext.util.JSON.decode(o.response.responseText);
                    Baseliner.message( _('File Deploy'), _('Data stored') );
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

