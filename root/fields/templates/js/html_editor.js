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
    field_order_html: 99
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
	return [
		{
		  xtype: 'label',
		  //autoEl: {cn: style_label},
		  fieldLabel: _(meta.name_field),
		  hidden: meta ? (meta.hidden ? meta.hidden : false): true
		},		
		{   xtype: 'panel', layout:'fit',
			hidden: meta ? (meta.hidden ? meta.hidden : false): true,
			listeners: {
				'afterrender':function(){
					var disable = meta && meta.readonly ? meta.readonly : false;
					if(disable){
					    var mask = this.el.mask();
					    mask.setStyle('opacity', 0);
					    mask.setStyle('height', 5000);
					}
				}
			},  			
			items: [ //this panel is here to make the htmleditor fit
			new Baseliner.CLEditor({
					name: meta.id_field,
					fieldLabel: _('Description'),
					width: '100%',
					value: data ? data[meta.bd_field] : '',
					height: 350
				})
			]
		}				
    ]
})
