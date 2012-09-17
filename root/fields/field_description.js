/*
name: description
params:
    id_field: 'description'
    origin: 'system'
    html: '/fields/field_description.html'
    js: '/fields/field_description.js'
    field_order: 16
    section: 'body'    
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	return [
		{   xtype:'panel', layout:'fit',
			//hidden: rec.fields_form.show_description ? false : true,
			items: [ //this panel is here to make the htmleditor fit
				{
					xtype:'htmleditor',
					name:'description',
					fieldLabel: _('Description'),
					width: '100%',
					value: data ? data.description : '',
					height:350,
					disabled: meta ? !meta.write ? meta.write: meta.readonly : true
				}
			]
		}
    ]
})