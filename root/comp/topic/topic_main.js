<%perl>
    use Baseliner::Utils;
    my $ii = Baseliner::Utils::_nowstamp();
    my $swEdit = $c->stash->{swEdit};
</%perl>

(function(params){
    var view_is_dirty = false;
    var form_is_loaded = false;
    var ii = "<% $ii %>";  // used by the detail page
    var btn_form_ok = new Ext.Button({
            text: _('Save'),
            icon:'/static/images/icons/save.png',
            cls: 'x-btn-icon-text',
            type: 'submit',
            hidden: true,
            handler: function() {
                var form2 = form_topic.getForm();
                var action = form2.getValues()['topic_mid'] >= 0 ? 'update' : 'add';
                
                if (form2.isValid()) {
                   form2.submit({
                       params: {action: action},
                       success: function(f,a){
                            Baseliner.message(_('Success'), a.result.msg );
                            
                            form2.findField("topic_mid").setValue(a.result.topic_mid);
                            form2.findField("status").setValue(a.result.topic_status);

                            if( params._parent_grid != undefined && params._parent_grid.getStore()!=undefined ) {
                                params._parent_grid.getStore().reload();
                            }
                            
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
                            btn_detail.show();
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
    });

    // Detail Panel
    var detail = new Ext.Panel({ });
    var show_detail = function(){
        cardpanel.getLayout().setActiveItem( 0 );
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
    var form = new Ext.Panel({ layout:'fit' });
    var form_topic;
    var load_form = function(rec) {
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', rec, function(comp) {
            if( ! form_is_loaded ) {
                form.removeAll();
                form_topic = comp;
                form.add( comp );
                form.doLayout();
                form_is_loaded = true;
            }
            btn_form_ok.show();
            if(params.topic_mid){
                btn_comment.show();
                btn_detail.show();
            }else{
                btn_comment.hide();
                btn_detail.hide();
            }
        });            
    };
    var show_form = function(){
        if( params!==undefined && params.topic_mid !== undefined ) {
            if (!form_is_loaded){
                Baseliner.ajaxEval( '/topic/json', { topic_mid: params.topic_mid }, function(rec) {
                    load_form( rec );
                });
            }else{
                btn_form_ok.show();
                if(params.topic_mid){
                    btn_comment.show();
                    btn_detail.show();
                }else{
                    btn_comment.hide();
                    btn_detail.hide();
                }                
            }
        } else {
            
            Baseliner.ajaxEval( '/topic/new_topic', { new_category_id: params.new_category_id, new_category_name: params.new_category_name }, function(rec) {
                load_form( rec );
            });
        }
          
        cardpanel.getLayout().setActiveItem( 1 );
    };

    Baseliner.show_topic = function(topic_mid, title) {
        Baseliner.add_tabcomp('/topic/view', title , { topic_mid: topic_mid, title: title } );
    };

    // if id_com is undefined, then its add, otherwise it's an edit
    Baseliner.Topic.comment_edit = function(topic_mid, id_com) {
        var win_comment;    
        var comment_field = new Ext.form.HtmlEditor({
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
        text:_('Edit'),
        icon:'/static/images/icons/edit.png',
        cls: 'x-btn-text-icon',
        enableToggle: true, handler: show_form, allowDepress: false, toggleGroup: 'form'
    });
        
    var tb = new Ext.Toolbar({
        isFormField: true,
        items: [
            btn_detail,
            btn_edit,
            '-',
            btn_comment,
            btn_form_ok
        ]
    });
    var cardpanel = new Ext.Panel({
        layout: 'card',
        activeItem: 0,
        title: params.title,
        tbar: tb,
        items: [ detail, form ]
    });
    var detail_reload = function(){
        detail.load({ url: '/topic/view', params: { topic_mid: params.topic_mid, ii: ii, html: 1, categoryId: params.categoryId }, scripts: true, callback: function(x){ 
            // loading HTML has finished
            //   careful: errors here block will break js in baseliner
        }});
        detail.body.setStyle('overflow', 'auto');
    };
    detail.on( 'render', function() {
        detail_reload();
%if($swEdit){    
        btn_edit.toggle(true);
        btn_detail.toggle(false);
        show_form();
%}        
    });
    

    // Baseliner.ajaxEval( '/topic/json', { topic_mid: params.topic_mid }, function(rec) {
    //     load_form( rec );
    // });
    
    cardpanel.tab_icon = '/static/images/icons/topic_one.png';
    return cardpanel;
})
