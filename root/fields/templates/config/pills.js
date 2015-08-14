(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);


//    var tf = Baseliner.cols_templates['textfield'];
//    var pf = Baseliner.cols_templates['colorComboPalette'];
// var opitions = new Baseliner.GridEditor({
//     title: _('Options'),
//     height: 200,
//     witdth: 400,
//     name: 'options',
//     records: data ? data.options_colors: [],
//     preventMark: false,        
//     columns: [
//         Ext.apply({ dataIndex:'option', header: _('Option') }, tf() ),
//         Ext.apply({ dataIndex:'color', header: _('Color') }, pf() ),
//     ],
//     viewConfig: { forceFit: true }
// });
     ret.push([  
       { xtype:'textfield',fieldLabel: _('Option settings'), name: 'options', value: data.options },
       { xtype:'textfield',fieldLabel: _('Default value'), name: 'default_value', value: data.default_value }
       //opitions 
    ]);
    return ret;
})
