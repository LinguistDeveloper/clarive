Baseliner.FieldEditor = Ext.extend( Ext.Panel, {
    frame: true,
    get_save_data : function(){
        var self = this;
        var arr = [];
        self.category_fields_store.each(function(r){
            arr.push( r.data );
        });
        return arr;
    },
    initComponent: function(){
        var self = this;
        var id_drag_drop = Ext.id();

        var treeRoot = new Ext.tree.AsyncTreeNode({
            expanded: true,
            draggable: false
        });

        var tree_fields = new Ext.tree.TreePanel({
            title: _('Fields configuration'),
            dataUrl: "/topicadmin/list_tree_fields",
            layout: 'form',
            colapsible: true,
            useArrows: true,
            animate: true,
            containerScroll: true,
            autoScroll: true,
            height:500,         
            rootVisible: false,
            enableDD: true,
            ddGroup: 'tree_fields_dd' + id_drag_drop,          
            root: treeRoot
        });
        
        tree_fields.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_fields.getLoader();
            loader.baseParams.id_category = self.id_category;
        });     
        
        var blank_image = new Ext.BoxComponent({autoEl: {tag: 'img', src: Ext.BLANK_IMAGE_URL}, height:10});
        
        Baseliner.delete_field_row = function( id_grid, id ) {
            var g = Ext.getCmp( id_grid );
            var s = g.getStore();
            s.each( function(row){
                if( row.data.id == id ) {
                    var data = row.data.params;
                    var parent_id;
                    switch (data.origin){
                        case 'system':  parent_id = 'S';
                                        break;
                        case 'custom':  parent_id = 'C';
                                        break;
                        case 'templates': parent_id = 'T';
                                        break;
                    }                   
                    var parent_node = tree_fields.getNodeById(parent_id);
                    if(parent_node!=undefined) {
                        if( !parent_node.expanded){
                            parent_node.expand();   
                        }                   
                        parent_node.appendChild({id:row.data.id, id_field: row.data.id_field, text: row.data.name, params:  row.data.params, icon: row.data.img, leaf: true});
                    }
                    s.remove( row );
                }
            });
        };
        
        function insert_node(node){
            var attr = node.attributes;
            var data = attr.params || {};
            
            var id = attr.id;
            //attr.params.id_field = attr.id_field;
            var d = { id: id, id_field: attr.id_field, name: attr.text, params: attr.params, img: attr.icon };
            
            
            var r = new self.category_fields_store.recordType( d, id );
        
        
            //Para evitar que seleccione estado compartido Solicitado   
            //rowIndex = self.category_fields_store.find('id', id);
            //if(rowIndex == -1){
            //  alert('no existe');
            //}
            //else{
            //  alert('existe');
            //}
            
            self.category_fields_store.add( r );
            self.category_fields_store.commitChanges();
        }
        
        self.category_fields_store = new Baseliner.JsonStore({
            root: 'data' , 
            remoteSort: true,
            id: 'id', 
            url: '/topicadmin/get_conf_fields',
            fields: [
                {  name: 'id' },                     
                {  name: 'id_field' },
                {  name: 'name' },
                {  name: 'params' },
                {  name: 'img' },
                {  name: 'meta' }
            ]           
        });
        
        self.category_fields_store.load({params: {id_category: self.id_category}});
        
        var btn_save_config = new Ext.Toolbar.Button({
            text: _('Save'),
            icon: '/static/images/icons/save.png',
            cls: 'x-btn-text-icon',
            handler: function() {
                var fields = new Array();
                var params = new Array();
                self.category_fields_store.each(function (row){
                    fields.push(row.data.id_field);
                    params.push(Ext.util.JSON.encode(row.data.params));
                })
                
                Baseliner.ajax_json('/topicadmin/update_fields',{ id_category: self.id_category, fields: fields, params: params },function(res){
                    Baseliner.message(_('Success'), res.msg );
                });
            }
        });
        
        var category_fields_grid = new Ext.grid.GridPanel({
            store: self.category_fields_store,
            layout: 'form',
            height: 500,
            title: _('Fields category'),
            hideHeaders: true,
            enableDragDrop : true,
            ddGroup : 'mygrid-dd' + id_drag_drop,  
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            },
            columns: [
                { header: '', width: 20, dataIndex: 'id_field', renderer: function(v,meta,rec,rowIndex){ return '<img style="float:right" src="' + rec.data.img + '" />'} },
                { header: _('Name'), width: 240, dataIndex: 'name'},
                { width: 40, dataIndex: 'id',
                        renderer: function(v,meta,rec,rowIndex){
                            return '<a href="javascript:Baseliner.delete_field_row(\''+category_fields_grid.id+'\', '+v+')"><img style="float:middle" height=16 src="/static/images/icons/clear.png" /></a>'
                        }             
                }
            ],
            // bbar: [ '->', btn_save_config ] IE10 not compatible here
        }); 
        
        category_fields_grid.on( 'afterrender', function(){
            var el = this.el.dom; 
            var fields_box_dt = new Baseliner.DropTarget(el, {
                comp: this,
                ddGroup: 'tree_fields_dd' + id_drag_drop,
                copy: true,
                notifyDrop: function(dd, e, id) {
                    var n = dd.dragData.node;
                    var attr = n.attributes;
                    var data = attr.params || {};
                    
                    if (!isNaN(attr.id)){
                        if (data.origin == 'template' ){
                            
                            var btn_cerrar_custom_field = new Ext.Toolbar.Button({
                                text: _('Close'),
                                width: 50,
                                handler: function() {
                                    winCustomField.close();
                                }
                            })
                            
                            var btn_grabar_custom_field = new Ext.Toolbar.Button({
                                text: _('Save'),
                                width: 50,
                                handler: function(){
                                    var id = self.category_fields_store.getCount() + 1;
                                    
                                    var form = form_template_field.getForm();
                                    var name_field = form.findField("name_field").getValue();
                                    var id_field = Baseliner.name_to_id( name_field );
                                    
                                    var recordIndex = self.category_fields_store.findBy(
                                        function(record, id){
                                            if(record.get('id_field') === id_field) {
                                                  return true;  // a record with this data exists
                                            }
                                            return false;  // there is no record in the store with this data
                                        }
                                    );

                                    if(recordIndex != -1){
                                        Ext.Msg.show(   {   title: _('Information'), 
                                                            msg: _('Field already exists, introduce another field name') , 
                                                            buttons: Ext.Msg.OK, 
                                                            icon: Ext.Msg.INFO
                                                        });
                                    }else{
                                        if (attr.meta) { //Casos especiales, como la plantilla listbox
                                            var objTemp = attr.data[combo_system_fields.getValue()];
                                            // clone
                                            objTemp = Ext.util.JSON.decode( Ext.util.JSON.encode( objTemp ) );

                                            if (objTemp.type != 'form'){ 
                                                objTemp.id_field = id_field;
                                                objTemp.name_field = name_field;
                                                objTemp.bd_field = id_field;
                                                objTemp.origin = 'custom';
                                            }
                                            
                                            if ( objTemp.filter != undefined){
                                                if(objTemp.filter === 'manual'){
                                                    objTemp.filter = txt_filters.getValue() ? txt_filters.getValue() : 'none' ;
                                                }
                                            }
                                            if ( objTemp.single_mode != undefined){
                                                var value = form.findField("valuesgroup").getValue().getGroupValue();
                                                 objTemp.single_mode = ( value == 'S' || value ==  'single') ? true : false ;
                                                 objTemp.list_type = value=='S' ? 'single' : value=='M' ? 'multiple' : value=='G' ? 'grid' : value;
                                            }
                                            
                                            var d = { id: id, id_field: id_field, name: name_field, params: objTemp , img: '/static/images/icons/icon_wand.gif' };
                                        }else{
                                            //attr.params.id_field = id_field;
                                            //attr.params.name_field = name_field;
                                            //attr.params.bd_field = id_field;
                                            //attr.params.origin = 'custom';
                                            var objTemp = attr.params;
                                            objTemp = Ext.util.JSON.decode( Ext.util.JSON.encode( objTemp ) );
                                            objTemp.id_field = id_field;
                                            objTemp.name_field = name_field;
                                            objTemp.bd_field = id_field;
                                            objTemp.origin = 'custom';
                                            
                                            var d = { id: id, id_field: id_field, name: name_field, params: objTemp, img: '/static/images/icons/icon_wand.gif' };
                                        }
                                        
                                        try{
                                            var r = new self.category_fields_store.recordType( d, id );
                                            self.category_fields_store.add( r ); 
                                        }catch(err){
                                            id += 1; 
                                            var r = new self.category_fields_store.recordType( d, id );
                                            self.category_fields_store.add( r )
                                        };
                                        
                                        self.category_fields_store.commitChanges();
                                        winCustomField.close();
                                    }
                                }
                            });
        
                                            
                            var txt_filters = new Ext.form.TextField({
                                fieldLabel: _('Filter'),
                                emptyText: 'role1, role2, ...',
                                hidden: true     
                            });
                            
                            var combo_system_fields = new Ext.form.ComboBox({
                                mode: 'local',
                                triggerAction: 'all',
                                forceSelection: true,
                                editable: false,
                                fieldLabel: _('Type'),
                                hiddenName: 'cmb_system_fields',
                                hidden: true,
                                store: attr.meta ? attr.meta : []
                            });
                            
                            combo_system_fields.on('select', function(cmb,row,index){
                                if (attr.data[combo_system_fields.getValue()].filter){
                                    if (attr.data[combo_system_fields.getValue()].filter === 'manual'){
                                        txt_filters.show();    
                                    }
                                }else{
                                    txt_filters.hide();
                                };
                                if (attr.data[combo_system_fields.getValue()].single_mode != undefined){
                                    var form = form_template_field.getForm();
                                    form.findField("valuesgroup").show();
                                    form_template_field.doLayout();
                                }else{
                                    var form = form_template_field.getForm();
                                    form.findField("valuesgroup").hide();
                                };
                            });                         
                            
                            if (attr.id_field == 'listbox' || attr.id_field == 'form' ) combo_system_fields.show();
                            
                            var form_template_field = new Ext.FormPanel({
                                url: '/topicadmin/create_clone',
                                frame: true,
                                buttons: [btn_grabar_custom_field, btn_cerrar_custom_field],
                                defaults:{anchor:'100%'},
                                items   : [
                                            { fieldLabel: _('Field'), name: 'name_field', xtype: 'textfield', allowBlank:false },
                                            combo_system_fields,
                                            {
                                                xtype: 'radiogroup',
                                                id: 'valuesgroup',
                                                fieldLabel: _('Values'),
                                                hidden: true,
                                                defaults: {xtype: "radio",name: "type"},
                                                items: [
                                                    {boxLabel: _('Single'), inputValue: 'single', checked: true},
                                                    {boxLabel: _('Multiple'), inputValue: 'multiple'},
                                                    {boxLabel: _('Grid'), inputValue: 'grid'}
                                                ]
                                            },                                          
                                            txt_filters
                                        ]
                            });
        
                            var winCustomField = new Baseliner.Window({
                                modal: true,
                                width: 500,
                                title: _('Custom field'),
                                items: [form_template_field]
                            });
                            
                            winCustomField.show();
                            
                        }else{
                            insert_node (n);
                            n.destroy();
                        }
                    }else{
                        if(attr.id != 'T'){
                            if (n.hasChildNodes()){
                                n.eachChild(function(node) {
                                    insert_node (node);
                                });                         
                                n.removeAll();
                            }
                        }
                    }
                    return (true); 
                }
            });
        });
        
        category_fields_grid.on('viewready', function() {
            var ddrow = new Baseliner.DropTarget(category_fields_grid.getView().mainBody, {  
                comp: category_fields_grid,
                ddGroup : 'mygrid-dd' + id_drag_drop,  
                notifyDrop : function(dd, e, data){  
                    var sm = category_fields_grid.getSelectionModel();  
                    var rows = sm.getSelections();  
                    var cindex = dd.getDragData(e).rowIndex;  
                    if (sm.hasSelection()) {  
                        for (i = 0; i < rows.length; i++) {  
                            self.category_fields_store.remove(self.category_fields_store.getById(rows[i].id));  
                            self.category_fields_store.insert(cindex,rows[i]);  
                        }  
                        sm.selectRecords(rows);
                    }
                }
            });
        });
        
        category_fields_grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var sel = grid.getStore().getAt(rowIndex);
            var field_meta = sel.data.meta;
            var tree = new Baseliner.DataEditor({
                title: _('Metadata'),
                data: sel.data.params,
                metadata: field_meta
            });
        
            var props = [];
            var config_form;
            try{
                if( field_meta.config_form ) {
                    config_form = new Baseliner.FormPanel({ 
                        title:_('Custom'), 
                        layout: 'fit',
                        frame: false, border: false,
                        items:[ { xtype:'textarea', height: 80, fieldLabel: 'XXX' } ] 
                    });
                    props.push( config_form ); 
                    // TODO call config_form url
                }
            }catch(err){};
            props.push( tree );

            var field_config = new Ext.TabPanel({ 
                activeTab: 0,
                plugins: [ new Ext.ux.panel.DraggableTabs()], 
                items: props
            });
        
            var w = new Baseliner.Window({ layout:'fit',width:600, height:450, items: tree });
            w.show();
            tree.on('destroy', function(){
               sel.data.params = tree.data;
               w.close();
            });
        }); 
        
        self.items = [ {
                xtype: 'panel',
                layout: 'column',
                items:  [ { columnWidth: .49, items:  tree_fields },
                          { columnWidth: .02, items: blank_image },
                          { columnWidth: .49, items: category_fields_grid },
                          { xtype: 'hidden', name: 'id_category', value: self.id_category }
                        ],
                bbar: [ '->', btn_save_config ]
            }
        ];
        Baseliner.FieldEditor.superclass.initComponent.call(this);
    }
});

