(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.push([ 
        new Baseliner.ComboDouble({
            fieldLabel: _('What Topics to Show'), name:'include_options', value: data.include_options || 'all_parent',
            data: [ 
                ['none',_('No Releases and no Changesets')],
                ['no_releases',_('No Releases')],
                ['no_changesets',_('No Changesets')],
                ['changesets_and_releases',_('Only Changesets and Releases')],
                ['all_parent', _('All Parent Topics') ] 
            ]
        })
    ]);
    return ret;
})
