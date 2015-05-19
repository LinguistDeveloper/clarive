(function(params){
    var data = params.data || {};
    return [
      new Baseliner.DataEditor({ 
          name:'variables', 
          title: _('Variables to check'), 
          hide_save: true, 
          hide_cancel: true,
          height: 560, 
          data: data.variables || {},
          hide_type: true
      })
    ]
})


