/*
name: title
params:
    id_field: 'title'
    origin: 'system'
    html: '/fields/field_title.html'
    js: '/fields/field_title.js'
    field_order: 2
    section: 'body'
---
*/

(function(params){
	var data = params.topic_data;
    return [
		{
			xtype:'textfield',
			fieldLabel: _('Title'),
			name: 'title',
			value: data ? data.title : '',
			style: { 'font-size': '16px' },
			width: '100%',
			height: 30,
			allowBlank: false
		}
    ]
})
