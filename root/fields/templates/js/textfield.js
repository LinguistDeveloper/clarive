/*
name: Textfield
params:
    origin: 'template'
    type: 'textfield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/textfield.js'
    field_order: 1
    section: 'body'
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
    return [
		{
			xtype:'textfield',
			fieldLabel: _(meta.name_field),
			name: meta.id_field,
			value: data ? eval('data.' + meta.bd_field): '',
			style: { 'font-size': '16px' },
			width: '100%',
			height: 30,
			allowBlank: false,
			readOnly: meta ? meta.readonly : true,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
		}
    ]
})
