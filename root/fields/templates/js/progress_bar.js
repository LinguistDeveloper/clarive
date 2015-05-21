/*
name: Progress bar
params:
    origin: 'template'
    type: 'progress_bar'
    html: '/fields/templates/html/progress_bar.html'
    js: '/fields/templates/js/progress_bar.js'
    field_order: 4
    section: 'body'
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	
    return [
		{ xtype:'sliderfield', fieldLabel: _(meta.name_field), name: meta.id_field,
			value: data ? eval('data.' + meta.bd_field) : 0,
			anchor: '40%', tipText: function(thumb){
					return String(thumb.value) + '%';
			},
			disabled: Baseliner.eval_boolean(meta.readonly),
			hidden: Baseliner.eval_boolean(meta.hidden)
		}
    ]
})
