(function(params){
    var is_new = !! params.mid;
    params.rec.var_type = params.rec.var_type || 'value';
    
    var pnid = 'variables-' + Ext.id();
    var fieldid = pnid + '-field';
    var field;
    var creating_field = false;

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
    }

    var var_type = new Baseliner.ComboSingle({ 
        anchor: '100%',
        fieldLabel: _('Type'),
        name: 'var_type',
        allowBlank: false,
        value: params.rec.var_type,
        data: ['value','combo','array','textarea','password','ci']
    });
    
    var_type.on('select', function(){
        load_on_type( var_type.getValue() );
    });
    
    var ci_class =  new Baseliner.CIClassComboSimple({
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
        value: params.rec.var_ci_role || 'CI',
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

    var variables = new Baseliner.VariableForm({
        name: 'variables',
        fieldLabel: _('Default'),
        height: 400,
        hidden: params.rec.mid==undefined,
        variable_name: params.rec.name, 
        default_value: params.rec.variables || params.rec.var_default,  // var_default is for legacy 
        data: params.rec.variables,
        deferredRender: false,
        renderHidden: false
    });
    
    load_on_type( params.rec.var_type ) ;
    var ret = [
        var_type,
        ci_role,
        ci_class,
        var_ci_multiple,
        var_ci_mandatory,
        combo_opts 
    ];
    if( params.rec.mid == undefined  )
       ret.push({ xtype:'container', style:'margin-left:110px', html:_('To set default values, save the CI first then reload') }); 
    ret.push(
            variables
    );
    return ret;
})

