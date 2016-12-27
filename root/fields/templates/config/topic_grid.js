(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    Cla.help_push({ title:_('Topic Grid'), path:'rules/palette/fieldlets/topic-grid' });
    ret.push([
        { xtype:'numberfield', name:'height', fieldLabel:_('Height'), fieldClass: "x-fieldlet-type-height", minValue:'1', value: data.height || "250"}
    ]);
    return ret;
})
