(function(params){
    var data = params.data || {};
    return [
        { xtype:'textarea', fieldLabel: _('Local Dir'), height: 80, name: 'source_dir', value: params.data.source_dir },
        { xtype:'textarea', fieldLabel: _('Tar File Path'), height: 80, name: 'tarfile', value: params.data.tarfile },
	{ xtype:'tabpanel', fieldLabel: _('Files'), height: 200, activeTab:0, items:[
            new Baseliner.ArrayGrid({ 
                title:_('Include'), 
                name: 'include', 
                value: data.include,
                description:_('Include Files'), 
                default_value:'.*' 
            }), 
            new Baseliner.ArrayGrid({ 
                title:_('Exclude'), 
                name: 'exclude', 
                value: data.exclude,
                description:_('Exclude Files'), 
                default_value:'.*' 
            })
        ]}
    ]
})
