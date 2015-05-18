(function(params){
    var data = params.data || {};

    return [
        Baseliner.ci_box({ name:'service', fieldLabel:_('Service'), allowBlank: false, 'role':'CatalogService', value: data.service, force_set_value: true, singleMode: false }),
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Split task'), name:'split_task', checked: data.split_task },
    ]
})

