(function(params){
    var data = params.data || {};
    return [
      { xtype: 'textfield', name: "mid", fieldLabel: _("Mid"), allowBlank: false, value: data.mid },
      new Baseliner.DataEditor({ 
          name:'variables', 
          title: _('Variables to update'), 
          hide_save: true, 
          hide_cancel: true,
          height: 560, 
          data: data.variables || {},
          hide_type: true
      })
    ]
})


