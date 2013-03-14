/*
name: Datefield
params:
    origin: 'template'
    type: 'datefield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/datetimefield.js'
    field_order: 1
    section: 'body'
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;
	
    return [
		{
			xtype:'datefield',
			fieldLabel: _(meta.name_field),
			name: meta.id_field,
			value: data ? eval('data.' + meta.bd_field): '',
			//style: { 'font-size': '16px' },
			//width: '50px',
			//height: 30,
			//allowBlank: false,
			readOnly: meta ? meta.readonly : true,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
		}
    ]
})
