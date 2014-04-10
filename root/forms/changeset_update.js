(function(params){
    var data = params.data || {};
    return [
        new Baseliner.ComboStatus({ name: 'status_on_ok', fieldLabel: _('Status on Success'), value: data.status_on_ok||''  }),
        new Baseliner.ComboStatus({ name: 'status_on_fail', fieldLabel: _('Status on Failure'), value: data.status_on_fail||''  }),
        new Baseliner.ComboStatus({ name: 'status_on_rollback_ok', fieldLabel: _('Status on Rollback OK'), value: data.status_on_rollback_ok||''  }),
        new Baseliner.ComboStatus({ name: 'status_on_rollback_fail', fieldLabel: _('Status on Rollback Failure'), value: data.status_on_rollback_fail||''  })
    ]
})
