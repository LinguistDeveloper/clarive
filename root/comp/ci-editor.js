<%args>
    $save
</%args>
(function(params){
    var menu_services = new Ext.Button({
        text: _('Services'),
        icon:'/static/images/icons/service.png',
        cls: 'x-btn-icon-text',
        menu: { items:[] }
    });
        
    var load_form = function(params){
        if( params.rec == undefined ) params.rec = {};            // master row record
        //if( params.rec.data == undefined ) params.rec.data = {};  //  yaml ci data
        var can_save = <% $save %>;
        var mid = params.mid;
        var beforesubmit = [];
        var is_active = params.rec.active == undefined ? true : params.rec.active;

        var activate_save = function(){
            setTimeout( function(){
                if( Ext.getCmp(btn_form_save.id) ) btn_form_save.enable();
            }, 1000);
        };
        var submit_form = function( close_form ){
            var form2 = form.getForm();
            if ( form2.isValid() ) {
               var flag = true;
               Ext.each( beforesubmit, function( cb ){
                  var ret = cb( form2 );
                  if( !ret ) flag = false;
               });
               var form_data = form.getValues();
               Baseliner.ajax_json('/ci/update', {action: params.action, mid: params.mid, collection:params.collection, form_data:form_data },function(res){
                    mid = params.mid = res.mid;
                    params.action = 'edit';
                    set_txt();
                    Baseliner.message(_('Success: %1', mid), res.msg );
                    if( close_form ) cardpanel.destroy();
                    activate_save();
               }, function(res){
                    activate_save();
                    Ext.Msg.alert( _('Error'), res.msg );
               });
            }
            else {
                if( Ext.getCmp(btn_form_save.id) ) btn_form_save.enable();
            }
        };

        var calendar;
        var show_calendar = function(){
            if( btn_form_calendar.pressed ) {
                if( ! calendar ) {
                    var cal = { id_cal: -1, bl: params.rec.bl || '*', ns: mid, name: params.rec.name };
                    Baseliner.ajaxEval( '/job/calendar', cal, function(comp){
                        calendar = comp;
                        cardpanel.add( calendar );
                        cardpanel.getLayout().setActiveItem( calendar );
                    });
                } else {
                    cardpanel.getLayout().setActiveItem( calendar );
                }
            } else {
                cardpanel.getLayout().setActiveItem( 0 );
            }
        }
        
        var data_panel;
        var show_data = function(){
            if( btn_data.pressed ) {
                if( ! data_panel ) {
                    var save_foo = function(de, de_data){
                        form.getForm().setValues( de_data ); 
                    };
                    data_panel = new Baseliner.DataEditor({ data: params.rec, hide_cancel: true, save_only: true, on_save: save_foo });
                    cardpanel.add( data_panel );
                    cardpanel.getLayout().setActiveItem( data_panel );
                } else {
                    cardpanel.getLayout().setActiveItem( data_panel );
                }
            } else {
                cardpanel.getLayout().setActiveItem( 0 );
            }
        };

        var depend_panel;
        var show_depends = function(){
            if( btn_depends.pressed ) {
                if( ! depend_panel ) {
                    //depend_panel = new Baseliner.CIDepends({ data: params.rec });
                    depend_panel = new Baseliner.CIGrid({ ci: { role:'CI' }, 
                        from_mid: params.mid, 
                        collection: params.collection,
                        field: children,
                        columns: ['mid','name','version','collection','rel_type'] });
                    cardpanel.add( depend_panel );
                    cardpanel.getLayout().setActiveItem( depend_panel );
                } else {
                    cardpanel.getLayout().setActiveItem( depend_panel );
                }
            } else {
                cardpanel.getLayout().setActiveItem( 0 );
            }
        };
        
        var btn_form_ok = new Ext.Button({
            text: _('Close'),
            icon:'/static/images/icons/left.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            handler: function() { cardpanel.destroy() }
        });

        var btn_form_save = new Ext.Button({
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: !can_save,
            handler: function() { 
                btn_form_save.disable();
                submit_form( false )
            }
        });

        var btn_data = new Ext.Button({
            text: _('Data'),
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon-text',
            enableToggle: true, pressed: false, toggleGroup: 'ci-editor-panel',
            handler: show_data
        });

        var btn_depends = new Ext.Button({
            text: _('Dependencies'),
            icon:'/static/images/expand.gif',
            cls: 'x-btn-icon-text',
            enableToggle: true, pressed: false, toggleGroup: 'ci-editor-panel',
            handler: show_depends
        });

        var btn_form_calendar = new Ext.Button({
            text: _('Calendar'),
            icon:'/static/images/icons/calendar.png',
            cls: 'x-btn-icon-text',
            enableToggle: true, pressed: false, toggleGroup: 'ci-editor-panel',
            handler: show_calendar
        });

        cardpanel.getTopToolbar().add([
            btn_form_ok, btn_form_save, '-', btn_depends, btn_form_calendar, btn_data, menu_services //btn_form_reset
        ]);
        var fieldset = new Ext.form.FieldSet({
            defaults: {
               //anchor: '100%',  
               msgTarget: 'under'
            },
            hidden: true,
            //padding: 0,
            style: { 
                //margin: '30px 0px 0px -20px'
                margin: '0px 0px 0px -10px'
                //'border-top' : '#eee 1px solid', 
                //'border-left' : '#f5f0f0 6px solid' }
            },
            //title: _(params.collection),
            collapsible: false,
            border: false,
            autoHeight : true
        });
        var set_txt = function(){
            var txt = (params.action == 'add' ? 'New: %1' : 'Edit: %1 (%2)' );
            txt_cont.update( _( txt, params.item, params.mid ) );
        };
        var txt_cont = new Ext.Container({ style:{'font-size': '20px', 'margin-bottom':'20px'} });
        var bl_combo = new Baseliner.model.SelectBaseline({ value: ['*'], colspan: 1 });
        var children = new Ext.form.Hidden({ name: 'children', value: params.rec.children });
        var desc = { xtype:'textarea', fieldLabel: _('Description'), name:'description', allowBlank: true, value: params.rec.description, height: 80 };
        var form = new Baseliner.FormPanel({
            url:'/ci/update',
            padding: 10,
            defaults: {
               allowBlank: false,
               anchor: '100%'
            },
            frame: true,
            bodyStyle: {
                'background-color': 'white',
                'overflow-y': 'auto' 
            },
            items: [
                txt_cont,
                children,
                { layout:'column', border: false, defaults:{ layout:'form', border: false, padding: '0px 2px 10px 2px'}, items:[
                    { columnWidth : .65, defaults: { anchor: '100%' }, items:[
                        { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false, value: params.rec.name, height: 30, style:'font-size: 18px;' },
                        ( params.has_description > 0 ? desc : [] )
                    ]},
                    { columnWidth : .35, defaults: { anchor: '100%' }, items:[
                        { xtype: 'checkbox', colspan: 1, fieldLabel: _('Active'), name:'active', checked: is_active, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Moniker'), name:'moniker', value: params.rec.moniker, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Version'), name:'versionid', readOnly: true, submitValue: false, value: params.rec.versionid, allowBlank: true },
                        ( params.has_bl > 0 ? bl_combo : [] )
                    ]}
                ]},
                fieldset
            ],
            listeners: {
                'afterrender':function(){
                    if( !can_save ) {
                        var mask = this.el.mask();
                        mask.setStyle( 'opacity', 0);
                        mask.setStyle( 'height', 5000 );
                    }
                }
            }
        });
        txt_cont.on('afterrender', function(){
            set_txt();
        });
        form.on( 'afterrender', function(){
            params.rec.collection = params.collection;
            params.form = form;
            bl_combo.getStore().on( 'load', function(){
                bl_combo.setValue( params.rec.bl );
            });
            var add_ci_form = function(form_url, params) {
                    Baseliner.ajaxEval( form_url, params, function(res){
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
            };
            if( params.ci_form ) {
                // XXX deprecated: (ci_form inconsistent with cache)
                Ext.each( params.ci_form, function(form_url){
                    add_ci_form( form_url, params );
                });
            } else {
                Baseliner.ci_call( params.mid, 'ci_form', { collection: params.collection }, function(res){
                    var forms = res.data;
                    Ext.each( forms, function(form_url){
                        add_ci_form( form_url, params );
                    });
                });
                //form.getForm().loadRecord( params.rec );
            }
        });
        var destroying=false;
        var beforedestroy = function(){
            bl_combo.originalValue = bl_combo.getValue();  // XXX multibox reports isDirty always
            if( children.getValue() == '' ) children.originalValue = children.getValue();  // XXX always dirty
            // deactivated save protection for now
            if( false && !destroying && form.getForm().isDirty() ) {
                Baseliner.confirm( _('You are about to lose your changes. Save now?'), function(){
                    submit_form( false );
                    destroying = true;
                    //cardpanel.destroy();
                }, function(){
                    destroying = true;
                    //cardpanel.destroy();
                });
                return false;
            }
        }
        //cardpanel.on('beforedestroy', function(){ return beforedestroy() });
        form.on('beforedestroy', function(){ return beforedestroy(); });
        cardpanel.on('destroy', function(){
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
    };

    var cardpanel = new Ext.Panel({
       layout: 'card',
       tbar: [],
       frame: true,
       bodyStyle: {
            'background-color' : 'white'
       }
    });

    cardpanel.on('afterrender', function(){
        if( params.load ) {
            Baseliner.ajaxEval( '/ci/load', { mid: params.mid }, function(res) {
                var rec = res.rec;
                if( ! res.success ) {
                    Baseliner.error( _('CI'), _('CI with id %1 missing or invalid', params.mid ) );
                    cardpanel.destroy();
                    return;
                }
                var c = Ext.apply({
                        collection: rec.collection,
                        item: rec.collection,
                        has_bl: rec.has_bl,
                        has_description: rec.has_description,
                        bl: rec.bl,
                        "class": rec["class"],  // deprecated for classname
                        classname: rec.classname,
                        ci_form: rec.ci_form,
                        mid: rec.mid,
                        rec: rec,
                        tab_icon: rec.icon,
                        action: 'edit'
                }, params );
                if( rec.services == undefined || rec.services.length < 1 ) {
                    menu_services.disable();
                    menu_services.setText( _('No Services') );
                } else {
                    Ext.each( rec.services, function(service) {
                        menu_services.menu.add({ text: service.name, key: service.key, icon: service.icon, handler:function(){
                            Baseliner.run_service( { mid: rec.mid, classname: rec.classname }, service );
                        }});
                    });
                }
                var f = load_form( c );
                //f.on('afterrender', function(){ f.body.setStyle({ overflow: 'hidden' }); });
                cardpanel.add( f );
                cardpanel.getLayout().setActiveItem( f );
                cardpanel.setTitle( _('CI: %1' , rec.name ) );
                cardpanel.ownerCt.changeTabIcon( cardpanel, rec.icon );
                cardpanel.body.setStyle({ overflow: 'hidden' });
                cardpanel.doLayout(); // otherwise, no tbar
            });
        } else {
            // someone sent me full row data (DEPRECATED)
            Baseliner.ci_call( params.collection, 'attribute_default_values', {}, function(res){
                params.rec = res;
                var f = load_form( params ); //Ext.apply( res.data, params ) );
                cardpanel.add( f );
                cardpanel.getLayout().setActiveItem( f );
                //cardpanel.setTitle( _('CI: %1' , params.name ) );
                cardpanel.doLayout();
            });
        }
    });
    Baseliner.edit_check( cardpanel, true );  // block window closing from the beginning
    return cardpanel;
})


