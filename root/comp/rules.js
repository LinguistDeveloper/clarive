(function(params){
    var ps = 30;
    var rule_store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        url: '/rule/list',
        baseParams: Ext.apply({ start:0, limit: ps}, params),
        fields: [ 'mid','_id','_parent','_is_leaf','type', 'item','class','versionid','ts','tags','data','properties','icon','collection']
    });
    var search_field = new Baseliner.SearchField({
        store: rule_store,
        params: {start: 0, limit: ps },
        emptyText: _('<Enter your search string>')
    });

    var rule_add = function(){
        var ac = 0;
        var check_sm_events = new Ext.grid.CheckboxSelectionModel({
            singleSelect: true,
            sortable: false,
            checkOnly: true
        });

        var store_events =new Ext.data.SimpleStore({
            fields: [ 'ev_type', 'ev_id', 'ev_desc'],
            data:[ 
                [ 'trigger', 'event.topic.new', 'Nuevo Tópico' ],
                [ 'trigger', 'event.topic.edit_field', 'Campo de Tópico Modificado' ],
                [ 'trigger', 'event.topic.change', 'Estado de Tópico Modificado' ],
                [ 'trigger', 'event.topic.file.add', 'Fichero Adjuntado a Tópico' ],
                [ 'trigger', 'event.topic.file.del', 'Fichero Quitado del Tópico' ],
                [ 'trigger', 'event.topic.topic.add', 'Tópico Añadido a Tópico' ],
                [ 'trigger', 'event.topic.topic.del', 'Tópico Quitado del Tópico' ],
                [ 'continuous', 'event.topic.date', 'Fecha Planificada Superada' ],
                [ 'continuous', 'event.topic.hours', 'Horas Estimadas Superadas' ],
                [ 'continuous', 'event.topic.low', 'Tópico Sin Actividad Prolongada' ],
                [ 'trigger', 'event.project.new', 'Proyecto Creado' ],
                [ 'trigger', 'event.project.deleted', 'Proyecto Borrado' ],
                [ 'trigger', 'event.user.new', 'Usuario Creado' ],
                [ 'trigger', 'event.user.deleted', 'Usuario Borrado' ],
                [ 'trigger', 'event.user.login', 'Login de Usuario' ],
                [ 'trigger', 'event.user.logout', 'Logout de Usuario' ],
                [ 'trigger', 'event.job.new', 'Pase Creado' ],
                [ 'trigger', 'event.job.done', 'Pase Finalizado' ],
                [ 'trigger', 'event.job.topic.demote', 'Marcha Atrás de Cambio Completada' ],
                [ 'trigger', 'event.job.topic.promote', 'Despliegue de Cambio Completada' ],
                [ 'trigger', 'event.sem.up', 'Semáforo Levantado' ],
                [ 'trigger', 'event.sem.down', 'Semáforo Bajado' ],
                [ 'trigger', 'event.ci.new', 'Nuevo CI' ],
                [ 'trigger', 'event.ci.edit', 'CI Modificado' ],
                [ 'trigger', 'event.ci.deleted', 'CI Borrado' ],
            ]
        });
        var grid_events = new Ext.grid.GridPanel({
            sm: check_sm_events,
            store: store_events,
            border: false,
            height: 280,
            viewConfig: { forceFit: true },
            columns:[
                check_sm_events,
                { header: _('Description'), width: 100, dataIndex: 'ev_desc', renderer:function(v){ return '<b>'+v+'</b>'} },
                { header: _('Event Type'), width: 60, dataIndex: 'ev_type' },
                { header: _('Event'), width: 100, dataIndex: 'ev_id' }
            ]
        });
        var form_events = new Ext.FormPanel({
            defaults: {
                anchor: '90%'
            },
            border: false,
            items: [
                { xtype:'textfield', fieldLabel:_('Name'), name:'rule_name' },
                { border:false, html:'<span id="boot"><p><h4>'+_('Select the Event') + ':</h4></p>' },
                grid_events
            ]
        });
        var store_status =new Ext.data.SimpleStore({
            fields: ['status'],
            data:[ 
                [ 'Cerrado' ],
                [ 'Integración' ],
                [ 'Preproducción' ],
                [ 'Producción' ],
                [ 'Desarrollo' ],
                [ 'Nuevo' ],
                [ 'Desestimado' ],
                [ 'Elaboración de requerimientos' ],
                [ 'Recepción de requerimientos' ],
                [ 'Validación' ],
                [ 'Parametrización' ],
                [ 'Validar parche de datos' ],
                [ 'UAT Parche de datos' ],
                [ 'Chequeo parche de datos' ],
                [ 'Aceptado' ]
            ]
        });
        var combo_status = new Ext.form.ComboBox({
            store: store_status,
                displayField: 'status',
                valueField: 'status',
                hiddenName: 'status',
                name: 'status',
            editable: false,
            mode: 'local',
            forceSelection: true,
            triggerAction: 'all', 
            fieldLabel: _('Estado del Tópico'),
            emptyText: _('seleccione estados...'),
            autoLoad: true
        });
        var store_cat =new Ext.data.SimpleStore({
            fields: ['cat'],
            data:[ 
                [ 'Nueva codificación' ],
                [ 'Parametrización no estándar' ],
                [ 'Desarrollo' ],
                [ 'Nuevo colectivo' ],
                [ 'Apertura/Restricción C4T' ],
                [ 'Versión base' ],
                [ 'Versión de datos' ],
                [ 'Nuevo código cuenta canal' ],
                [ 'Nuevo código canal' ],
                [ 'Activación/Desactivación básica' ],
                [ 'Conjunto completo de promociones' ],
                [ 'Comunicaciones en factura' ],
                [ 'Actualizaciones country codes/tarifas' ],
                [ 'Pequeños cambios en portal web' ],
                [ 'Parche de datos' ],
                [ 'Entrega independiente' ],
                [ 'Bug' ]
            ]
        });
        var combo_cat = new Ext.form.ComboBox({
            store: store_cat,
                displayField: 'cat',
                valueField: 'cat',
                hiddenName: 'cat',
                name: 'cat',
            editable: false,
            mode: 'local',
            forceSelection: true,
            triggerAction: 'all', 
            fieldLabel: _('Categoría'),
            emptyText: _('seleccione categoría...'),
            autoLoad: true
        });

        var form1 = new Ext.FormPanel({
            border: false,
            defaults: { anchor:'80%' },
            items: [
                { border:false, html:'<span id="boot"><p><h4>'+_('Configuración') + ':</h4></p>' },
//                { xtype: 'textfield', name:'tt', fieldLabel:_('Tiempo de inactividad (D)'), anchor:'50%' },
                combo_cat,
                combo_status
            ]
        });
        var form_when = new Ext.FormPanel({
            border: false,
            items: [
                {
                    xtype: 'radiogroup',
                    id: 'eventtypegroup',
                    anchor: '50%',
                    fieldLabel: _('Event Type'),
                    defaults: {xtype: "radio",name: "rule_when"},
                    items: [
                        {boxLabel: _('Pre'), inputValue: 'pre', checked: true},
                        {boxLabel: _('Continuous'), inputValue: 'pre', checked: true},
                        {boxLabel: _('Post'), inputValue: 'post'}
                    ]
                }
            ]
        });
        var check_sm_actions = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        var store_actions = new Baseliner.JsonStore({
            root: 'data' , 
            remoteSort: true,
            autoLoad: true,
            totalProperty:"totalCount", 
            url: '/rule/actions',
            fields: [ 'text','attributes' ]
        });

       var render_desc = function(v) {
          return v.name;
       }
       var render_key = function(v) {
          return v.key;
       }
        var grid_actions = new Ext.grid.GridPanel({
            sm: check_sm_actions,
            store: store_actions,
            border: false,
            height: 280,
            viewConfig: { forceFit: true },
            columns:[
                check_sm_actions,
                { header: _('Name'), width: 100, dataIndex: 'text', renderer:function(v){ return '<b>'+v+'</b>'} },
                { header: _('Description'), width: 60, dataIndex: 'attributes', renderer: render_desc },
                { header: _('Key'), width: 100, dataIndex: 'attributes', renderer: render_key }
            ]
        })
        
        var form_actions = new Ext.FormPanel({
            border: false,
            items: [
                { border:false, html:'<span id="boot"><p><h4>'+_('Select the Action') + ':</h4></p>' },
                grid_actions
            ]
        });
        var first = 0;
        var last = 4;
        var navHandler = function(direction){
            ac += direction;
            if( direction < 0 ) {
                bdone.hide();
                bnext.show();
            }
            if( ac == first ) {
                bback.disable();
            }
            if( ac > first ) bback.enable();
            if( ac == last ) {
                bdone.show();
                bnext.hide();
            }
            card.getLayout().setActiveItem( ac ); 
        };
        var bback = new Ext.Button({
                    text: _('Back'),
                    handler: navHandler.createDelegate(this, [-1]),
                    disabled: true
                });
        var bnext = new Ext.Button({
                    text: _('Next'),
                    handler: navHandler.createDelegate(this, [1])
                });
        var bdone = new Ext.Button({
                    text: _('Done'),
                    hidden: true,
                    handler: function(){
                        var f = form_events.getForm();
                        var d = f.getValues();
                        Baseliner.ajaxEval('/rule/save', d, function(res){
                            Baseliner.message(_('Rule'), _('Regla guardada con éxito') );
                        });
                        win.close();
                    }
                });

        // Custom form
        var user_store_to = new Baseliner.Topic.StoreUsers({
            autoLoad: true,
            baseParams: {}
        });
        var user_to = new Baseliner.model.Users({ 
            store: user_store_to,
            name: 'to',
            fieldLabel:_('To')
        });
        var user_cc = new Baseliner.model.Users({ 
            store: user_store_to,
            name: 'to',
            fieldLabel:_('CC')
        });
        var user_bcc = new Baseliner.model.Users({ 
            store: user_store_to,
            name: 'to',
            fieldLabel:_('BCC')
        });
        //user_box_store.on('load',function(){ user_box.setValue( rec.users) ;            });

        var form2 = new Ext.FormPanel({
            autoScroll: true,
            defaults: {
                anchor: '80%'
            },
            items: [
                { xtype:'textfield', name:'subject', fieldLabel:_('Subject') },
                { xtype:'checkbox', name:'na', boxLabel:_('Notificar al Asignado') },
                { xtype:'checkbox', name:'na', boxLabel:_('Notificar al que la ha creado') },
                { xtype:'textfield', name:'nr', fieldLabel:_('Notificar a Roles)'), anchor:'80%' },
                user_to,
                user_cc,
                user_bcc,
                {
                        xtype:'htmleditor',
                        name:'body',
                        fieldLabel: _('Body'),
                        width: '100%',
                        height: 200
                }
        ]
        });
        var card = new Ext.Panel({
            //title: 'Example Wizard',
            layout:'card',
            height: 450,
            activeItem: 0, // make sure the active item is set on the container config!
            bodyStyle: 'padding:15px',
            defaults: {
                border: false
            },
            // just an example of one possible navigation scheme, using buttons
            bbar: [
                '->', 
                bback, bnext,bdone
            ],
            items: [
                form_events, form_when, form_actions, form1, form2
            ]
        });
        
        var win = new Ext.Window({
            title: _('Edit Rule'),
            width: 900,
            items: [
                card
            ]
        });
        win.show();
    };

    var render_actions = function(value,row){
        return '';
    };
    var grid = new Ext.grid.GridPanel({
        title: _('Rules'),
        store: rule_store,
        //sm: check_sm,
        tbar: [ search_field,
            { xtype:'button', text: 'Crear', icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon', handler: rule_add },
            { xtype:'button', text: 'Borrar', icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Etiquetar', icon: '/static/images/icons/tag.gif', cls: 'x-btn-text-icon' },
            { xtype:'button', text: 'Exportar', icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' },
        ],
        bbar: new Ext.PagingToolbar({
            store: rule_store,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
        }),        
        columns:[
            //check_sm,
            //{ width: 16, hidden: true, dataIndex: 'icon', renderer: Baseliner.render_icon },
            { header: _('Rule'), width: 160, dataIndex: 'rule_name' },
            { header: _('Type'), width: 80, dataIndex: 'rule_type' },
            { header: _('Actions'), hidden: true, width: 160, dataIndex: 'rule_name', renderer: render_actions },
            //{ header: _('Data'), hidden: false, width: 250, dataIndex: 'data', renderer: render_mapping_long }
        ]
    });
    var tree_load = function(){
        var loader = tree.getLoader();
        loader.load(tree.root);
        tree.root.expand();
    };
    var tree = new Ext.tree.TreePanel({
        autoScroll: true,
        animate: true,
        lines: true,
	    stripeRows: true,
        enableSort: false,
        enableDD: true,
        dataUrl: '/rule/tree',
        rootVisible: true,
        useArrows: true,
        root: { nodeType: 'async', text: 'Reglas', draggable: false, id: 'root', expanded: true },
        tbar: [ search_field,
            { xtype:'button', text: 'Crear', icon: '/static/images/icons/edit.gif', cls: 'x-btn-text-icon', handler: rule_add },
            { xtype:'button', text: 'Borrar', icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon' },
            { xtype: 'button', text: _('Reload'), handler: tree_load, icon:'/static/images/icons/refresh.gif', cls:'x-btn-text-icon' },
            { xtype:'button', text: 'Exportar', icon: '/static/images/icons/downloads_favicon.png', cls: 'x-btn-text-icon' },
        ]
    });
    return tree;
})
