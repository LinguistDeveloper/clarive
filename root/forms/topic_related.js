(function(params){
    var data = params.data || {};


    var cstatus = new Baseliner.StatusBox({ name: 'related_status', fieldLabel: _('Filter statuses'), value: data.related_status || ''  });
    var ccategory = new Baseliner.CategoryBox({ name: 'related_categories', fieldLabel: _('Filter categories'), value: data.related_categories || ''  });
    var query_type = new Baseliner.ComboSingle({ fieldLabel: _('Query type'), name:'query_type', value: params.data.query_type || 'children', data: [
        'children',
        'parents',
        'related'
    ]});

    return [
        { xtype:'textfield', fieldLabel: _('Mid'), name: 'mid', value: data.mid, allowBlank: false },
        query_type,
        cstatus,
        ccategory,
        { xtype:'numberfield', fieldLabel: _('Depth'), name: 'depth', value: data.depth || 1 },
        { xtype:'textfield', fieldLabel: _('Fields'), name: 'fields', value: data.fields }
    ]
})




