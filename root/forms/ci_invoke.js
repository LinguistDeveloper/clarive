(function(params){
    var data = params.data || {};
    
    var ci_class =  new Baseliner.CIClassCombo({
        name: 'ci_class',
        allowBlank: false,
        fieldLabel: _('CI Class'),
        value: data.ci_class
    });
    
    ci_class.on('select', function(){
        ci_method.show();
        ci_method.setValue(''); 
        ci_method.store.reload();
    });
    
    Baseliner.CIMethodCombo = Ext.extend(Baseliner.ComboSingleRemote, {
        fieldLabel: _('CI Methods'),
        field: 'name',
        fields: [ 'classname', 'name', 'p_required','p_optional','n_required','n_optional' ],
        url: '/ci/class_methods'
    });
    
    var ci_method = new Baseliner.CIMethodCombo({
        name: 'ci_method',
        allowBlank: false,
        hidden: !data.ci_class,
        value: data.ci_method
    });
    
    var named = new Baseliner.DataEditor({ 
           name:'named', title: _('Named'), 
           hide_save: true, hide_cancel: true,
           data: data.named || {} 
    });
    var ta = Baseliner.cols_templates['textarea'];
    var positional = new Baseliner.GridEditor({
        title: _('Positional'),
        name: 'positional', records: data.positional, preventMark: false,        
        columns: [
            Ext.apply({ dataIndex:'variable', header: _('Name') }, ta() ),
            Ext.apply({ dataIndex:'value', header:_('Value') }, ta() )
        ],
        viewConfig: { forceFit: true }
    });
    ci_method.on('select', function(s,rec,ix){
        var rd = rec.data;
        named.setData(null);
        positional.remove_all();
        if( rd.n_required.length || rd.n_optional.length ) {
            var de={}; //Ext.apply({},named.getData()); // clone
            Ext.each( rd.n_required, function(p){ if(!de[p]) de[p] = '' });
            Ext.each( rd.n_optional, function(p){ if(!de[p]) de[p] = '' });
            named.setData(de);
        }
        if( rd.p_required.length || rd.p_optional.length ) {
            var de=[]; //Ext.apply({},positional.getData()); // clone
            Ext.each( rd.p_required, function(p){ positional.add_row({ variable: p, value: ''}, true) });
            Ext.each( rd.p_optional, function(p){ positional.add_row({ variable: p, value: ''}, true) });
        }
    });
    ci_method.store.on('beforeload', function(){
        this.baseParams = Ext.apply( this.baseParams, { classname: ci_class.getValue() });
    });
    return [ 
       ci_class, ci_method,
       { xtype: 'textfield', name:'ci_mid', fieldLabel: _('MID'), allowBlank: true, value: data.ci_mid },
       { xtype: 'tabpanel', activeTab: 0, height: 300, fieldLabel: _('Arguments'), items: [ named, positional ] }
    ];
})

