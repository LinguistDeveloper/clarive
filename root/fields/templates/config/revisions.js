(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    
    ret.push([ 
    	{ xtype:'textfield', name:'branch', fieldLabel: _('Branch'), value: data.branch }
    ]);
    return ret;
})
