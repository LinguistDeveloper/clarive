<%args>
  $natures_json    => $ARGS{natures_json} 
  $job_states_json => $ARGS{job_states_json}
  $envs_json       => $ARGS{envs_json}
  $types_json      => $ARGS{types_json}
  $query_id        => '-1'
</%args>
<%perl>
    my $iid = Util->_md5;
    use Baseliner::Sugar;
    my $view_natures = config_value('job_new.view_natures');
</%perl>
(function(params){
    if( !params ) params = {};
    var view_natures = <% $view_natures ? 'false' : 'true' %>; 
    var state_id = 'job-monitor';
   
    // -- ADDING Arr.map() method --
    // Production steps of ECMA-262, Edition 5, 15.4.4.19
    // Reference: http://es5.github.com/#x15.4.4.19
    if (!Array.prototype.map) {
      Array.prototype.map = function(callback, thisArg) {
    
        var T, A, k;
    
        if (this == null) {
          throw new TypeError(" this is null or not defined");
        }
    
        // 1. Let O be the result of calling ToObject passing the |this| value as the argument.
        var O = Object(this);
    
        // 2. Let lenValue be the result of calling the Get internal method of O with the argument "length".
        // 3. Let len be ToUint32(lenValue).
        var len = O.length >>> 0;
    
        // 4. If IsCallable(callback) is false, throw a TypeError exception.
        // See: http://es5.github.com/#x9.11
        if ({}.toString.call(callback) != "[object Function]") {
          throw new TypeError(callback + " is not a function");
        }
    
        // 5. If thisArg was supplied, let T be thisArg; else let T be undefined.
        if (thisArg) {
          T = thisArg;
        }
    
        // 6. Let A be a new array created as if by the expression new Array(len) where Array is
        // the standard built-in constructor with that name and len is the value of len.
        A = new Array(len);
    
        // 7. Let k be 0
        k = 0;
    
        // 8. Repeat, while k < len
        while(k < len) {
    
          var kValue, mappedValue;
    
          // a. Let Pk be ToString(k).
          //   This is implicit for LHS operands of the in operator
          // b. Let kPresent be the result of calling the HasProperty internal method of O with argument Pk.
          //   This step can be combined with c
          // c. If kPresent is true, then
          if (k in O) {
    
            // i. Let kValue be the result of calling the Get internal method of O with argument Pk.
            kValue = O[ k ];
    
            // ii. Let mappedValue be the result of calling the Call internal method of callback
            // with T as the this value and argument list containing kValue, k, and O.
            mappedValue = callback.call(T, kValue, k, O);
    
            // iii. Call the DefineOwnProperty internal method of A with arguments
            // Pk, Property Descriptor {Value: mappedValue, Writable: true, Enumerable: true, Configurable: true},
            // and false.
    
            // In browsers that support Object.defineProperty, use the following:
            // Object.defineProperty(A, Pk, { value: mappedValue, writable: true, enumerable: true, configurable: true });
    
            // For best browser support, use the following:
            A[ k ] = mappedValue;
          }
          // d. Increase k by 1.
          k++;
        }
    
        // 9. return A
        return A;
      };      
    }
    // -- END --
    
    var is_portlet = '<% $c->stash->{is_portlet} %>';
    var ps = is_portlet ? 10 : 25; //page_size
    var last_magic = 0;
    var real_top;
    var div1   = '<div style="white-space:normal !important;">';
    var div2   = '</div>';
    // La fuente de Datos JSON con todos el listado:
    var reader = new Ext.data.JsonReader({
        root: 'data' , 
        remoteSort: true,
        totalProperty:"totalCount", 
        id: 'id'
        }, 
        [ 
            {  name: 'id' },
            {  name: 'mid' },
            {  name: 'name' },
            {  name: 'type_raw' },
            {  name: 'type' },
            {  name: 'bl' },
            {  name: 'bl_text' },
            {  name: 'job_key' },
            {  name: 'starttime' },
            {  name: 'pre_start' },
            {  name: 'pre_end' },
            {  name: 'run_start' },
            {  name: 'run_end' },
            {  name: 'schedtime' },
            {  name: 'last_log' },
            {  name: 'contents' },
            {  name: 'changesets' },
            {  name: 'changeset_cis' },
            {  name: 'cs_comments' },
            {  name: 'releases' },
            {  name: 'applications' },
            {  name: 'maxstarttime' },
            {  name: 'approval_expiration' },
            {  name: 'endtime' },
            {  name: 'runner' },
            {  name: 'id_rule' },
            {  name: 'rule_name' },
            {  name: 'rollback' },
            {  name: 'has_errors' },
            {  name: 'has_warnings' },
            {  name: 'username' },
            {  name: 'step' },
            {  name: 'step_code' },
            {  name: 'exec' },
            {  name: 'pid' },
            {  name: 'host' },
            {  name: 'owner' },
            {  name: 'comments' },
            {  name: 'when' },
            {  name: 'ago' },
            {  name: 'day' },
            {  name: 'status_code' },
            {  name: 'status' },
            {  name: 'natures' }, 
            {  name: 'subapps' },
            {  name: 'can_restart' },
            {  name: 'can_cancel' },
            {  name: 'can_delete' }
        ]
    );

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
        var cfg = grid.getColumnModel().config;
        
        if( !args.store_data ) { 
            var row=0, col=0;
            var gv = grid.getView();
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
            grid.store.each( function(rec) {
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
        form.findField('title').setValue( _('Monitor') );
        form.findField('rows').setValue( grid.store.getCount() );
        form.findField('total_rows').setValue( grid.store.getTotalCount() );
        var el = form.getEl().dom;
        var target = document.createAttribute("target");
        target.nodeValue = args.target || "_blank";
        el.setAttributeNode(target);
        el.action = args.url;
        el.submit(); 
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
        menu: [ btn_csv ]
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

    // Nature Filters

    var natures = <% $natures_json %>;
    
    
    var nature_hash = {}; // this is used by the render_nature
    Ext.each( natures, function(nat) {
        nature_hash[ nat.ns ] = nat; 
    });
    
            
    var nature_menu = [{
          text: _('All-f'),
          handler: function (item) {
            item.parentMenu.ownerCt.setText('');
            delete store.baseParams.filter_nature;
            store.reload();
          }
      },'-'
    ];
    nature_menu.push( natures.map(function (x) {

      // Por defecto siempre se van a mostrar en uppercase, pero tampoco est￡ de m￡s filtrar un poco esto.
      var nature_name = x.name == 'ZOS'      ? 'z/OS' 
                      : x.name == 'FICHEROS' ? 'Ficheros'
                      : x.name == 'TODAS'    ? 'Todas'
                      : x.name
                      ;
      return {
        text: nature_name,
        //icon: '/static/images/nature/' + x.icon + '.png',
        handler: function (item) { 
          item.parentMenu.ownerCt.setText( '<b>' + _('Natures: %1',  nature_name) + '</b>' );
          //store.baseParams.filter_nature = x.ns ;
          store.baseParams.filter_nature = x.id ;
          store.reload();
          return;
        }
      }
    }));
    
    var nature_menu_btn = new Ext.Button({
      //text: _('Natures'),
      icon: '/static/images/nature/nature.png',
      menu: nature_menu
    });

    // Job Status Filter

    var job_states_json = <% $job_states_json %>;
    
    //var job_states_check_state = {
    //  CANCELLED: true,
    //  ERROR: true,
    //  EXPIRED: true,
    //  FINISHED: true,
    //  KILLED: true,
    //  RUNNING: true,
    //  WAITING: true,
    //};
    
    var job_states_check_state = {};
    for (i=0; i<job_states_json.length;i++){
        job_states_check_state[job_states_json[i].name] = true;
    }

    var to_perl_bool = function (obj) { // Object -> Object
      // Converts Javascript booleans to Perl's C-like notation. Just in case. 
      var ret = obj;
      for (property in ret) {
        ret[property] = ret[property] ? 1 : 0;
      }
      return ret;
    };
    var modify_job_states_check_state = function (name) {
      if (job_states_check_state[name] == true) {
        job_states_check_state[name] = false;
      }
      else {
        job_states_check_state[name] = true;
      }
      return;
    };
    var item_job_states = [
        {  text: _('All'), hideOnClick:false, handler: function(){ 
              menu_job_states.items.each( function(i){
                  if( i.checked===false ) i.setChecked(true,false);
              });
        }},
        {  text: _('Check None'), hideOnClick:false, handler: function(){ 
              menu_job_states.items.each( function(i){
                  if( i.checked===true ) i.setChecked(false,false);
              });
        }},
        '-'
    ];
    item_job_states.push(  
        job_states_json
            .map(function (x) {
              return {
                  id_status: x.name,
                  text: _(x.name),
                  checked: job_states_check_state[x.name],
                  hideOnClick:false,
                  checkHandler: function (obj) {
                      modify_job_states_check_state(obj.id_status);
                      //item.parentMenu.ownerCt.setText( '<b>' + status_count + '</b>' );
                      store.baseParams.job_state_filter = Ext.util.JSON.encode(to_perl_bool(job_states_check_state));
                      store.reload();
                  }
              }
            })
            .sort(function(a,b){ 
                if(a.text== b.text) return 0;
                return a.text > b.text? 1: -1;
            })
    );
    var menu_job_states = new Ext.menu.Menu({
      items: item_job_states
    });

    // Baseline Filter

    var menu_list = [];
    menu_list.push({
      text: _('All'),
      handler: function (item) {
        item.parentMenu.ownerCt.setText('');
        delete store.baseParams.filter_bl;
        store.reload();
      }
    },'-');
    menu_list.push( <%$envs_json%>.map(function (x) {
          return {
            text: String.format('{0}: {1}', x.bl, x.name ),
            icon: '/static/images/icons/baseline.gif',
            handler: function (item) {
              item.parentMenu.ownerCt.setText( '<b>' + _('Baseline: %1',  x.bl ) + '</b>' );
              store.baseParams.filter_bl = x.bl;
              store.reload();
            }
          };
        })
    );
    var menu_bl = new Ext.Button({
      //text: _("Baseline"),
      icon: '/static/images/icons/baseline.gif',
      menu: menu_list
    });

    // Job Type filter

    var menu_type_filter = new Ext.Button({
      text: _('Type'),
      menu: [
          {
            text: _('All'),
            handler: function (item) {
               item.parentMenu.ownerCt.setText( _('Type') );
               delete store.baseParams.filter_type;
               store.reload();
            }
          },
          '-',
          {
            text: _('promote'),
            icon: '/static/images/icons/arrow_right.gif',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( '<b>' + _('Type: %1', _('promote')) + '</b>' );
               store.baseParams.filter_type = 'promote';
               store.reload();
            }
          },{
            text: _('demote'),
            icon: '/static/images/icons/arrow_left.gif',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( '<b>' + _('Type: %1', _('demote')) + '</b>' );
               store.baseParams.filter_type = 'demote';
               store.reload();
            }
          },{
            text: _('static'),
            //icon: '/static/images/icons/arrow_left.gif',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( '<b>' + _('Type: %1', _('static')) + '</b>' );
               store.baseParams.filter_type = 'static';
               store.reload();
            }            
          }
      ]
    });
    // end

    var store = new Baseliner.GroupingStore({
            reader: reader,
            url: '/job/monitor_json',
            baseParams: { limit: ps, query_id: '<% $query_id %>', query: params.query },
            remoteSort: true,
            remoteGroup: true,
            //groupField: 'when',
            sortInfo: { field: 'starttime', direction: "DESC" }
    });
    
    // var paging = new Ext.PagingToolbar({
    //         store: store,
    //         pageSize: ps,
    //         displayInfo: true,
    //         displayMsg: _('Rows {0} - {1} of {2}'),
    //         emptyMsg: "No hay registros disponibles"
    // });
    //paging.on('beforechange', function(){ refresh_stop(); });
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
                    paging.afterTextItem.hide();
                } else {
                    paging.afterTextItem.show();
                }
            }
        },
        forceSelection: true
    });

    var paging = new Ext.PagingToolbar({
            store: store,
            pageSize: ps,
            plugins:[
                ps_plugin,
                new Ext.ux.ProgressBarPager()
            ],
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: _('There are no rows available')
    });
    var next_start = 0;
    store.on('load', function(s,recs,opt) {
        //console.log( s );
        next_start = s.reader.jsonData.next_start;
        //store.baseParams.next_start = next_start;
        //alert(next_start);
    });

    paging.on("beforechange", function(p,opts) {
        opts.next_start = next_start;
    });

    <& /comp/search_field.mas &>
    var search_field = new Ext.app.SearchField({
        store: store,
        params: {start: 0, limit: ps},
        emptyText: _('<Enter your search string>')
    });
    //---------- Refreshments
    var task_interval_base = 5000;  // start with 5 seconds and grow from there
    var task_interval_increment = 500;  // grow .5 sec slower 
    var task_interval_max = 30000;  // max 30 sec refresh 
    var task_interval = task_interval_base;
    var task = {
        run: function() {
            var ids=[];
            var top_id=0;
            //var q = store.baseParams['query']; //current search query 
            //if( q != undefined && q !='' ) { return; } //no refresh while querying
            refresh_button_wait_on();
            var flag_running = false;
            store.each( function(rec) {
                var id = rec.data.mid;
                if( parseInt(id) > parseInt( top_id ) ) {
                    top_id = id;
                }
                ids.push(id);
                // anything live and running?
                if( rec.data.status_code == 'RUNNING' ) {
                    flag_running = true;
                }
            });
            var last_interval = task_interval;
            if( flag_running ) {
                task_interval = task_interval_base;
            } else {
                task_interval = task_interval < task_interval_max ? task_interval+task_interval_increment : task_interval_max;
            }
            
            var swRefresh = true;
            
            if(Ext.getCmp('main-panel').getActiveTab().title != 'Monitor' && Ext.isIE8 ){
                swRefresh = false;
            }
            
            if(swRefresh){
                var filter = store.baseParams || {};
                // send from and where, to determine if there's a more recent job
                Baseliner.ajax_json( '/job/refresh_now',
                    { ids: ids, filter: filter, top: top_id, real_top: real_top, last_magic: last_magic, _ignore_conn_errors: true  }, function(res) {
                    refresh_button_wait_off();
                    if( ! res.success ) {
                        refresh_stop();
                    } else {
                        if( res.need_refresh  ) {
                            store.reload();
                        }
                        last_magic = res.magic;
                        real_top = res.real_top;
                    }
                });                
            }
            
            if( last_interval != task_interval ) {
                autorefresh.stop(task);
                task.interval = task_interval;
                autorefresh.start(task);
            }
            return true;
        },
        interval: task_interval
    };
    var autorefresh = new Ext.util.TaskRunner();
    var refresh_button_wait_on = function() { refresh_button.getEl().setOpacity( .3 ); };
    var refresh_button_wait_off = function() { refresh_button.getEl().setOpacity( 1 ); };
    var refresh_button = new Ext.Button({ text: _('Auto Refresh'),
        icon: '/static/images/icons/time.gif', 
        enableToggle: true,
        pressed: false,
        cls: 'x-btn-text-icon',
        handler: function(t) {
            if( t.pressed ) {
                autorefresh.start(task);
            } else {
                autorefresh.stop(task);
            }
        }
    });
    var refresh_stop = function() {
        refresh_button.toggle(false);
        autorefresh.stop(task);
    };

    Baseliner.trap_check = function(mid){
        var trap_win;
        var trap_do = function(mid,action){
            trap_win.close();
            Ext.Msg.prompt(_('Comment'), _('Comment'), function(btn,text){
                if( btn=='cancel') return ;
                Baseliner.ci_call( mid, 'trap_action',  { action: action, comments: text }, function(res){
                    if( res.success ) {
                        grid.getStore().reload();
                    } else {
                        Ext.Msg.alert( _('Error'), _('Could not %2 the job: %1', res.msg, action ) );
                    }
                });
            }, this, 300, '');
        };
        trap_win = new Baseliner.Window({
            title: _('Error trapped'),
            width: 400, height: 350,
            padding: 5,
            modal: true,
            border: false,
            layout: 'vbox',
            layoutConfig: { align:'stretch' },
            items: [
                { flex:1, layout:'hbox', padding: 20, 
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Retry')+'</b>', icon:'/static/images/icons/refresh.gif', 
                        handler:function(){trap_do(mid,'retry')} },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('Retries the job task that failed') }]},
                { flex:1, layout:'hbox', padding: 20, 
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Skip')+'</b>', icon:'/static/images/icons/skip.png', 
                        handler:function(){trap_do(mid,'skip')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('Skips the job task that failed, ignoring the error') }]},
                { flex:1, layout:'hbox', padding: 20, 
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Abort')+'</b>', icon:'/static/images/icons/delete.gif', 
                        handler:function(){trap_do(mid,'abort')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('The task will fail') }]},
                { flex:1, layout:'hbox', padding: 20, 
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Pause')+'</b>', icon:'/static/images/icons/paused.png', 
                        handler:function(){trap_do(mid,'pause')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('The trap timeout countdown will be paused') }]}
            ]
        });
        trap_win.show();
    }
                
    var button_html = new Ext.Toolbar.Button({ icon: '/static/images/icons/html.gif',
        style: 'width: 30px', cls: 'x-btn-icon', hidden: false,
        handler: function(){
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var win_opener = function( key ) {
                    var win = window.open( '/job/log/html/' + key );
                    if( win == null || typeof(win)=='undefined' ) {
                        Baseliner.error( _('Warning'), _('Your browser is blocking pop-up windows. Turn if off to see the log.') );
                    }
            };
            if( sel != undefined ) {
                if( sel.data.job_key ) {
                    win_opener( sel.data.job_key );
                } else {
                    Baseliner.ci_call( sel.data.mid, 'gen_job_key', {}, function( res ) {
                        win_opener( res.job_key );
                    });
                }
            }
        } 
    });

    var run_inproc = function(){
        var sm = grid.getSelectionModel();
        var sel = sm.getSelected();
        if( sel ) {
            var cons_inproc = new Baseliner.MonoTextArea({ value:'' });
            var cons_pan = new Ext.Panel({ layout:'fit', items: cons_inproc, wait: _('Loading...') });
            var win = new Baseliner.Window({ title:_('Run In-process: %1', sel.data.name), 
                layout: 'fit', width: 800, height: 600, items: cons_pan });
            cons_inproc.on('afterrender', function(){ 
                Baseliner.showLoadingMask( cons_pan.el );
                Baseliner.ci_call( sel.data.mid, 'run_inproc', { mid: sel.data.mid }, function(res){
                    Baseliner.message( _('Run In-Process'), _('Job %1 in-process run finished', sel.data.name ) );
                    if( !Ext.getCmp(cons_pan.id) ) return;
                    if( !Ext.getCmp(cons_inproc.id) ) return;
                    cons_inproc.setValue( res ? res.output : _('(no data)') );
                    Baseliner.hideLoadingMask( cons_pan.el );
                    if( grid ) {
                        var st =grid.getStore();
                        if( st ) st.reload();
                    }
                }, function(){
                    Baseliner.hideLoadingMask( cons_pan.el );
                });
            });
            win.show();
        }
    }
    var menu_tools = new Ext.Button({
      tooltip: _('Tools'),
      icon: '/static/images/icons/wrench.png',
      menu: [
% if( model->Permissions->user_has_action(username=>$c->username, action=>'action.job.run_in_proc') ) {
            { text: _('Run In-process'), handler:function(){ run_inproc() },
              icon: '/static/images/icons/job.png'
            },
% }
            {
                text: _('Export'),
                icon:'/static/images/download.gif',
                handler: function() {
                    var sm = grid.getSelectionModel();
                    if (sm.hasSelection())
                    {
                        var sel = sm.getSelected();
                        Baseliner.message( _('Job Export'), _('Job export started. Wait a few minutes...') );
                        var fd = document.all.FD || document.all.FrameDownload;
                        fd.src =  '/job/export?mid=' + sel.data.mid ;
                    } else {
                        Ext.Msg.alert(_('Error'), _('Select a row first'));   
                    };
                }
            }
      ]
    });

    var do_backout = function(){
        var sm = grid.getSelectionModel();
        var sel = sm.getSelected();
        if( sel ) {
            Ext.Msg.confirm(_('Confirmation'),  '<b>' + sel.data.name + '</b>: ' + _('Are you sure you want to rollback the job?'), 
                function(btn){ 
                    if(btn=='yes') {
                        Baseliner.ajaxEval('/job/rollback', sel.data, function(res){
                                Baseliner.message( _('Rollback'), res.msg ) ;
                                grid.getStore().reload();
                            }, function(res){
                                var deps = Ext.isArray(res.deps) ? res.deps.map(function(r){ return { job: r } }) : [];
                                // TODO use an extjs Grid with links that open the job dashboard for each, and cols for Project and BL
                                var msg = function(){/*
                                      <div id="boot">
                                      <div class="container_24"> 
                                        <div class="grid_24">
                                        <h4>
                                            <img src="/static/images/warnmsg.png" style="vertical-align:middle">
                                            [%= msg %]
                                        </h4>
                                        </div>
                                        <div class="clear"></div>
                                        <div class="grid_4">&nbsp;</div>
                                        <div class="grid_8">
                                          <table class="table" >
                                          [% Ext.each(deps,function(job){ %]
                                              <tr>
                                                  <td style="font-weight: bold">
                                                    [%= job.name %]
                                                  </td>
                                                  <td>
                                                    [%= job.bl %]
                                                  </td>
                                                  <td>
                                                    [%= job.projects.map(function(p){ return p.name }) %]
                                                  </td>
                                              </tr>
                                          [% }); %]
                                        </div>
                                      </div>
                                      </div>
                                */}.tmpl({ msg: res.msg, deps: res.deps });
                                var win = new Baseliner.Window({
                                    width: 800, height: 400, layout:'fit', //layout:'vbox', layoutConfig: { align:'stretch' },
                                    title: _('Dependencies'), 
                                    items: [
                                        { xtype:'panel', autoScroll: true, padding: 20, html: msg }
                                    ]
                                });
                                win.show();
                                //Baseliner.message( _('Rollback'), res.msg ) ;
                            }
                        );
                    }
                }
            );
        }
    };
    
    Baseliner.resume_job = function(mid,name) {
        Ext.Msg.confirm(_('Confirmation'),  '<b>' + name + '</b>: ' + _('Are you sure you want to resume the job?'), 
            function(btn){ 
                if(btn=='yes') {
                    Baseliner.ci_call( mid, 'resume',  {}, function(res){
                        if( !res.msg ) { 
                            grid.getStore().reload();
                            Baseliner.message( _('Success'), res.data );
                        } else {
                            grid.getStore().reload();
                            Ext.Msg.alert( _('Error'), _('Could not resume the job: %1', res.msg ) );
                        }
                    });
                }
            }
        );
    };

    // TODO this button is deprecated, remove it after a month from this commit
    var button_resume = new Ext.Toolbar.Button({
        text: _('Resume'),
        hidden: true,
        icon:'/static/images/icons/play.png',
        cls: 'x-btn-text-icon',
        handler: function(){
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var mode;
            if( sel.data.status_code == 'PAUSED' ) {
                Baseliner.resume_job(sel.data.mid,sel.data.name);
                button_resume.hide();
            }
            else if( sel.data.status_code == 'TRAPPED' || sel.data.status_code == 'TRAPPED_PAUSED' ) {
                Baseliner.trap_check(sel.data.mid);
                button_resume.hide();
            }
        }
    });
    
    var msg_cancel_delete = [ _('Cancel'), _('Delete') ];
    var button_cancel = new Ext.Toolbar.Button({
        text: msg_cancel_delete[0],
        icon:'/static/images/del.gif',
        disabled: true,
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var sc = sel.data.status_code;
            var mode;
            if( sc == 'RUNNING' ) {
                msg = _('Killing the job will interrupt current local processing but no remote processes');
                msg += "\n" + _('Are you sure you want to %1 the job?', _('kill') );
                mode = 'kill';
            } else if( sc == 'FINISHED' || sc == 'ERROR' || sc == 'CANCELLED' ) {
                msg = _('Are you sure you want to %1 the job?', _('delete') );
                mode = 'delete';
            } else {
                msg = _('Are you sure you want to %1 the job?', _('cancel') );
                mode = 'cancel';
            }
            Ext.Msg.confirm(_('Confirmation'),  '<b>' + sel.data.name + '</b>: ' + msg, 
                function(btn){ 
                    if(btn=='yes') {
                        Baseliner.ajaxEval( '/job/submit',  { action: 'delete', mode: mode, mid: sel.data.mid }, function(res){
                            //console.log( res );
                            if( res.success ) {
                                grid.getStore().reload();
                                if(sel.data.can_cancel){
                                    // button_cancel.enable();
                                    button_cancel.setText( msg_cancel_delete[1] );    
                                }
                            } else {
                                Ext.Msg.alert( _('Error'), _('Could not delete the job: %1', res.msg ) );
                            }
                        });
                    }
                } );
        }
    });


    var button_rollback = new Ext.Toolbar.Button({
        text: _('Rollback'),
        disabled: true,
        icon:'/static/images/icons/left.png',
        cls: 'x-btn-text-icon',
        handler: function() { do_backout() }
    });

    var button_rerun = new Ext.Toolbar.Button({
        text: _('Rerun'),
        disabled: true,
        icon:'/static/images/icons/restart.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if ( ! sm.hasSelection()) {
                Ext.Msg.alert(_('Error'), _('Select a row first'));   
            } else {
                var sel = sm.getSelected();
                var users = new Ext.data.SimpleStore({
                    fields: ['username'],
                    data: [ [sel.data.username], ['<% $c->username %>'] ]
                });
                var steps = new Ext.data.SimpleStore({
                    fields: ['step'],
                    data: [ ['PRE'], ['RUN'], ['POST'], ['END'] ]
                });
                var user_combo = new Ext.form.ComboBox({
                    name: 'username',
                    hiddenName: 'username',
                    fieldLabel: _('User'),
                    store: users,
                    valueField: 'username',
                    lazyRender: false,
                    value: sel.data.username,
                    mode: 'local',
                    editable: true,
                    triggerAction: 'all',
                    displayField: 'username'
                });
                var step_field = sel.data.step_code == 'END' ? 'PRE' : sel.data.step_code;
                var run_now = sel.data.step_code == 'END' ? true : false;
                var mid = sel.data.mid;
                var step_buttons = new Ext.Container({ layout: { type:'hbox' }, fieldLabel: _('Initial Step'), border: false,
                    items: ['PRE','RUN','POST','END'].map(function(st){ 
                        return { xtype:'button', text: st, enableToggle: true, width: 45, style:{ 'font-weight':(step_field==st?'bold':'') },
                            toggleGroup: 'step_buttons', allowDepress: false, pressed: step_field==st };
                    })
                });
                var form_res = new Ext.FormPanel({ 
                    frame: false,
                    height: 150,
                    defaults: { width:'100%' },
                    bodyStyle:'padding: 10px',
                    items: [
                        user_combo,
                        { xtype: 'hidden', name:'mid', value: sel.data.mid },
                        { xtype: 'hidden', name:'job_name', value: sel.data.name },
                        { xtype: 'hidden', name:'starttime',fieldLabel: _('Start Date'), value: sel.data.starttime },
                        { xtype: 'checkbox', name: 'run_now', fieldLabel : _("Run Now"), checked: run_now },
                        step_buttons
                    ],
                    buttons: [
                        {text:_('Rerun'), handler:function(f){ 
                            var but = this;
                            but.disable();
                            var form_data = form_res.getForm().getValues();                                     
                            step_buttons.items.each(function(btn){
                                if( btn.pressed ) form_data.step = btn.text;
                            });
                            Baseliner.ci_call( 'job', 'reset', form_data, 
                                function(res){ 
                                    Baseliner.message( sel.data.name, _('Job Restarted') );
                                    but.enable();
                                    try{
                                        store.reload();
                                    }catch(err){};
                                    win_res.close();
                                },
                                function(res) { 
                                    but.enable();
                                    Baseliner.error(_('Error'), _('Could not rerun the job: %1', res.msg) );
                                }
                            );
                         }},
                        {text:_('Cancel'), handler:function(f){ win_res.close() }}
                    ]
                });
                var win_res=new Ext.Window({
                    title: _('Rerun'),
                    width: 400,
                    height: 200,
                    bodyStyle:'background-color:#e0c080;padding: 10px',
                    items: form_res
                });
                win_res.show();
                /*
                Ext.Msg.confirm('<% _loc('Confirmation') %>', '<% _loc('Are you sure you want to rerun the job') %> ' + sel.data.name + '?', 
                    function(btn){ 
                        if(btn=='yes') {
                            var conn = new Ext.data.Connection();
                            conn.request({
                                url: '/job/submit',
                                params: { action: 'rerun', mid: sel.data.mid },
                                success: function(resp,opt) {
                                    Baseliner.message( sel.data.name, '<% _loc('Job Restarted') %>');
                                    store.load();
                                },
                                failure: function(resp,opt) { Baseliner.message('<% _loc('Error') %>', '<% _loc('Could not rerun the job.') %>'); }
                            }); 
                        }
                    } );
                */
            }
        }
    });

    //------------ Renderers
    var render_contents = function(value,metadata,rec,rowIndex,colIndex,store) {
        var return_value = new Array();
        if ( rec.data.changeset_cis && rec.data.changeset_cis.length > 0 ) {
          Ext.each(rec.data.changeset_cis, function(cs) {
            // console.log(cs);
            var link = '<a id="topic_'+ cs.mid +'_<% $iid %>" onclick="javascript:Baseliner.show_topic_colored(\''+ cs.mid + '\', \''+ cs.category.name + '\', \''+ cs.category.color + '\')" style="cursor:pointer;">'+ cs.category.name + ' #' + cs.mid + ' - ' + cs.title + '</a>';
            return_value.push(link);
          });
        } else {
          return_value = value;
        }
            // console.log(return_value[0]);
        if( return_value.length < 2 ) return return_value[0];
        var str = return_value.join('<li>');
        return '<li>' + str;
    };

    var render_releases = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value.length < 2 ) return value[0];
        var str = value.join('<li>');
        return '<li>' + str;
    };

    var render_app = function(value,metadata,rec,rowIndex,colIndex,store) {
        return String.format('<b>{0}</b>', ( !Ext.isArray(value) ? value : value.join('<br />') ) );
    };

    var render_nature = function(v,meta,rec,rowIndex,colIndex,store) {
        if( ! v ) return '' ;
        var ret = new Array();
        Ext.each( v, function( ns ) {
            if( ! ns ) return;
            var nat = nature_hash[ ns ];
            if( !nat ) {
                nat = {};
                nat.name = ns;
                nat.icon = 'nature';
            }
            ret.push( 
                String.format('<div style="height:20px;"><img style="float:left" src="/static/images/nature/{0}.png" />&nbsp;{1}</div>', nat.icon, nat.name )
            );
        });
        return ret.join('');
    };

    var render_subapp = function(v,meta,rec,rowIndex,colIndex,store) {
        if( ! v ) return '';
        if( typeof v != 'object' ) return v;
        return Baseliner.render_wrap( v.join(', ') );
    };

    var render_ago = function(v,meta,rec,rowIndex,colIndex,store) {
        if( ! v ) return '';
        return rec.data.ago;
    };

    var render_level = function(value,metadata,rec,rowIndex,colIndex,store) {
        var icon;
        var bold = false;
        var status = rec.data.status_code;
        var type   = rec.data.type_raw;
        var rollback = rec.data.rollback;
        if( status=='RUNNING' ) { icon='gears.gif'; bold=true }
        else if( status=='READY' ) icon='waiting.png';
        else if( status=='APPROVAL' ) icon='user_delete.gif';
        else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.gif'; bold=true; }
        else if( status=='IN-EDIT' ) icon='log_w.gif';
        else if( status=='WAITING' ) icon='waiting.png';
        else if( status=='PAUSED' ) icon='paused.png';
        else if( status=='TRAPPED' ) icon='paused.png';
        else if( status=='TRAPPED_PAUSED' ) icon='paused.png';
        else if( status=='CANCELLED' ) icon='close.png';
        else { icon='log_e.gif'; bold=true; }
        value = (bold?'<b>':'') + value + (bold?'</b>':'');

        // Rollback?
        if( status == 'FINISHED' && rollback == 1 )  {
            value += ' (' + _('Rollback OK') + ')';
            icon = 'log_e.gif';
        } 
        else if( status == 'ERROR' && rollback == 1 )  {
            value += ' (' + _('Rollback Failed') + ')';
        }
        else if( rollback == 1 )  {
            value += ' (' + _('Rollback') + ')';
        }

        //else if( type == 'demote' || type == 'rollback' ) value += ' ' + _('(Rollback)');
        if( status == 'APPROVAL' ) { // add a link to the approval main
            value = String.format("<a href='javascript:Baseliner.request_approval({0},\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id ); 
        }
% if( $c->stash->{user_action}->{'action.job.resume'} ) {
        else if( status == 'PAUSED' ) { // add a link to the approval main
            value = String.format("<a href='javascript:Baseliner.resume_job({0},\"{3}\",\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id, rec.data.name ); 
        }
% }
        else if( status == 'TRAPPED' || status == 'TRAPPED_PAUSED' ) { // add a link to the trap
            value = String.format("<a href='javascript:Baseliner.trap_check({0},\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id ); 
        }
        if( icon!=undefined ) {
            var err_warn = ''; // rec.data.has_errors > 0 ? _('(errors: %1)', rec.data.has_errors) : '';
            err_warn += rec.data.has_warnings > 0 ? '<img src="/static/images/icons/log_w.gif" />' : '';
            return div1 
                + "<table><tr><td><img alt='"+status+"' border=0 src='/static/images/icons/"+icon+"' /></td>"
                + '<td>' + value + '</td><td>'+err_warn+'</td></tr></table>' + div2 ;
        } else {
            return value;
        }
    };

    var render_job = function(value, metadata, record){
        var contents = ''; record.data.contents.join('<br />');
        var execs = record.data.exec > 1 ? " ("+record.data.exec+")" : '';
        return String.format(
                '<b><a href="javascript:Baseliner.openLogTab({1}, \'{2}\');" style="font-family: Tahoma;">{0}{3}</a></b><br />',
                value, record.data.mid, record.data.name, execs ); 
    };

    function renderLast(value, p, r){
        return String.format('{0}<br/>by {1}', value.dateFormat('M j, Y, g:i a'), r.data['lastposter']);
    }
    
    var gview = new Ext.grid.GroupingView({
            forceFit: true,
            enableRowBody: true,
            autoWidth: true,
            autoSizeColumns: true,
            deferredRender: true,
            startCollapsed: false,
            hideGroupedColumn: true,
            //groupTextTpl: '{[ values.rs[0].data["day"] ]}',
            //groupTextTpl: '{[ values.rs[0].data["ago"] ]}',  // TODO use this only when field is "when"
            getRowClass: function(record, index, p, store){
                var css='';
                p.body='';
                var desc = record.data.comments;
                if( (desc != undefined) && (desc != '') ) {
                    //desc = desc.replace(/\n|\r|/,'');
                    p.body +='<div style="color: #333; font-weight: bold; padding: 0px 0px 5px 30px;">';
                    p.body += '<img style="float:left" src="/static/images/icons/post.gif" />';
                    p.body += '&nbsp;' + desc + '</div>';
                    css += ' x-grid3-row-expanded '; 
                }
                // console.dir(record.data);
                var return_value = new Array();
                if ( record.data.changeset_cis && record.data.changeset_cis.length > 0 ) {
                  Ext.each(record.data.changeset_cis, function(cs) {
                    // console.log(cs);
                    var link = '<span style="text-align: center;vertical-align: middle;"><a id="topic_'+ cs.mid +'_<% $iid %>" onclick="javascript:Baseliner.show_topic_colored(\''+ cs.mid + '\', \''+ cs.category.name + '\', \''+ cs.category.color + '\')" style="cursor:pointer">'+ cs.category.name + ' #' + cs.mid + ' - ' + cs.title + '</a>';
                    var comments = '';
                    if ( record.data.cs_comments[cs.mid] ) {
                      comments = "<img src='/static/images/icons/paperclip.gif' style='cursor:pointer;height:12px;width:12px;' onclick='javascript:( new Baseliner.view_field_content({ username: \"<% $c->username %>\", mid: \""+ cs.mid + "\", field: \"" + record.data.cs_comments[cs.mid] + "\", title: \"" + cs.category.name + ' #' + cs.mid + ' - ' + cs.title + "\" }))'/>";
                    }
                    return_value.push(link + '&nbsp' + comments + '</span>');
                  });
                  if ( record.data.releases ) {
                    Ext.each( record.data.releases, function(rel) {
                      return_value.push(rel);
                    });
                  }
                } else {
                  return_value = record.data.contents;
                }

                var cont = return_value;
                if( cont != undefined ) {
                    p.body +='<div style="color: #505050; margin: 0px 0px 5px 20px;">';
                    for( var i=0; i<cont.length; i++ ) {
                        p.body += cont[i] + '<br />';
                    }
                    p.body +='</div>';
                    css += ' x-grid3-row-expanded '; 
                }
                css += index % 2 > 0 ? ' level-row info-odd ' : ' level-row info-even ' ;
                return css;
            }
    });
    /* gview.getGroup = function(v, r, groupRenderer, rowIndex, colIndex, ds){
        var g = groupRenderer ? groupRenderer(v, {}, r, rowIndex, colIndex, ds) : String(v);
        if( g === '' ) {
            g = this.cm.config[colIndex].emptyGroupText || this.emptyGroupText;
        }
        return g;
    }; */
    var row_sel = new Ext.grid.RowSelectionModel({singleSelect:true});

    var filters = new Ext.ux.grid.GridFilters({
		menuFilterText: _('Filters'),
        encode: true,
        local: false,
        filters: [
           //{ type: 'string', dataIndex: 'status', emptyText: _('Job Status') },
           { type: 'date', dataIndex: 'starttime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'endtime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'maxstarttime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'schedtime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') }	
        ]
	});
	
    // create the grid
    var grid = new Ext.grid.EditorGridPanel({
        title: _('Monitor'),
        plugins: [ filters ],
        header: false,
        tab_icon: '/static/images/icons/television.gif',
        stripeRows: false,
        autoScroll: true,
        family: 'jobs',
        loadMask: true,
        stateful: true,
        stateId: state_id,
        wait: _('Loading...'),
        store: store,
        view: gview,
        selModel: row_sel, 
        columns: [
                { header: _('ID'), width: 60, dataIndex: 'id', sortable: true, hidden: true },
                { header: _('MID'), width: 60, dataIndex: 'mid', sortable: true, hidden: true },
                { header: _('Job'), width: 140, dataIndex: 'name', sortable: true, renderer: render_job },    
                { header: _('Job Status'), width: 130, dataIndex: 'status', renderer: render_level, sortable: true },
                { header: _('Status Code'), width: 60, dataIndex: 'status_code', hidden: true, sortable: true },
                { header: _('Step'), width: 50, dataIndex: 'step_code', sortable: true , hidden: false },	
                { header: _('Application'), width: 70, dataIndex: 'applications', renderer: render_app, sortable: true, hidden: is_portlet ? true : false },
                { header: _('Baseline'), width: 50, dataIndex: 'bl', sortable: true },
                { header: _('Natures'), width: 120, hidden: view_natures, dataIndex: 'natures', sortable: false, renderer: render_nature }, // not in DB
                { header: _('Subapplications'), width: 120, dataIndex: 'subapps', sortable: false, hidden: true, renderer: render_subapp }, // not in DB
                { header: _('Job Type'), width: 100, dataIndex: 'type', sortable: true, hidden: true },
                { header: _('User'), width: 80, dataIndex: 'username', sortable: true , renderer: Baseliner.render_user_field, hidden: is_portlet ? true : false},	
                { header: _('Execution'), width: 80, dataIndex: 'exec', sortable: true , hidden: true },	
                { header: _('Last Message'), width: 180, dataIndex: 'last_log', sortable: true , hidden: is_portlet ? true : true },	
                { header: _('Changesets'), width: 100, dataIndex: 'changesets', renderer: render_contents, sortable: true, hidden: true },
                { header: _('Releases'), width: 100, dataIndex: 'releases', renderer: render_releases, sortable: true, hidden: true },
                { header: _('Scheduled'), width: 130, dataIndex: 'schedtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Start Date'), width: 130, dataIndex: 'starttime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Max Start Date'), width: 130, dataIndex: 'maxstarttime', sortable: true, hidden: true }, 
                { header: _('Approval expiration'), width: 130, dataIndex: 'approval_expiration', sortable: true, hidden: true },	
                { header: _('End Date'), width: 130, dataIndex: 'endtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('PID'), width: 50, dataIndex: 'pid', sortable: true, hidden: true },	
                { header: _('Host'), width: 120, dataIndex: 'host', sortable: true, hidden: true },	
                { header: _('Owner'), width: 120, dataIndex: 'owner', sortable: true, hidden: true },	
                { header: _('Runner'), width: 80, dataIndex: 'runner', sortable: true, hidden: true },	
                { header: _('Rule'), width: 80, dataIndex: 'rule_name', sortable: false, hidden: true },	
                { header: _('When'), width: 120, dataIndex: 'when', hidden: true, sortable: true, renderer: render_ago },	
                { header: _('Comments'), hidden: true, width: 150, dataIndex: 'comments', sortable: true },
                { header: _('PRE Start Date'), width: 130, dataIndex: 'pre_start', sortable: true , hidden: true }, 
                { header: _('PRE End Date'), width: 130, dataIndex: 'pre_end', sortable: true , hidden: true }, 
                { header: _('RUN Start Date'), width: 130, dataIndex: 'run_start', sortable: true , hidden: true }, 
                { header: _('RUN End Date'), width: 130, dataIndex: 'run_end', sortable: true , hidden: true } 

            ],
        bbar: paging,        
        tbar: is_portlet ? [] : [ 
                search_field,
                button_html,
                menu_bl, nature_menu_btn, { text: _('Status'), menu: menu_job_states }, menu_type_filter, '-',
                // end
% if( $c->stash->{user_action}->{'action.job.create'} ) {
                new Ext.Toolbar.Button({
                    text: _('New'),
                    icon:'/static/images/icons/job.png',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        Baseliner.add_tabcomp('/job/create', _('New Job'), { tab_icon: '/static/images/icons/job.png' } );
                    }
                }),
% }
                new Ext.Toolbar.Button({
                    //text: _('View Log'),
                    icon:'/static/images/icons/moredata.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            Baseliner.addNewTabComp('/job/log/list?mid=' + sel.data.mid+'&auto_refresh=1', sel.data.name );
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
% if( $c->stash->{user_action}->{'action.job.resume'} ) {
                button_resume,
% }
% if( $c->stash->{user_action}->{'action.job.delete'} || $c->stash->{user_action}->{'action.job.cancel'} ) {
                button_cancel,
% }
% if( $c->stash->{user_action}->{'action.job.restart'} ) {
                button_rollback,
                button_rerun,
% }
% if( $c->stash->{user_action}->{'action.job.restart'} || $c->stash->{user_action}->{'action.job.reschedule'} ) {
                new Ext.Toolbar.Button({
                    text: _('Reschedule'),
                    icon:'/static/images/date_field.png',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            if( sel.data.status_code != 'READY' && sel.data.status_code != 'APPROVAL' ) {
                                Baseliner.error( _('Reschedule'), 
                                    _("Job cannot be rescheduled unless its status is '%1' (current: %2)", _('READY')+"|"+_('APPROVAL'), _(sel.data.status) ) );
                                return;
                            }
                            var curr = Date.parseDate(sel.data.schedtime, 'Y-m-d H:i:s' );
                            var fupdatepanel = new Baseliner.FormPanel({
                                frame: true,
                                items: [
                                    {
                                        xtype: 'datefield',
                                        anchor: '100%',
                                        fieldLabel: _('Date'),
                                        name:'date',
                                        value: curr,
                                        format: 'Y-m-d'
                                    },
                                  {
                                    xtype: 'uxspinner', 
                                    name: 'time', 					
                                    fieldLabel: _('Time'),
                                        anchor: '100%',
                                    allowBlank: false,
                                    value: curr.format('H:i'),
                                    strategy: new Ext.ux.form.Spinner.TimeStrategy()				  
                                  }		   
                                ]
                            });

                            var winupdate = new Baseliner.Window({
                                layout: 'fit',
                                height: 150, width: 380,
                                tbar: [
                                    '->',
                                    {  text: _('Cancel'), icon: IC('close'), handler: function(){ winupdate.close(); } },
                                    {  text: _('Update'), icon: IC('edit'), handler: function(){ 
                                            var d = fupdatepanel.getValues();
                                            Baseliner.ci_call( sel.data.mid, 'reschedule', d, function(res){
                                                Baseliner.message( _('Reschedule'), res.msg );
                                                store.reload();
                                                winupdate.close();
                                            });
                                                                                
                                     } }
                                ],
                                title: 'Modificar fecha y hora del pase.',
                                items: fupdatepanel
                            });
                            winupdate.show();
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
% }
                '->',
                menu_tools,
                btn_reports,
                btn_clear_state,
                refresh_button
                ]
        });

        grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            Baseliner.openLogTab(r.get('mid') , r.get('name') );
        });		


        grid.on("activate", function(){
            grid.setTitle(_('Monitor'));
        });

    var first_load = true;

    // Yellow row selection
        row_sel.on('rowselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).addClass('x-grid3-row-selected-yellow');
        var sc = rec.data.status_code;
        button_resume.disable();
        if ( rec.data.can_cancel || rec.data.can_delete ) {
            if( (sc == 'CANCELLED' || sc == 'ERROR' || sc == 'FINISHED') && rec.data.can_delete == '1' ) {
                button_cancel.setText( msg_cancel_delete[1] );
                button_cancel.enable();
            } else if (rec.data.can_cancel == '1') {
                button_cancel.setText( msg_cancel_delete[0] );
                button_cancel.enable();
            } else {
                button_cancel.disable();
            }
        } else {
            button_cancel.disable();
        };
        if( rec.data.status_code === 'PAUSED' || rec.data.status_code === 'TRAPPED' || rec.data.status_code === 'TRAPPED_PAUSED' ) {
            button_resume.show();
        }
        if (rec.data.can_restart == '1'){
            button_rollback.enable();
            button_rerun.enable();
        } else {
            button_rollback.disable();
            button_rerun.disable();
        };
    });
    row_sel.on('rowdeselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).removeClass('x-grid3-row-selected-yellow');
    });

    grid.on("activate", function() {
        if( first_load ) {
            Baseliner.showLoadingMask( grid.getEl() , _('Loading...') );
            first_load = false;
        }
    });
    store.load({params:{start:0 , limit: ps }, callback: function(){
        Baseliner.hideLoadingMaskFade(grid.getEl());
    } }); 

    grid.on('destroy', function(){
        autorefresh.stop(task);
    });
    return grid;
})
