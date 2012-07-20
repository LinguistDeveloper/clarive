(function(params){
    var port_num = params.rec.data.port_num;
    if( port_num == undefined ) port_num = 22;

    return [
       Baseliner.ci_box({ name:'server', fieldLabel:_('Server'), role:'Server', value: params.rec.data.server }),
       { xtype:'textfield', fieldLabel: _('Port'), name:'port_num', value: port_num },
       { xtype:'textarea', height: 180, anchor:'100%', fieldLabel: _('Private Key'), name:'port', allowBlank: true, value: params.rec.data.private_key },
    ]
})
