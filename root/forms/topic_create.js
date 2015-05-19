(function(params){
    var data = params.data || {};
    return [
      { xtype: 'textfield', name: "title", fieldLabel: _("Title of the topic"), allowBlank: false, value: data.title },
      { xtype: 'textfield', name: "category", fieldLabel: _("Category (id or name)"), allowBlank: false, value: data.category },
      { xtype: 'textfield', name: "status", fieldLabel: _("Status (id or name)"), allowBlank: false, value: data.status },
      { xtype: 'textfield', name: "username", fieldLabel: _("Owner of the topic. Blank for 'clarive'"), allowBlank: true, value: data.username },
      new Baseliner.DataEditor({ 
          name:'variables', 
          title: _('Topic data. Type id_field in key and string or variable (${variable}) in value'), 
          hide_save: true, 
          hide_cancel: true,
          height: 560, 
          data: data.variables || {},
          hide_type: true
      })
    ]
})


