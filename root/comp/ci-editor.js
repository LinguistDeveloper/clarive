<%args>
    $save => 0;
</%args>
(function(params){
    var menu_services = new Ext.Button({
        text: _('Services'),
        icon:'/static/images/icons/service.png',
        cls: 'x-btn-icon-text',
        menu: { items:[] }
    });

    var load_form = function(opts){
        if( opts.rec == undefined ) opts.rec = {};            // master row record
        var can_save = Cla.eval_boolean(<% $save %>);
        var mid = opts.mid;
        var ci_form = opts.ci_form; 
        var has_bl = Cla.eval_boolean( opts.rec.has_bl );
        var has_description = Cla.eval_boolean( opts.rec.has_description );
        var beforesubmit = [];
        var is_active = opts.rec.active == undefined ? true : opts.rec.active;

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
               Baseliner.ajax_json('/ci/update', {action: opts.action, mid: opts.mid, collection:opts.collection, form_data:form_data },function(res){
                    mid = params.mid = opts.mid = res.mid;
                    params.action = opts.action = 'edit';
                    set_txt(opts.action,opts.collection,mid);
                    cardpanel.setTitle( _('CI: %1' , form_data.name ) );
                    Baseliner.message(_('Success: %1', mid), res.msg );
                    if( close_form ) {  // who's using this?
                        cardpanel.destroy();
                        return;
                    }
                    if( opts.reload_on_save ) {
                        // TODO not working due to tbar dups, but the idea is that a given 
                        //    CI class can request a reload everytime, ie. variable
                        cardpanel.remove(form);
                        edit_form(mid);
                    }
                    activate_save();
               }, function(res){
                    activate_save();
                    Ext.Msg.alert( _('Error'), res.msg );
               });
            } else {
                var failedFields = [];
                form2.items.each(function(f){
                   if(!f.validate()){
                       failedFields.push(f.fieldLabel);
                   }
                });

                var msg = '';
                var elements = form.getValues();
                for (var key1 in elements) {
                   var obj = elements[key1];
                   if('[object Object]' == Object.prototype.toString.call(obj)){
                        for (var key2 in obj) {
                            var subObj = obj[key2];
                            if(subObj != null && '[object Object]' == Object.prototype.toString.call(subObj)){
                                for (var key3 in subObj) {
                                    if(failedFields.indexOf(key3)>-1){
                                        if(key2==='*'){key2='common';};
                                        msg = msg+'Field '+key3+' in tab '+key2+' of section '+key1+' is not valid.<br/><br/>';
                                    }
                                }
                            }
                        }
                   }
                }
                if(msg.length>0)
                    Baseliner.warning( _('Not Saved'), msg );
                else
                    Baseliner.warning( _('Not Saved'), _('There are invalid fields in the form or variables.') );
                //if(msg.length>0){Baseliner.alert(_('Warning'),msg);};
                if( Ext.getCmp(btn_form_save.id) ) btn_form_save.enable();
            }
        };

        var calendar;
        var show_calendar = function(){
            if( btn_form_calendar.pressed ) {
                if( ! calendar ) {
                    var cal = { id_cal: -1, bl: opts.rec.bl || '*', ns: mid, name: opts.rec.name };
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
                    data_panel = new Baseliner.DataEditor({ data: opts.rec, hide_cancel: true, save_only: true, on_save: save_foo });
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
                    //depend_panel = new Baseliner.CIDepends({ data: opts.rec });
                    depend_panel = new Baseliner.CIGrid({ ci: { role:'CI' }, 
                        from_mid: opts.mid, 
                        collection: opts.collection,
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
            icon:'/static/images/icons/close.png',
            cls: 'x-btn-icon-text ui-comp-ci-editor-close',
            type: 'submit',
            handler: function() { cardpanel.destroy() }
        });

        var btn_form_save = new Ext.Button({
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text ui-comp-ci-editor-save',
            type: 'submit',
            hidden: !can_save,
            handler: function() { 
                btn_form_save.disable();
                submit_form( false )
            }
        });

        var btn_edit = new Ext.Button({
            text: _('Edit'),
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-icon-text',
            pressed: true, toggleGroup: 'ci-editor-panel'+cardpanel.id,allowDepress: false, 
            handler: function(){ cardpanel.getLayout().setActiveItem(form) }
        });

        var btn_data = new Ext.Button({
            text: _('Data'),
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon-text',
            pressed: false, toggleGroup: 'ci-editor-panel'+cardpanel.id,allowDepress: false, 
            handler: show_data
        });

        var btn_depends = new Ext.Button({
            text: _('Dependencies'),
            icon:'/static/images/expand.gif',
            cls: 'x-btn-icon-text',
            pressed: false, toggleGroup: 'ci-editor-panel'+cardpanel.id,allowDepress: false, 
            handler: show_depends
        });

        var btn_form_calendar = new Ext.Button({
            text: _('Calendar'),
            icon:'/static/images/icons/calendar.png',
            cls: 'x-btn-icon-text',
            pressed: false, toggleGroup: 'ci-editor-panel'+cardpanel.id,allowDepress: false, 
            handler: show_calendar
        });

        cardpanel.getTopToolbar().add([
            btn_form_ok, btn_form_save, '-', btn_edit, btn_depends, btn_form_calendar, btn_data, '-', menu_services //btn_form_reset
        ]);
        cardpanel.doLayout();
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
            //title: _(opts.collection),
            collapsible: false,
            border: false,
            autoHeight : true
        });
        var set_txt = function(action, collection, mid){
            var txt = (action == 'add' ? 'New: %1' : 'Edit: %1 (%2)' );
            txt_cont.update( _( '<b>'+txt+'</b>', Cla.ci_loc(collection), mid ) );
        };
        var txt_cont = new Ext.Container({ style:{'font-size': '20px', 'margin-bottom':'20px'} });
        var bl_combo = new Baseliner.model.SelectBaseline({ value: opts.rec.bl || ['*'], colspan: 1 });
        var children = new Ext.form.Hidden({ name: 'children', value: opts.rec.children });
        var desc = { xtype:'textarea', fieldLabel: _('Description'), name:'description', allowBlank: true, value: opts.rec.description, height: 80 };
        var form = new Baseliner.FormPanel({
            url:'/ci/update',
            padding: 10,
            defaults: {
               allowBlank: false,
               anchor: '100%',
            },
            bodyStyle: {
                'background-color': 'white',
                'overflow-y': 'auto' 
            },
            items: [
                txt_cont,
                children,
                { layout:'column', border: false, defaults:{ layout:'form', border: false, padding: '0px 2px 10px 2px'}, items:[
                    { columnWidth : .65, defaults: { anchor: '100%' }, items:[
                        { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false, value: opts.rec.name, height: 30, style:'font-size: 18px;' },
                        ( has_description > 0 ? desc : [] )
                    ]},
                    { columnWidth : .35, defaults: { anchor: '100%' }, items:[
                        { xtype: 'checkbox', colspan: 1, fieldLabel: _('Active'), name:'active', checked: is_active, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Moniker'), name:'moniker', value: opts.rec.moniker, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Version'), name:'versionid', readOnly: true, submitValue: false, value: opts.rec.versionid, allowBlank: true },
                        ( has_bl > 0 ? bl_combo : [] )
                    ]}
                ]},
                fieldset
            ],
            listeners: {
                'afterrender':function(){
                    if( !can_save ) {
                        // TODO provisional: this is commented pending a better solution and more generic
                        /*var mask = this.el.mask();
                        mask.setStyle( 'opacity', 0);
                        mask.setStyle( 'height', 5000 );*/
                    }
                }
            }
        });
        txt_cont.on('afterrender', function(){
            set_txt(opts.action,opts.collection,opts.mid);
        });
        form.on( 'afterrender', function(){
            opts.rec.collection = opts.collection;
            form.getForm().el.set({ autocomplete: 'off' });
            var add_ci_form = function(form_url, opts) {
                    Baseliner.ajaxEval( form_url, opts, function(res){
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
                            //form.getForm().loadRecord( opts.rec );
                            form.getForm().setValues( opts.rec );
                            form.fireEvent('field_loaded');
                        }
                    });
            };
            if( ci_form ) {
                if(ci_form.constructor === Array) 
                    form.pending_fields = form.pending_fields+ci_form.length; else form.pending_fields++;
                // XXX deprecated: (ci_form inconsistent with cache)
                Ext.each( ci_form, function(form_url){
                    add_ci_form( form_url, opts );

                });
            } else {
                Baseliner.ci_call( opts.mid, 'ci_form', { collection: opts.collection }, function(res){
                    if (res.data != null && res.data.length) {
                        var forms = res.data;

                        if (forms.constructor === Array) {
                            form.pending_fields = form.pending_fields + forms.length;
                        } else {
                            form.pending_fields++;
                        }

                        Ext.each( forms, function(form_url){
                            add_ci_form( form_url, opts );
                        });
                    }
                }, function(res){
                    // No ci form ignore
                });
                //form.getForm().loadRecord( opts.rec );
            }
        });
        var destroying=false;
        var beforedestroy = function(){
            if( opts.mid==undefined ) return true;
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
        form.on('beforedestroy', function(){ return beforedestroy(); });
        cardpanel.on('destroy', function(){
            if( opts.mid==undefined ) return true;
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
       bodyStyle: { 'background-color' : 'white' }
    });
    var edit_form = function(mid){
        Baseliner.ajaxEval( '/ci/load', { mid: mid }, function(res) {
            var rec = res.rec;
            if( ! res.success ) {
                Baseliner.error( _('CI'), _('CI with id %1 missing or invalid', mid ) );
                cardpanel.destroy();
                return;
            }
            var c = {
                    collection: rec.collection,
                    bl: rec.bl,
                    "class": rec["class"],  // deprecated for classname
                    classname: rec.classname,
                    ci_form: rec.ci_form,
                    mid: rec.mid,
                    rec: rec,
                    tab_icon: rec.icon,
                    action: 'edit'
            };
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
            cardpanel.get_current_state = function(){ // for favorite to have correct icon
                return { icon: rec.icon }
            }
        }, function(res){
            Cla.error(_('CI %1', mid ), _('Error opening CI %1: %2', mid, res.msg));
            cardpanel.destroy();
        });
    };
    cardpanel.on('afterrender', function(){
        if( params.mid ) {
            edit_form(params.mid);
        } else {
            // someone sent me full row data (DEPRECATED)
            Baseliner.ajax_json( '/ci/new_ci', { 'collection': params.collection }, function(res) {
                var f = load_form({ 
                    action:'add', 
                    rec: res.rec, 
                    ci_form: res.rec.ci_form,
                    "class": params.collection, 
                    classname: params.collection, 
                    collection: params.collection 
                }); //Ext.apply( res.data, params ) );
                cardpanel.add( f );
                cardpanel.getLayout().setActiveItem( f );
                cardpanel.doLayout();
            });
        }
    });
    Baseliner.edit_check( cardpanel, true );  // block window closing from the beginning
    return cardpanel;
})


