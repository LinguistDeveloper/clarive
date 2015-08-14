(function(params){
    var data_value = params.rec.data || {};

    var on_submit = function( form ){
        //var d = de.getData();
        //var vf = Ext.util.JSON.encode( d );
        //variables_field.setValue( vf );
    };
    
    var variables = new Baseliner.VariableForm({
        name: 'variables',
        fieldLabel: _('Variables'),
        height: 300,
        data: params.rec.variables,
        deferredRender: false,
        renderHidden: false
    });
    
    return {
        beforesubmit: on_submit,
        fields: [
           Baseliner.ci_box({ name:'bls', fieldLabel:_('Environments'), allowBlank: true,
               'class':'bl', value: params.rec.bls, force_set_value: true, singleMode: false }),
           Baseliner.ci_box({ name:'parent_project', fieldLabel:_('Parent Project'), allowBlank: true,
               role:'Project', value: params.rec.parent_project, force_set_value: true, singleMode: true }),
           Baseliner.ci_box({ name:'repositories', fieldLabel:_('Repositories'), allowBlank: true,
               role:'Repository', value: params.rec.repositories, singleMode: false, force_set_value: params.rec.repositories ? true: false }),
            variables
        ]
    }
})
