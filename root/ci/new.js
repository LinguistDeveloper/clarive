(function(params){
    var btn_form_ok = new Ext.Button({
        text: _('Accept'),
        icon:'/static/images/icons/save.png',
        cls: 'x-btn-icon-text',
        type: 'submit',
        handler: function() {
            var form2 = form.getForm();
            if ( form2.isValid() ) {
               form2.submit({
                   params: {action: params.action },
                   success: function(f,a){
                        Baseliner.message(_('Success'), a.result.msg );
                        form.destroy();
                   },
                   failure: function(f,a){
                       Ext.Msg.alert({  
                           title: _('Error'), 
                           msg: a.result.msg , 
                           buttons: Ext.Msg.OK, 
                           icon: Ext.Msg.INFO
                       });                      
                   }
               });
            }
        }
    });

    var tb = new Ext.Toolbar({
        items: [
            btn_form_ok
            //btn_form_reset
        ]
    });
    var fieldset = new Ext.form.FieldSet({
        defaults: { anchor: '70%' },
        style: { 'margin-top':'30px' },
        title: _(params.class),
        collapsible: true,
        autoHeight : true
    });
    var form = new Ext.FormPanel({
        url:'/ci/update',
        tbar: tb,
        defaults: {
           anchor: '70%' 
        },
        bodyStyle:'padding: 10px 0px 0px 15px',
        items: [
            { xtype: 'container', html:_('New: %1', params.item), style:{'font-size': '20px', 'margin-bottom':'20px'} },
            { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false },
            Baseliner.combo_baseline({ value: params.bl || '*' }),
            { xtype: 'hidden', name:'collection', value: params.collection },
            fieldset
        ]
    });
    if( params.component ) {
        Baseliner.ajaxEval( params.component, params, function(res){
            if( res != undefined ) {
                fieldset.add( res );
                fieldset.doLayout();
            }
        });
    }
    return form;
})
