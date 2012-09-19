(function(params){
    if( params.rec == undefined ) params.rec = {};            // master row record
    //if( params.rec.data == undefined ) params.rec.data = {};  //  yaml ci data
    var mid = params.mid;
    var beforesubmit = [];
    var is_active = params.rec.active || true;

    var submit_form = function( close_form ){
            var form2 = form.getForm();
            if ( form2.isValid() ) {
               var flag = true;
               Ext.each( beforesubmit, function( cb ){
                  var ret = cb( form2 );
                  if( !ret ) flag = false;
               });
               form2.submit({
                   params: {action: params.action, mid: params.mid, collection:params.collection },
                   success: function(f,a){
                        params.mid = a.result.mid;
                        Baseliner.message(_('Success'), a.result.msg );
                        if( close_form ) form.destroy();
                   },
                   failure: function(f,a){
                       Ext.Msg.alert( _('Error'), a.result.msg );
                   }
               });
            }
    };
    var btn_form_ok = new Ext.Button({
        text: _('Close'),
        icon:'/static/images/icons/left.png',
        cls: 'x-btn-icon-text',
        type: 'submit',
        handler: function() { form.destroy() }
    });

    var btn_form_save = new Ext.Button({
        text: _('Save'),
        icon:'/static/images/icons/save.png',
        cls: 'x-btn-icon-text',
        type: 'submit',
        handler: function() { submit_form( false ) }
    });

    var tb = new Ext.Toolbar({
        items: [
            btn_form_ok, btn_form_save
            //btn_form_reset
        ]
    });
    var fieldset = new Ext.form.FieldSet({
        defaults: { 
           anchor: '90%',
           msgTarget: 'under'
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
           anchor: '90%' 
        },
        bodyStyle:'padding: 10px 0px 0px 15px',
        items: [
            { xtype: 'container', html:_( txt, params.item), style:{'font-size': '20px', 'margin-bottom':'20px'} },
            { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false, value: params.rec.name, style:'font-weight:bold' },
            { xtype: 'checkbox', fieldLabel: _('Active'), name:'active', checked: is_active, allowBlank: true },
            ( params.has_bl > 0 ? bl_combo : [] ),
            //Baseliner.combo_baseline({ value: params.bl || '*' }),
            //{ xtype: 'hidden', name:'collection', value: params.collection },
            //{ xtype: 'hidden', name:'mid' , value: params.rec.mid },
            fieldset
        ]
    });
    form.on( 'afterrender', function(){
        params.rec.collection = params.collection;
        params.form = form;
        bl_combo.getStore().on( 'load', function(){
            bl_combo.setValue( params.rec.bl );
        });
        if( params.ci_form ) {
            Baseliner.ajaxEval( params.ci_form, params, function(res){
                if( res != undefined ) {
                    var fields;
                    if( Ext.isObject( res ) ) {
                        fields = res.fields;
                        if( res.beforesubmit ) beforesubmit.push( res.beforesubmit );
                    } else {
                        fields = res;
                    }
                    fieldset.show();
                    fieldset.add( fields );
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
        var grid_id = params._parent_grid;
        if( ! grid_id ) return;
        var grid = Ext.getCmp( grid_id );
        if( grid ) {
            var sm = grid.getSelectionModel();
            if( sm ) sm.clearSelections();
            var s = grid.getStore();
            if( s ) s.reload();
        }
    });
    return form;
})

