(function(params){
    var server_store = new Baseliner.store.CI({ baseParams: { role:'Server' } });
    var server = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('SSH Server'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.rec.data.server != undefined ) 
            server.setValue( params.rec.data.server ) ;            
    });

    return [
       server,
       { xtype:'textfield', fieldLabel: _('Path'), name:'path', value: params.rec.data.path }
    ]
})


