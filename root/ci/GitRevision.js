(function(params){

    var data = params.rec;
    // console.log( data.repo );
    return [
        { xtype: 'textfield', fieldLabel: _('SHA'), name:'sha', allowBlank: false, value: data.sha },
        Baseliner.ci_box({ name:'repo', class:'BaselinerX::CI::GitRepository', fieldLabel:_('Git Repository'), force_set_value:true, value: data.repo })
    ]
})

