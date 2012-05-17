(function(params){
    // Detail Panel
    var detail = new Ext.Panel({ });
    var show_detail = function(){
        cardpanel.getLayout().setActiveItem( 0 );
    };
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

    // Form Panel
    var form = new Ext.Panel({ });
    var show_form = function(){
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', { params: { title: 1212 } }, function(comp) {
            form.removeAll();
            form.add( comp );
            form.doLayout();
        });
        cardpanel.getLayout().setActiveItem( 1 );
    };
    var tb = new Ext.Toolbar({
        isFormField: true,
        items: [
            { 
            icon:'/static/images/icons/detail.png',
            cls: 'x-btn-icon',
            enableToggle: true, pressed: true, handler: show_detail, toggleGroup: 'form' },
            { text:'Editar',
            icon:'/static/images/icons/edit.png',
            cls: 'x-btn-text-icon',
            enableToggle: true, handler: show_form, toggleGroup: 'form' },
            '-',
            _('Estado') + ': ',
            { xtype: 'combo', value: 'New' },
            '->',
            { text: _('Add Comment'), menu: menu_comment }
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
    detail.on( 'render', function() {
        detail.load({ url: '/topic/view', params: { id: params.id, html: 1 }, scripts: true });
        detail.body.setStyle('overflow', 'auto');
    });

    cardpanel.tab_icon = '/static/images/icons/topic_one.png';
    return cardpanel;
})
