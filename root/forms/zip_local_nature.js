(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('Local Dir'), height: 80, name: 'source_dir', value: params.data.source_dir },
        { xtype:'textarea', fieldLabel: _('Zip File Path'), height: 80, name: 'zipfile', value: params.data.zipfile }
    ]
})

