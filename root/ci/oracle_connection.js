(function(params){
    var server_store = new Baseliner.store.CI({ baseParams: { role:'Server' } });
    var server = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('Server'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.rec.data.server != undefined ) 
            server.setValue( params.rec.data.server ) ;            
    });

    return [
       server,
       { xtype:'textfield', inputType: 'number', fieldLabel: _('Port'), name:'port', value: params.rec.data.port },
       { xtype:'textfield', fieldLabel: _('SID'), name:'sid', value: params.rec.data.sid },
       { xtype:'textfield', fieldLabel: _('User'), name:'user', value: params.rec.data.user },
       { xtype:'textfield', inputType:'password', name:'password', fieldLabel: _('Password'), value: params.rec.data.password }
    ]
})

