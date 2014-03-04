(function(params){
    var data = params.data || {};
    var errors = new Baseliner.ComboSingle({ fieldLabel: _('Errors'), name:'errors', value: data.errors || 'fail', data: [
        'fail',
        'warn',
        'custom',
        'silent'
    ]});
    var custom_error = new Ext.Panel({ 
        layout:'column', fieldLabel:_('Return Codes'), frame: true, 
        hidden: data.errors!='custom',
        items: [
            { layout:'form', columnWidth:.33, labelAlign:'top', frame: true, items: { xtype:'textfield', anchor:'100%', fieldLabel: _('Ok'), name: 'rc_ok', value: data.rc_ok } },
            { layout:'form', columnWidth:.33, labelAlign:'top', frame: true, items: { xtype:'textfield', anchor:'100%', fieldLabel: _('Warn'), name: 'rc_warn', value: data.rc_warn } },
            { layout:'form', columnWidth:.33, labelAlign:'top', frame: true, items: { xtype:'textfield', anchor:'100%', fieldLabel: _('Error'), name: 'rc_error', value: data.rc_error } }
        ],
        show_hide : function(){ 
            errors.getValue()=='custom' ? this.show() : this.hide();
            this.doLayout();
        }
    });
    errors.on('select', function(){ custom_error.show_hide() });
    return [
        Baseliner.ci_box({ name: 'server', role:'Baseliner::Role::HasAgent', fieldLabel:_('Server'), with_vars: 1, value: data.server, force_set_value: true }),
        { xtype:'textfield', fieldLabel: _('User'), name: 'user', value: data.user },
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 80, name: 'path', value: data.path }),
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Arguments'), 
            name: 'args', 
            value: data.args,
            description:_('Command arguments'), 
            default_value:'.' 
        }), 
        new Baseliner.MonoTextArea({ fieldLabel: _('Home Directory'), height: 50, name: 'home', value: data.home }),
        errors, custom_error,
        new Baseliner.ErrorOutputTabs({ data: data }) 
    ]
})


