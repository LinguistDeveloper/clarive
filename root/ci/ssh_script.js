(function(params){
    var server_store = new Baseliner.store.CI({ baseParams: { role:'Destination' } });
    var server = new Baseliner.model.CISelect({ store: server_store, 
        singleMode: true, 
        fieldLabel:_('SSH Destination'), 
        name:'server', 
        hiddenName:'server', 
        allowBlank:false }); 
    server_store.on('load',function(){
        if( params.rec.data.server != undefined ) 
            server.setValue( params.rec.data.server ) ;            
    });

    return [
       server,
       { xtype:'textfield', fieldLabel: _('Script'), name:'script', value: params.rec.data.script }
    ]
})



