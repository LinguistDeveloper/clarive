(function(params){
    if( !params.rec ) params.rec = {};

    var data = params.rec;

    var variables_input = new Baseliner.VariableForm({
        name: 'variables_input',
        fieldLabel: _('Input'),
        height: 225,
        data: data.variables_input,
        deferredRender: false,
        renderHidden: false,
        show_action: false,
        hidden_bl: true
    });    

    var variables_output = new Baseliner.VariableForm({
        name: 'variables_output',
        fieldLabel: _('Output'),
        height: 225,
        data: data.variables_output,
        deferredRender: false,
        renderHidden: false,
        show_action: true,
        hidden_bl: true
    });  

    var text_help = new Baseliner.CLEditor({
        width: '99.7%',
        padding: 0,
        value: data.text_help,
        height: 397,
        submitValue: false
    });      

    return [
        {
            xtype: 'radiogroup',
            name: 'type',
            anchor:'25%',
            fieldLabel: _('Type'),
            defaults: {xtype: "radio",name: "type"},
            items: [
                {boxLabel: _('Project'), inputValue: 'P', checked: params.rec.type == undefined || params.rec.type == 'P'},
                {boxLabel: _('Subproject'), inputValue: 'S', checked: params.rec.type == 'S'},
            ]
        },    
        //Baseliner.ci_box({ name:'project', fieldLabel:_('Project'), allowBlank: true, 'class':'project', value: data.project, force_set_value: true, singleMode: false }),
        Baseliner.ci_box({ name:'area', fieldLabel:_('Area'), allowBlank: true, 'class':'area', value: data.area, force_set_value: true, singleMode: true }),        
        variables_input,
        variables_output,
        Baseliner.ci_box({ name:'ancestor', fieldLabel:_('Ancestor'), allowBlank: true, 'role':'CatalogTask', value: data.ancestor, force_set_value: data.ancestor ? true : false, singleMode: false }),
        Baseliner.ci_box({ name:'prerequisite', fieldLabel:_('Prerequisite'), allowBlank: true, 'role':'CatalogTask', value: data.prerequisite, force_set_value: data.prerequisite ? true : false , singleMode: false }),
        {   xtype: 'panel',
            border: false,  
            name: 'text_help',
            margin: 0, padding: 0,
            fieldLabel: _('Help'),
            items: text_help,
            get_save_data : function(){
                return text_help.getValue();
            },
            is_valid : function(){
                var is_valid = text_help.getValue() != '' ? true : false;
                if (is_valid && this.on_change_lab){
                    this.getEl().applyStyles('border: none; margin_bottom: 0px');
                    this.on_change_lab.style.display = 'none';
                }
                return is_valid;
            }               
        }               
    ]
})

