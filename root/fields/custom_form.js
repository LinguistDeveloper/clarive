/*
name: Custom Form
params:
    origin: template
    js: /fields/templates/custom_form.js
    type: customform
    field_order: 100
    section: details
    set_method: set_custom
    form_file: /forms
    fieldset: 0 
    fieldset_check: 0
    custom_fields: []
---
*/
(function(params){
	var data = params.topic_data;
	var meta = params.topic_meta;
	var form = params.form;

    var file = meta.form_file;

    // return a container first, then later load it with the component from ajaxEval
    var custom_form_container = new Ext.Container({ 
        layout:'form',
        hidden: true
    });
	
    // optional fieldset configuration
    var fs = {
        defaults: { 
           anchor: '70%',
           msgTarget: 'under',
           allowBlank: false
        },
        style: { 'margin-top':'30px' },
        title: _( meta.name_field ),
        checkboxToggle: true,
        collapsible: false,
        autoHeight : true
    };
    if( meta.fieldset_check ) {
        fs.checkboxToggle = meta.fieldset_check == 0 ? false : true;
        fs.collapsible = false;  // the checkbox does the collapse
    }
    var fieldset = new Ext.form.FieldSet(fs);
    // go for the component
    Baseliner.ajaxEval( meta.form_file, params, function(res) {
        if( !meta.fieldset || meta.fieldset == 0 || res.xtype == 'fieldset' ) {
            custom_form_container.add( res ) ;
        } else {
            fieldset.add( res );
            custom_form_container.add( fieldset) ;
        }
        if( ! custom_form_container.isVisible() ) custom_form_container.show();
        form.doLayout();
    });
	
	return [
		custom_form_container
    ]
})

