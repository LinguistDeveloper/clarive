(function(params){
    var data = params.data || {};
    return [
        new Baseliner.UserAndRoleBox({ fieldLabel: _('TO'), name:'to', allowBlank: false, value: data.to }),
        new Baseliner.UserAndRoleBox({ fieldLabel: _('CC'), name:'cc', allowBlank: true, value: data.cc }),
        { xtype: 'textfield', fieldLabel: _('Subject'), name:'subject', anchor:'100%', allowBlank: false, value: data.subject },
        new Baseliner.HtmlEditor({ fieldLabel: _('Body'), name:'body', anchor:'100%', allowBlank: false, value: data.body })
    ]
})
