Baseliner.Prefs = Ext.extend(Ext.util.Observable, {
    js_date_format: _('js_date_format'),
    js_dt_format: _('js_dt_format'),
    js_dtd_format: _('js_dtd_format'),
    is_logged_in: true,
    toolbar_height: 28,
    constructor: function(config){
        if( !config ) config = {};
        // site options
        config.site = Ext.apply({
            show_menu: true,
            show_dashboard : true,
            show_lifecycle : true,
            show_tabs : true,
            show_search : true
        }, config.site );
        // date format
        if( config.df =='js_date_format' ) {   // not found in .po file
            config.df = 'Y-M-d';
        }
        // raw?
        if( config.site_raw ) {
            Ext.apply(config.site, {
                    show_tabs : false,
                    show_portal : false,
                    show_menu : false,
                    show_main : false
            });
        }
        Ext.apply( this, 
            Ext.apply({}, config) 
        );
        // construct
        Baseliner.Prefs.superclass.constructor.call(this, config);
    }, 
    load: function(){
        var self = this;
        Baseliner.ci_call( 'user', 'prefs_load', { _res_key:'data' }, function(res){
            Ext.apply( self, res.data );
        });
    }, 
    save: function(){
        var self = this;
        var prefs = { site: self.site, stash: self.stash, js_date_format: self.js_date_format };
        Baseliner.ci_call( 'user', 'prefs_save', { prefs: prefs }, function(res){
            Baseliner.message(_('Prefereces'), _('Saved ok') );
        });
    }, 
    open_editor : function() {
        var upload = new Ext.Container();
        upload.on('afterrender', function(){
            var uploader = new qq.FileUploader({
                element: upload.el.dom,
                action: '/user/avatar_upload',
                allowedExtensions: ['png'],
                template: '<div class="qq-uploader">' + 
                    '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
                    '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
                    '<ul class="qq-upload-list"></ul>' + 
                 '</div>',
                onComplete: function(fu, filename, res){
                    //Baseliner.message(_('Upload File'), _('File %1 uploaded ok', filename) );
                    Baseliner.message(_('Upload File'), _(res.msg, filename) );
                    reload_avatar_img();
                },
                onSubmit: function(id, filename){
                    //uploader.setParams({topic_mid: data ? data.topic_mid : obj_topic_mid.getValue(), filter: meta.rel_field });
                },
                onProgress: function(id, filename, loaded, total){},
                onCancel: function(id, filename){ },
                classes: {
                    // used to get elements from templates
                    button: 'qq-upload-button',
                    drop: 'qq-upload-drop-area',
                    dropActive: 'qq-upload-drop-area-active',
                    list: 'qq-upload-list',
                                
                    file: 'qq-upload-file',
                    spinner: 'qq-upload-spinner',
                    size: 'qq-upload-size',
                    cancel: 'qq-upload-cancel',

                    // added to list item when upload completes
                    // used in css to hide progress spinner
                    success: 'qq-upload-success',
                    fail: 'qq-upload-fail'
                }
            });
        });
        var img_id = Ext.id();
        var reload_avatar_img = function(){
                // reload image
                var el = Ext.get( img_id );
                var rnd = Math.floor(Math.random()*80000);
                el.dom.src = '/user/avatar/image.png?' + rnd;
        };
        var gen_avatar = function(){
            Baseliner.ajaxEval('/user/avatar_refresh', {}, function(res){
                Baseliner.message( _('Avatar'), res.msg );
                reload_avatar_img();
            });
        };
        var rnd = Math.floor(Math.random()*80000); // avoid caching
        Baseliner.ajaxEval('/user/user_data', {}, function(res){
            if( !res.success ) {
                Baseliner.error( _('User data'), res.msg );
                return;
            }
            var img = String.format('<img width="32" id="{0}" style="border: 2px solid #bbb" src="/user/avatar/image.png?{1}" />', img_id, rnd );
            var api_key = res.data.api_key;
            var default_dashboard = res.data.dashboard;
            var gen_apikey = function(){
                Baseliner.ci_call('user', 'save_api_key', {}, function(res){
                    Baseliner.message( _('API Key'), res.msg );
                    if( res.success ) {
                        api_key.setValue( res.api_key );
                    }
                });
            };
            var save_apikey = function(){
                Baseliner.ci_call('user', 'save_api_key', { api_key_param: api_key.getValue() }, function(res){
                    Baseliner.message( _('API Key'), res.msg );
                });
            };
            var api_key = new Ext.form.TextArea({ height: 50, anchor:'90%',fieldLabel:_('API Key'), value: api_key });
             var change_dashboard_form = new Ext.FormPanel({
                url: '/user/change_dashboard',
                frame: false,
                border: false,
                labelWidth: 100, 
                timeout: 120,
                 items: [
                     new Baseliner.DashboardBox({ fieldLabel: _('Default dashboard'), name:'dashboard', singleMode: true, allowBlank: true, baseParams: { username: true }, value: default_dashboard })
                 ],
                 buttons: [
                     { text: _('Aceptar'),
                          handler: function() {
                             var form = change_dashboard_form.getForm();

                             if (form.isValid()) {
                               form.submit({
                                   success: function(f,a){
                                         Baseliner.message(_('Success'), a.result.msg );
                                         win_change.close(); 
                                   },
                                   failure: function(f,a){
                                         Ext.Msg.show({  
                                             title: _('Information'), 
                                             msg: a.result.msg , 
                                             buttons: Ext.Msg.OK, 
                                             icon: Ext.Msg.INFO
                                           });                       
                                   }
                               });
                             }
                         }
                     }
                ]
            });
            var preftabs = new Ext.TabPanel({ 
                activeTab: 0, 
                plugins: [ new Ext.ux.panel.DraggableTabs()], 
                items: [
                    { xtype:'panel', layout:'form', frame: false, border: false,
                        title: _('Avatar'),
                        bodyStyle: { 'background-color':'#fff', padding: '10px 10px 10px 10px' },
                        items: [
                            { xtype:'container', fieldLabel:_('Current avatar'), html: img },
                            { xtype:'button', width: 80, fieldLabel: _('Change avatar'), scale:'large', text:_('Change Avatar'), handler:gen_avatar },
                            { xtype:'container', fieldLabel: _('Upload avatar'), items: [ upload ] }
                          ]
                    },
                    { xtype:'panel', layout:'form', frame: false, border: false,
                        title: _('Default dashboard'),
                        bodyStyle: { 'background-color':'#fff', padding: '10px 10px 10px 10px' },
                        items: [
                            change_dashboard_form
                        ]
                    },
                    { title: _('API'), layout:'form', frame: false, border: false, 
                        bodyStyle: { 'background-color':'#fff', padding: '10px 10px 10px 10px' },
                        items: [
                            api_key,
                            { xtype:'button',  fieldLabel: _('Save API Key'), width: 150, scale:'large', text:_('Save'), handler: save_apikey },
                            { xtype:'button',  fieldLabel: _('Generate API Key'), width: 150, scale:'large', text:_('Generate API Key'), handler: gen_apikey }
                        ]
                    }
                ]
            });
            var win = new Baseliner.Window({
                title: _('Preferences'),
                layout:'fit', width: 600, height: 400, 
                items: [ preftabs ]
            });
            win.show(); 
        });
    }
});

