<%perl>
    use Baseliner::Utils;
    my $ii = Baseliner::Utils::_nowstamp();
    my $swEdit = $c->stash->{swEdit};
    my $permEdit = $c->stash->{permissionEdit};
    my $app = $c->stash->{app};
    my $admin = $c->stash->{admin};
</%perl>

(function(params){
    var self = {};
    var view_is_dirty = false;
    var form_is_loaded = false;
    var swEdit = <% $swEdit ? 'true' : 'false' %>;
    var permEdit = <% $permEdit ? 'true' : 'false' %>;
    var ii = "<% $ii %>";  // used by the detail page
    var app = '<% $app %>';
    var admin = '<% $admin %>';
    
    var btn_form_ok = new Ext.Button({
            name: 'grabar',
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: true,
            handler: function() {
                var save_topic = function (){
                    if (form2.isValid()) {
                       form2.submit({
                           params: {action: action, form: custom_form, _cis: Ext.util.JSON.encode( _cis ) },
                           success: function(f,a){
                                Baseliner.message(_('Success'), a.result.msg );
                                if( params._parent_grid != undefined && params._parent_grid.getStore()!=undefined ) {
                                    params._parent_grid.getStore().reload();
                                }
                                    
                                if (closeTab) {
                                    var tabpanel = Ext.getCmp('main-panel');
                                    var objtab = tabpanel.getActiveTab();                                
                                    tabpanel.remove(objtab);
                                }else{
                                    
                                    form2.findField("topic_mid").setValue(a.result.topic_mid);
                                    form2.findField("status").setValue(a.result.topic_status);
                
                                    var store = form2.findField("status_new").getStore();
                                    store.on("load", function() {
                                        form2.findField("status_new").setValue( a.result.topic_status );
                                    });
                                    store.load({
                                        params:{    'categoryId': form2.findField("category").getValue(),
                                                    'statusId': form2.findField("status").getValue(),
                                                    'statusName': form2.findField("status_new").getRawValue()
                                                }
                                    });
                                    
                                    params.topic_mid = a.result.topic_mid;
                                    btn_comment.show();
                                    //btn_detail.show();
                                    Baseliner.TopicExtension.toolbar.length > 0 ? btn_detail.hide(): btn_detail.show();
                                    if(action == 'add'){
                                        var tabpanel = Ext.getCmp('main-panel');
                                        var objtab = tabpanel.getActiveTab();
                                        var title = objtab.title + ' #' + a.result.topic_mid;
                                        objtab.setTitle( title );
                                        var info = Baseliner.panel_info( objtab );
                                        info.params.topic_mid = a.result.topic_mid;
                                        info.title = title;
                                    }
                                    view_is_dirty = true;
                                    
                                    if (gdi) {
                                        //var objSolicitud = Ext.get('gdi_solicitud');
                                        form2.findField('title').setValue(a.result.title);
                
                                        //form2.findField('gdi_solicitud').setValue(a.result.title);
                                        //form2.findField('gdi_solicitud').show();
                                        //form2.findField('status_new').show();    
                                    }
                                }
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
                
                self.form_topic.on_submit();
                
                var form2 = self.form_topic.getForm();
                var action = form2.getValues()['topic_mid'] >= 0 ? 'update' : 'add';
                var custom_form = '';
                var closeTab = false;
                
                var gdi = form2.findField('gdi');
                if (gdi){
                    custom_form = gdi;
                    
                    var status_store = form2.findField("status_new").getStore();
            		var rowIndex = status_store.find('action','New');
                    if(rowIndex != -1){
                        var status_old = form2.findField("status").getValue();
                        sel = status_store.getAt(rowIndex);
                        if(sel.data.id == status_old && status_old != form2.findField("status_new").getValue()){
                            closeTab = true;
                        }
                        
                    }
                    
                    var id_obj_status = form2.findField("status_new").id;
                    //if (Baseliner.GDI.get_action_status(id_obj_status) != 'New') Baseliner.GDI.check_status(id_obj_status);
                    //alert(Baseliner.GDI.get_action_status(id_obj_status));
                    //if ( Baseliner.GDI.get_action_status(id_obj_status) == 'Ok' ){
                    if ( Baseliner.GDI.get_action_status(id_obj_status) != 'New' && Baseliner.GDI.check_status(id_obj_status) == 'Ok' ){
                        Ext.Msg.confirm( _('Confirmation'), '¿Desea dar por realizada la solicitud ?', 
                        function(btn){ 
                            if(btn == 'no') {
                                Baseliner.GDI.change_status(id_obj_status, 'Processing');
                                save_topic();
                            }else{
                                save_topic();
                                closeTab = true;
                            }
                        });
                    }else{
                        save_topic();    
                    }
                }else{
                    save_topic();
                }
            }
    });

    // Detail Panel
    var detail = new Ext.Panel({
        //padding: '0px'
    });
    
    var show_detail = function(){
        self.cardpanel.getLayout().setActiveItem( detail );
        
        ////*************************************************************
        //if(btn_form_fin_solicitud){
        //    btn_form_fin_solicitud.hide();
        //    btn_form_volver.hide();
        //    btn_edit.show();
        //}
        ////*************************************************************
        
        btn_form_ok.hide();
        if( view_is_dirty ) {
            view_is_dirty = false;
            detail_reload();
        }
    };

    Baseliner.Topic.file_del = function( topic_mid, md5, id_row ) {
        Baseliner.ajaxEval( '/topic/file/delete', { md5 : md5, topic_mid: topic_mid }, function(res) {
            if( res.success ) {
                Baseliner.message( _('File'), res.msg );
                Ext.fly( id_row ).remove();
            }
            else {
                Ext.Msg.alert( _('Error'), res.msg );
            }
        });
    };

    // Form Panel
    var form_panel = new Ext.Panel({
        layout:'form',
        //autoHeight: true
        style: { padding: '15px' },
        defaults: {anchor:'80%' }
    });

    var _cis = [];
    var load_form = function(rec) {
        if( rec._cis ) {
            _cis = rec._cis;
        } else {
            rec._cis = _cis;
        }
        rec.id_panel = self.cardpanel.id;
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', rec, function(comp) {
            if( ! form_is_loaded ) {
                //form_panel.removeAll();
                self.form_topic = comp;
                ////form_panel.add( comp );
                //form_panel.doLayout();
                self.cardpanel.add( self.form_topic );
                self.cardpanel.getLayout().setActiveItem( self.form_topic );
                form_is_loaded = true;
                
                ////////////************************************************************
                ////////if (btn_form_fin_solicitud){
                ////////    //var id_obj_status = self.form_topic.getForm().findField("status_new").id;
                ////////    //if (Baseliner.GDI.get_action_status(id_obj_status) == 'New') btn_form_fin_solicitud.show();
                ////////
                ////////    var obj_status = self.form_topic.getForm().findField("status_new");
                ////////    var storeStatus = obj_status.getStore();
                ////////    storeStatus.on("load", function() {
                ////////        alert('sdsdsdsd');
                ////////        if (Baseliner.GDI.get_action_status(obj_status.id) == 'New') btn_form_fin_solicitud.show();
                ////////    });                
                ////////}
                ////////
                ////////////************************************************************
            }

            // now show/hide buttons
            btn_form_ok.show();

            if(params.topic_mid){
                btn_comment.show();
                Baseliner.TopicExtension.toolbar.length > 0 ? btn_detail.hide(): btn_detail.show();
                //btn_detail.show();
            }else{
                btn_comment.hide();
                btn_detail.hide();
            }
        });            
    };

    var show_form = function(){
        self.cardpanel.getLayout().setActiveItem( loading_panel );
        if( params!==undefined && params.topic_mid !== undefined ) {
            if (!form_is_loaded){

                Baseliner.ajaxEval( '/topic/json', { topic_mid: params.topic_mid }, function(rec) {
                    load_form( rec );
                    //////*************************************************************
                    ////alert('pasa');
                    ////if(btn_form_fin_solicitud){
                    ////    btn_edit.hide();
                    ////    var id_obj_status = self.form_topic.getForm().findField("status_new").id;
                    ////    if (Baseliner.GDI.get_action_status(id_obj_status) == 'New') btn_form_fin_solicitud.show();
                    ////    btn_detail.show();
                    ////}
                    //////****************************************************************                    
                });
            }else{
                self.cardpanel.getLayout().setActiveItem( self.form_topic );
                
                //////*******************************************************************
                ////if(btn_form_fin_solicitud){
                ////    var id_obj_status = self.form_topic.getForm().findField("status_new").id;
                ////    if (Baseliner.GDI.get_action_status(id_obj_status) == 'New') btn_form_fin_solicitud.show();
                ////    btn_edit.hide();   
                ////}
                //////******************************************************************

                btn_form_ok.show();
                
                if(params.topic_mid){
                    //btn_comment.show();
                    Baseliner.TopicExtension.toolbar.length > 0 ? btn_detail.hide(): btn_detail.show();
                    
                }else{
                    btn_comment.hide();
                    btn_detail.hide();
                }                
            }
        } else {
            Baseliner.ajaxEval( '/topic/new_topic', { new_category_id: params.new_category_id, new_category_name: params.new_category_name, ci: params.ci, dni: params.dni }, function(rec) {
                load_form( rec );
            });
        }
          
    };

    var kanban;
    var show_kanban = function(){
        Baseliner.ajaxEval('/topic/children', { mid: params.topic_mid }, function(res){
            var topics = res.children;
            kanban = Baseliner.kanban({ topics: topics, background: '#888',
                on_tab: function(){
                    self.cardpanel.getLayout().setActiveItem( detail );
                    btn_detail.toggle( true );
                }
            });
            self.cardpanel.add( kanban );
            self.cardpanel.getLayout().setActiveItem( kanban );
        });
    };

    var rg;
    var show_graph = function(){
        if( rg ) { rg.destroy(); rg=null }
        Baseliner.ajaxEval( '/ci/json_tree', { mid: params.topic_mid, does_any:['Project', 'Infrastructure','Topic'], direction:'children', depth:4 }, function(res){
            if( ! res.success ) { Baseliner.message( 'Error', res.msg ); return }
            rg = new Baseliner.JitRGraph({ json: res.data });
            self.cardpanel.add( rg );
            self.cardpanel.getLayout().setActiveItem( rg );
        });
    };

    Baseliner.show_topic = function(topic_mid, title) {
        Baseliner.add_tabcomp('/topic/view', title , { topic_mid: topic_mid, title: title } );
    };

    // if id_com is undefined, then its add, otherwise it's an edit
    Baseliner.Topic.comment_edit = function(topic_mid, id_com) {
        var win_comment;    
        var comment_field = new Baseliner.HtmlEditor({
            listeners: { 'initialize': function(){ comment_field.focus() } }
        });
        var btn_submit = {
            xtype: 'button',
            text: _('Add Comment'),
            handler: function(){
                var text, content_type;
                var id = cardcom.getLayout().activeItem.id;
                if( id == comment_field.getId() ) {
                    text = comment_field.getValue();
                    content_type = 'html';
                } else {
                    text = code.getValue();
                    content_type = 'code';
                }
                Baseliner.ajaxEval( '/topic/comment/add',
                    { topic_mid: topic_mid, id_com: id_com, text: text, content_type: content_type },
                    function(res) {
                       if( ! res.failure ) { 
                           Baseliner.message(_('Success'), res.msg );
                           win_comment.close();
                           detail_reload();
                       } else {
                            Ext.Msg.show({ 
                                title: _('Information'),
                                msg: res.msg , 
                                buttons: Ext.Msg.OK, 
                                icon: Ext.Msg.INFO
                            });                         
                        }
                     }
                );
            }
        };

        var code_field = new Ext.form.TextArea({});
        var code;

        var btn_html = {
            xtype: 'button',
            text: _('HTML'),
            enableToggle: true, pressed: true, allowDepress: false, toggleGroup: 'comment_edit',
            handler: function(){
                cardcom.getLayout().setActiveItem( 0 );
            }
        };
        var btn_code = {
            xtype: 'button',
            text: _('Code'),
            enableToggle: true, pressed: false, allowDepress: false, toggleGroup: 'comment_edit',
            handler: function(){
                cardcom.getLayout().setActiveItem( 1 );
                var com = code_field.getEl().dom;
                code = CodeMirror(function(elt) {
                    com.parentNode.replaceChild( elt, com );
                }, { 
                    value: comment_field.getValue(),
                    lineNumbers: true, tabMode: "indent", smartIndent: true, matchBrackets: true
                });
            }
        };
        var cardcom = new Ext.Panel({ 
            layout: 'card', 
            activeItem: 0,
            items: [ comment_field, code_field ]
        });

        win_comment = new Ext.Window({
            title: _('Add Comment'),
            layout: 'fit',
            width: 700,
            closeAction: 'close',
            maximizable: true,
            autoHeight: true,
            bbar: [ 
                btn_html,
                btn_code, '->', btn_submit],
            items: cardcom
        });
        if( id_com !== undefined ) {
            Baseliner.ajaxEval('/topic/comment/view', { id_com: id_com }, function(res) {
                if( res.failure ) {
                    Baseliner.message( _('Error'), res.msg );
                } else {
                    comment_field.setValue( res.text );
                    win_comment.show();
                }
            });
        } else {
            win_comment.show();
        }
    };

    var btn_comment = new Ext.Toolbar.Button({
        text: _('Add Comment'),
        icon:'/static/images/icons/comment_new.gif',
        cls: 'x-btn-icon-text',
        handler: function() {
            Baseliner.Topic.comment_edit( params.topic_mid );
        }
    });

    var btn_detail = new Ext.Toolbar.Button({
        icon:'/static/images/icons/detail.png',
        cls: 'x-btn-icon',
        enableToggle: true, pressed: true, allowDepress: false, handler: show_detail, toggleGroup: 'form'
    });
    
    var btn_edit = new Ext.Toolbar.Button({
        name: 'edit',
        text:_('Edit'),
        icon:'/static/images/icons/edit.png',
        cls: 'x-btn-text-icon',
        enableToggle: true, handler: show_form, allowDepress: false, toggleGroup: 'form'
    });
        
    var btn_kanban = new Ext.Toolbar.Button({
        icon:'/static/images/icons/kanban.png',
        cls: 'x-btn-icon',
        enableToggle: true, handler: show_kanban, allowDepress: false, toggleGroup: 'form'
    });
        
    var btn_graph = new Ext.Toolbar.Button({
        icon:'/static/images/ci/ci-grey.png',
        cls: 'x-btn-icon',
        enableToggle: true, handler: show_graph, allowDepress: false, toggleGroup: 'form'
    });
        
    var loading_panel = Baseliner.loading_panel();

    var tb;
    if( Baseliner.TopicExtension.toolbar.length > 0 ) {
        Ext.each( Baseliner.TopicExtension.toolbar, function(etb){
            var tb_external = etb(self,params,btn_detail,btn_form_ok,btn_edit);
            if( tb_external ) tb = tb_external;
        });
    }
    if( ! tb ) {
        tb = new Ext.Toolbar({
            isFormField: true,
            items: [
                btn_detail,
                btn_edit,
                '-',
                btn_comment,
                btn_form_ok,
                '->',
                btn_kanban,
                btn_graph
            ]
        });
    }
    
    self.cardpanel = new Ext.Panel({
        layout: 'card',
        activeItem: 0,
        title: params.title,
        tbar: tb,
        //frame: true,
        padding: '15px 15px 15px 15px',
        defaults: {border: false},
        items: [ loading_panel, detail ]
    });
    
    var detail_reload = function(){
        detail.load({
            url: '/topic/view',
            params: { topic_mid: params.topic_mid, ii: ii, html: 1, categoryId: params.new_category_id },
            scripts: true,
            callback: function(x){ 
                // loading HTML has finished
                //   careful: errors here block will break js in baseliner
                if( ! swEdit ) {
                    var layout = self.cardpanel.getLayout().setActiveItem( detail );
                }
            }
        });
        detail.body.setStyle('overflow', 'auto');
    };
    detail.on( 'render', function() {
        detail_reload();
        if( swEdit ) {
            if( !permEdit ) {
                btn_edit.hide();
            } else {
                btn_edit.toggle(true);
                btn_detail.toggle(false);
                show_form();        
            }
        }
    });
    
    if( !permEdit ) {
        btn_edit.hide();
    }
    
    //Baseliner.ajaxEval( '/topic/json', { topic_mid: params.topic_mid }, function(rec) {
    //    load_form( rec );
    //});
    
    self.cardpanel.tab_icon = '/static/images/icons/topic_one.png';
    if( ! params.title ) {
        self.cardpanel.setTitle("#" + params.topic_mid) 
    }
    return self.cardpanel;
})
