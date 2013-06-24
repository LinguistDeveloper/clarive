(function(params){
return [
   { xtype:'textfield', fieldLabel: _('Root Dir'), name:'root_dir', value: params.rec.root_dir, allowBlank: true, anchor: '100%' },
   { xtype:'textfield', fieldLabel: _('Start Path'), name:'start_path', value: params.rec.start_path, allowBlank: true, anchor: '100%' }
]
})
