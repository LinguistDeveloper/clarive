(function(params){
    var data = params.data || {};

    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    var date_type =  new Baseliner.ComboDouble({ allowBlank: false, fieldLabel: _('Date to be shown'), name:'date_type', value: data.date_type || 'today', data: [
        ['today', _('Hoy')],
        ['yesterday', _('Yesterday')],
        ['date', _('Date')]
      ] 
    });

    var common = Cla.dashlet_common(params);

    return common.concat([
        ccategory,
        { xtype:'textfield', allowBlank: false, fieldLabel: _('Date field with scheduled start date'), name: 'date_field', value: data.date_field },
        date_type
    ]);
})
