/*
name: Timefield
params:
    origin: 'template'
    type: 'timefield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/timefield.js'
    field_order: 1
    section: 'body'
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
    return [
		{
			xtype:'timefield',
			fieldLabel: _(meta.name_field),
			name: meta.id_field,
			value: data ? eval('data.' + meta.bd_field): '',
			readOnly: meta ? meta.readonly : true,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
		}
    ]
})

