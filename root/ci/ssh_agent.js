(function(params){
    var server_store = new Baseliner.store.CI({ baseParams: { role:'Server' } });
    var servers = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('Server'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.rec.data.server != undefined ) 
            servers.setValue( params.rec.data.server ) ;            
    });

    return [
       servers
    ]
})
