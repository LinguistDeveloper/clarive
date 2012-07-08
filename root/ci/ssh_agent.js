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

    var port_num = params.rec.data.port_num;
    if( port_num == undefined ) port_num = 22;

    return [
       servers,
       { xtype:'textfield', fieldLabel: _('Port'), name:'port_num', value: port_num },
       { xtype:'textfield', fieldLabel: _('Private Key'), name:'port', allowBlank: true, value: params.rec.data.private_key },
    ]
})
