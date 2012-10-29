/*
name: HTML/Editor
params:
    origin: 'template'
    type: 'html/editor'
    html: '/fields/templates/html/dbl_row_body.html'
    js: '/fields/templates/js/html_editor.js'
    field_order: 2
    section: 'body'
    data: 'clob'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	return [
		{   xtype: 'panel', layout:'fit',
			hidden: meta ? (meta.hidden ? meta.hidden : false): true,
			items: [ //this panel is here to make the htmleditor fit
				new Baseliner.HtmlEditor({
					name: meta.id_field,
					fieldLabel: _('Description'),
					width: '100%',
					value: data ? eval('data.' + meta.bd_field): '',
					height: 350,
					disabled: meta ? meta.readonly : true
				})
			]
		}
    ]
})
