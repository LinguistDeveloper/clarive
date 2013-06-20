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
        var save = <% $save %>;
        var mid = params.mid;
        var beforesubmit = [];
        var is_active = params.rec.active == undefined ? true : params.rec.active;

        var activate_save = function(){
            setTimeout( function(){
                btn_form_save.enable();
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
                   form2.submit({
                       params: {action: params.action, mid: params.mid, collection:params.collection },
                       success: function(f,a){
                            mid = params.mid = a.result.mid;
                            params.action = 'edit';
                            set_txt();
                            Baseliner.message(_('Success: %1', mid), a.result.msg );
                            if( close_form ) form.destroy();
                            activate_save();
                       },
                       failure: function(f,a){
                           activate_save();
                           Ext.Msg.alert( _('Error'), a.result.msg );
                       }
                   });
                }
                else {
                    btn_form_save.enable();
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

        Baseliner.CIDepends = Ext.extend( Ext.Panel, {
            layout: 'fit', 
            initComponent: function(){
                //this.layoutConfig = { columns:2, rows:2 };
                Baseliner.CIDepends.superclass.initComponent.call(this);
                /*
                this.ci_grid = new Ext.GridPanel({ 
                    title: _('CIs'), region:'west', split: true,
                    store: new Baseliner.CIStore({}), 
                    columns: [
                    ]
                });
                */
                var to_mid = new Baseliner.CIGrid({ ci: { role:'CI' }, from_mid: mid });
                this.add( to_mid );
            }
        });
        var depend_panel;
        var show_depends = function(){
            if( btn_depends.pressed ) {
                if( ! depend_panel ) {
                    depend_panel = new Baseliner.CIDepends({ data: params.rec });
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
            hidden: !save,
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
               msgTarget: 'under'
            },
            hidden: true,
            margin: 0,
            padding: 10,
            style: { 
                margin: '30px 0px 0px -20px'
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
        var bl_combo = new Baseliner.model.SelectBaseline({ value: ['TEST'], colspan: 1 });
        var desc = { xtype:'textarea', fieldLabel: _('Description'), name:'description', allowBlank: true, value: params.rec.description, height: 80 };
        var form = new Ext.FormPanel({
            url:'/ci/update',
            defaults: {
               allowBlank: false,
               anchor: '90%' 
            },
            autoScroll: true,
            bodyStyle:'padding: 10px 0px 0px 15px',
            items: [
                txt_cont,
                { layout:'column', border: false, defaults:{ border: false}, items:[
                    { layout:'form', columnWidth : .65, defaults: { anchor: '96%' }, items:[
                        { xtype: 'textfield', fieldLabel: _('Name'), name:'name', allowBlank: false, value: params.rec.name, height: 30, style:'font-size: 18px;' },
                        ( params.has_description > 0 ? desc : [] )
                    ]},
                    { layout:'form', columnWidth : .35, defaults: { anchor: '100%' }, items:[
                        { xtype: 'checkbox', colspan: 1, fieldLabel: _('Active'), name:'active', checked: is_active, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Moniker'), name:'moniker', value: params.rec.moniker, allowBlank: true },
                        { xtype: 'textfield', colspan: 1, fieldLabel: _('Version'), name:'versionid', value: params.rec.versionid, allowBlank: true },
                        ( params.has_bl > 0 ? bl_combo : [] )
                    ]}
                ]},
                fieldset
            ]
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
    };
    var cardpanel = new Ext.Panel({
       layout: 'card',
       autoScroll: true,
       tbar: []
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
                Ext.each( rec.services, function(service) {
                    menu_services.menu.add({ text: service.name, key: service.key, icon: service.icon, handler:function(){
                        Baseliner.run_service( { mid: rec.mid, classname: rec.classname }, service );
                    }});
                });
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
            var f = load_form( params );
            cardpanel.add( f );
            cardpanel.getLayout().setActiveItem( f );
            cardpanel.setTitle( _('CI: %1' , params.name ) );
            cardpanel.doLayout();
        }
    });
    return cardpanel;
})


