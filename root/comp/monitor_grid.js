<%args>
  $natures_json    => $ARGS{natures_json} 
  $job_states_json => $ARGS{job_states_json}
  $envs_json       => $ARGS{envs_json}
  $types_json      => $ARGS{types_json}
  $query_id        => '-1'
</%args>
<%perl>
    use Baseliner::Sugar;
    my $view_natures = config_value('job_new.view_natures');
</%perl>
(function(params){
    if( !params ) params = {};
    var view_natures = <% $view_natures ? 'false' : 'true' %>; 
   
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
            {  name: 'schedtime' },
            {  name: 'last_log' },
            {  name: 'contents' },
            {  name: 'applications' },
            {  name: 'maxstarttime' },
            {  name: 'endtime' },
            {  name: 'runner' },
            {  name: 'id_rule' },
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
            {  name: 'grouping' },
            {  name: 'day' },
            {  name: 'status_code' },
            {  name: 'status' },
            {  name: 'natures' }, 
            {  name: 'subapps' } 
        ]
    );

    // Nature Filters

    var natures = <% $natures_json %>;
    
    
    var nature_hash = {}; // this is used by the render_nature
    Ext.each( natures, function(nat) {
        nature_hash[ nat.ns ] = nat; 
    });
    
            
    var nature_menu = natures.map(function (x) {

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
    });
    
    nature_menu.push({
      icon: '/static/images/icons/all.png',
      text: _('All-f'),
      handler: function (item) {
        item.parentMenu.ownerCt.setText( _('Nature') );
        delete store.baseParams.filter_nature;
        store.reload();
      }
    });
   
    var nature_menu_btn = new Ext.Button({
      //text: _('Natures'),
      icon: '/static/images/icons/nature.gif',
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
    var item_job_states = job_states_json.map(function (x) {
      return {
        id_status: x.name,
        text: _(x.name),
        checked: job_states_check_state[x.name],
        checkHandler: function (obj) {
          modify_job_states_check_state(obj.id_status);
          store.load({
            params: {
              job_state_filter: Ext.util.JSON.encode(to_perl_bool(job_states_check_state))
            }
          });
        }
      };
    });
    var menu_job_states = new Ext.menu.Menu({
      items: item_job_states
    });

    // Baseline Filter

    var menu_list = <%$envs_json%>.map(function (x) {
      return {
        text: String.format('{0}: {1}', x.bl, x.name ),
        icon: '/static/images/icons/baseline.gif',
        handler: function (item) {
          item.parentMenu.ownerCt.setText( '<b>' + _('Baseline: %1',  x.bl ) + '</b>' );
          store.baseParams.filter_bl = x.bl;
          store.reload();
        }
      };
    });
    menu_list.push({
      icon: '/static/images/icons/all.png',
      text: _('All'),
      handler: function (item) {
        item.parentMenu.ownerCt.setText( _('Baseline') );
        delete store.baseParams.filter_bl;
        store.reload();
      }
    });
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
          },{
            text: _('All'),
            icon: '/static/images/icons/all.png',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( _('Type') );
               delete store.baseParams.filter_type;
               store.reload();
            }
          }
      ]
    });
    // end

    var group_field = 'grouping';

    var store = new Baseliner.GroupingStore({
            reader: reader,
            url: '/job/monitor_json',
            baseParams: { limit: ps, query_id: '<% $query_id %>', query: params.query },
            remoteSort: true,
            sortInfo: { field: 'starttime', direction: "DESC" },
            groupField: group_field
    });
    
    var paging = new Ext.PagingToolbar({
            store: store,
            pageSize: ps,
            displayInfo: true,
            displayMsg: _('Rows {0} - {1} of {2}'),
            emptyMsg: "No hay registros disponibles"
    });
    //paging.on('beforechange', function(){ refresh_stop(); });

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
    var task_interval_increment = 2000;  
    var task_interval_max = 60000;  
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
                // send from and where, to determine if there's a more recent job
                Baseliner.ajaxEval( '/job/refresh_now',
                    { ids: ids, top: top_id, real_top: real_top, last_magic: last_magic, _ignore_conn_errors: true  }, function(res) {
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
                        Ext.Msg.alert( _('Error'), _('Could not retry the job: %1', res.msg ) );
                    }
                });
            }, this, 300, '');
        };
        trap_win = new Baseliner.Window({
            title: _('Error trapped'),
            width: 400, height: 300,
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
            { text: _('Run In-process'), handler:function(){ run_inproc() },
              icon: '/static/images/icons/job.png'
            },
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
                            }, function(res){
                                var win = new Baseliner.Window({
                                    width: 800, height: 600, layout:'fit',
                                    title: _('Dependencies'), 
                                    items: new Baseliner.DataEditor({ data: res.deps })
                                });
                                win.show();
                                Baseliner.message( _('Rollback'), res.msg ) ;
                            }
                        );
                    }
                }
            );
        }
    };

    var button_resume = new Ext.Toolbar.Button({
        text: _('Resume'),
        hidden: true,
        icon:'/static/images/icons/play.png',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var mode;
            if( sel.data.status_code == 'PAUSED' ) {
                Ext.Msg.confirm(_('Confirmation'),  '<b>' + sel.data.name + '</b>: ' + _('Are you sure you want to resume the job?'), 
                    function(btn){ 
                        if(btn=='yes') {
                            Baseliner.ci_call( sel.data.mid, 'resume',  {}, function(res){
                                if( res.success ) {
                                    grid.getStore().reload();
                                } else {
                                    Ext.Msg.alert( _('Error'), _('Could not resume the job: %1', res.msg ) );
                                }
                            });
                        }
                    }
                );
                button_resume.hide();
            }
            else if( sel.data.status_code == 'TRAPPED' ) {
                Baseliner.trap_check(sel.data.mid);
                button_resume.hide();
            }
        }
    });
    
    var msg_cancel_delete = [ _('Cancel'), _('Delete') ];
    var button_cancel = new Ext.Toolbar.Button({
        text: msg_cancel_delete[0],
        icon:'/static/images/del.gif',
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
                            } else {
                                Ext.Msg.alert( _('Error'), _('Could not delete the job: %1', res.msg ) );
                            }
                        });
                    }
                } );
        }
    });
    //------------ Renderers
    var render_contents = function(value,metadata,rec,rowIndex,colIndex,store) {
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
        else if( status == 'TRAPPED' ) { // add a link to the trap
            value = String.format("<a href='javascript:Baseliner.trap_check({0},\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id ); 
        }
        if( icon!=undefined ) {
            var err_warn = rec.data.has_errors > 0 ? _('err: %1', rec.data.has_errors) : '';
            err_warn += rec.data.has_warnings > 0 ? _('warn: %1', rec.data.has_warnings) : '';
            return div1 
                + "<table><tr><td><img alt='"+status+"' border=0 src='/static/images/icons/"+icon+"' /></td>"
                + '<td>' + value + '</td><td>'+err_warn+'</td></tr></table>' + div2 ;
        } else {
            return value;
        }
    };

    Baseliner.openLogTab = function(id, name) {
        //Baseliner.addNewTabComp('/job/log/list?mid=' + id, _('Log') + ' ' + name, { tab_icon: '/static/images/icons/moredata.gif' } );
        Baseliner.addNewTab('/job/log/dashboard?mid=' + id + '&name=' + name , name, { tab_icon: '/static/images/icons/job.png' });
    };

    var render_job = function(value, metadata, record){
        var contents = ''; record.data.contents.join('<br />');
        return String.format(
                '<b><a href="javascript:Baseliner.openLogTab({1}, \'{2}\');" style="font-family: Tahoma;">{0}</a></b><br />',
                value, record.data.mid, record.data.name ); 
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
            groupTextTpl: '{[ values.rs[0].data["day"] ]}',
            getRowClass: function(record, index, p, store){
                var css='';
                p.body='';
                var desc = record.data.comments;
                if( desc != undefined ) {
                    //desc = desc.replace(/\n|\r|/,'');
                    p.body +='<div style="color: #333; font-weight: bold; padding: 0px 0px 5px 30px;">';
                    p.body += '<img style="float:left" src="/static/images/icons/post.gif" />';
                    p.body += '&nbsp;' + desc + '</div>';
                    css += ' x-grid3-row-expanded '; 
                }
                var cont = record.data.contents;
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

    // create the grid
    var grid = new Ext.grid.EditorGridPanel({
        title: _('Monitor'),
        header: false,
        tab_icon: '/static/images/icons/television.gif',
        stripeRows: false,
        autoScroll: true,
        loadMask: true,
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
                { header: _('Application'), width: 70, dataIndex: 'applications', renderer: render_app, sortable: false, hidden: is_portlet ? true : false },
                { header: _('Baseline'), width: 50, dataIndex: 'bl', sortable: true },
                { header: _('Natures'), width: 120, hidden: view_natures, dataIndex: 'natures', sortable: false, renderer: render_nature }, // not in DB
                { header: _('Subapplications'), width: 120, dataIndex: 'subapps', sortable: false, hidden: true, renderer: render_subapp }, // not in DB
                { header: _('Job Type'), width: 100, dataIndex: 'type', sortable: true, hidden: true },
                { header: _('User'), width: 80, dataIndex: 'username', sortable: true , renderer: Baseliner.render_user_field, hidden: is_portlet ? true : false},	
                { header: _('Execution'), width: 80, dataIndex: 'exec', sortable: true , hidden: true },	
                { header: _('Last Message'), width: 180, dataIndex: 'last_log', sortable: true , hidden: is_portlet ? true : true },	
                { header: _('Contents'), width: 100, dataIndex: 'contents', renderer: render_contents, sortable: true, hidden: true },
                { header: _('Scheduled'), width: 130, dataIndex: 'schedtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Start Date'), width: 130, dataIndex: 'starttime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Max Start Date'), width: 130, dataIndex: 'maxstarttime', sortable: true, hidden: true },	
                { header: _('End Date'), width: 130, dataIndex: 'endtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('PID'), width: 50, dataIndex: 'pid', sortable: true, hidden: true },	
                { header: _('Host'), width: 120, dataIndex: 'host', sortable: true, hidden: true },	
                { header: _('Owner'), width: 120, dataIndex: 'owner', sortable: true, hidden: true },	
                { header: _('Runner'), width: 80, dataIndex: 'runner', sortable: true, hidden: true },	
                { header: _('Rule'), width: 80, dataIndex: 'id_rule', sortable: true, hidden: true },	
                { header: _('Grouping'), width: 120, dataIndex: 'grouping', hidden: true },	
                { header: _('Comments'), hidden: true, width: 150, dataIndex: 'comments', sortable: true }
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
                            Baseliner.addNewTabComp('/job/log/list?mid=' + sel.data.mid, sel.data.name );
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
% if( $c->stash->{user_action}->{'action.job.resume'} ) {
                button_resume,
% }
% if( $c->stash->{user_action}->{'action.job.create'} ) {
                button_cancel,
% }
% if( $c->stash->{user_action}->{'action.job.restart'} ) {
                new Ext.Toolbar.Button({
                    text: _('Rollback'),
                    icon:'/static/images/icons/left.png',
                    cls: 'x-btn-text-icon',
                    handler: function() { do_backout() }
                }),
                new Ext.Toolbar.Button({
                    text: _('Rerun'),
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
                            var step_combo = new Ext.form.ComboBox({
                                name: 'step',
                                hiddenName: 'step',
                                fieldLabel: _('Initial Step'),
                                store: steps,
                                valueField: 'step',
                                lazyRender: false,
                                value: step_field,
                                mode: 'local',
                                editable: true,
                                triggerAction: 'all',
                                displayField: 'step'
                            });
                            var run_now = sel.data.step_code == 'END' ? true : false;
                            var mid = sel.data.mid;
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
                                    step_combo
                                ],
                                buttons: [
                                    {text:_('Rerun'), handler:function(f){ 
                                        var form_data = form_res.getForm().getValues();                                     
                                        Baseliner.ci_call( 'job', 'reset', form_data, 
                                            function(res){ 
                                                Baseliner.message( sel.data.name, _('Job Restarted') );
                                                store.reload();
                                                win_res.close();
                                            },
                                            function(res) { 
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
                }),
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
                            if( sel.data.status_code != 'READY' ) {
                                Baseliner.error( _('Reschedule'), 
                                    _("Job cannot be rescheduled unless its status is '%1' (current: %2)", _('READY'), _(sel.data.status) ) );
                                return;
                            }
                            var curr = Date.parseDate(sel.data.schedtime, 'Y-m-d H:i:s' );
                            var fupdatepanel = new Baseliner.FormPanel({
                                frame: true,
                                url: '/job/job_update', 
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
                                    value: curr.format('H:i:s'),
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
                refresh_button
                ]
        });

        grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            Baseliner.openLogTab(r.get('id') , r.get('name') );
        });		


        grid.on("activate", function(){
            grid.setTitle(_('Monitor'));
        });

    var first_load = true;

    // Yellow row selection
        row_sel.on('rowselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).addClass('x-grid3-row-selected-yellow');
        var sc = rec.data.status_code;
        button_resume.hide();
        if( sc == 'CANCELLED' || sc == 'ERROR' || sc == 'FINISHED' ) {
            button_cancel.setText( msg_cancel_delete[1] );
        } else {
            button_cancel.setText( msg_cancel_delete[0] );
        }
        if( rec.data.status_code === 'PAUSED' || rec.data.status_code === 'TRAPPED' ) {
            button_resume.show();
        }
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
