(function(params){
    if( !params.rec ) params.rec = {};

    var bls = Baseliner.ci_box({ name:'bls', hiddenName:'bls', "class":'BaselinerX::CI::bl', allowBlank:false, singleMode:false,
        fieldLabel:_('BLs'), value: params.rec.bls, force_set_value: true });
    var bind_releases = params.rec.bind_releases == undefined ? false : params.rec.bind_releases;

	var ci_update = params.rec.ci_update == undefined ? false : params.rec.ci_update;
	var frozen = params.rec.frozen == undefined ? false : params.rec.frozen;
	var readonly = params.rec.readonly == undefined ? false : params.rec.readonly;

    return [
        bls,
        { xtype:'textfield', name: 'seq', fieldLabel:_('Sequence'), anchor:'100%', value: params.rec.seq==undefined ? 100 : params.rec.seq },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Bind releases'), name:'bind_releases', checked: bind_releases, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('CI update'), name:'ci_update', checked: ci_update, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Frozen'), name:'frozen', checked: frozen, allowBlank: true },
        { xtype: 'cbox', colspan: 1, fieldLabel: _('Read only'), name:'readonly', checked: readonly, allowBlank: true },
        {
            xtype: 'radiogroup',
            name: 'type',
            anchor:'75%',
            fieldLabel: _('Type'),
            defaults: {xtype: "radio",name: "type"},
            items: [
                {boxLabel: _('General'), inputValue: 'G', checked: params.rec.type == undefined || params.rec.type == 'G'},
                {boxLabel: _('Initial'), inputValue: 'I', checked: params.rec.type == 'I'},
                {boxLabel: _('Deployable'), inputValue: 'D', checked: params.rec.type == 'D'},
                {boxLabel: _('Canceled'), inputValue: 'FC', checked: params.rec.type == 'FC'},
                {boxLabel: _('Final'), inputValue: 'F', checked: params.rec.type == 'F'}
            ]
        }
    ]
})


