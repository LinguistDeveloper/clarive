(function(params){
    var opts = params.click;

    var controller = opts.controller;
    var filename = opts.filename;

    var load_file = function(){
        Cla.ajax_json( controller, { repo_mid: opts.repo_mid, filename: opts.filename, filepath: opts.filepath }, function(res){
            if( editor ) {
                editor.setValue( res.body );
                editor.parms = res.parms || {};
            }
            panel.enable();
            panel.ownerCt.changeTabIcon( panel, IC('file.png') );
        }, function(res){
            Cla.error( _('Editor'), _('Could not open file `%1`: %2', filename, res?res.msg:'') );
        });
    }

    var editor = new Baseliner.CodeEditor({
        value: params.data
    });

    var parms_edit = function(){
        var parms = new Baseliner.VariableForm({
            name: 'parms',
            height: 300,
            data: {},
            deferredRender: false,
            renderHidden: false
        });

        var btn_parms_save = new Ext.Button({
            icon: IC('save'), text: _('Save'), handler: function(){ 
                console.log( parms.get_save_data() );
            }
        });
    
        var win = new Baseliner.Window({ 
            layout: 'fit',
            width: 800, height: 400,
            tbar: [ 
                '->',
                { text:_('Close'), icon: IC('close'), handler:function(){ win.close() } },
                btn_parms_save 
            ],
            items: [ parms ]
        });
        win.show();
        return true;
    }

    var btn_save = new Ext.Button({
        icon: IC('save'), text: _('Save')
    });

    var btn_parms = new Ext.Button({
        icon: IC('properties'), text: _('Parameters'), handler: function(){ parms_edit() }
    });

    var panel = new Ext.Panel({ 
        layout: 'fit', 
        tab_icon: IC('loading.gif'),
        disabled: true,
        tbar: [ 
            opts.filename,
            '-',
            btn_save,
            btn_parms
        ],
        items: editor
    });

    load_file();

    return panel;
})
