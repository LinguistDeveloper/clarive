(function(params){
    var data = params.data || {};

    var type_form = new Baseliner.ComboDouble({ 
        fieldLabel: _('Type'), name:'type_form', value: data.type_form,
        data: [ 
          ['wizard',_('Wizard')],
          ['topic',_('Topic')],
          ['global',_('Global')]
        ]
    });

    var pn = new Ext.Panel({});

    Baseliner.require('/comp/topic/form_editor.js' + '?'+Math.random(), function(){
        var form_fields = new Baseliner.FieldEditor({
            name: 'fields',
            btn_save_hidden: true, 
            fields: data.fields ? data.fields : undefined
        });
        pn.add(form_fields);
        pn.doLayout();
    });

    return [ 
        type_form,
        pn
    ];
})
