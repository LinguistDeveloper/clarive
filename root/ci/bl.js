(function(params){
    if( !params.rec ) params.rec = {};

    return [
        { xtype:'textfield', name: 'bl', fieldLabel:_('Baseline ID'), anchor:'100%', value: params.rec.bl },
        { xtype:'textfield', name: 'seq', fieldLabel:_('Sequence'), anchor:'100%', value: params.rec.seq==undefined ? 100 : params.rec.seq }
    ]
})


