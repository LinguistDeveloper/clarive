Baseliner.Catalog = Ext.extend( Ext.Panel, {
    layout :'card',
    activeItem : 0, // make sure the active item is set on the container config!
    current : 0,
    first : 1,
    constructor : function(config){
        Baseliner.Catalog.superclass.constructor.call(this, Ext.apply({
            defaults: { border: false }
        }, config ));
    },
    initComponent: function(){
        var self = this;
        self.stash = {};
        self.loading_panel = Baseliner.loading_panel();
        self.build_bls();    
        self.progress = 0;    
        self.items = [ self.loading_panel, self.build_tree() ];
        self.apply_events();
        self.last = self.last==undefined ? self.items.length-1 : self.last;
        self.addEvents(['done']);

        self.bstart = new Ext.Button({
            text: _('Start Now'),
            icon: '/static/images/icons/catalog-cart.png',
            hidden: true,
            handler: function(){ self.start() }
        });
        self.bnext = new Ext.Button({
            tooltip: _('Next'),
            icon: IC('right-arrow'),
            hidden: true,
            handler: function(){ self.navigate(1,true) }
        });
        self.bback = new Ext.Button({
            tooltip: _('Back'),
            icon: IC('left-arrow'),
            handler: function(){ self.navigate(-1,true) },
            hidden: true,
            //disabled: true
        });
        self.bsave = new Ext.Button({
            text: _('Save'),
            icon: IC('save_disk.png'),
            hidden: true,
            handler: function(){ 
                self.catalog_save();
            }
        });          

        self.tbar = [ '->', self.bback, self.bstart, self.bnext, self.bsave ];

        if (self.perm_bdone) {
            self.bdone = new Ext.Button({
                text: _('Request Now'),
                icon: IC('catalog-done.png'),
                hidden: true,
                handler: function(){ 
                    self.catalog_request();
                }
            }); 

            self.tbar.push(self.bdone);           
        }
        Baseliner.Catalog.superclass.initComponent.call(this);
    },
    apply_events : function(){
        var self = this;
        self.check_sm.on('beforerowselect', function( sm, index, keepExisting, record){
            if (record.data.type == 'project' || record.data.type == 'subproject' || record.data.type == 'folder' || record.data.type == 'draft' || record.data.type == '_history_folder' || record.data.type == 'history' ){
                return false;
            }
            if (record.data.type == 'service'){
                var rows = self.store.query('type', 'service');
                if (self.checkHasServiceSelected()){
                    return false;  
                } 
            }
            
        });

        self.treegrid.on('rowdblclick', function( grid, index ){
            var r = grid.getStore().getAt(index);
            if (r.data.type == 'draft'){
                self.call_wizard( r.data.mid, r.data.attributes.baseline );
            }else if (r.data.type == 'history'){
                Baseliner.show_topic_from_row( r.data.attributes, self.treegrid );    
            }
            
        });

        self.treegrid.on('rowclick', function( grid, index ){
            //alert('core');
            var node = self.store.getAt( index );

            // if (node.data.type == 'project' || node.data.type == 'subproject' || node.data.type == 'folder' || node.data.type == 'draft' || node.data.type == '_history_folder' || node.data.type == 'history' ){
            //     return false;
            // }                

            if( !self.check_sm.isSelected(index) ){
                var nodes = self.getChildrenNodes( node );
                self.check_sm.deselectRange(nodes[0], nodes[nodes.length - 1]); 
                var nodes_selected = self.check_sm.getSelections();
                var service_selected;
                has_only_service = true;
                for(var i=0, len = nodes_selected.length; i < len; i++){
                    if(nodes_selected[i].data.type != 'service'){
                        has_only_service = false;
                        if (service_selected) break;
                    }else{
                        service_selected = nodes_selected[i];    
                    }
                }
                if (has_only_service){
                    var node_selected = self.check_sm.getSelected();
                    if (node_selected && node_selected.data.attributes.split_task && node_selected.data.attributes.split_task != '0') self.check_sm.clearSelections();                        
                }else{

                    var nodes_prerequisite = [];

                    if ( node.data && node.data.attributes && node.data.attributes.prerequisite){
                        Ext.each(node.data.attributes.prerequisite, function(prerequisite){
                                var rows = self.store.query('mid', prerequisite);
                                Ext.each(rows.items, function(row_node){
                                    self.check_sm.deselectRow(self.store.indexOfId(row_node.id));
                                });
                        });
                    }else{
                        var task_project = {
                            mid : node.data.project.mid,
                            type : node.data.project.type
                        };

//VER SI ESTA ENTRE LOS PREREQUESITES DE LOS NODES SELECTED;

                        var task_mid = [];
                        task_mid.push(node.data.mid);
                        Baseliner.ajax_json('/catalog/check_task_requested', { task_mid: task_mid, task_project: task_project, bl: self.stash.bl }, function(res){
                            if(res.success){
                                if (res.task_requested.length == 0){
                                    var nodes_selected = self.check_sm.getSelections();
                                    var nodes_index = [];
                                    Ext.each( nodes_selected, function(node_selected){
                                        var row_index = self.store.indexOfId(node_selected.id);
                                        nodes_index.push(row_index); 
                                    });

                                    nodes_index.push(self.store.indexOfId(node.id));
                                    self.check_sm.selectRows(nodes_index);                                     
                                }
                            }else{
                                Baseliner.message( _('Catalog'), _('Error checking task') );
                            }
                        });   
                    }


                    if( typeof service_selected === 'object' ){
                        var rows = self.store.query('id_service', service_selected.data.mid);
                        var has_task_selected = false;
                        Ext.each( rows.keys, function( id ){
                            if(self.check_sm.isIdSelected(id)){
                                has_task_selected = true;
                                return false;
                            };
                        });
                        if (!has_task_selected) self.check_sm.deselectRow(self.store.indexOfId(service_selected.id));
                    }                        
                }

            }else{
                var nodes_selected = self.check_sm.getSelections();
                var hasServiceSelected = false;

                var nodes_prerequisite = self.getPrerequesitesNodes( node );

                if (node.data.type == 'service' || node.data.type == 'task_group') {
                    var all_nodes = self.getChildrenNodes( node );
                    var nodes = [];
                    for (var i = 0; i < all_nodes.length; i++){
                        var row = self.store.getAt(all_nodes[i]);
                        if (row.data.attributes.optional && row.data.attributes.optional == '1') continue;
                        nodes.push(all_nodes[i]);
                    }
                }else{
                    var nodes = self.getParentNodes(node);
                    var last_node = nodes[nodes.length-1];

                    if (typeof last_node === 'object' ){
                        if(!self.check_sm.isIdSelected(last_node.id)){
                            hasServiceSelected = true;
                            nodes = [];
                        }
                    };
                } 

                var nodes_index = [];
                Ext.each( nodes_selected, function(node_selected){
                    var row_index = self.store.indexOfId(node_selected.id);
                    if (hasServiceSelected && index == row_index){
                        nodes_prerequisite = [];
                    }else{
                        nodes_index.push(row_index); 
                    }
                });
                nodes = nodes.concat(nodes_index);
                nodes = nodes.concat(nodes_prerequisite);

                var task_project = {};
                var mid_nodes = [];
                self.mids_nodes_index = {};
                for (var i = 0; i < nodes.length; i++){
                    var row = self.store.getAt(nodes[i]);
                    self.mids_nodes_index[row.data.mid] = nodes[i];
                    mid_nodes.push(row.data.mid);
                    task_project.mid = row.data.project.mid;
                    task_project.type = row.data.project.type;
                }

//VER SI ESTA ENTRE LOS PREREQUESITES DE LOS NODES SELECTED;

                var task_mid = mid_nodes;
                Baseliner.ajax_json('/catalog/check_task_requested', { task_mid: task_mid, task_project: task_project, bl: self.stash.bl }, function(res){
                    if(res.success){
                        for( var i = 0; i< res.task_requested.length; i++){
                            //console.log(res.task_requested[i]);
                            var index = self.mids_nodes_index[res.task_requested[i]];
                            var row = self.store.getAt(index);
                            row.data.bl_include = false;
                            if (row.data.attributes.repeatable){
                                row.data.bl_include = true;
                            } 
                            var row_view = self.treegrid.getView().getRow(index);
                            var row_innerHTML = row_view.innerHTML;
                            row_innerHTML = row_innerHTML.replace( "(" + _('Repeated') + ")", "" );
                            row_view.innerHTML = row_innerHTML.replace( row.data.name, row.data.name + ' <span style="color:#f30"><i>(' + _('Repeated') + ')</i></span>');
                        }
                    }else{
                        Baseliner.message( _('Catalog'), _('Error checking task') );
                    }
                });  
                self.check_sm.selectRows(nodes);
            }
        });
    },
    button_setup : function(){
        var self = this;
        self.stash.is_first_form == 1 ? self.bback.disable() : self.bback.enable();
        if (self.perm_bdone){
            self.stash.show_request == 1 ? self.bdone.show() : self.bdone.hide();      
        }
        if (self.stash.service_selected.forms.length == 1){
            self.bback.disable();
        }else{
            self.bnext.enable();
        }
    },
    do_wizard_panel: function(){
        var self = this;

        var fd = self.form_data;

        self.getLayout().setActiveItem( self.current ); 
        var wizard = self.getLayout().activeItem;
        wizard.removeAll();

        var service_selected = self.stash.service_selected;
        var service_selected_name;
        var service_selected_description;

        var html = [];

        if (service_selected.type == '_service'){
            service_selected_name = self.stash.current_form.task && self.stash.current_form.task.name ? self.stash.current_form.task.name : '';    
            service_selected_description = '';
            html.push('<div id="boot"><h3>' + service_selected_name + '</h3><p>' + service_selected_description + '</p><hr /></div>');

        }else{
            service_selected_name = service_selected.name;
            service_selected_description = service_selected.description;  

            html.push('<div id="boot"><h2>' + service_selected_name + '</h2><p>' + service_selected_description + '</p><hr /></div>');
            if(fd.form.task){
                var name = fd.form.task.name ? fd.form.task.name : '';
                var description = fd.form.task.description ? fd.form.task.description : '';
                if ( name != ''){
                    html.push('<div id="boot"><h3>' + name + '</h3><p>' + description + '</p><hr /></div>');    
                }
            }
        }

        var title = new Ext.Panel({ border: false, frame: false, columnWidth: 1, html: html.join('') });

        wizard.add(title);

        self.wizards.push(wizard);

        Ext.each( fd.form.fieldlets, function(fieldlet){
            var topic_meta = fieldlet.params;
            var key_data = fd.form.project.mid + '_' + fieldlet.params.id_field;
            var pattern = key_data;
            var from_data = fieldlet.params.from ? '_' + fieldlet.params.from : '';
            key_data += from_data; 

            var topic_data = {};
            var new_values;

            //console.log(self.stash.wizard_data);

            if (self.stash.wizard_data[ key_data ]){
                topic_data[fieldlet.params.id_field + from_data] = self.stash.wizard_data[ key_data ];
            } 
            if (topic_meta.scope == 'project') {
                topic_data[fieldlet.params.id_field +'_options'] = self.stash.variables[ fieldlet.params.id_field ];

                for (prop in self.stash.wizard_data) {
                    if(!prop.search(pattern)){
                        if (prop != key_data){
                            new_values = self.stash.wizard_data[ prop ];
                        }
                    }
                }         

                function onlyUnique(value, index, self) { 
                    return self.indexOf(value) === index;
                }

                var all_options = topic_data[fieldlet.params.id_field +'_options'].concat(new_values);
                var unique = all_options.filter( onlyUnique ); 
                topic_data[fieldlet.params.id_field +'_options'] = unique;
                
            } // else Global TODO??

            topic_data['variables_output'] = fd.form.task && fd.form.task.attributes && fd.form.task.attributes.variables_output ? fd.form.task.attributes.variables_output : {};

            Baseliner.ajax_json(fieldlet.params.js, { topic_meta: topic_meta, topic_data: topic_data }, function(res){
                var wizard = self.getLayout().activeItem;

                var colspan =  topic_meta.colspan || wizard.form_columns;
                var cw = topic_meta.colWidth || ( colspan / wizard.form_columns );
                var p_style = {};
                if( Ext.isIE ) p_style['margin-top'] = '8px';
                p_style['padding-right'] = '10px';
                var p_opts = { layout:'form', style: p_style, border: false, columnWidth: cw };
                var p = new Ext.Container( p_opts );
                p.add( res );
                wizard.add(p);
                wizard.doLayout();  
            });   

        });

        wizard.el.dom.style.visibility = 'visible';
        return fd;
    },
    save_panel_data: function(){
        var self = this;
        if( !self.stash ) self.stash = {};
        
        // check if its not the "loading" panel:
        if( self.items.length > 2 ) {
            var curr_form_data = self.getLayout().activeItem;

            if(typeof curr_form_data.getValues === 'function'){
                var lpd = curr_form_data.getValues();
                var lpd_unique = {};

                for (var key in lpd) {
                    var tmp_value = lpd[key];
                    lpd_unique[self.id_project + '_' + key] = tmp_value;
                }

                if( !self.stash.wizard_data ) self.stash.wizard_data = {};
                self.stash.wizard_data = Ext.apply( self.stash.wizard_data, lpd_unique );
            }
        }
    },
    catalog_save: function(){
        var self = this;
        self.save_panel_data();

        self.loading_start();

        Baseliner.ajax_json('/catalog/save', { id_rule: self.id_rule, stash: self.stash }, function(res){
            self.stash = res.stash;
            if(res.success){
                Baseliner.message( _('Catalog'), _('Draft saved'));
            }else{
                Baseliner.message( _('Catalog'), _('Error saving draft') );
            }
            self.getLayout().setActiveItem( self.last_item ); 
            self.current = self.last_item;
        });            
    },
    catalog_request: function(){
        var self = this;
        var id_rule = self.id_rule ? self.id_rule : self.stash.id_rule;

        self.save_panel_data();


        var curr_form_data = self.getLayout().activeItem;
        //var form_data = curr_form_data.getForm();

        //if (form_data.isValid() ) {
        if (curr_form_data.is_valid_wizard()) {            
            self.loading_start();
            Baseliner.ajax_json('/catalog/request', { id_rule: id_rule, stash: self.stash }, function(res){
                self.stash = res.stash;
                if(res.success){
                    Baseliner.message( _('Catalog'), _('Request saved'));
                }else{
                    Baseliner.message( _('Catalog'), _('Error saving request') );
                }

                Ext.each( self.wizards, function(wizard){
                    self.remove(wizard);
                });

                self.done();
            });            
        }else{
            Ext.MessageBox.show({
               title: _('Catalog'),
               msg: _('Please, fill the required fields'),
               buttons: Ext.MessageBox.OK,
               //fn: showResult,
               icon: Ext.MessageBox.INFO
           });
        } 
            
    },
    navigate : function(direction, anim){
        var self = this;

        if (self.id_project) self.save_panel_data();

        var curr_form_data = self.getLayout().activeItem;
        var obj_form_data = curr_form_data.getForm();


        // if(typeof curr_form_data.getValues === 'function'){
        //     var lpd = curr_form_data.getValues();
        //     //console.log(lpd);
        // }

        if (curr_form_data.is_valid_wizard()) {
            var form_data = self.form_data;

            // console.log(self.form_data);

            // var fieldlets = form_data.form.fieldlets;
            // for ( i=0; i < fieldlets.length; i++){
            //     console.log( fieldlets[i].id_field);
            //     console.log(obj_form_data.findField(fieldlets[i].id_field));
            // }



            self.id_rule = form_data.id_rule ? form_data.id_rule : self.stash.id_rule;
            self.id_project = form_data.form.project.mid;            

            if( direction < 0 ) {
                self.stash.catalog_step = 'PREV';
            }else{
                self.stash.catalog_step = 'NEXT';    
            }
            
            var dir2 = direction < 0 ? 'r' : 'l';
            self.stash.wizard_direction = direction < 0 ? 'left' : 'right';
                
            self.progress = 0;
            self.timer = setInterval(self.updateProgress(self.progress) , 2000);
            Ext.MessageBox.show({
                title : _('Catalog'),
                msg : _('Processing data...'),
                progressText : _('Loading...'),
                width : 300,
                progress : true,
                closable : false
            });

            Baseliner.ajax_json('/catalog/next_panel', { id_rule: self.id_rule, stash: self.stash }, function(res){
                try{
                    self.stash = res.stash;
                    self.button_setup();
                    self.progress = 100;  
                    clearInterval(self.timer);
                    Ext.MessageBox.updateProgress(100, _('All data loaded!'));
                    Ext.MessageBox.hide.defer(100, Ext.MessageBox);

                    if (self.stash.is_last_form){
                        Baseliner.message( _('Catalog'), _('There are no more forms'));
                    }
                    else{
                        self.form_data = [];
                        self.form_data = { form: self.stash.current_form, id_rule: self.id_rule };
                        if( anim ) {
                            var first = self.getLayout().activeItem;
                            first.getEl().slideOut(dir2, {
                                callback: function() {
                                    self.do_wizard_panel();
                                }
                            });
                        } else {
                            self.do_wizard_panel();
                        }  
                    }
                      
                } catch(e) {
                    clearInterval(self.timer);
                    Ext.MessageBox.updateProgress(100, _('All data loaded!'));
                    Ext.MessageBox.hide();
                }
            });
        }else{
            Ext.MessageBox.show({
               title: _('Catalog'),
               msg: _('Please, fill the required fields'),
               buttons: Ext.MessageBox.OK,
               //fn: showResult,
               icon: Ext.MessageBox.INFO
           });
        }

    },
    updateProgress: function (){
        var self = this;
        return function(){
            if (self.progress < 100) self.progress += 25;
            Ext.MessageBox.updateProgress(self.progress/100, self.progress + _('% completed'));
        };        
    },
    activate : function(ix){
        var self = this;
        self.current = ix;
        self.getLayout().setActiveItem( self.current ); 
    },
    loading_start : function(){
        this.last_item = this.current;
        this.activate(0);
    },
    loading_end : function(){
        this.last_item = this.current;
        this.activate(this.first);
    },
    can_start : function(){
        var self = this;
        self.selections = [];
        Ext.each( self.check_sm.getSelections(), function(sel){
            if( sel.data.type == 'service' || sel.data.type == 'task_group' || sel.data.type == 'task' ) self.selections.push(sel.data);
        });
        if( self.selections.length > 0 ) self.bstart.show(); else self.bstart.hide();
    },
    done : function(){
        var self = this;
        self.fireEvent('done', self) ;
        self.loading_end();
        if (self.perm_bdone) self.bdone.hide();
        self.bsave.hide();
        self.bnext.hide();
        self.bback.hide();
        self.check_sm.clearSelections();
        self.show_bls();
        self.activate(1);
       
    },
    getProject : function (id_parent){
        var self = this;
        var row = self.store.query('_id', id_parent);
        var node = row.items[0];
        if (node.data.type != 'project'){
            node = self.getProject(node.data._parent); 
        }
        return node;
    },
    getFolder : function (id_parent){
        var self = this;
        var row = self.store.query('_id', id_parent);
        var node = row.items[0];
        if (node.data.type != 'folder' && node.data.type != 'project'){
            node = self.getFolder(node.data._parent); 
        }
        return node;
    },
    start : function(){
        var self = this;
        var sels = self.check_sm.getSelections().map(function(r){ return r.data });
        var bl_call_wizard = true;

        self.hide_bls();

        self.loading_start();

        self.form_data = [];
        self.wizards = [];
        self.stash.service_selected = undefined;
        self.stash.filters = {};
        var tasks_selected = [];

        for (var i=0, len = sels.length; i < len; i++){
            if (sels[i].type == 'service') {
                var project = self.getProject(sels[i]._parent);
                sels[i].project = {
                    name: project.data.name,
                    mid: project.data.mid,
                };
                sels[i].tasks = [];
                self.stash.service_selected = sels[i];
                var folder = self.getFolder(sels[i]._parent);
                self.stash.filters[folder.data.id_task] = 1;
                self.stash.filters[sels[i].id_task] = 1;
            }else{
                if (sels[i].type == 'task_group') continue;
                var row = self.store.query('_id', sels[i]._parent);
                var node = row.items[0];
                var origin;
                if (node.data.type != 'folder'){
                    origin = node.data.name;
                }else{
                    origin = '';
                }    
                sels[i].attributes.origin = origin;

                if(sels[i].bl_include || sels[i].bl_include === undefined){
                    tasks_selected.push(sels[i]);    
                }

                var folder = self.getFolder(sels[i]._parent);
                self.stash.filters[sels[i].id_task] = 1;
                self.stash.filters[folder.data.id_task] = 1;
            }
        }

        if ( !self.stash.service_selected ){
            if(tasks_selected.length > 0){
                var project = self.getProject(tasks_selected[0]._parent);
                self.stash.service_selected = {
                    project: {
                        name: project.data.name,
                        mid: project.data.mid,
                    },
                    tasks: [],
                    type: '_service'
                }                 
            }else{
                bl_call_wizard = false;
            }
        }

        if (bl_call_wizard){
            self.stash.service_selected.tasks = tasks_selected;
            self.stash.selection_catalog = self.stash.service_selected;
            self.call_wizard(undefined, self.bl);
        }
        else{
            Ext.MessageBox.show({
               title: _('Catalog'),
               msg: _('There are not tasks to do'),
               buttons: Ext.MessageBox.OK,
               //fn: showResult,
               icon: Ext.MessageBox.INFO
           });

           self.loading_end();            
        }
    },
    clone_request: function(mid){
        var self = this;
        var win;

        var data_bl = [];
        Ext.each(self.btns_bl, function(btn_bl){
            data_bl.push([btn_bl.bl_id, btn_bl.bl_id]);
        });             

        var store_bl = new Ext.data.ArrayStore({
            id: 0,
            fields: [
                'id',
                'name'
            ],
            data: data_bl
        });

        var cbx_bls = new Ext.ux.form.SuperBoxSelect({
            allowBlank: false,
            msgTarget: 'under',
            triggerAction: 'all',
            store: store_bl,
            mode: 'local',
            fieldLabel: _('BLs'),
            typeAhead: true,
            name: 'bls',
            displayField: 'name',
            hiddenName: 'bls',
            valueField: 'id'
        });


        var form_clone_request = new Ext.FormPanel({
            name: 'form_clone_request',
            frame: true,
            items   : [
                cbx_bls                
            ],
            buttons: [
                {
                    text: _('Cancel'),
                    type: 'submit',
                    handler: function() {
                        win.close();
                    }
                },
                {
                    text: _('Clone'),
                    type: 'submit',
                    handler: function() {

                        var form = form_clone_request.getForm();
                        if (form.isValid()) {

                            self.loading_start();
                            var tbar = self.getTopToolbar();
                            tbar.hide();

                            Baseliner.ajax_json('/catalog/clone_request',{ mid: mid, bls: cbx_bls.getValue() }, function(res){
                                if(res.success){
                                    var index_current_node = self.store.find('mid', mid);
                                    var current_node = self.store.getAt( index_current_node );

                                    var index_project = self.store.find('mid', current_node.data.project);
                                    var project_node = self.store.getAt( index_project );

                                    var clone_record = current_node.copy();

                                    for (i = 0; i < res.request.length; i++){
      
                                        var key = Ext.id();
                                        var node_record = new self.NodeRecord({
                                            _id: key,
                                            _is_leaf: res.request[i]._is_leaf,
                                            _parent: project_node.id,
                                            name: res.request[i].name,
                                            icon: res.request[i].icon,
                                            attributes: res.request[i].attributes,
                                            mid: res.request[i].mid,
                                            type: res.request[i].type
                                        }, key);
            
                                        self.store.insert(index_project + i + 1, node_record);                                  
                                    }
                                    Baseliner.message( _('Catalog'), _('Request cloned'));
                                }else{
                                    Baseliner.message( _('Catalog'), _('Error cloning request'));
                                }
                                self.getLayout().setActiveItem( self.last_item ); 
                                self.current = self.last_item;
                                tbar.show();
                            });
                            win.close();
                        }
                    }
                }
            ]
        });


        
        win = new Ext.Window({
            title: _('Copy request'),
            autoHeight: true,
            width: 730,
            closeAction: 'close',
            modal: true,
            constrain: true,
            items: form_clone_request
        });

        win.show();
    },
    call_wizard: function(mid, baseline){
        var self = this;
        self.hide_bls( baseline );
        self.loading_start();
        self.form_data = [];
        self.wizards = [];        

        Baseliner.ajax_json('/catalog/wizard_start',{ stash: self.stash, mid: mid || undefined }, function(res){  
            try{
                Ext.apply( self.stash, res.stash );

                var service_selected = self.stash.service_selected;
                var id_rule = service_selected.id_rule ;
                self.length_wizard = (service_selected.forms && service_selected.forms.length) ? service_selected.forms.length : 0;

                if(self.stash.current_form){
                    var fp = new Baseliner.FormPanel({ 
                        name: 'wizard',
                        layout:'column',
                        labelAlign: 'top',
                        autoScroll: true,
                        bodyStyle: { padding: '20px 20px 20px 20px' },
                        border: false,
                        form_columns: 12,
                    });

                    self.add( fp );
                    self.form_data = { form: self.stash.current_form, id_rule: id_rule };

                    self.bstart.hide();
                    self.bnext.show();
                    self.bback.show();
                    self.bback.disable(); 
                    self.bsave.show();
                    if (self.perm_bdone) self.bdone.hide();
                    self.button_setup();        

                    if (self.id_project) self.save_panel_data();
                    self.current = 2;

                    var form_data = self.form_data;
                    self.id_rule = form_data.id_rule ? form_data.id_rule : self.stash.id_rule;
                    self.id_project = form_data.form.project.mid;            
                    self.stash.wizard_direction = 'right';
                    self.do_wizard_panel();
                }else{
                    self.catalog_request();                
                }
            }
            catch(e){
                clearInterval(self.timer);
                Ext.MessageBox.updateProgress(100, _('All data loaded!'));
                Ext.MessageBox.hide();
            }
        });                
    },
    set_baseParams_bl : function(){
        var self = this;
        return self.bl;
    },
    build_tree : function(){
        var self = this;
        self.NodeRecord = Ext.data.Record.create([ 
            '_id', '_parent', '_is_leaf', 'id_rule','name','mid','description','tasks','type', 'project', 'bl', 'icon', 'id_task', 'attributes', 'forms', 'id_service'
        ]);

        self.store = new Ext.ux.maximgb.tg.AdjacencyListStore({  
           autoLoad : false,  
           url: '/catalog/generate',
           remoteSort: true,
           reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'totalCount', successProperty: 'success' }, self.NodeRecord )
        }); 

        self.store.on('beforeload', function(s,obj) {
            self.progress = 0;
            self.timer = setInterval(self.updateProgress() , 2000);
            Ext.MessageBox.show({
                title : _('Catalog'),
                msg : _('Processing data...'),
                progressText : _('Loading...'),
                width : 300,
                progress : true,
                closable : false
            });

            if( obj.params && obj.params.anode!= undefined ) {
                var row = self.store.getById( obj.params.anode );
                obj.params.mid = row.data.mid;
            }

            obj.params.bl = self.set_baseParams_bl();

        });

        self.store.on('load', function(obj){
            self.progress = 100;  
            clearInterval(self.timer);
            Ext.MessageBox.updateProgress(100, _('All data loaded!'));
            Ext.MessageBox.hide.defer(500, Ext.MessageBox);
            self.activate(1);
            //self.store.expandAll();
            var gen_stash = self.store.reader.jsonData.stash;
            Ext.apply( self.stash, gen_stash );
            // self.store.each(function(row){
            //     //if( /^(service|folder)$/.test(row.data.type) ) self.store.expandNode(row);
            //     //if( row.data.type == 'project' ) self.store.collapseNode(row);
            //     if( row.data.collapse == 'collapsed' ) self.store.collapseNode(row);
            // });
        });

        var search_field = new Baseliner.SearchField({
            store: self.store,
            params: {start: 0, limit: 100 },
            emptyText: _('<Enter your search string>')
        });

        var id_auto = Ext.id();
        self.check_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });

        self.check_sm.on('rowselect', function(){
            self.can_start();
        });

        self.check_sm.on('rowdeselect', function(){
            self.can_start();
        });

        var render_item = function(value,metadata,rec,rowIndex,colIndex,store) {
            var active = rec.data.active;
            var type = rec.data.type;
            icon = rec.data.icon || ( 
                type=='folder' ? IC('catalog-folder.png') 
                : IC('catalog-light.png') );

            var ret = '';
            ret += '<img  style="vertical-align:middle" src="' + icon + '" alt="edit" />';
            ret += '<span style="margin-left: 4px;"><b>' + value + '</span>';
            return ret;                
        };
        
        var render_data = function(value,metadata,rec,rowIndex,colIndex,store) {
            var arr = [];
            if(rec.data.type === 'draft'){
                var drafts = rec.data.tasks ? rec.data.tasks : [];
                drafts.unshift(rec.data.mid);
                arr.push( String.format('<img style="cursor:pointer;" src="/static/images/icons/copy-16.png" onclick="Baseliner.clone_request(\'{0}\', \'{1}\');" />', rec.data.mid, self.id ) );
                arr.push( String.format('<img style="cursor:pointer;" src="/static/images/icons/gear-16.png" onclick="Baseliner.call_wizard(\'{0}\', \'{1}\', \'{2}\');" />', rec.data.mid, rec.data.attributes.baseline, self.id ) );
                arr.push( String.format('<img style="cursor:pointer;" src="/static/images/icons/x-mark-4-16.png" onclick="Baseliner.delete_draft(\'{0}\', {1});" />', drafts.toString(), rowIndex) );
            }else if ( rec.data.type === 'history' ){
                arr.push( String.format('<img style="cursor:pointer;" src="/static/images/icons/copy-16.png" onclick="Baseliner.clone_request(\'{0}\', \'{1}\');" />', rec.data.mid, self.id ) );
            }
            return arr.join(' ');
        };    

        var render_ts = function(value,metadata,rec,rowIndex,colIndex,store) {

            if(rec.data.type === 'draft' || rec.data.type === 'history'){ 
                return Ext.util.Format.date(value.ts, 'd-m-Y G:i:s');
            }
        };            

        var render_bs = function(value,metadata,rec,rowIndex,colIndex,store) {

            if(rec.data.type === 'draft' || rec.data.type === 'history'){ 
                var baseline = value.baseline ? value.baseline : '';
                return baseline;
            }
        };  

        var render_status = function(value,metadata,rec,rowIndex,colIndex,store){

            if(rec.data.type === 'draft' || rec.data.type === 'history'){ 
                var ret = String.format(
                    '<span class="label" style="padding:2px 8px 4px 8px;background-color:{0}; font-size: 9px;;padding: 1px 1px 1px 1px; margin: 0px 4px -10px 0px;border-radius:0px">&nbsp;</span><b><span class="bali-topic-status" style="font-size: {1}px;">{2}</span></b>',
                    value.status_color, 8, value.status );
                return ret;
            }
        };        

        Baseliner.clone_request = function( mid, obj_id ){
            var obj = Ext.getCmp(obj_id);
            obj.clone_request( mid );
        }  

        Baseliner.call_wizard = function( mid, baseline, obj_id ){
            var obj = Ext.getCmp(obj_id);
            obj.call_wizard(mid, baseline);
        }   

        Baseliner.delete_draft = function( drafts, index ){
            var mids = drafts.split(',');
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete?'), 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ajaxEval( '/topic/update?action=delete',{ topic_mid: mids },
                        function(res) {
                            if ( res.success ) {
                                treegrid.getStore().removeAt(index);
                                Baseliner.message( _('Success'), res.msg );

                            } else {
                                Baseliner.error( _('Error'), res.msg );
                            }
                        }
                    );
                }
            } );                
        }
                
        var treegrid = new Ext.ux.maximgb.tg.GridPanel({
            hideHeaders: true,
            stripeRows: true,
            height: 100,
            sortable: false,
            store: self.store,
            sm: self.check_sm,
            tbar: [ 
                search_field
            ],
            viewConfig: {
                //headersDisabled: true,
                enableRowBody: true,
                scrollOffset: 2,
                forceFit: true,
                getRowClass: function(record, index, p, store){
                    var css='';
                    p.body='';
                    var title = record.data.description;
                    if( title && title.length > 0  ) {
                        p.body +='<div style="color: #333; font-weight: normal; padding: 0px 0px 10px 80px; ">';
                        //p.body += '<img style="vertical-align:middle" src="/static/images/icons/post.gif">';
                        p.body += '&nbsp;' + title + '</div>';
                        css += ' x-grid3-row-expanded '; 
                    }
                    //css += index % 2 > 0 ? ' level-row info-odd ' : ' level-row info-even ' ;
                    return css;
                }
            },
            master_column_id : id_auto,
            autoExpandColumn: id_auto,
            columns:[
                self.check_sm,
                { width: 16, hidden: true, dataIndex: 'icon' },
                { id: id_auto, header: _('Service'), width: 470, dataIndex: 'name', renderer: render_item },
                { header: _('Status'), dataIndex: 'attributes',  width: 50,  renderer: render_status  },
                { header: _('Baseline'), dataIndex: 'attributes',  width: 50,  renderer: render_bs  },
                { header: _('Timestamp'), dataIndex: 'attributes',  width: 50, type: 'date', renderer: render_ts  },
                { header: _('Actions'),  dataIndex: 'id', width: 50, renderer: render_data }
            ]
        });

        self.treegrid = treegrid;
        return treegrid;
    },
    getChildren: function(node){
        var self = this;
        var children = [];
        var rows = self.store.query('_parent', node.id);
        Ext.each( rows.items, function( item ){
            children.push(item);
        });
        
        return children; 
    },
    getChildrenNodes: function(node){
        var self = this;
        var nodes = [];
        //var node = self.store.getAt( index );
        var children = self.getChildren( node );

        for(var i = 0, len = children.length; i < len; i++) {
            nodes.push(self.store.indexOfId(children[i].id));
            nodes = nodes.concat( self.getChildrenNodes( children[i] ) );
        }
        return nodes;
    },
    getPrerequesitesNodes: function(node){
        var self = this;
        var nodes_prerequisite = [];

        if(node.data && node.data.attributes && node.data.attributes.prerequisite){
            var prerequisites = node.data.attributes.prerequisite;
            Ext.each(prerequisites, function(prerequisite){
                var node_prerequisite = self.store.query('mid', prerequisite);
                Ext.each(node_prerequisite.items, function(prerequisite){
                    if(prerequisite.data.id_service === node.data.id_service && prerequisite.data.project.mid === node.data.project.mid){
                        nodes_prerequisite.push(self.store.indexOfId(prerequisite.id));
                        nodes_prerequisite = nodes_prerequisite.concat( self.getPrerequesitesNodes(prerequisite));
                    }else{
                        if ( node.data.project.type === 'S'){
                            if (prerequisite.data.project.mid === node.data.project.parent_mid){
                                nodes_prerequisite.push(self.store.indexOfId(prerequisite.id));
                                nodes_prerequisite = nodes_prerequisite.concat( self.getPrerequesitesNodes(prerequisite));                                             
                            }
                        }
                    }
                });                            
            });
        }
        return nodes_prerequisite;        
    },
    getParentNodes: function(node){
        var self = this;
        var nodes = [];
        var row = self.store.query('_id', node.data._parent);
        var parent = row.items[0];
        if (parent.data.type == 'task'){
            nodes.push(self.store.indexOfId(parent.id));
            nodes = nodes.concat( self.getParentNodes(parent) ); 
        }else{
            if (parent.data.type == 'service'){
                if (self.checkHasServiceSelected()){
                    nodes.push(parent);
                }else{
                    nodes.push(self.store.indexOfId(parent.id));
                } 
            }
        }

        return nodes;        
    },
    checkHasServiceSelected: function(){
        var self = this;
        var rows = self.store.query('type', 'service');
        var has_service_selected = false;
        Ext.each(rows.keys, function(id){
            if(self.check_sm.isIdSelected(id)){
                has_service_selected = true;
                return false;
            };
        });

        return has_service_selected;        
    },
    build_bls : function(){
        var self = this;    
        // load baselines
        var bls = new Baseliner.store.Baseline(); 
        bls.load({
            callback: function(records){
                var tbar = self.getTopToolbar();
                if( self.force_bl ) {
                    records=[];
                    Ext.each( self.force_bl, function(fbl){
                        records.push({ id: fbl });
                    });
                }
                var def_bl = self.force_bl || '*';
                var k = 0;
                tbar.insert(k++, String.format('<b>{0}</b>:', _('Environment') ) );
                //records.push({ id: '%' });
                self.btns_bl = [];
                Ext.each(records, function(bl){
                    var name = bl.id == '*' ? 'General' : bl.id == '%' ? 'All' : bl.id; 
                    self.btns_bl.push(
                        new Ext.Toolbar.Button({
                            text: _(name),
                            enableToggle: true,
                            pressed: ( bl.id == def_bl ? true:false), 
                            width: '30',
                            bl_id: bl.id,
                            allowDepress: false,
                            toggleGroup: 'catalog-bls-'+self.id, 
                            toggleHandler: function(btn, pressed){
                                self.activate(0);
                                self.bl = btn.bl_id;
                                self.store.load( {params:{bl: btn.bl_id}} );
                                self.check_sm.clearSelections();
                            }                            
                        })
                    );
                    tbar.insert(k++,self.btns_bl[self.btns_bl.length-1]);                        
                });

                self.bl = '*';
                self.store.baseParams = Ext.apply({ pretty: true, level: 1 }, {bl: self.bl});
                self.store.load( {params:{bl: '*'}} );

                tbar.doLayout();
                self.doLayout();
            }
        });
    },
    hide_bls: function(bl){
        var self = this; 
        if(bl){
            Ext.each(self.btns_bl, function(btn_bl){
                if(btn_bl.text != bl){
                    btn_bl.hide();
                }else{
                    btn_bl.enableToggle = false;
                } 
            }); 
        }else{
            Ext.each(self.btns_bl, function(btn_bl){
                if(!btn_bl.pressed) btn_bl.hide();
            }); 
        }
    },
    show_bls: function(){
        var self = this; 
        Ext.each(self.btns_bl, function(btn_bl){
            btn_bl.enableToggle = true;
            btn_bl.show();
        });             
    }
});
