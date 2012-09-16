/*
name: priority
params:
    id_field: 'id_priority'
    origin: 'system'
    html: '/fields/field_priority.html'
    js: '/fields/field_priority.js'
    set_method: 'set_priority'
    field_order: 4
    section: 'body'
    relation: priorities
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
    function get_expr_response_time(row){
        var str_expr = '';
        var expr = row.data.expr_response_time.split(':');
        for(i=0; i < expr.length; i++)
        {
            if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
                continue;
            }else{
                str_expr += expr[i] + ' ';
            }
        }
        return str_expr;
    }
    
    function get_expr_deadline(row){
        var str_expr = '';
        var expr = row.data.expr_deadline.split(':');
        for(i=0; i < expr.length; i++)
        {
            if (expr[i].length == 2 && expr[i].substr(0,1) == '0'){
                continue;
            }else{
                str_expr += expr[i] + ' ';
            }
        }
        return str_expr;
    }
    
    function load_txt_values_priority(row){
        var ff = params.form.getForm();
        var obj_rsp_expr_min = ff.findField("txt_rsptime_expr_min");
        var obj_rsp_time = ff.findField("txtrsptime");
        var obj_deadline_expr_min = ff.findField("txt_deadline_expr_min");
        var obj_deadline = ff.findField("txtdeadline");
        obj_rsp_expr_min.setValue('');
        obj_rsp_time.setValue('');
        obj_deadline_expr_min.setValue('');
        obj_deadline.setValue('');
		if(row.data){
			if(row.data.expr_response_time){
				obj_rsp_expr_min.setValue(row.data.expr_response_time + '#' + row.data.response_time_min);
				obj_rsp_time.setValue(get_expr_response_time(row));
			}
			if(row.data.expr_deadline){
				obj_deadline_expr_min.setValue(row.data.expr_deadline + '#' + row.data.deadline_min);
				obj_deadline.setValue(get_expr_deadline(row));
			}
		}
    }
	
	var store_category_priority = new Baseliner.JsonStore({
		root: 'data' , 
		remoteSort: true,
		totalProperty:"totalCount", 
		id: 'id', 
		url: '/topicadmin/get_config_priority',
		fields: [
			{  name: 'id' },
			{  name: 'id_category' },
			{  name: 'name' },
			{  name: 'response_time_min' },
			{  name: 'expr_response_time' },
			{  name: 'deadline_min' },
			{  name: 'expr_deadline' },
			{  name: 'is_active' }  
		]
	});
	
	
    var combo_priority = new Ext.form.ComboBox({
        value: data ? data.name_priority : '',
        mode: 'local',
        forceSelection: true,
        emptyText: 'select a priority',
        triggerAction: 'all',
        fieldLabel: _('Priority'),
        name: 'priority',
        hiddenName: 'priority',
        displayField: 'name',
        valueField: 'id',
        store: store_category_priority,
		readOnly: meta ? meta.readonly: false,
        //hidden: rec.fields_form.show_priority ? false : true,
        listeners:{
            'select': function(cmd, rec, idx){
                load_txt_values_priority(rec);
            }
        }           
    });
	
	
	return [
		{
			xtype:'textfield',
			fieldLabel: _('Response'),
			hidden: true,
			name: 'txtrsptime',
			readOnly: true
		},
		{
			xtype:'textfield',
			fieldLabel: _('Resolution'),
			hidden: true,
			name: 'txtdeadline',
			readOnly: true
		},
		{ xtype: 'hidden', name: 'txt_rsptime_expr_min', value: -1 },
		{ xtype: 'hidden', name: 'txt_deadline_expr_min', value: -1 },
		combo_priority
		
    ]
})