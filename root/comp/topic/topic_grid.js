<%perl>
    use Baseliner::Utils;
    my $id = _nowstamp;
</%perl>

(function(params){
    var ps_maxi = 25; //page_size for !mini mode
    var ps_mini = 50; //page_size for mini mode
    var ps = ps_maxi; // current page_size
    var filter_current;
    var stop_filters = false;
    var typeApplication = '<% $c->stash->{typeApplication} %>';
    var parse_typeApplication = (typeApplication != '') ? '/' + typeApplication : '';
    var query_id = '<% $c->stash->{query_id} %>';
    var id_project = '<% $c->stash->{id_project} %>';
    var id_report = params.id_report;
    var report_rows = params.report_rows;
    var report_name = params.report_name;
	var fields = params.fields;
	 
	//if(params.data_report){
	//	report_rows = params.data_report.report_rows;
	//	report_name = params.data_report.report_name;
	//	fields = params.data_report.fields;
	//}
	
    var mini_mode = false;
    if( report_rows ) {
        ps_maxi=report_rows;
        ps_mini=report_rows;
        ps= parseInt(report_rows);
        mini_mode = params.mini_mode==undefined ? true : params.mini_mode;
    }
   
    var state_id =id_report ? 'topic-grid-'+id_report : 'topic-grid';
    //console.log( params );
    
    var base_params = { start: 0, limit: ps, typeApplication: typeApplication, 
        from_mid: params.from_mid,
        to_mid: params.to_mid,
        id_project: id_project ? id_project : undefined, 
        topic_list: params.topic_list ? params.topic_list : undefined 
    };  // for store_topics

    // this grid may be limited for a given category category id 
    var category_id = '<% $c->stash->{category_id} %>';
    if( category_id ) {
        params.id_category = category_id;
        base_params.categories = category_id;
    }
    var status_id = [];
    status_id = params.status_id ? params.status_id.split(',') : '<% $c->stash->{status_id} %>' ? '<% $c->stash->{status_id} %>' : undefined;
    base_params.statuses = status_id;
    
    if( id_report ) {
        base_params.id_report = id_report;
    }
    var store_config = {
        baseParams: base_params,
        remoteSort: false,
        listeners: {
            'beforeload': function( obj, opt ) {
                if( opt !== undefined && opt.params !== undefined )
                    filter_current = Baseliner.merge( filter_current, opt.params );
            }
        }
    };
    if( fields ) {
        store_config.add_fields = fields.ids.map(function(r){ return { name: r } });
		//console.dir(fields);
        //alert( fields.ids );
    }

    // Create store instances
    var store_category = new Baseliner.Topic.StoreCategory();
    //var store_label = new Baseliner.Topic.StoreLabel();
    var store_topics = new Baseliner.Topic.StoreList(store_config);
   
    var loading;
    store_topics.on('beforeload',function(){
        //loading = new Ext.LoadMask(panel.el, {msg:"Please wait..."});
        //loading = Ext.Msg.wait(_('Loading'), _('Loading'), { modal: false } );
        /*
        loading = Ext.Msg.show({
                title : _('Loading'),
                msg : _('Loading'),
                buttons: false,
                closable:false,
                wait: true,
                modal: false,
                minWidth: Ext.Msg.minProgressWidth,
                waitConfig: {}
            });
            */
    });
    store_topics.on('load',function(){
        if( loading ) loading.hide();
    });
    
    var init_buttons = function(action) {
        btn_edit[ action ]();
        // btn_delete[ action ]();
    }
    
    var button_no_filter = new Ext.Button({
        icon:'/static/images/icons/clear-all.png',
        tooltip: _('Clear filters'),
        hidden: false,
        cls: 'x-btn-icon',
        disabled: false,
        handler: function(){
            selNodes = tree_filters.getChecked();
            stop_filters = true;  // avoid constant firing
            Ext.each(selNodes, function(node){
                if(node.attributes.checked3){
                    node.attributes.checked3 = -1;
                    node.getUI().toggleCheck(node.attributes.checked3);
                }
                else{
                    node.getUI().toggleCheck(true);
                }
            });
            stop_filters = false;
            loadfilters();
        }
    });
    
    //var button_create_view = new Ext.Button({
    //    icon:'/static/images/icons/add.gif',
    //    tooltip: _('Create view'),
    //    cls: 'x-btn-icon',
    //    disabled: false,
    //    handler: function(){
    //        add_view();
    //    }
    //});
    
    var button_create_view = new Baseliner.Grid.Buttons.Add({
        text:'',
        tooltip: _('Create view'),
        disabled: false,        
        handler: function() {
            add_view()
        }
    });     
    
    var button_delete_view = new Baseliner.Grid.Buttons.Delete({
        text: _(''),
        tooltip: _('Delete view'),
        cls: 'x-btn-icon',
        disabled: true,
        handler: function() {
            Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the views selected?'), 
                function(btn){ 
                    if(btn=='yes') {
                        var views_delete = new Array();
                        selNodes = tree_filters.getChecked();
                        Ext.each(selNodes, function(node){
                            var type = node.parentNode.attributes.id;
                            if(type !== 'V'){
                                return false;
                            }else{
                                if(!eval('node.attributes.default')){  //se pone eval, al parecer hay conflicto con I.E, palabra reservada default
                                    views_delete.push(node.attributes.idfilter);
                                    node.remove();
                                }
                            }
                        });
                        
                        Baseliner.ajaxEval( '/topic/view_filter?action=delete',{ ids_view: views_delete },
                            function(response) {
                                if ( response.success ) {
                                    Baseliner.message( _('Success'), response.msg );
                                    tree_filters.getLoader().load(tree_root);
                                    loadfilters();
                                    button_delete_view.disable();
                                } else {
                                    Baseliner.message( _('ERROR'), response.msg );
                                }
                            }
                        );
                    }
                }
            );
        }
    }); 
    
    
    var add_view = function() {
        var win;
        
        var title = 'Create view';
        
        var form_view = new Ext.FormPanel({
            frame: true,
            url: '/topic/view_filter',
            buttons: [
                {
                    text: _('Accept'),
                    type: 'submit',
                    handler: function() {
                        var form = form_view.getForm();
                        if (form.isValid()) {
                            form.submit({
                                params: {action: 'add', filter: Ext.util.JSON.encode( filter_current )},
                                success: function(f,a){
                                    Baseliner.message(_('Success'), a.result.msg );
                                    var parent_node = tree_filters.getNodeById('V');
                                    var ff;
                                    ff = form_view.getForm();
                                    var name = ff.findField("name").getValue();
                                    parent_node.appendChild({id:a.result.data.id, idfilter: a.result.data.idfilter, text:name, filter:  Ext.util.JSON.encode( filter_current ), 'default': false, cls: 'forum', iconCls: 'icon-no', checked: false, leaf: true});
                                    win.close();
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
                },
                {
                text: _('Close'),
                handler: function(){ 
                        win.close();
                    }
                }
            ],
            defaults: { anchor: '100%' },
            items: [
                {
                    xtype:'textfield',
                    fieldLabel: _('Name view'),
                    name: 'name',
                    //width: '100%',
                    allowBlank: false
                }
            ]
        });
        
        win = new Ext.Window({
            title: _(title),
            width: 550,
            autoHeight: true,
            items: form_view
        });
        win.show();     
    };
    
    var btn_add = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            store_category.load({params:{action: 'create'}});
            add_topic();
        }       
    });
    
    var add_topic = function() {
        var win;
        
        var render_category = function(value,metadata,rec,rowIndex,colIndex,store){
			
            var color = rec.data.color;
            var ret = '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background: '+ color + '">' + value + '</span></div>';
            return ret;
        };
        
        var topic_category_grid = new Ext.grid.GridPanel({
            store: store_category,
            height: 200,
            hideHeaders: true,
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            },
            columns: [
              { header: _('Name'), width: 200, dataIndex: 'name', renderer: render_category },
              { header: _('Description'), width: 450, dataIndex: 'description' }
        
            ]
        });
        
        topic_category_grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            var title = _(r.get( 'name' ));
            Baseliner.add_tabcomp('/topic/view?swEdit=1', title , { 
                title: title, new_category_id: r.get( 'id' ), 
                new_category_name: r.get( 'name' ), _parent_grid: grid_topics.id } );
            win.close();
        });     
        
        var cat_title = _('Select a category');
        
        var form_topic = new Ext.FormPanel({
            frame: true,
            items: [
                topic_category_grid
            ]
        });

        win = new Ext.Window({
            title: cat_title,
            width: 550,
            autoHeight: true,
            closeAction: 'close',
            modal: true,
            items: form_topic
        });
        win.show();     
    };
    
    
    var make_title = function(){
        var title = [];
        if( report_name ) {
            return report_name; 
        }
        var selNodes = tree_filters.getChecked();
        Ext.each(selNodes, function(node){
            //var type = node.parentNode.attributes.id;
            title.push(node.text);
        }); 
        return title.length > 0 ? title.join(', ') : _('(no filter)');
    };

    var form_report = new Ext.form.FormPanel({
        url: '/topic/report_html', renderTo:'run-panel', style:{ display: 'none'},
        items: [
           { xtype:'hidden', name:'data_json'},
           { xtype:'hidden', name:'title' },
           { xtype:'hidden', name:'rows' },
           { xtype:'hidden', name:'total_rows' }
        ]
    });
    
    var form_report_submit = function(args) {
        var data = { rows:[], columns:[] };
        // find current columns
        var cfg = grid_topics.getColumnModel().config;
        
        if( !args.store_data ) { 
            var row=0, col=0;
            var gv = grid_topics.getView();
            for( var row=0; row<9999; row++ ) {
                if( !gv.getRow(row) ) break;
                var d = {};
                for( var col=0; col<9999; col++ ) {
                    if( !cfg[col] ) break;
                    if( cfg[col].hidden || cfg[col]._checker ) continue; 
                    var cell = gv.getCell(row,col); 
                    if( !cell ) break;
                    //console.log( cell.innerHTML );
                    d[ cfg[col].dataIndex ] = args.no_html ? $(cell.innerHTML).text() : cell.innerHTML;
                }
                data.rows.push( d ); 
            }
        } else {
            // get the grid store data
            store_topics.each( function(rec) {
                var d = rec.data;
                var topic_name = String.format('{0} #{1}', d.category_name, d.topic_mid )
                d.topic_name = topic_name;
                data.rows.push( d ); 
            });
        }
        
        for( var i=0; i<cfg.length; i++ ) {
            //console.log( cfg[i] );
            if( ! cfg[i].hidden && ! cfg[i]._checker ) 
                data.columns.push({ id: cfg[i].dataIndex, name: cfg[i].report_header || cfg[i].header });
        }
        
        // report so that it opens cleanly in another window/download
        var form = form_report.getForm(); 
        form.findField('data_json').setValue( Ext.util.JSON.encode( data ) );
        form.findField('title').setValue( make_title() );
        form.findField('rows').setValue( store_topics.getCount() );
        form.findField('total_rows').setValue( store_topics.getTotalCount() );
        var el = form.getEl().dom;
        var target = document.createAttribute("target");
        target.nodeValue = args.target || "_blank";
        el.setAttributeNode(target);
        el.action = args.url;
        el.submit(); 
    };

    var btn_html = {
        icon: '/static/images/icons/html.png',
        text: _('HTML Report'),
        handler: function() {
            form_report_submit({ url: '/topic/report_html' });
        }
    };

    var btn_yaml = {
        icon: '/static/images/icons/yaml.png',
        text: _('YAML'),
        handler: function() {
            form_report_submit({ no_html: true, url: '/topic/report_yaml' });
        }
    };

    var btn_csv = {
        icon: '/static/images/icons/csv.png',
        text: _('CSV'),
        handler: function() {
            form_report_submit({ no_html: true, url: '/topic/report_csv', target: 'FrameDownload' });
        }
    };

    var btn_reports = new Ext.Button({
        icon: '/static/images/icons/exports.png',
        iconCls: 'x-btn-icon',
        menu: [ btn_html, btn_csv, btn_yaml ]
    });
    
    var btn_edit = new Baseliner.Grid.Buttons.Edit({
        disabled: true,
        handler: function() {
            var sm = grid_topics.getSelectionModel();
                if (sm.hasSelection()) {
                    Ext.each( sm.getSelections(), function(r) {
                        Baseliner.show_topic_from_row( r, grid_topics );
                    });
                } else {
                    Baseliner.message( _('ERROR'), _('Select at least one row'));    
                };
        }
    });
    
    var btn_clear_state = new Ext.Button({
        icon: '/static/images/icons/reset-grey.png',
        tooltip: _('Reset Grid Columns'),
        iconCls: 'x-btn-icon',
        handler: function(){
            // deletes 
            var cp=new Ext.state.CookieProvider();
            Ext.state.Manager.setProvider(cp);
            Ext.state.Manager.clear( state_id );
            Baseliner.refreshCurrentTab();
        }
    });
    
    // var btn_delete = new Baseliner.Grid.Buttons.Delete({
    //     disabled: true,
    //     handler: function() {
    //         var sm = grid_topics.getSelectionModel();
    //         var sel = sm.getSelected();
    //         var topic_names=[];
    //         var topic_mids=[];
    //         Ext.each( sm.getSelections(), function(sel){
    //             topic_names.push( sel.data.category_name + ' #' + sel.data.topic_mid );
    //             topic_mids.push( sel.data.topic_mid );
    //         });
    //         if( topic_names.length > 0 ) {
    //             var names = topic_names.slice(0,10).join(',');
    //             if( topic_names.length > 10 ) {
    //                 names += _(' (and %1 more)', topic_names.length-10 );
    //             }
    //             Ext.Msg.confirm( _('Confirmation'), _('Are you sure you want to delete the topic(s)') + ': <br /><b>' + names + '</b>?', 
    //                 function(btn){ 
    //                     if(btn=='yes') {
    //                         Baseliner.Topic.delete_topic({ topic_mids: topic_mids, success: function(){ 
    //                             grid_topics.getStore().remove(sm.getSelections());
    //                             init_buttons('disable') 
    //                         }});
    //                     }
    //                 }
    //             );
    //         }
    //     }
    // });
    
    var btn_mini = new Ext.Toolbar.Button({
        icon:'/static/images/icons/updown_.gif',
        cls: 'x-btn-text-icon',
        enableToggle: true, pressed: mini_mode || false, allowDepress: true,
        handler: function() {
            if( btn_mini.pressed && ptool.pageSize == ps_maxi ) {
                ptool.pageSize =  ps_mini;
                store_topics.baseParams.limit = ps_mini;
                ps = ps_mini;
                ps_plugin.setValue( ps_mini );
            }
            else if( !btn_mini.pressed && ptool.pageSize == ps_mini ) {
                ptool.pageSize =  ps_maxi;
                store_topics.baseParams.limit = ps_maxi;
                ps = ps_maxi;
                ps_plugin.setValue( ps_maxi );
            }
            //store_topics.reload();
            ptool.doRefresh();
        }       
    }); 
    
    var btn_kanban = new Ext.Toolbar.Button({
        icon:'/static/images/icons/kanban.png',
        cls: 'x-btn-text-icon',
        //enableToggle: true,
        pressed: false,
        handler: function(){
            // kanban fullscreen 
            var mids = [];
            var sm = grid_topics.getSelectionModel();
            if (sm.hasSelection()) {
                Ext.each( sm.getSelections(), function(r) {
                    mids.push( r.get('topic_mid') );
                });
            } else {
               store_topics.each( function(r){
                    mids.push( r.get('topic_mid') );
               });
            }
            var kanban = new Baseliner.Kanban({ topics: mids });
            kanban.fullscreen();
        }
    }); 
    
    var render_id = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div style='font-weight:bold; font-size: 14px; color: #808080'> #" + value + "</div>" ;
    };

    function returnOpposite(hexcolor) {
        var r = parseInt(hexcolor.substr(0,2),16);
        var g = parseInt(hexcolor.substr(2,2),16);
        var b = parseInt(hexcolor.substr(4,2),16);
        var yiq = ((r*299)+(g*587)+(b*114))/1000;
        return (yiq >= 128) ? '#000000' : '#FFFFFF';
    }
    
    Baseliner.open_monitor_query = function(q){
        Baseliner.add_tabcomp('/job/monitor', null, { query: q });
    }
    
    var body_mini_tpl = function(){/*
                  <span style='font-weight:[%=font_weight%]; font-size: 12px; cursor: pointer; [%=strike%]' 
                  onclick='javascript:Baseliner.show_topic_colored([%=mid%],"[%=category_name%]","[%=category_color%]", "[%=id%]");'>[%=value%][%=folders%]</span>
          */}.tmpl();
    
    var body_tpl = function(){/* 
                <span style='font-weight:[%=font_weight%]; font-size: 14px; cursor: pointer; [%=strike%]' 
                onclick='javascript:Baseliner.show_topic_colored([%=mid%],"[%=category_name%]","[%=category_color%]", "[%=id%]")'>[%=value%]</span>
                        <br><div style='margin-top: 5px'>[%=modified_on%][%=folders%]
                        <a href='javascript:Baseliner.open_monitor_query("[%=current_job%]")'>[%=current_job%]</a><font color='808080'></br>[%=who%]</font ></div> 
           */}.tmpl();

    var render_title = function(value,metadata,rec,rowIndex,colIndex,store) {
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};		
		
		var mid = rec.data.topic_mid;
        var category_name = rec.data.category_name;
        var category_color = rec.data.category_color;
		var date_modified_on = rec.data.modified_on.dateFormat('M j, Y, g:i a');
		var modified_by = rec.data.modified_by;
		
		//#######################################Ñapa
		if ( rec.json['mid_' + this.alias] ){
			mid = rec.json['mid_' + this.alias];
			category_name = rec.json['category_name_' + this.alias];
			category_color = rec.json['category_color_' + this.alias];
			var modified_on_to_date = new Date(rec.json['modified_on_' + this.alias]);
			date_modified_on = modified_on_to_date.dateFormat('M j, Y, g:i a');
			modified_by = rec.json['modified_by_' + this.alias];
		}
		//#######################################
		
        var tag_color_html;
        tag_color_html = '';
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
        var font_weight = rec.data.user_seen===true ? 'normal' : 'bold';

        // folders tags
        var folders;
        if( rec.data.directory && rec.data.directory.length>0 ) {
            folders = '<span id="boot" style="background: transparent"><span class="label topictag">' + rec.data.directory.join('</span><span class="label topictag">') + '</span></span>';
        } else {
            folders = '';
        }

        if(rec.data.labels){
            tag_color_html = "";
            for(i=0;i<rec.data.labels.length;i++){
                var label = rec.data.labels[i].split(';');
                var label_name = label[1];
                var label_color = label[2];
                tag_color_html = tag_color_html
                    //+ "<div id='boot'><span class='label' style='font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;float:left;padding:1px 4px 1px 4px;margin-right:4px;color:"
                    + "<span style='font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;float:left;padding:1px 4px 1px 4px;margin-right:4px;-webkit-border-radius: 3px;-moz-border-radius: 3px;border-radius: 3px;"
                    + "color: #fff;background-color:" + label_color + "'>" + label_name + "</span>";
            }
        }
        
        // rowbody: 
        if(btn_mini.pressed){
            return tag_color_html + body_mini_tpl({ 
                        value: value, 
                        strike: strike,
                        modified_on: date_modified_on, 
                        who: _('by %1', modified_by), 
						mid: mid,
						category_name: category_name,
						category_color: category_color,
                        id: grid_topics.id, 
                        font_weight: font_weight, 
                        folders: folders, 
                        current_job: rec.data.current_job });                        
        }else{
            return tag_color_html + body_tpl({ 
                        value: value, 
                        strike: strike,
                        modified_on: date_modified_on, 
                        who: _('by %1', modified_by), 
						mid: mid,
                        category_name: category_name, 
                        category_color: category_color, 
                        id: grid_topics.id, 
                        font_weight: font_weight, 
                        folders: folders, 
                        current_job: rec.data.current_job });                        
        }
        
    };
    
    var render_title_comprimido = function(value,metadata,rec,rowIndex,colIndex,store) {
        var tag_color_html = '';
        var strike = ( rec.data.is_closed ? 'text-decoration: line-through' : '' );
        
        if(rec.data.labels){
            for(i=0;i<rec.data.labels.length;i++){
                var label = rec.data.labels[i].split(';');
                var label_name = label[1];
                var label_color = label[2];
                tag_color_html = tag_color_html + "<div id='boot'><span class='label' style='font-size: 9px; float:left;padding:1px 4px 1px 4px;margin-right:4px;color:#" + returnOpposite(label_color) + ";background-color:#" + label_color + "'>" + label_name + "</span></div>";                
            }
        }
        return tag_color_html + "<div style='font-weight:bold; font-size: 14px; "+strike+"' >" + value + "</div>";
    };  
    
    var render_ci = function(value,metadata,rec,rowIndex,colIndex,store) {
        //if( !value ) return '';
        var arr=[];
		
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};		

        Ext.each( value, function(v){
            arr.push( typeof v=='object' ? v.moniker ? v.moniker : v.name : v );
        });
        return arr.join('\n');
    };
    
    // calendar meta_type, a little table precompiled
    var html_cal = function(){/*
         <table style="background: transparent">
         <tbody>
         <tr>
            <td style="font-size:9px; font-weight: bold">[%= slotname %]: </td>
            [% if(start_date) { %]
            <td style="font-size:9px">[%= start_date + ' (' + _('start') + ')' %]</td>
            [% } if(plan_start_date) { %]
            <td style="font-size:9px">[%= plan_start_date + ' (' + _('planned start') + ')' %]</td>
            [% } if(end_date) { %]
            <td style="font-size:9px">[%= end_date + ' (' + _('end') + ')'%]</td>
            [% } if(plan_end_date) { %]
            <td style="font-size:9px">[%= plan_end_date + ' (' + _('planned end') + ')'%]</td>
            [% } %]
         </tr>
         </tbody>
         </table>
    */}.tmpl();
    var render_cal = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( typeof value != 'object' ) return '';
        var arr=[];
        for( var slot in value ) {
            var cal = value[slot];
            if( !cal ) continue;
            if(cal.start_date) cal.start_date = Date.parseDate(cal.start_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            if(cal.plan_start_date) cal.plan_start_date = Date.parseDate(cal.plan_start_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            if(cal.end_date) cal.end_date = Date.parseDate(cal.end_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            if(cal.plan_end_date) cal.plan_end_date = Date.parseDate(cal.plan_end_date,'d/m/Y H:i:s').format( Prefs.js_date_format );
            arr.push( html_cal(cal) );
        }
        return arr.join('\n');
    };
    var render_custom_data = function(data_key, value,metadata,rec,rowIndex,colIndex,store) {
        var arr=[];
        Ext.each( value, function(v){
            try {
                eval('var xx= v.'+data_key);
                arr.push(xx);
            } catch(e) {};
        });
        return arr.join('<br>');
    };
	
    var render_date = function(value,metadata,rec,rowIndex,colIndex,store) {
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};			
        if( !value && value == undefined ) return '';
		//var value_to_date = new Date(value);
		//return value_to_date.dateFormat('d/m/Y');
		var date;
		if (value.getMonth) {
			date = value;
		}else{
			var dateStr= value;
			if (dateStr == '' || dateStr == undefined) return '';
			var a=dateStr.split(" ");
			var d=a[0].split("-");
			var t=a[1].split(":");
			date = new Date(d[0],(d[1]-1),d[2],t[0],t[1],t[2]);
		}
		return date.dateFormat('d/m/Y');
    };
	
    var render_bool = function(value) {
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};			
        if( !value ) return '';
        return '<input type="checkbox" '+ ( value ? 'checked' : '' ) + '></input>'; 
    };
	
    var render_topic_rel = function(value,metadata,rec,rowIndex,colIndex,store) {
        var arr = [];
		
        
        if ( !rec.json[this.dataIndex] ) {
            var str = this.dataIndex;
            var res = str.replace('_' +  this.alias,"");
            value = rec.json[res];
        };
        
        if ( !value || value == undefined ) return '';
		//if( !value  ) return '';
		
		//#################################################Ñapa 
		if ( value[0] && !value[0].mid ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};
		//#####################################################
		
		Ext.each( value, function(topic){
			arr.push( Baseliner.topic_name({
				link: true,
				parent_id: grid_topics.id,
				mid: topic.mid, 
				mini: btn_mini.pressed,
				size: btn_mini.pressed ? '9' : '11',
				category_name: topic.category.name,
				category_color: topic.category.color,
				//category_icon: topic.category.icon,
				is_changeset: topic.is_changeset,
				is_release: topic.is_release
			}) ); 
		});
		return arr.join("<br>");
    }
	
    var shorten_title = function(t){
        if( !t || t.length==0 ) {
            t = '';
        } else if( t.length > 12 ) {
            t = t.substring(0,12) + '\u2026'; 
        } 
        return t;
    }
    Baseliner.open_topic_grid = function(dir,title,mid){
       var gridp ={ tab_icon: '/static/images/icons/topic.png' } ;
       if( dir ) {
           gridp[ dir=='in' ? 'to_mid' : 'from_mid' ] = mid;
           gridp[ 'tab_icon' ] = '/static/images/icons/topic_' + dir + '.png';
       }
       Baseliner.add_tabcomp('/comp/topic/topic_grid.js',  _('#%1 %2', mid, shorten_title( title )), gridp ); 
    };
    var render_actions = function(value,metadata,rec,rowIndex,colIndex,store) {
        var actions_html = new Array();
        var swGo = false;
        actions_html.push("<span id='boot' style='background: transparent'>");
        
        var ref_html = function(dir, refs){
            var img = dir =='in' ? 'referenced_in' : 'references_out';
            var ret = [];
            // open children
            ret.push("<a href='#' onclick='javascript:Baseliner.open_topic_grid(\""+dir+"\", \""+rec.data.title+"\", "+rec.data.topic_mid+"); return false'>");
            ret.push("<span class='label' style='cursor:pointer; color:#333; borderx: 1px #2ECC71 solid; padding-left: 0px; background-color: transparent; font-size:10px; margin-top:0px'>");
            ret.push("<img src='/static/images/icons/"+img+".png'>");
            ret.push( refs.length );
            ret.push("</span>");
            ret.push("</a>&nbsp;");           
            return ret.join('');
        }
        if( Ext.isArray( rec.data.references_out ) && rec.data.references_out.length > 0 ) {
            swGo = true;
            actions_html.push( ref_html( 'out', rec.data.references_out ) );
        }
        if(rec.data.numcomment){
            swGo = true;
            actions_html.push("<span style='float: right; color: #808080'><img border=0 src='/static/images/icons/comment_blue.gif' /> ");
            actions_html.push('<span style="font-size:9px">' + rec.data.numcomment + '</span>&nbsp;');
            actions_html.push("</span>");
        }
        if(rec.data.num_file){
            swGo = true;
            actions_html.push("<span style='float: right; color: #808080'><img border=0 src='/static/images/icons/paperclip.gif' /> ");
            actions_html.push('<span style="font-size:9px">' + rec.data.num_file + '</span>&nbsp;');
            actions_html.push("</span>");           
        }
        if( Ext.isArray( rec.data.referenced_in ) && rec.data.referenced_in.length > 0 ) {
            if( swGo && !btn_mini.pressed )  actions_html.push( '<br>' );
            swGo = true;
            actions_html.push( ref_html( 'in', rec.data.referenced_in ) );
        }
        
        actions_html.push("</span>");
        var str = swGo ? actions_html.join(""):'';
        return str;
    };
    
    var render_project = function(value,metadata,rec,rowIndex,colIndex,store){
        var tag_project_html = '';
        if(rec.data.projects){
            for(i=0;i<rec.data.projects.length;i++){
                var project = rec.data.projects[i].split(';');
                var project_name = project[1];              
                tag_project_html = tag_project_html ? tag_project_html + ',' + project_name: project_name;
            }
        }
        return tag_project_html;
    };

    var render_status = function(value,metadata,rec,rowIndex,colIndex,store){
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};			
		//////////if(rec.json[this.dataIndex + '_' + this.alias]){
		//////////	value = rec.json[this.dataIndex + '_' + this.alias];
		//////////}		
        var size = btn_mini.pressed ? '8' : '8';
        var ret = String.format(
            '<b><span class="bali-topic-status" style="font-size: {0}px;">{1}</span></b>',
            size, value );
           //+ '<div id="boot"><span class="label" style="float:left;padding:2px 8px 2px 8px;background:#ddd;color:#222;font-weight:normal;text-transform:lowercase;text-shadow:none;"><small>' + value + '</small></span></div>'
        return ret;
    };

    var render_progress = function(value,metadata,rec,rowIndex,colIndex,store){
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};			
        if( value==undefined || value == 0 ) return '';
        if( rec.data.category_status_type == 'I'  ) return '';  // no progress if its in a initial state

        var cls = ( value < 20 ? 'danger' : ( value < 40 ? 'warning' : ( value < 80 ? 'info' : 'success' ) ) );
        var ret =  [
            '<span id="boot">',
            '<div class="progress progress-'+ cls +'" style="height: 8px">',
                '<div class="bar" style="width: '+value+'%">',
                '</div>',
            '</div>',
            '</span>'
        ].join('');
        return ret;
    };

    var render_topic_name = function(value,metadata,rec,rowIndex,colIndex,store){
        var d = rec.data;
        return Baseliner.topic_name({
            link: true,
            parent_id: grid_topics.id,
            mid: d.topic_mid, 
            mini: btn_mini.pressed,
            size: btn_mini.pressed ? '9' : '11',
            category_name: d.category_name,
            category_color:  d.category_color,
            category_icon: d.category_icon,
            is_changeset: d.is_changeset,
            is_release: d.is_release
        });
    };
	
    var render_default = function(value,metadata,rec,rowIndex,colIndex,store){
		if ( !rec.json[this.dataIndex] ) {
			var str = this.dataIndex;
			var res = str.replace('_' +  this.alias,"");
			value = rec.json[res];
		};
        return value;
    };	

    var search_field = new Baseliner.SearchField({
        store: store_topics,
        params: {start: 0 },
        emptyText: _('<Enter your search string>')
    });

    var ps_plugin = new Ext.ux.PageSizePlugin({
        editable: false,
        width: 90,
        data: [
            ['5', 5], ['10', 10], ['15', 15], ['20', 20], ['25', 25], ['50', 50],
            ['100', 100], ['200',200], ['500', 500], ['1000', 1000], [_('all rows'), -1 ]
        ],
        beforeText: _('Show'),
        afterText: _('rows/page'),
        value: ps,
        listeners: {
            'select':function(c,rec) {
                ps = rec.data.value;
                if( rec.data.value < 0 ) {
                    ptool.afterTextItem.hide();
                } else {
                    ptool.afterTextItem.show();
                }
            }
        },
        forceSelection: true
    });
    var ptool = new Ext.PagingToolbar({
            store: store_topics,
            pageSize: ps,
            plugins:[
                ps_plugin,
                new Ext.ux.ProgressBarPager()
            ],
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
    });

    var check_sm = new Ext.grid.CheckboxSelectionModel({
        _checker: true,
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });

    var dragger = {     
        header : '',
        id : 'dragger',
        menuDisabled : true,
        fixed : true,
        hideable: false,
        dataIndex: '', 
        width: 7, 
        sortable: false,
        renderer: function(v,m,rec){
            var div = document.createElement('div');
            div.innerHTML = 'abc';
            m.tdCls = m.tdCls + ' dragger-target';
            return ' '; //'<div>aaa</div>';
        }
    };
	
	var force_fit = true;
	
	var type_filters ={
		string: 'string',
		number: 'numeric',
		date: 'date',
		status: 'list',
		ci: 'list'
	}
	var fields_filter = [];
	
    var columns = [];
    var col_map = {
        topic_name : { header: _('Name'), sortable: true, dataIndex: 'topic_name', width: 90, sortable: true, renderer: render_topic_name },
        category_name : { header: _('Category'), sortable: true, dataIndex: 'category_name', hidden: true, width: 80, sortable: true, renderer: render_default },
        category_status_name : { header: _('Status'), sortable: true, dataIndex: 'category_status_name', width: 50, renderer: render_status },
        title : { header: _('Title'), dataIndex: 'title', width: 250, sortable: true, renderer: render_title},
        progress : { header: _('%'), dataIndex: 'progress', width: 25, sortable: true, renderer: render_progress },
        numcomment : { header: _('More info'), report_header: _('Comments'), sortable: true, dataIndex: 'numcomment', width: 45, renderer: render_actions },         
        projects : { header: _('Projects'), dataIndex: 'projects', sortable: true, width: 60, renderer: render_project },
        topic_mid : { header: _('ID'), hidden: true, sortable: true, dataIndex: 'topic_mid', renderer: render_default},    
        moniker : { header: _('Moniker'), hidden: true, sortable: true, dataIndex: 'moniker', renderer: render_default},    
        cis_out : { header: _('CIs Referenced'), hidden: true, sortable: false, dataIndex: 'cis_out', renderer: render_default},    
        cis_in : { header: _('CIs Referenced In'), hidden: true, sortable: false, dataIndex: 'cis_in', renderer: render_default},    
        references_out : { header: _('References'), hidden: true, sortable: false, dataIndex: 'references_out', renderer: render_default},    
        references_in : { header: _('Referenced In'), hidden: true, sortable: false, dataIndex: 'referenced_in', renderer: render_default},    
        assignee : { header: _('Assigned To'), hidden: true, sortable: true, dataIndex: 'assignee', renderer: render_default},
        current_job : { header: _('Current Job'), hidden: true, sortable: true, dataIndex: 'current_job', renderer: render_default},
        modified_by : { header: _('Modified By'), hidden: true, sortable: true, dataIndex: 'modified_by', renderer: render_default },
        modified_on : { header: _('Modified On'), hidden: true, sortable: true, dataIndex: 'modified_on', renderer: render_date },
        created_on : { header: _('Created On'), width: 80, hidden: true, sortable: true, dataIndex: 'created_on', renderer: render_date },
        created_by : { header: _('Created By'), width: 40, hidden: true, sortable: true, dataIndex: 'created_by', renderer: render_default}
    };
    var gridlets = {
    };
    var meta_types = {
        custom_data : { sortable: true, width: 40, renderer: render_custom_data  },
        calendar : { sortable: true, width: 250, renderer: render_cal  },
        date : { sortable: true, width: 40, renderer: render_date  },
        bool : { sortable: true, width: 40, renderer: render_bool  },
        ci : { sortable: true, width: 90, renderer: render_ci  },
        revision : { sortable: true, width: 90, renderer: render_ci  },
        project : { sortable: true, width: 90, renderer: render_ci  },
        topic : { sortable: true, width: 90, renderer: render_topic_rel  },
        release : { sortable: true, width: 90, renderer: render_topic_rel  }
    };
    if( fields ) {
		force_fit = false;
        columns = [ dragger, check_sm, col_map['topic_name'] ];
        Ext.each( fields.columns, function(r){ 
            // r.meta_type, r.id, r.as, r.width, r.header
			//console.dir(r);
			
			if(r.filter){
				//console.dir(r);
				//alert(r.id);
				var filter_params = {type: type_filters[r.filter.type], dataIndex: r.id + '_' + r.category};
				
				//console.dir(filter_params);
				switch (filter_params.type){
					case 'date':   
						filter_params.dateFormat = 'Y-m-d';
						filter_params.beforeText = _('Before');
						filter_params.afterText = _('After'); 
						filter_params.onText = _('On');	
						break;
					case 'numeric':
						filter_params.menuItemCfgs = {
							emptyText: _('Enter Number...'),
						}
						break;
					case 'string':
						filter_params.emptyText = _('Enter Text...');
						break;
					case 'list':
						if (r.filter.options){
							if(r.filter.options.length == 1 && r.filter.values[0] == -1){
								filter_params.type = 'string';
								filter_params.emptyText = _('Enter mid...');
								break;						
							}else{
								var options = [];
								for(i=0;i<r.filter.options.length;i++){
									if(r.filter.values[i] == '') r.filter.values[i] = -1;
									options.push( [ r.filter.values[i],r.filter.options[i] ]);
								}
								filter_params.options = options;
							}
						}else{
							filter_params = undefined;
						}
				}
				if(filter_params) {
					fields_filter.push(filter_params);
				}
			}
			
			var col = gridlets[ r.gridlet ] || col_map[ r.id ] || meta_types[ r.meta_type ] || {
                dataIndex: r.id + '_' + r.category,
                hidden: false, width: 80, sortable: true,
				renderer: render_default
            };
			
			//console.log( r );
			//console.log(col);
			
            col = Ext.apply({},col);  // clone the column
			col.dataIndex =  r.id + '_' + r.category;
			//if( !col.dataIndex ) col.dataIndex = r.id;
			
            if( r.meta_type == 'custom_data' && r.data_key ) {
                var dk = r.data_key;
                col.renderer = function(v,m,row,ri){ return render_custom_data(dk,v,m,row,ri) };
            }
            col.hidden = false;
			
			col.alias = r.category;
			col.header = _(r.header || r.as || r.text || r.id);
            col.width = r.width || col.width;
			
			
			//console.log( col );
            columns.push( col );
        });
    } else {
         columns = [ dragger, check_sm ];
         var cols = ['topic_name', 'category_name', 'category_status_name', 'title', 'progress',
            'numcomment', 'projects', 'topic_mid', 'moniker', 'cis_out', 'cis_in', 'references_out',
            'references_in', 'assignee', 'modified_by', 'modified_on', 'created_on', 'created_by', 'current_job'];
         Ext.each( cols, function(col){
             columns.push( col_map[col] );
         });
    }
	
	
    var filters = new Ext.ux.grid.GridFilters({
		menuFilterText: _('Filters'),
        encode: true,
        local: false,
        filters: fields_filter
	});
	
	
    var grid_topics = new Ext.grid.GridPanel({
        //title: _('Topics'),
        //header: false,
		plugins: [filters],		
        stripeRows: true,
        autoScroll: true,
        stateful: true,
        stateId: state_id, 
        //enableHdMenu: false,
        store: store_topics,
        //enableDragDrop: true,
        dropable: true,
        autoSizeColumns: true,
        deferredRender: true,
        ddGroup: 'explorer_dd',
        viewConfig: {forceFit: force_fit},
%if ( !$c->stash->{typeApplication} ){
        sm: check_sm,
%}
        //loadMask:'true',
        columns: columns,
        tbar:   [ 
                search_field
                ,
%if ( !$c->stash->{typeApplication} ){              
                btn_add,
                btn_edit,
                // btn_delete,
%}              
                //btn_labels
                '->',
                btn_clear_state,
                btn_reports,
                btn_kanban,
                btn_mini
                //btn_close
        ],      
        bbar: ptool
    });
    
//    grid_topics.on('rowclick', function(grid, rowIndex, columnIndex, e) {
//        //init_buttons('enable');
//    });
    
    grid_topics.on('cellclick', function(grid, rowIndex, columnIndex, e) {
        if(columnIndex == 1){
            topicsSelected();
        }
    });
    
    grid_topics.on('headerclick', function(grid, columnIndex, e) {
        if(columnIndex == 1){
            topicsSelected();
        }
    });
    

/*
    node: Ext.tree.AsyncTreeNode
    allowChildren: true
    attributes: Object
    attributes: 
        calevent: Object
        children: Array[1]
        data:
            click: Object
            topic_mid: "67183"
        expandable: true
        icon: "/static/images/icons/topic.png"
        iconCls: "no-icon"
        id: "xnode-2696"
        leaf: false
        loader: Baseliner.TreeLoader.Ext.extend.constructor
        text: "<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #20bcff;background-color: transparent;color:#20bcff;border-radius:0px"></span><b>Funcionalidad #67183</b>: NAT:BIZTALK"
        topic_name: 
            category_color: "#20bcff"
            category_name: "Funcionalidad"
            is_changeset: "0"
            is_release: "0"
            mid: "67183"
        url: "/lifecycle/tree_topic_get_files"
    childNodes: Array[0]
    childrenRendered: false
    disabled: false
    draggable: true
    events: Object
    expanded: false
    firstChild: null
    hidden: false
    id: "xnode-2696"
    isTarget: true
    lastChild: null
    leaf: false
    listeners: undefined
    loaded: false
    loading: false
    nextSibling: null
    ownerTree: sb
    parentNode: Ext.tree.AsyncTreeNode
    previousSibling: Ext.tree.AsyncTreeNode
    rendered: true
    text: "<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #20bcff;background-color: transparent;color:#20bcff;border-radius:0px"></span><b>Funcionalidad #67183</b>: NAT:BIZTALK"
    ui: sb
*/


    grid_topics.store.on('load', function() {
        for( var ix=0; ix < grid_topics.store.getCount(); ix++ ) {
            //var rec = grid_topics.store.getAt( ix );
            var cell = grid_topics.view.getCell( ix, 0 );
            var el = Ext.fly( cell );
            el.setStyle( 'background-color', '#ddd' );
            new Ext.dd.DragZone( el, {
                ddGroup: 'explorer_dd',
                index: ix,
                getDragData: function(e){
                    var sourceEl = e.getTarget();
                    var data = grid_topics.store.getAt( this.index ).data;
                    var d = sourceEl.cloneNode(true);
                    d.id = Ext.id();
                    var mid = data.topic_mid;
                    // TODO create topic node using the original data from attributes
                      // inject into loader? Loader.newNode or something?
                    var text = String.format('<span unselectable="on" style="font-size:0px;padding: 8px 8px 0px 0px;margin : 0px 4px 0px 0px;border : 2px solid #{1};background-color: transparent;color:#{1};border-radius:0px"></span><b>{0}</b>{2}', data.topic_name, data.category_color, '' );
                    d.innerHTML = text;
                    //text = data.topic_name;
                    var node = {
                            contains: Ext.emptyFn,
                            text: text,
                            leaf: true,
                            parentNode: Ext.emptyFn,
                            attributes: {
                                text: text,
                                icon: "/static/images/icons/topic.png",
                                iconCls: "no-icon",
                                leaf: true,
                                data: {
                                    topic_mid: mid
                                },
                                topic_name: {
                                    category_color: data.category_color,
                                    category_name: data.category_name,
                                    is_changeset: data.is_changeset,
                                    is_release: data.is_release,
                                    mid: mid
                                }
                            }
                        };
                    return {
                        ddel: d,
                        sourceEl: sourceEl,
                        repairXY: Ext.fly(sourceEl).getXY(),
                        node: node,
                        sourceStore: null,
                        draggedRecord: { }
                    };
                }
            });
        }
    });

    function topicsSelected(){
        var topics_checked = getTopics();
        if (topics_checked.length > 0 ){
            var sw_edit;
            check_sm.each(function(rec){
                sw_edit = (rec.get('sw_edit'));
            });
            if(sw_edit){
                init_buttons('enable'); 
            }else{
                // btn_delete.enable();
                btn_edit.disable();
            }               
            //init_buttons('enable');
        }else{
            if(topics_checked.length == 0){
                init_buttons('disable');
            }else{
                // btn_delete.enable();
                btn_edit.disable();
            }
        }
    }
    function getTopics(){
        var topics_checked = new Array();
        check_sm.each(function(rec){
            topics_checked.push(rec.get('topic_mid'));
        });
        return topics_checked
    }   

    grid_topics.on("rowdblclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);
        Baseliner.show_topic_from_row( r, grid_topics );
    });
    
    grid_topics.on( 'render', function(){
        var el = grid_topics.getView().el.dom.childNodes[0].childNodes[1];
        var grid_topics_dt = new Baseliner.DropTarget(el, {
            comp: grid_topics,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                var s = grid_topics.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var projects = row.get('projects');
                    if( typeof projects != 'object' ) projects = new Array();
                    for (i=0;i<projects.length;i++) {
                        var project = projects[i].split(';');
                        var project_name = project[1];
                        if(project_name == data.project){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
                        
                        projects.push( data.id_project + ';' + data.project );
                        row.set('projects', projects );
                        row.endEdit();
                        row.commit();
                        
                        Baseliner.ajaxEval( '/topic/update_project',{ id_project: data.id_project, topic_mid: row.get('topic_mid') },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Project %1 is already assigned', data.project));
                    }
                    
                };
                
                var add_label = function(node) {
                    var text = node.attributes.text;
                    // determine the row
                    var t = Ext.lib.Event.getTarget(e);
                    var rindex = grid_topics.getView().findRowIndex(t);
                    if (rindex === false ) return false;
                    var row = s.getAt( rindex );
                    var swSave = true;
                    var labels = row.get('labels');
                    if( typeof labels != 'object' ) labels = new Array();
                    for (i=0;i<labels.length;i++) {
                        var label = labels[i].split(';');
                        var label_name = label[1];
                        if(label_name == text){
                            swSave = false;
                            break;
                        }
                    }

                    //if( projects.name.indexOf( data.project ) == -1 ) {
                    if( swSave ) {
                        row.beginEdit();
                        
                        labels.push( node.attributes.idfilter + ';' + text + ';' + node.attributes.color );
                        row.set('labels', labels );
                        row.endEdit();
                        row.commit();
                        
                        var label_ids = new Array();
                        for(i=0;i<labels.length;i++){
                            var label = labels[i].split(';');
                            label_ids.push(label[0]);
                        }
                        Baseliner.ajaxEval( '/topic/update_topic_labels',{ topic_mid: row.get('topic_mid'), label_ids: label_ids },
                            function(response) {
                                if ( response.success ) {
                                    //store_label.load();
                                    Baseliner.message( _('Success'), response.msg );
                                    //init_buttons('disable');
                                } else {
                                    //Baseliner.message( _('ERROR'), response.msg );
                                    Ext.Msg.show({
                                        title: _('Information'), 
                                        msg: response.msg , 
                                        buttons: Ext.Msg.OK, 
                                        icon: Ext.Msg.INFO
                                    });
                                }
                            }
                        
                        );
                    } else {
                        Baseliner.message( _('Warning'), _('Label %1 is already assigned', text));
                    }
                    
                };              
                
                var attr = n.attributes;
                if(attr.data){
                    if( typeof attr.data.id_project == 'undefined' ) {  // is a project?
                        //Baseliner.message( _('Error'), _('Node is not a project'));
                    } else {
                        add_node(n);
                    }
                }
                else{
                    if(n.parentNode.attributes.id == 'L'){
                        add_label(n);
                    }else{
                        //Baseliner.message( _('Error'), _('Node is not a label'));
                    }
                    
                }
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true); 
             }
        });
        
    }); 

   
    var render_color = function(value,metadata,rec,rowIndex,colIndex,store) {
        return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>" ;
    };  

    function loadfilters( unselected_node ){
        var labels_checked = new Array();
        var statuses_checked = new Array();
        var categories_checked = new Array();
        var priorities_checked = new Array();
        var type;
        var selected_views = { };
        
        selNodes = tree_filters.getChecked();
        if( selNodes.length > 0 ) button_no_filter.enable();
          else button_no_filter.disable();
          

        for( var i=0; i<selNodes.length; i++ ) {
            var node = selNodes[ i ];
            type = node.parentNode.attributes.id;
            //if (type == 'C') console.log(node);
            var node_value = node.attributes.checked3 == -1 ? -1 * (node.attributes.idfilter) : node.attributes.idfilter;
            switch (type){
                //Views
                case 'V':   
                            var d = Ext.util.JSON.decode(node.attributes.filter);
                            if( d.query !=undefined && selected_views.query !=undefined ) {
                                d.query = d.query + ' ' + selected_views.query;
                            }
                            selected_views = Baseliner.merge(selected_views, d );
                            break;
                //Labels
                case 'L':   labels_checked.push(node_value);
                            //labels_checked.push(node.attributes.idfilter);
                            break;
                //Statuses
                case 'S':   statuses_checked.push(node_value);
                            //statuses_checked.push(node.attributes.idfilter);
                            break;
                //Categories
                case 'C':   categories_checked.push(node_value);
                            //categories_checked.push(node.attributes.idfilter);
                            break;
                //Priorities
                case 'P':   priorities_checked.push(node_value);
                            //priorities_checked.push(node.attributes.idfilter);
                            break;
            }
        }
        //alert('merge views: ' + Ext.util.JSON.encode(selected_views));
        filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node);
    }
    
    function filtrar_topics(selected_views, labels_checked, categories_checked, statuses_checked, priorities_checked, unselected_node){
        // copy baseParams for merging
        var bp = store_topics.baseParams;
        var base_params;
        if( bp !== undefined )
            base_params= { start: bp.start, limit: ps, sort: bp.sort, dir: bp.dir, typeApplication: typeApplication, topic_list: params.topic_list, id_project: id_project ? id_project : undefined, categories: category_id ? category_id : undefined, statuses: status_id  };        // object for merging with views 
        var selected_filters = {labels: labels_checked, categories: categories_checked, statuses: statuses_checked, priorities: priorities_checked};
        
        //alert('selected_views ' + Ext.util.JSON.encode(selected_views));
        //alert('merge_filters: ' + Ext.util.JSON.encode(merge_filters));
        //alert('bfilters: ' + Ext.util.JSON.encode(base_params));

        // merge selected filters with views
        var merge_filters = Baseliner.merge( selected_views, selected_filters);
        // now merge baseparams (query, limit and start) over the resulting filters
        var filter_final = Baseliner.merge( merge_filters, base_params );
        // query and unselected
        
        
        //if( unselected_node != undefined ) {
        //    var unselected_type = unselected_node.parentNode.attributes.id;
        //    var unselected_filter = Ext.util.JSON.decode(unselected_node.attributes.filter);
        //    if( unselected_type == 'V' ) {
        //        if( bp.query == unselected_filter.query ) {
        //            filter_final.query = '';
        //        } else {
        //            filter_final.query = bp.query.replace( unselected_filter.query, '' );
                    filter_final.query = bp.query;
                    //filter_final.query = filter_final.query.replace( /^ +/, '' );
                    //filter_final.query = filter_final.query.replace( / +$/, '' );
        //        }
        //    }
        //}
        //else if( selected_views.query != undefined  && bp.query != undefined ) {
        //    //filter_final.query = bp.query + ' ' + selected_views.query;
        //}

        //alert('curr ' + Ext.util.JSON.encode(filter_final));
        //if( base_params.query !== filter_final.query ) {
            //delete filter_final['query'];    
        //}
        //console.dir(filter_final);
        
        if (statuses_checked.length == 0) filter_final.clear_filter = 1
        
        store_topics.baseParams = filter_final;
        search_field.setValue( filter_final.query );
        store_topics.load();
        filter_current = filter_final;
    };


    var tree_root = new Ext.tree.AsyncTreeNode({
                text: 'Filters',
                expanded: true
            });

    var tree_filters = {};
    
    function checkchange(node_selected, checked) {
        var type = node_selected.parentNode.attributes.id;
        if (!changing  ) {
            //if (type != 'V') {
                changing = true;
                var c3 = node_selected.attributes.checked3;
                node_selected.getUI().toggleCheck( c3 );
                changing = false;
            //}
        
        
            if( stop_filters ) return;
            
            var swDisable = true;
            var selNodes = tree_filters.getChecked();
            var tot_view_defaults = 1;
            //Ext.each(selNodes, function(node){
            //  
            //  var type = node.parentNode.attributes.id;
            //  if(type == 'V'){
            //      //if(!eval('node.attributes.default')){   //Eval, I.E
            //      if(!node.attributes['default']){   // I.E 8.0
            //          button_delete_view.enable();
            //          swDisable = false;
            //          return false;
            //      }else{
            //          if(selNodes.length == tot_view_defaults){
            //              swDisable = true;
            //          }else{
            //              swDisable = false;
            //          }
            //      }
            //  }else{
            //      swDisable = true;
            //  }
            //});
            
            if (swDisable)
                button_delete_view.disable();
                
            if( checked ) {
                loadfilters();
            } else {
                loadfilters( node_selected );
            }
        }
    }
	
    if( !id_report ) {
        var id_collapse = Ext.id();
        tree_filters = new Ext.tree.TreePanel({
            region : 'east',
            header: false,
            hidden: !!id_report,
            width: 210,
            split: true,
            collapsible: true,
            tbar: [
                button_no_filter, '->',
                //button_create_view,
                //button_delete_view,
                '<div class="x-tool x-tool-expand-west" style="margin:-2px -4px 0px 0px" id="'+id_collapse+'"></div>'
            ],
            dataUrl: "/topic/filters_list" + parse_typeApplication,
            split: true,
            colapsible: true,
            useArrows: true,
            animate: true,
            autoScroll: true,
            rootVisible: false,
            root: tree_root,
            enableDrag: true,
            enableDrop: false,
            ddGroup: 'explorer_dd',
            listeners: {
                'checkchange': checkchange
            }       
        });
        
        tree_filters.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = tree_filters.getLoader();
            if(category_id){
                loader.baseParams = {category_id: category_id}; 
            }
            if(status_id){
                loader.baseParams = {status_id: status_id}; 
            }       
            
        }); 
        
        var changing = false;
        
        tree_filters.on('beforechildrenrendered', function(node){
            /* Changing node text
            node.setText( String.format('<span>{0}</span><span style="float:right; margin-right:1px">{1}</span>',
                node.text,
                '<img src="/static/images/icons/config.gif" onclick="Baseliner.aaa()" />'  )
            );
            */
            if(node.attributes.id == 'C' || node.attributes.id == 'L'){
                node.eachChild(function(n) {
                    //console.log(n.getUI());
                    var color = n.attributes.color;
                    if( ! color ) color = '#999';
                    var style = document.createElement('style');
                    var head = document.getElementsByTagName('head')[0];
                    var rules = document.createTextNode(
                        '.forum.dinamic' + n.id + ' a span { margin-left: 5px; padding: 1px 4px 2px;;-webkit-border-radius: 3px;-moz-border-radius: 3px;border-radius: 3px;color: #fff;' 
                         + ';background: ' + color +
                        ';font-family:Helvetica Neue,Helvetica,Arial,sans-serif;font-size: xx-small; font-weight:bolder;}'
                    );
                    style.type = 'text/css';
                    if(style.styleSheet) {
                        style.styleSheet.cssText = rules.nodeValue;
                    } else {
                        style.appendChild(rules);
                    }
                    head.appendChild(style);
                    n.attributes.cls = 'forum dinamic' + n.id;
                });
            }
        });
        
        // expand the whole tree
        tree_filters.getLoader().on( 'load', function(){
            tree_root.expandChildNodes();

            // draw the collapse button onclick event 
            var el_collapse = Ext.get( id_collapse );
            if( el_collapse ){
                el_collapse.dom.onclick = function(){ 
                    panel.body.dom.style.overflow = 'hidden'; // collapsing shows overflow, so we hide it
                    tree_filters.collapse();
                };
            }
            // select filter for current category
            //////if( params.id_category ){
            //////    var chi = tree_filters.root.findChild('idfilter', params.id_category, true );
            //////    if( chi ) chi.getUI().toggleCheck(true);
            //////
            //////}
        });
            
    } // if !id_report
        
    var panel = new Ext.Panel({
        layout : "border",
        defaults: {layout:'fit'},
        title: _('Topics'),
        //tab_icon: '/static/images/icons/topic.png',
        items : [
            {
                region:'center',
                collapsible: false,
                items: [
                    grid_topics
                ]
            },   
            tree_filters  // show only if not report
        ]
    });
        
    grid_topics.on('afterrender', function(){
        grid_topics.loadMask = new Ext.LoadMask(grid_topics.bwrap, { msg: _('Loading'), store: store_topics });
        store_topics.load({
            params: {
                start:0 , limit: ps,
                topic_list: params.topic_list,
                //query_id: '<% $c->stash->{query_id} %>', id_project: '<% $c->stash->{id_project} %>',
                query_id: '<% $c->stash->{query_id} %>', 
                typeApplication: typeApplication
            }
        });
    });
    //store_label.load();
    
    panel.print_hook = function(){
        return { title: grid_topics.title, id: Baseliner.grid_scroller( grid_topics ).id };
    };
    return panel;
})
