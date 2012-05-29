<%perl>
    my $ii = int rand 9999999999999999999;
    my $swEdit = $c->stash->{swEdit};

</%perl>
(function(params){
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
                           //store_opened.load();
                           win.setTitle(_('Edit topic'));
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
        //btn_form_reset.hide();
    };
    /* 
    var form_comment = new Ext.FormPanel({
        defaults: { hideLabel: true },
        items: [
            { xtype:'textarea', width: 200 }
        ]
    });
    var menu_comment = new Ext.menu.Menu({
        text: _('Comment'),
        style: {
            overflow: 'visible'     // For the Combo popup
        },
        items: form_comment
    });
    menu_comment.on('render', function(){ menu_comment.keyNav.disable() } );
    */

    // Form Panel
    var form = new Ext.Panel({ });
    var form_topic;
    var show_form = function(){
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', { id: params.id }, function(comp) {
            form.removeAll();
            form_topic = comp;
            form.add( comp );
            form.doLayout();
            btn_form_ok.show();
            //btn_form_reset.show();
        });
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
            enableToggle: true, pressed: true, toggleGroup: 'comment_edit',
            handler: function(){
                cardcom.getLayout().setActiveItem( 0 );
            }
        };
        var btn_code = {
            xtype: 'button',
            text: _('Code'),
            enableToggle: true, pressed: false, toggleGroup: 'comment_edit',
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
        enableToggle: true, pressed: true, handler: show_detail, toggleGroup: 'form'
    });
    
    var btn_edit = new Ext.Toolbar.Button({
        text:_('Edit'),
        icon:'/static/images/icons/edit.png',
        cls: 'x-btn-text-icon',
        enableToggle: true, handler: show_form, toggleGroup: 'form'
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
        detail.load({ url: '/topic/view', params: { id: params.id, html: 1 }, scripts: true, callback: function(x){ 
            // finished loading HTML
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
