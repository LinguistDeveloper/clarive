(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    return common.concat([
        { xtype:'textfield', fieldLabel: _('Days Average'), name: 'days_avg', value: data.days_avg?data.days_avg:'1000D' },
        { xtype:'textfield', fieldLabel: _('Days Last'), name: 'days_last', value: data.days_last?data.days_last:'100D' }
    ])
})




