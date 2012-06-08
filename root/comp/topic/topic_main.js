<%perl>
    my $ii = int rand 9999999999999999999;
    my $swEdit = $c->stash->{swEdit};

</%perl>
(function(params){
    var view_is_dirty = false;
    var form_is_loaded = false;
    var ii = "<% $ii %>";  // used by the detail page
    var btn_form_ok = new Ext.Button({
            text: _('Accept'),
            type: 'submit',
            hidden: true,
            handler: function() {
                var form2 = form_topic.getForm();
                var action = form2.getValues()['id'] >= 0 ? 'update' : 'add';
                
                if (form2.isValid()) {
                   form2.submit({
                       params: {action: action},
                       success: function(f,a){
                            Baseliner.message(_('Success'), a.result.msg );
                            
                            form2.findField("id").setValue(a.result.topic_id);
                            form2.findField("mid").setValue(a.result.topic_mid);
                            form2.findField("status").setValue(a.result.topic_status);
                            
                            var store = form2.findField("status_new").getStore();
                            store.load({
                                params:{    'categoryId': form2.findField("category").getValue(),
                                            'statusId': form2.findField("status").getValue(),
                                            'statusName': form2.findField("status_new").getRawValue()
                                        }
                            });
                            params.id = a.result.topic_id;
                            params.mid = a.result.topic_mid;
                            btn_comment.show();
                            if(action == 'add'){
                                var tabpanel = Ext.getCmp('main-panel');
                                var objtab = tabpanel.getActiveTab();
                                objtab.setTitle(objtab.title + ' #' + a.result.topic_id);
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
    //var btn_form_reset = ({
    //    text: _('Reset'),
    //    hidden: true,
    //    handler: function(){ 
    //            //win.close();
    //        }
    //});
    // Detail Panel
    var detail = new Ext.Panel({ });
    var show_detail = function(){
        cardpanel.getLayout().setActiveItem( 0 );
        btn_form_ok.hide();
        if( view_is_dirty ) {
            view_is_dirty = false;
            detail_reload();
        }
        //btn_form_reset.hide();
    };

    Baseliner.Topic.file_del = function( id_topic, md5, id_row ) {
        Baseliner.ajaxEval( '/topic/file/delete', { md5 : md5, id_topic: id_topic }, function(res) {
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
                //var form2 = form_topic.getForm();
                //form2.findField("status").setValue(rec.status);                 
            }
            btn_form_ok.show();
            if(params.id){
                btn_comment.show();
            }else{
                btn_comment.hide();
            }
            //btn_form_reset.show();
        });
    };
    var show_form = function(){
        if( params!==undefined && params.id !== undefined ) {
            Baseliner.ajaxEval( '/topic/json', { id: params.id }, function(rec) {
                
                load_form( rec );
            });
        } else {
            load_form({ new_category_id: params.new_category_id, new_category_name: params.new_category_name });
        }
          
        cardpanel.getLayout().setActiveItem( 1 );
    };

    // if id_com is undefined, then its add, otherwise it's an edit
    Baseliner.Topic.comment_edit = function(id_topic, id_com) {
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
                    { id_topic: id_topic, id_com: id_com, text: text, content_type: content_type },
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
        //disabled: true,
        handler: function() {
            Baseliner.Topic.comment_edit( params.id );
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
            //{ 
            //    icon:'/static/images/icons/detail.png',
            //    cls: 'x-btn-icon',
            //    enableToggle: true, pressed: true, handler: show_detail, toggleGroup: 'form'
            //},
            //{ text:_('Edit'),
            //    icon:'/static/images/icons/edit.png',
            //    cls: 'x-btn-text-icon',
            //    enableToggle: true, handler: show_form, toggleGroup: 'form'
            //},
            btn_detail,
            btn_edit,
            '-',
            btn_comment,
            '-',
            //_('Estado') + ': ',
            //{ xtype: 'combo', value: 'New' },
            '->',
            btn_form_ok
            //btn_form_reset
        ]
    });
    var cardpanel = new Ext.Panel({
        layout: 'card',
        activeItem: 0,
        cardSwitchAnimation:'slide',
        title: params.title,
        tbar: tb,
        items: [ detail, form ]
    });
    var detail_reload = function(){
        detail.load({ url: '/topic/view', params: { id: params.id, ii: ii, html: 1, categoryId: params.categoryId }, scripts: true, callback: function(x){ 
            // loading HTML has finished
            //   careful: errors here block will break js in baseliner
            var el = document.getElementById('uploader_' + ii );
            var uploader = new qq.FileUploader({
                element: el,
                action: '/topic/upload',
                //debug: true,  
                // additional data to send, name-value pairs
                params: {
                    id_topic: params.id
                },
                template: '<div class="qq-uploader">' + 
                    '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
                    '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
                    '<ul class="qq-upload-list"></ul>' + 
                 '</div>',
                onCancel: function(){
                },
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
    

    
    cardpanel.tab_icon = '/static/images/icons/topic_one.png';
    return cardpanel;
})
