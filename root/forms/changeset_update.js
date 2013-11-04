(function(params){
    var data = params.data || {};
    var ComboStatus = Ext.extend( Baseliner.ComboDoubleRemote, { 
        allowBlank: true,
        url: '/ci/status/combo_list', field: 'id_status', displayField: 'name',
        fields: [ 'id_status', 'name' ]
    });
    return [
        new ComboStatus({ name: 'status_on_ok', fieldLabel: _('Status on Success'), value: data.status_on_ok||''  }),
        new ComboStatus({ name: 'status_on_fail', fieldLabel: _('Status on Failure'), value: data.status_on_fail||''  }),
        new ComboStatus({ name: 'status_on_rollback_ok', fieldLabel: _('Status on Rollback OK'), value: data.status_on_rollback_ok||''  }),
        new ComboStatus({ name: 'status_on_rollback_fail', fieldLabel: _('Status on Rollback Failure'), value: data.status_on_rollback_fail||''  })
    ]
})
