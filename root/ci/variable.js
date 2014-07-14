(function(params){
    var data = {};
    data[ 'var_default' ] = params.rec.var_default;
    var mf = new Baseliner.MetaForm({
        data: data
    });
    
    var pnid = 'variables-' + Ext.id();
    var fieldid = pnid + '-field';
    var field;
    var creating_field = false;

    var create_default_field = function(meta){
        if( creating_field ) return;
        creating_field = true;
        var_default.removeAll();
        if( field ) {
            if( Ext.isFunction( field.get_save_data ) ) {
                data[ 'var_default' ] = field.get_save_data();
            } else if( Ext.isFunction( field.getValue ) ) {
                data[ 'var_default' ] = field.getValue();
            } else {
                delete data['var_default'];
            }
        }
        // create field
        meta = Ext.apply({
            id: 'var_default',
            description: params.rec.description,
            type: var_type.getValue(),
            classname: ci_class.getValue(),
            role: ci_role.getValue(),
            data: data,
            field_attributes: { 
                singleMode: !( var_ci_multiple.checked )
            },
            options: combo_opts.getValue()
        }, meta);
        
        // now the MetaForm will generate the default field
        field = mf.to_field(meta); 

        field.columnWidth = .9;
        field.allowBlank = true;
        field.submitValue = true;
        
        var panel_default = new Ext.Panel({ 
            layout:'column', 
            border: false, items:[
                field, 
                { columnWidth: .1, border: false, 
                    items: new Ext.Button({ text: 'refresh', style:'padding-left: 10px', 
                            handler: function(){ create_default_field() } }) } 
            ]
        });
        var_default.add(panel_default);
        field.on('afterrender', function(){
            //panel_default.doLayout();
            var_default.doLayout();
        });
        creating_field = false;
    }
    
    var load_on_type = function( ty ) {
        if( !ty ) return ;
        if( ty == 'ci' ) {
            ci_class.enable(); ci_class.show();
            ci_role.enable(); ci_role.show();
            var_ci_mandatory.enable(); var_ci_mandatory.show();
            var_ci_multiple.enable(); var_ci_multiple.show();
            combo_opts.disable(); combo_opts.hide();
        } else if( ty == 'combo' ) {
            ci_class.disable(); ci_class.hide();
            ci_role.disable(); ci_role.hide();
            var_ci_mandatory.disable(); var_ci_mandatory.hide();
            var_ci_multiple.disable(); var_ci_multiple.hide();
            combo_opts.enable(); combo_opts.show();
        } else if( ty == 'array' ) {
            ci_class.disable(); ci_class.hide();
            ci_role.disable(); ci_role.hide();
            var_ci_mandatory.disable(); var_ci_mandatory.hide();
            var_ci_multiple.disable(); var_ci_multiple.hide();
            combo_opts.disable(); combo_opts.hide();
        } else if( ty == 'textarea' ) {
            ci_class.disable(); ci_class.hide();
            ci_role.disable(); ci_role.hide();
            var_ci_mandatory.disable(); var_ci_mandatory.hide();
            var_ci_multiple.disable(); var_ci_multiple.hide();
            combo_opts.disable(); combo_opts.hide();
        } else {
            ci_class.disable(); ci_class.hide();
            ci_role.disable(); ci_role.hide();
            var_ci_mandatory.disable(); var_ci_mandatory.hide();
            var_ci_multiple.disable(); var_ci_multiple.hide();
            combo_opts.disable(); combo_opts.hide();
        }
        create_default_field({ 
            type: params.rec.var_type,
            classname: params.rec.var_ci_class,
            role: params.rec.var_ci_role,
            field_attributes: {
                singleMode: !( params.rec.var_ci_multiple )
            },
            options: params.rec.var_combo_options
        });
    }

    var var_type = new Baseliner.ComboSingle({ 
        anchor: '100%',
        fieldLabel: _('Type'),
        name: 'var_type',
        allowBlank: false,
        value: params.rec.var_type,
        data: ['value','combo','array','textarea','password','ci']
    });
    
    var var_default = new Ext.Container({ fieldLabel: _('Default') });
    
    var_type.on('select', function(){
        load_on_type( var_type.getValue() );
    });
    
    var ci_class =  new Baseliner.CIClassCombo({
        name: 'var_ci_class',
        hidden: true,
        disabled: true,
        value: params.rec.var_ci_class
    });
    
    var ci_role =  new Baseliner.ComboSingleRemote({ 
        fieldLabel: _('CI Role'),
        name: 'var_ci_role',
        hidden: true,
        disabled: true,
        allowBlank: true,
        baseParams: { name_format: 'short' },
        value: params.rec.var_ci_role || 'ci',
        field: 'name',
        fields: [ 'role', 'name' ],
        url: '/ci/roles'
    });
    
    var var_ci_multiple = new Baseliner.CBox({
        fieldLabel: _('CI Multiple'), 
        name: 'var_ci_multiple',
        checked: params.rec.var_ci_multiple, 
        default_value: false
    });
    
    var var_ci_mandatory = new Baseliner.CBox({
        fieldLabel: _('CI Mandatory'), 
        name: 'var_ci_mandatory',
        checked: params.rec.var_ci_mandatory,
        default_value: true
    });
    
    var combo_opts = new Baseliner.ArrayGrid({ 
        hidden: true,
        disabled: true,
        fieldLabel:_('Combo Options'), 
        name: 'var_combo_options', 
        value: params.rec.var_combo_options,
        default_value:'option1' 
    }); 
    
    load_on_type( params.rec.var_type ) ;
    
    return [
        var_type,
        var_default,
        ci_role,
        ci_class,
        var_ci_multiple,
        var_ci_mandatory,
        combo_opts
       // name is now the variable name { xtype:'textfield', fieldLabel: _('Variable'), name:'variable', allowBlank: true, value: params.rec.variable }
       //{ xtype: 'textarea', fieldLabel: _('Description'), height: 200, name:'description', allowBlank: true, value: params.rec.description }
    ]
})

