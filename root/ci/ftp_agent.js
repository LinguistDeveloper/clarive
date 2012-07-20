(function(params){
    var server_store = new Baseliner.store.CI({ baseParams: { role:'Server' } });
    var server = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('Server'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.rec.server != undefined ) 
            server.setValue( params.rec.server ) ;            
    });

    return [
       server,
       { xtype:'textfield', fieldLabel: _('User'), name:'user', value: params.rec.user },
       { xtype:'textfield', inputType:'password', name:'password', fieldLabel: _('Password'), value: params.rec.password }
    ]
})


