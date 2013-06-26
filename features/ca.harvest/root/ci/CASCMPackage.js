(function(params){
    var vers = new Baseliner.CIGrid({ 
        fieldLabel: _('Versions'),
        readOnly: true,
        from_mid: params.rec.mid 
    });
    return [
        { xtype:'textfield', fieldLabel:_('PackageObjID'), value: params.rec.packageobjid, readOnly: true, name:'packageobjid',  anchor:'100%' },
        vers
    ]
})

