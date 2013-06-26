(function(params){
    if( ! params.rec ) params.rec = {};
    var data = params.rec;
	
    var store = new Ext.data.ArrayStore({
        fields: [ 'parse_type' ],
        data : [ ['Path'], ['Source'] ]
    });  
    var parse_type =  new Ext.form.ComboBox({
        name: 'parse_type',
        xtype: 'combo',
        fieldLabel: _('Parse Type'),
        store: store,
        triggerAction: 'all',
        valueField: 'parse_type',
        editable: false,
        displayField: 'parse_type',
        mode: 'local',
        anchor: '100%',
        value: params.rec.parse_type || 'Path',
        forceSelection: true,
        allowBlank: false,
        selectOnFocus: true
    });  
    
    var cis = new Baseliner.CIGrid({
        fieldLabel: _('CIs'),
        name: 'cis',
        anchor: '100%',
        value: params.rec.cis 
    });
    
    var topics = new Baseliner.TopicGrid({ fieldLabel:_('Topics'), name:'topics', value: params.rec.topics });
	
    return [
        { xtype:'textfield', fieldLabel:_('Options'), name:'regex_options', value: params.rec.regex_options || 'xmsi', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Timeout'), name:'timeout', value: params.rec.timeout || '10', anchor:'100%' },
        parse_type,
        { xtype:'textarea', fieldLabel:_('Pattern'), name:'regex', 
            height: 100,
            value: params.rec.regex, anchor:'100%', 
            style:'font: 11px Consolas, Courier New, monotype' 
        },
        topics,
        cis
    ]
})
