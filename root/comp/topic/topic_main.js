<%args>
    $title 
    $id_rel
</%args>
(function(){
    var detail = new Ext.Panel({ region: 'center' });
    var form = new Ext.Panel({ region: 'center', hidden: true });
    var show_detail = function(){
        panel.add( detail );
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
        panel.remove( detail );
        //Baseliner.ajaxEval( '/comp/topic/topic_form2.js', {}, function(comp) {
            //form.add( comp );
        //});
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
    var panel = new Ext.Panel({
        layout: 'border',
        title: '<% $title %>',
        tbar: tb,
        items: [ ]
    });
    panel.on( 'render', function() {
        panel.add( detail ) ;
    });
    detail.on( 'render', function() {
        detail.load({ url: '/topic/view', params: { id_rel: '<% $id_rel %>', html: 1 }, scripts: true });
    });

    return panel;
})
