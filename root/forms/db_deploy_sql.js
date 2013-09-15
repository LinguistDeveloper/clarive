(function(params){
    var ignore = new Ext.form.Checkbox({ name: 'ignore', checked: ( params.data.ignore=='on' ? true : false ) , fieldLabel: _("Ignore Errors") });
    var transactional = new Ext.form.Checkbox({ name: 'transactional', checked: ( params.data.transactional=='on' ? true : false ) , fieldLabel: _("Transactional") });
    return [
       Baseliner.ci_box({ name:'db', anchor:'100%', fieldLabel:_('Database'), role:'DatabaseConnection', force_set_value: true, value: params.data.db }),
        ignore,
        transactional,
       { xtype:'textarea', height: 180, anchor:'100%', fieldLabel: _('Options'), name:'options', value: params.data.options }
    ]
})



