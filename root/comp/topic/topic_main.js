<%args>
    $title 
    $id_rel
</%args>
(function(){
    var detail = new Ext.Panel({
    });
    var form = new Ext.Panel({  });
    var show_detail = function(){
        tabpanel.getLayout().setActiveItem( 0 );
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
    var show_form = function(){
        Baseliner.ajaxEval( '/comp/topic/topic_form.js', {}, function(comp) {
            form.removeAll();
            //alert( comp );
            form.add( comp() );
            form.doLayout();
        });
        tabpanel.getLayout().setActiveItem( 1 );
    };
    var tb = new Ext.Toolbar({
        isFormField: true,
        items: [
            { text:'Resumen', enableToggle: true, pressed: true, handler: show_detail, toggleGroup: 'form' },
            { text:'Editar', enableToggle: true, handler: show_form, toggleGroup: 'form' },
            '-',
            _('Estado') + ': ',
            { xtype: 'combo', value: 'New' },
            '->',
            { text: _('Add Comment'), menu: menu_comment }
        ]
    });
    var tabpanel = new Ext.Panel({
        layout: 'card',
        activeItem: 0,
        title: '<% $title %>',
        tbar: tb,
        items: [ detail, form ]
    });
    detail.on( 'render', function() {
        detail.load({ url: '/topic/view', params: { id_rel: '<% $id_rel %>', html: 1 }, scripts: true });
        detail.body.setStyle('overflow', 'auto');
    });

    return tabpanel;
})
