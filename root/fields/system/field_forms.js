(function(params){
	var form = params.form;
    var custom_form_container = new Ext.Container({ 
        hidden: true
    });
	
    if( params.value != '' ) {
        var f = params.value;
        for( var i=0; i<f.length; i++ ) {
           var fieldset = new Ext.form.FieldSet({
                defaults: { 
                   anchor: '70%',
                   msgTarget: 'under',
                   allowBlank: false
                },
                style: { 'margin-top':'30px' },
                title: _( f[i].form_name ),
                collapsible: true,
                autoHeight : true
            });
            Baseliner.ajaxEval( f[i].form_path, {}, function(res) {
                if( res.xtype == 'fieldset' ) {
                    custom_form_container.add( res ) ;
                } else {
                    fieldset.add( res );
                    custom_form_container.add( fieldset) ;
                }
                if( ! custom_form_container.isVisible() ) custom_form_container.show();
                form.doLayout();
            });
        }
    }
	
	return [
		custom_form_container
    ]
})