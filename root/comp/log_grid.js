<%args>
    $mid
    $annotate_now => 0
    $job_exec => 1
    $user_action
    $service_name
</%args>
(function(params){
    if( !params ) params = {};
    var ps = 500; //page_size
    var mid = '<% $mid %>' ;
    var job_exec = '<% $job_exec %>' ;
    var job_exec_max = job_exec;
    var filter_key = 'log_filter_<% $mid . int(rand(9999999999)) %>' ;
    var annotate_now = <% $annotate_now ? 'true' : 'false' %> ;
    var filter_cookie; // = Baseliner.cookie.get( filter_key );
    var filter_obj = filter_cookie || params.filter_obj || {
        info : true,
        comment: true,
        warn : true,
        debug: false,
        error: true
    };
    
    var store_load = function(params) {
        if( params == undefined ) params={};
        if( params.anim == undefined ) params.anim='f';
        params.callback = function(){
            Baseliner.hideLoadingMaskFade(grid.getEl());
            if( params.anim == 'f' ) 
                grid.getGridEl().fadeIn({ duration: .1 });
            if( params.anim == 'r' ) 
                grid.getGridEl().slideIn('r', { duration: .1 });
            if( params.anim == 'l' ) 
                grid.getGridEl().slideIn('l', { duration: .1 });
        };
        store.load( params );
    };
    
    var reader = new Ext.data.JsonReader({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id'
        }, [ 
            {  name: 'id' },
            {  name: 'id_data' },
            {  name: 'mid' },
            {  name: 'job' },
            {  name: 'text' },
            {  name: 'datalen' },
            {  name: 'ts' },
            {  name: 'lev' },
            {  name: 'section' },
            {  name: 'step' },
            {  name: 'exec' },
            {  name: 'prefix' },
            {  name: 'milestone' },
            {  name: 'module' },
            {  name: 'ns' },
            {  name: 'provider' },
            {  name: 'service_key' },
            {  name: 'file' },
            {  name: 'data' },
            {  name: 'more' }
        ]
    );
    var grouping = 'step';
    var store = new Baseliner.GroupingStore({
            reader: reader,
            url: '/job/log/json',
            baseParams: {  start: 0, limit: ps, mid: '<% $mid %>', service_name: '<% $service_name %>', filter: {} },
            remoteSort: true,
            //sortInfo: { field: 'starttime', direction: "DESC" },
            groupField: grouping
    });
    

    var current_job = function() { return store.reader.jsonData.job }
    var current_hash = function() { return store.reader.jsonData.job_key }

    store.on( 'beforeload', function( obj, opt ) {
        var f = Ext.util.JSON.encode( filter_obj );
        obj.baseParams.filter = f;
    });

    //Filtering
    var filter_me = function( item, checked ) {
        filter_obj[ item.value ] = checked;
        var cm = grid.getColumnModel();
        cm.setHidden( cm.getIndexById('module'), !filter_obj['debug'] );
        cm.setHidden( cm.getIndexById('service_key'), !filter_obj['debug'] );
        cm.setHidden( cm.getIndexById('milestone'), !filter_obj['debug'] );
        Baseliner.cookie.set( filter_key , filter_obj ); 
        params.filter_obj = filter_obj;
        store_load();
    };

    var filter_menu = new Ext.menu.Menu({
        items: [
            { value: 'info', text: _('Information'),checked: filter_obj['info'] , checkHandler: filter_me },
            { value: 'comment', text: _('Comments'),checked: filter_obj['comment'] , checkHandler: filter_me },
            { value: 'warn', text: _('Warning'),checked: filter_obj['warn'] , checkHandler: filter_me },
            { value: 'error', text: _('Error'), checked: filter_obj['error'], checkHandler: filter_me },
            { value: 'debug', text: _('Debug'),checked: filter_obj['debug'] , checkHandler: filter_me }
        ]
    });

    // AutoRefresh
    var button_autorefresh = new Ext.Button({ text: _('Auto Refresh'),
        icon: '/static/images/icons/time.gif', 
        enableToggle: true,
        pressed: false,
        cls: 'x-btn-text-icon',
        handler: function(t) {
            if( t.pressed ) {
                if( mid == "" ) {
                    t.toggle();
                } else {
                    autorefresh.start(task);
                }
            } else {
                autorefresh.stop(task);
            }
        }
    });
    var ATTEMPTS = 10;
    var task_off_count = ATTEMPTS;
    var task = {
        run: function() {
            if( mid == "" ) return; 
            var f = Ext.util.JSON.encode( filter_obj );
            var je = store.baseParams.job_exec || job_exec;
            Ext.Ajax.request({
                url: '/job/log/auto_refresh',
                params: { mid: mid, cnt: store.getCount(), job_exec: je, filter: f },
                success: function(xhr) {
                    var res = xhr.responseText;
                    var data = Ext.util.JSON.decode( res );
                    //menu_exec.setText( data.count + ' - ' + store.getCount() + ', ' + data.top_id );
                    if( data.count > store.getCount() ) {
                        store_load();
                    } else {
                    }
                    if( data.stop_now ) {
                        if( task_off_count > 0 ) {
                            task_off_count--;
                        } else {
                            task_off_count = ATTEMPTS;
                            autorefresh.stop(task);
                            button_autorefresh.toggle( false ); 
                            Baseliner.message( _('Warning'), _('Job is not active') );
                        }
                    } else {
                        task_off_count = ATTEMPTS;
                    }
                },
                failure: function(xhr) {
                }
            });
                
        },
        interval: 3000
    };
    var autorefresh = new Ext.util.TaskRunner();

    //Annotations
    var annotation = function(r) {
        var a_form = new Ext.FormPanel({
            frame: true,
            url: '/wiki/post', 
            items: [
                {
                    xtype: 'textarea',
                    fieldLabel: _('Comments'),
                    width: 450,
                    height: 200
                }
            ]
        });
        var field_annotate = new Ext.form.HtmlEditor({ width: 450, height: 200, title:_('Text')});
        var field_data = new Ext.form.TextArea({ width: 450, height: 200, title:_('Data') });
        var severity = new Ext.form.ComboBox ({
                editable: false,
                forceSelection: true,
                mode: "local",
                triggerAction: "all",
                value: "info",
                allowBlank: false,
                valueField: "value",
                displayField: "text",
                hiddenName: 'bl',
                listWidth:90,
                width:90,
                lazyRender: true,
                name: "severity",
                allowBlank: 0,
                listClass: "x-combo-list-small",
                store: new Ext.data.SimpleStore({
                    fields: ['value', 'text'],
                    data :  [["info",_('Information')],["warn",_('Warning')],["error",_('Error')]]
                    })
                });

        var win = new Ext.Window({
            layout: 'fit',
            height: 450, width: 600,
            maximizable: true,
            closeAction: 'close',
            //autoDestroy: true,
            title: _('Annotations'),
            tbar: [
                { 
                    text: _('Save'),
                    icon:'/static/images/download.gif',
                    cls: 'x-btn-text-icon',
                    handler: function(){
                        if( field_annotate.getValue().length > 2000 ) {
                            Ext.Msg.show({icon: 'ext-mb-error', buttons: { cancel: true },
                                title: _("Form Error"),
                                msg: _('Field limit exceeded: %1 chars. Use the Data field for large content', 2000) });
                            return ;
                        }
                        Baseliner.ci_call( mid, 'annotate',  
                            { text: field_annotate.getValue(), data: field_data.getValue(),
                                jobid: mid, job_exec: store.baseParams.job_exec || job_exec, level: severity.getValue() },
                            function(res){
                                Baseliner.message(_('Annotation'), _('Submitted') );
                                    win.close();
                                store_load();
                        });
                }
                }, '->', new Ext.Toolbar.TextItem (_("Severity")), severity
            ],
            items : [ { xtype:'tabpanel', activeTab:0, items: [ field_annotate, field_data ] } ] 
        });

        win.show();
    };

    <& /comp/search_field.mas &>

    //------------ Row Coloring
    var render_msg = function(value,metadata,rec,rowIndex,colIndex,store) {
        var prefix = rec.data.prefix;
        var div1   = '<div style="white-space:normal !important;">';
        var div2   = '</div>';
        var milestone = rec.data.milestone;
        var section = rec.data.section;
        if( ( section != undefined && section != 'general') && (rec.data.lev == 'comment' || rec.data.lev == 'warn' || rec.data.lev == 'error') ) value = '<b>' + section + '</b>: ' + value;
        if( prefix!=undefined && prefix!='' ) {
            return div1 + '<b>'+prefix+'</b>: ' + value + div2; 
        } else {
            if( milestone!=undefined && milestone!='' )
                return div1 + '<b>'+value+'</b>' + div2;
            else
                return div1 + value + div2;
        }
    };

    Baseliner.levRenderer = function(value,metadata,rec,rowIndex,colIndex,store) {
        var icon;
        if( value=='debug' ) icon='log_d.gif';
        else if( value=='info' ) icon='log_i.gif';
        else if( value=='warning' || value=='warn' ) icon='log_w.gif';
        else if( value=='error' ) icon='log_e.gif';
        else if( value=='comment' ) icon='post.gif';
        if( icon!=undefined ) {
            return "<img alt='"+value+"' border=0 src='/static/images/"+icon+"' />" ;
        } else {
            return value;
        }
    };
    Baseliner.logColorRenderer = function(value,metadata,rec,rowIndex,colIndex,store) {
           metadata.attr += " style='background-color:#222299;' ";
    };
    var render_job_exec = function(value,metadata,rec,rowIndex,colIndex,store) {
        var exec = rec.data.exec;
        return value + ' ('+exec+')';
    };
    var render_task = function(value,metadata,rec,rowIndex,colIndex,store) {
        if(!value) value= _('Core'); //'\u2205'; //_('Core');
        return '<b>'+value+'</b>';
    };
    var onemeg = 1024 * 1024;

    //------------ Download Icons
    Baseliner.actionsRenderer = function(value,metadata,rec,rowIndex,colIndex,store) {
           var ret="";
           var xdatalen = rec.data.datalen;
           var datalen='';
           if( xdatalen > 4096 ) {
                  if( xdatalen >= onemeg ) {
                   datalen = Math.round( (xdatalen/onemeg) * 10) / 10;
                   datalen += 'MB';
               } else {
                   datalen = Math.round( (xdatalen/1024) * 10) / 10;
                   datalen += 'KB';
               }
           }
           if( value.more=='jes' ) {
             ret += "<a href='#' onclick='javascript:Baseliner.addNewTabComp(\"/job/log/jesSpool?id=" + rec.data.id + "&jobId=" + rec.data.mid + "&jobName=" + rec.data.job +"\"); return false;'><img border=0 src='/static/images/host.gif'/></a> " ;
//           if( value.more=='jes' ) {
//               ret += "<a href='#' onclick='javascript:Baseliner.addNewTabComp(\"/job/log/jesSpool?id=" + rec.data.id + "&job=" + rec.data.job +"\");'><img border=0 src='/static/images/mainframe.png' /></a> ";
           } else if( value.more=='link'  ) {
               ret += String.format("<a href='{0}' target='_blank'><img src='/static/images/icons/link.gif'</a>", rec.data.data );
           } else if( value.more!='' && value.more!=undefined && value.data ) {
               var img;
               if( value.more=='zip' ) {
                  img = '/static/images/icons/mime/file_extension_zip.png';
               } else {
                  img = '/static/images/download.gif';
           } 
               ret += "<a href='/job/log/download_data?id=" + rec.data.id + "' target='FrameDownload'><img border=0 src="+img+" /></a> " + datalen ;
           } else {
               if( value.more!='file' && value.data && xdatalen < 250000 ) {  // 250Ks max
                   var data_name = value.data_name;
                   if( data_name==undefined || data_name.length<1 ) {
                       data_name = "Log Data " + rec.data.id;
                   }
                   ret += "<a href='#' onclick='javascript:Baseliner.addNewTabSearch(\"/job/log/data?id=" + rec.data.id + "\",\""+data_name+"\"); return false;'><img border=0 src='/static/images/moredata.gif'/></a> " + datalen ;
               }
               else if( value.file!=undefined && value.file!='' && value.data ) { // alternative file
                   ret += "<a href='/job/log/highlight/" + rec.data.id + "' target='_blank'><img border=0 src='/static/images/silk/page_new.gif'></a> "
                   ret += "&nbsp;<a href='/job/log/download_data?id=" + rec.data.id + "&file_name=" + value.file + "' target='FrameDownload'><img border=0 src='/static/images/download.gif'/></a> " + datalen ;
               } 
           }
           return ret;
    };

    //------ Job exec list
    var exec_left  = function() {
        var je = store.baseParams.job_exec || job_exec;
        je--;
        if( je < 1 ) return;
        store.baseParams.job_exec = je;
        store_load({ anim:'l' });
    };
    var exec_right = function() {
        var je = store.baseParams.job_exec || job_exec;
        je++;
        store.baseParams.job_exec = je;
        store_load({ anim:'r' });
    };

    var menu_exec_change = function(item,checked) {
        if( checked ) {
            store.baseParams.job_exec = item.value;
            store_load({ anim:'f' });
        }
    };
    var menu_exec_list = [];
    for( var exec=1; exec <= job_exec ; exec++ ) {
        menu_exec_list.push({ text: exec, value: exec, checked: (exec==job_exec?true:false), group: 'exec', checkHandler: menu_exec_change });
    }
    var menu_exec = new Ext.Toolbar.Button({ text : _('Execution %1/%2', job_exec, job_exec_max), menu: { items: menu_exec_list } });
    var menu_exec_left  = new Ext.Toolbar.Button({ icon: '/static/images/icons/arrow_left.gif', cls: 'x-btn-text-icon', handler: exec_left  });
    var menu_exec_right = new Ext.Toolbar.Button({ icon: '/static/images/icons/arrow_right.gif', cls: 'x-btn-text-icon', handler: exec_right  });
    var menu_exec_review = function() {
        if( job_exec <= 1 ) menu_exec_left.disable();
           else menu_exec_left.enable();
        if( job_exec >= job_exec_max ) menu_exec_right.disable();
           else menu_exec_right.enable();
        if( job_exec_max > 1 ) 
            menu_exec.setText( '<b>' +  _('Execution %1/%2', job_exec, job_exec_max) + '</b>' );
        else 
            menu_exec.setText( _('Execution', job_exec ) );
    }

    //--- Resume from Suspend, Pause
    var button_resume = new Ext.Toolbar.Button({ text : _('Resume Job'), icon: '/static/images/icons/play.png', cls: 'x-btn-text-icon', hidden: true,
        handler: function(){
            Baseliner.ajaxEval( '/job/resume', { mid: current_job().mid, confirm: _('Do you wish to resume job %1',current_job().job_name) }, function(res) {
                Baseliner.message( _('Resume Job'), res.msg );
            });
        } 
    });

    var button_html = new Ext.Toolbar.Button({ icon: '/static/images/icons/html.gif',
        style: 'width: 30px', cls: 'x-btn-icon', hidden: false,
        handler: function(){
            var par = '';
            par += '&job_exec=' + job_exec;
            var hash = current_hash();
            var win_opener = function( key ) {
                    var win = window.open( '/job/log/html/' + key );
                    if( win == null || typeof(win)=='undefined' ) {
                        Baseliner.error( _('Warning'), _('Your browser is blocking pop-up windows. Turn if off to see the log.') );
                    }
            };
            if( hash != undefined ) {
                win_opener( hash + '?' + par  );
            } else {
                Baseliner.ajaxEval('/job/log/gen_job_key', { mid : mid }, function( res ) {
                    if( ! res.success ) { Baseliner.error( _('Error'), res.msg ); return; }
                    win_opener( res.job_key + '?' + par);
                });
            }
        } 
    });

    var menu_delete = { text : _('Delete Log'), icon: '/static/images/icons/delete.gif', cls: 'x-btn-text-icon', hidden: false,
        handler: function(){
            Baseliner.ajaxEval( '/job/log/delete', { mid: current_job().mid, job_exec: job_exec,
                confirm: _('Do you wish to delete all log data for job %1, exec %2?',current_job().mid, job_exec) }, function(res) {
                    Baseliner.message( _('Delete Log'), res.msg );
            });
        } 
    };

    var menu_stash = { text : _('View Stash'), icon: '/static/images/icons/stash.gif', cls: 'x-btn-text-icon', hidden: false,
        handler: function(){
                    var mid = current_job().mid;
                    Baseliner.add_tabcomp( "/comp/job_stash.js", _("Job Stash %1", mid ), { mid: mid } );
                 }
    };

    var menu_logfile = { text : _('View Logfile'), icon: '/static/images/icons/page.gif', cls: 'x-btn-text-icon', hidden: false,
        handler: function(){
                    var mid = current_job().mid;
                    Baseliner.add_tabcomp( "/comp/job_logfile.js", _("Logfile %1", mid ), { mid: mid } );
                 }
    };

    var button_cancel = new Ext.Toolbar.Button({ text : _('Resume Job'), icon: '/static/images/icons/play.png', cls: 'x-btn-text-icon', hidden: true,
        handler: function(){
            Baseliner.ajaxEval( '/job/resume', { mid: current_job().mid, confirm: _('Do you wish to resume job %1',current_job().job_name) }, function(res) {
                Baseliner.message( _('Resume Job'), res.msg );
            });
        } 
    });
    
    var gview = new Ext.grid.GroupingView({
        forceFit: true,
        enableRowBody: true,
        enableGrouping: true,
        autoWidth: true,
        autoSizeColumns: true,
        deferredRender: true,
        startCollapsed: false,
        //groupTextTpl: '{[ values.rs[0].data[grouping] || _("General") ]}',
        hideGroupedColumn: true
    });

    var row_sel = new Ext.grid.RowSelectionModel({singleSelect:true});
        // create the grid
        var grid = new Ext.grid.EditorGridPanel({
            title: _('Job Log'),
            header: false,
            /* stripeRows: true, */
            autoScroll: true,
            autoWidth: true,
            autoSizeColumns: true,
            deferredRender: true,
            clicksToEdit: 'auto',
            store: store,
            view: gview,
            viewConfig: {
                scrollOffset: 2,
                forceFit: true
            },
            selModel: row_sel, 
            loadMask: true,
            wait: _('Loading...'),
            columns: [
                { header: _('Job'), width: 120, dataIndex: 'job', sortable: true, hidden: true, renderer: render_job_exec },   
                { header: _('Step'), width: 40, dataIndex: 'step', sortable: true },
                { header: _('Execution'), width: 60, dataIndex: 'exec', sortable: true, hidden: true },
                { header: _('Level'), width: 30, dataIndex: 'lev', renderer: Baseliner.levRenderer, sortable: true },
                { header: _('Timestamp'), width: 100, dataIndex: 'ts', sortable: true }, 
                { header: _('Task'), width: 120, id:'service_key', dataIndex: 'service_key', sortable: true, hidden: false, renderer: render_task },
                { header: _('Message'), width: 450, dataIndex: 'text', sortable: true, cls: 'nowrapgrid', renderer: render_msg  },
                { header: _('Namespace'), width: 100, dataIndex: 'ns', sortable: true, hidden: true },   
                { header: _('Provider'), width: 100, dataIndex: 'provider', sortable: true, hidden: true },
                { header: _('Module'), width: 280, id: 'module', dataIndex: 'module', sortable: true, hidden: true, editor: new Ext.form.TextArea() },
                { header: _('Milestone'), width: 40, id: 'milestone', dataIndex: 'milestone', sortable: true, hidden: true },
                { header: _('Log Id'), width: 80, dataIndex: 'id', sortable: true, hidden: true },
                { header: _('Actions'), width: 100, dataIndex: 'more', renderer: Baseliner.actionsRenderer, sortable: true } 
            ],
            bbar: new Ext.PagingToolbar({
                                store: store,
                                pageSize: ps,
                                displayInfo: true,
                                displayMsg: _('Rows {0} - {1} of {2}'),
                                emptyMsg: "No hay registros disponibles"
                        }),        
            tbar: [ _('Search') + ': ', ' ',
                new Ext.app.SearchField({
                    store: store,
                    params: {start: 0, limit: ps, mid: '<% $mid %>' },
                    emptyText: _('<Enter your search string>')
                }),
                button_html,
                { text: _('Level'), menu: filter_menu },
                menu_exec_left,
                menu_exec,
                menu_exec_right,
                {
                    text: _('Annotate'),
                    icon: '/static/images/icons/post.gif', 
                    cls: 'x-btn-text-icon',
                    handler: annotation
                },
% if( $user_action->{'action.admin.default'} ) {
                button_resume,
                new Ext.Toolbar.Button({ 
                    text: _('Advanced'),
                    icon: '/static/images/icons/advanced.png', 
                    cls: 'x-btn-text-icon',
                    menu: { 
                        items: [ menu_stash, menu_delete, menu_logfile ]
                    }
                }),
% }
<%doc>
                new Ext.Toolbar.Button({
                    text: _('View Log'),
                    icon:'/static/ext/resources/images/default/dd/drop-yes.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        Baseliner.addNewTab('/job/log/list', _('Job Log') );
                    }
                }),
</%doc>
                '->',
                button_autorefresh
                ],
                tab_icon: '/static/images/icons/moredata.gif'
        });

    grid.on("rowdblclick", function(grid, rowIndex, e ) {
        var r = grid.getStore().getAt(rowIndex);
        Ext.Ajax.request({
            url: '/job/log/data',
            params: { id: r.get('id') },
            success: function(xhr) {
                var msg = xhr.responseText;
                var title = r.get('text');
                if( msg == undefined || msg.length < 15 ) { //usually msg has a <pre> tag
                    msg = '<pre>' + title;
                    title = r.get('job') + " - Log ID " + r.get('id');
                }
                var win = new Ext.Window({ layout: 'fit', 
                    autoScroll: true,
                    maximizable: true,
                    style: 'white-space: pre-wrap; white-space: -moz-pre-wrap; word-wrap: break-word;',
                    title: title,
                    height: 600, width: 700, 
                    html: msg
                });
                win.show();
            },
            failure: function(xhr) {
                var win = new Ext.Window({ layout: 'fit', 
                    autoScroll: true, title: 'Error', 
                    height: 600, width: 700, 
                    html: 'Server communication failure:' + xhr.responseText });
                win.show();
            }
        });
        //Baseliner.addNewTabComp('/job/log/list?mid=' + r.get('id') , '<% _loc('Log') %>' + r.get('name') );
    });		

    //Scroll to bottom when the store reloads
    store.on('load', function(){
        if( mid != "" ) {
            grid.view.scroller.scroll('down', 9999999999999, true);
        }
        var job = current_job();
        if( job != undefined ) {
            if( job.status == 'PAUSED' || job.status == 'SUSPENDED' || job.status == 'WAITING' ) {
                button_resume.show();
            }
            job_exec_max = job.exec;
            job_exec = store.baseParams.job_exec || job_exec;
            menu_exec_review();
        }
    });   
    
    // Yellow row selection
    row_sel.on('rowselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).addClass('x-grid3-row-selected-white');
    });
    row_sel.on('rowdeselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).removeClass('x-grid3-row-selected-white');
    });


    var first_time = true;
    grid.on('activate', function(){
        if( first_time ) {
            Baseliner.showLoadingMask( grid.getEl() , _('Loading...') );
            first_time = false;
            if( annotate_now ) {
                annotation();
            }
        }
    });

    grid.on('destroy', function(){
        autorefresh.stop(task);
    });

   grid.getView().getRowClass = function(rec, index){
        var css = '';
        if( rec.data.lev == 'debug' ) 
            css = index % 2 > 0 ? 'level-row debug-odd' : 'level-row debug-even' ;
        else if( rec.data.lev == 'error' )  
            css = index % 2 > 0 ? 'level-row error-odd' : 'level-row error-even' ;
        else if( rec.data.lev == 'warn' )  
            css = index % 2 > 0 ? 'level-row warn-odd' : 'level-row warn-even' ;
        else
            css = index % 2 > 0 ? 'level-row info-odd' : 'level-row info-even' ;

        return css;
    }; 
        
    //Ext.getCmp('main-panel').setActiveTab( Ext.getCmp('main-panel').add(grid) ) ;

    store_load();
    return grid;
})();


