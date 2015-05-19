(function(params){
    var common = Cla.dashlet_common(params);
    var data = params.data;
    var days = new Ext.ux.form.SpinnerField({ 
        value: data.days, 
        name: "days",
        fieldLabel: _("Number of days before today to list jobs"),
        anchor: "15%"
    });

    return common.concat([
        Baseliner.ci_box({ name:'bls', fieldLabel:_('Which bls do you want to see'), allowBlank: true,'class':'bl', valueField: 'name', value: data.bls, force_set_value: true, singleMode: false }),
        days
    ])
})




