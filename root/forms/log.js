(function(params){
    var data = params.data || {};
    
    var level = new Baseliner.ComboDouble({ 
        fieldLabel: _('Message Level'), name:'level', value: data.level || 'info', 
        data: [ 
          ['info',_('Info')], 
          ['warn',_('Warning')],
          ['error',_('Error')],
          ['debug',_('Debug')],
        ]
    });
    
    return [ 
        new Baseliner.MonoTextArea({ fieldLabel: _('Text'), height: 80, name: 'text', value: data.text }),
        level
    ];
})

