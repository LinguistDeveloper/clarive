(function(params){

    var data = params.data || {};

    var store_category_status = new Baseliner.Topic.StoreCategoryStatus({
        url:'/catalog/get_status_topic_service',
        autoLoad: true 
    });

    store_category_status.on('load',function(){
        status_box.setValue( data.init_run_status ) ;            
    });     

    var status_box = new Baseliner.model.Status({
        fieldLabel: _('Init run status'),
        store: store_category_status,
        singleMode: true,
        name: 'init_run_status'
    });

    return [
        Baseliner.ci_box({ name:'task', fieldLabel:_('Task'), allowBlank: false, 'role':'CatalogTask', value: data.task, force_set_value: true, singleMode: true }),
        status_box,
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Help'), name:'help', checked: data.help },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Repeatable'), name:'repeatable', checked: data.repeatable },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Optional'), name:'optional', checked: data.optional },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('CMDB'), name:'cmdb', checked: data.cmdb },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Notify'), name:'notify', checked: data.notify }, 
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Automatic'), name:'automatic', checked: data.automatic }
    ]
})
