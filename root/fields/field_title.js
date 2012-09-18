/*
name: title
params:
    id_field: 'title'
    origin: 'system'
    html: '/fields/field_title.html'
    js: '/fields/field_title.js'
    field_order: 2
    section: 'body'
    is_clone: 1
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
    return [
		{
			xtype:'textfield',
			fieldLabel: _(meta.name_field),
			name: meta.name_field,
			value: data ? eval('data.' + meta.name_field): '',
			style: { 'font-size': '16px' },
			width: '100%',
			height: 30,
			allowBlank: false,
			readOnly: meta ? meta.write ? meta.write: meta.readonly : true
		}
    ]
})
