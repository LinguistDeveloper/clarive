/*
name: Datefield
params:
    origin: 'template'
    type: 'datefield'
    html: '/fields/templates/html/row_body.html'
    js: '/fields/templates/js/datetimefield.js'
    field_order: 1
    section: 'body'
    default_today: 'false'
    meta_type: 'date'
---
*/

(function(params){
	var meta = params.topic_meta;
	var data = params.topic_data;

    var df = meta.format || 'Y-m-d';

    var value = data ? data[meta.bd_field]: ''; 
    if( value != '' && meta.default_today && meta.default_today == 'true' ) value = new Date( Date.now() ).format(df);
	
    return [
		{
			xtype:'datefield',
			fieldLabel: _(meta.name_field),
			name: meta.id_field,
			value: value, 
			//style: { 'font-size': '16px' },
			format:  df || Prefs.js_date_format,
			width: 165,
			//height: 30,
			//allowBlank: false,
			readOnly: meta ? meta.readonly : true,
			hidden: meta ? (meta.hidden ? meta.hidden : false): true
		}
    ]
})
