(function(params){
    var data = params.data || {};


    var store_category = new Baseliner.Topic.StoreCategory({
        fields: ['category', 'category_name' ],
        autoLoad: true,
        listeners:{
            'load': function(store, rec, opt){
                if (data && data.category) {
                    type_category.setValue(data.category);    
                }                
            }
        }        
    });

    var type_category = new Ext.form.ComboBox({ 
        name: 'category',
        valueField: 'category',
        hiddenName: 'category',
        displayField: 'category_name',
        fieldLabel: _('Category'),
        mode: 'local',
        store: store_category,
        editable: false,
        triggerAction: 'all'
   });

    var variables_input = new Baseliner.VariableForm({
        name: 'variables_input',
        fieldLabel: _('Input'),
        height: 150,
        data: data.variables_input,
        deferredRender: false,
        renderHidden: false,
        no_validation: true
    });    

    var variables_output = new Baseliner.VariableForm({
        name: 'variables_output',
        fieldLabel: _('Output'),
        height: 150,
        data: data.variables_output,
        deferredRender: false,
        renderHidden: false,
        no_validation: true
    }); 

    // var type = new Baseliner.ComboDouble({ 
    //     fieldLabel: _('Type'), name:'type', value: data.type,
    //     data: [ 
    //       ['CAT',_('Catalog')], 
    //       ['GEN',_('Generator')],
    //       ['RUN',_('Execution')] 
    //     ]
    // });

    return [
        type_category,
        Baseliner.ci_box({ name:'bls', fieldLabel:_('BLs'), allowBlank: true, 'class':'bl', value: data.bls, force_set_value: true, singleMode: false }),
        Baseliner.ci_box({ name:'project', fieldLabel:_('Project'), allowBlank: true, role:'Project', value: data.project, force_set_value: true, singleMode: false }),
        Baseliner.ci_box({ name:'area', fieldLabel:_('Area'), allowBlank: true, 'class':'area', value: data.area, force_set_value: true, singleMode: false }),
        variables_input,
        variables_output,
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Active'), name:'active', checked: data.active, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Repeatable'), name:'repeatable', checked: data.frozen, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('CMDB'), name:'notify', checked: data.notify, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Notify'), name:'notify', checked: data.notify, allowBlank: true } 
    ]
})
