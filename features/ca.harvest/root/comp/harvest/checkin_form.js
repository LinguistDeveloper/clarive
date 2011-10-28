(function(){
    var pkgname = '<% $c->stash->{pkgname} %>';
    var clientpath  = '<% $c->stash->{clientpath} %>';
    var viewpath  = '<% $c->stash->{viewpath} %>';
    var nsid  = '<% $c->stash->{nsid} %>';
    var msg = _('Harvest Checkin into Package: %1', pkgname );

    var store_viewpath = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'viewpath', 
        url: '/harvest/viewpaths',
        baseParams: { ns: nsid },
        fields: [ 
            {  name: 'viewpath' }
        ]
    });
    var combo_viewpath = new Ext.form.ComboBox({
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
    });
    var path_changer = function(){
        store_files.load({ params:{ viewpath: combo_viewpath.getRawValue() } });
    };
    combo_viewpath.on('select', path_changer );
    combo_viewpath.on('keyup', path_changer );
    combo_viewpath.on('change', path_changer );
    var do_checkin = function(f) {
        output.setValue(_('Checkin Started %1...', Baseliner.now() ) + "\n" );
        form.getForm().submit({
            url: '/harvest/checkin',
            //params: { selected: sels.ns, names: sels.name },
            waitMsg: _('Checking in files...'),
            success: function(fp, o){
                output.setValue( output.getValue() + o.result.output );
                Baseliner.messageRaw({ title:_('File Checkin Success'), width: 500 }, _('OK') );
                //win.close();
                //store.load();
            },
            failure: function(fp, o){
                var res = Ext.util.JSON.decode(o.response.responseText);
                output.setValue( output.getValue() + o.result.output );
                Ext.MessageBox.show({
                    title: _('Error during check-in'),
                    msg: res.msg,
                    buttons: Ext.MessageBox.OK,
                    icon: Ext.MessageBox.ERROR
                });
                win.close();
                store.load();
            }
        });
    };
    var button_checkin = { xtype:'button', text:_('Checkin'),
                style: 'font-size: 20px',
                handler: do_checkin, cls: 'x-btn-text-icon',icon: '/static/images/icons/package_add.png' };

    var store_files = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'path', 
        url: '/harvest/client_files',
        baseParams: { clientpath: clientpath },
        fields: ['path'] 
    });
    var render_file = function(value,metadata,rec,rowIndex,colIndex,store) {
        return '<div style="height: 20px; font-family: Consolas, Courier New, monospace; font-size: 12px; font-weight: bold; vertical-align: middle;">' 
            + value 
            + '</div>';
    };
    var view_conf = {
        //enableRowBody: true,
        scrollOffset: 2,
        forceFit: true
    };
    var grid_files = new Ext.grid.GridPanel({
        store: store_files,
        viewConfig: view_conf,
        height: 350,
        columns: [
             { header: _('Files to Checkin'), width: 300, dataIndex: 'path', sortable: false, renderer: render_file }
        ]
    });
    store_files.load({ params:{viewpath:viewpath}});

    var style_cons = 'background: #eee; background-image: none; color: #101010; font-family: "DejaVu Sans Mono", "Courier New", Courier';
    var output = new Ext.form.TextArea({
        name: 'output',
        fieldLabel: _('Harvest Log'),
        style: style_cons,
        width: 700,
        height: 200
    });

    var console = new Ext.Panel({
        layout: 'fit',
        collapsible: true,
        title: _('Harvest Log'),
        split: true,
        height: 350,
        items: [ output ],
        region: 'south'
    });


    var form = new Ext.FormPanel({
        region: 'center',
        frame: true,
        //autoHeight: true,
        width: '100%',
        height: 1000,
        bodyStyle: 'padding: 10px 10px 0 10px;',
        labelWidth: 80,
        layout: 'column',
        defaults: {
            width: 500
        },
        buttons: [ button_checkin ],
        items: [
        { columnWidth: 0.5, xtype:'fieldset',
            labelWidth: 90,
            defaults: {width: 400}, // Default config options for child items
            defaultType: 'textfield',
            autoHeight: true,
            bodyStyle: Ext.isIE ? 'padding:0 0 5px 15px;' : 'padding:10px 15px;',
            border: false,
            style: {
                "margin-left": "10px", // when you add custom margin in IE 6...
                "margin-right": Ext.isIE6 ? (Ext.isStrict ? "-10px" : "-13px") : "0"  // you have to adjust for it somewhere else
            },
            items: [
                 { xtype:'label', html: '<div style="height:50px">'+msg+'</div>', style:'font-size:20px' }
                ,{ xtype:'textarea', name:'comment', fieldLabel: _('Comment'), height: 200, value: '' }
                ,combo_viewpath
                ,{ xtype:'hidden', name:'clientpath', fieldLabel: _('Client Path'), value: clientpath }
                ,{ xtype:'hidden', name:'nsid', value: nsid }
            ]
        },
        { columnWidth: 0.5, layout:'fit', items: grid_files }
        ]
    });

    var panel = new Ext.Panel({
        layout: 'border',
        tbar: [ button_checkin ],
        items: [ form, console ]
    });
    return panel;
})();
