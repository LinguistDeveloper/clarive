(function(params){
    if( params.rec == undefined ) params.rec = {};            // master row record
    if( params.rec.data == undefined ) params.rec.data = {};  //  yaml ci data
    var mid = params.mid;
    var btn_form_ok = new Ext.Button({
        text: _('Accept'),
        icon:'/static/images/icons/save.png',
        cls: 'x-btn-icon-text',
        type: 'submit',
        handler: function() {
            var form2 = form.getForm();
            if ( form2.isValid() ) {
               form2.submit({
                   params: {action: params.action, mid: params.mid, collection:params.collection },
                   success: function(f,a){
                        Baseliner.message(_('Success'), a.result.msg );
                        form.destroy();
                   },
                   failure: function(f,a){
                       Ext.Msg.alert( _('Error'), a.result.msg );
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
        defaults: { 
           anchor: '70%',
           msgTarget: 'under',
           allowBlank: false
        },
        hidden: true,
        style: { 'margin-top':'30px' },
        title: _(params.collection),
        collapsible: true,
        autoHeight : true
    });
    var txt = (params.action == 'add' ? 'New: %1' : 'Edit: %1' );
    var bl_combo = new Baseliner.model.SelectBaseline({ value: ['TEST'] });
    var form = new Ext.FormPanel({
        url:'/ci/update',
        tbar: tb,
        defaults: {
           allowBlank: false,
           anchor: '70%' 
        },
        bodyStyle:'padding: 10px 0px 0px 15px',
        items: [
            { xtype: 'container', html:_( txt, params.data.item), style:{'font-size': '20px', 'margin-bottom':'20px'} },
            { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false, value: params.rec.name },
            ( params.has_bl > 0 ? bl_combo : [] ),
            //Baseliner.combo_baseline({ value: params.bl || '*' }),
            //{ xtype: 'hidden', name:'collection', value: params.collection },
            //{ xtype: 'hidden', name:'mid' , value: params.rec.mid },
            fieldset
        ]
    });
    form.on( 'afterrender', function(){
        params.rec.collection = params.collection;
        bl_combo.getStore().on( 'load', function(){
            bl_combo.setValue( params.rec.bl );
        });
        if( params.ci_form ) {
            Baseliner.ajaxEval( params.ci_form, params, function(res){
                if( res != undefined ) {
                    fieldset.show();
                    fieldset.add( res );
                    fieldset.doLayout();
                    //form.getForm().loadRecord( params.rec );
                    form.getForm().setValues( params.rec );
                }
            });
        } else {
            //form.getForm().loadRecord( params.rec );
        }
    });
    form.on('destroy', function(){
        // reload parent grid
        var g = params._parent_grid;
        if( g != undefined ) {
            var sm = g.getSelectionModel();
            if( sm != undefined ) sm.clearSelections();
            var s = g.getStore();
            if( s!=undefined ) s.reload();
        }
    });
    return form;
})

