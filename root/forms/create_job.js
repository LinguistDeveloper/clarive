(function(params){
    var data = params.data || {};
    var job_type = new Baseliner.ComboDouble({ 
        fieldLabel: _('Job type'), name:'job_type', value: data.job_type || 'static', 
        data: [ ['static',_('Static')], ['promote',_('Promote')], ['demote',_('Demote')] ]
    });
    var combo_bl = Baseliner.combo_baseline({ value: data.bl });
    var store_chain = new Baseliner.JsonStore({
        url: '/job/chains', root: 'data', totalProperty: 'totalCount', id: 'id',
        autoLoad: true,
        fields:['id','rule_name','rule_type']
    });
    var combo_chain = new Ext.form.ComboBox({ //new Baseliner.SuperBox({
        fieldLabel: _('Job Chain'),
        name: 'id_rule',
        displayField:'rule_name',
        hiddenName:'id_rule', 
        valueField: 'id',
        store: store_chain,
        mode: 'remote',
        minChars: 0, //min_chars ,
        loadingText: _('Searching...'),
        allowBlank: true,
        editable: false,
        lazyRender: true,
        value: data.id_rule
    });
    
    var job_stash = new Baseliner.DataEditor({ 
           name:'job_stash', title: _('Job Stash'), 
           height: 400,
           hide_save: true, hide_cancel: true,
           data: data.job_stash || {} 
    });

    return [
        { xtype:'tabpanel', height: '100%', activeTab: 0, items:[
            { xtype:'panel', frame: true, border: false, height: 500, layout:'form', defaults:{ anchor:'100%' }, title:_('Options'), items:[
                job_type,
                combo_bl,
                combo_chain,
                { xtype:'textfield', fieldLabel: _('Scheduled time'), name: 'schedtime', value: data.schedtime },
                { xtype:'textfield', fieldLabel: _('Changesets'), name: 'changesets', value: data.changesets },
                { xtype:'textfield', fieldLabel: _('Username'), name: 'username', value: data.username },
                { xtype:'textarea', fieldLabel: _('Comments'), height: 80, name: 'comments', value: data.comments }
                ]
            },
            job_stash
            ]
        }
    ]
})



