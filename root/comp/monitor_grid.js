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
    use Baseliner::Model::Permissions;

    my $view_natures = config_value('job_new.view_natures');
    my $show_no_cal = config_value( 'site.show_no_cal' ) // 1;
    my $has_no_cal = Baseliner::Model::Permissions->new->user_has_action( $c->username, 'action.job.no_cal' );
</%perl>
(function(params) {
    Cla.help_push({
        title: _('Monitor'),
        path: 'getting-started/monitor'
    });

    if( !params ) params = {};
    var view_natures = <% $view_natures ? 'false' : 'true' %>;
    var stateId = 'job-monitor';
    var currentState = params.current_state || {};
    var canResumeJob = <% $c->stash->{user_action}->{'action.job.resume'} ? 'true' : 'false' %>;
    var canDeleteJob = <% $c->stash->{user_action}->{'action.job.delete'} ? 'true' : 'false' %>;
    var canCreateJob = <% $c->stash->{user_action}->{'action.job.create'} ? 'true' : 'false' %>;
    var canCancelJob = <% $c->stash->{user_action}->{'action.job.cancel'} ? 'true' : 'false' %>;
    var canRestartJob = <% $c->stash->{user_action}->{'action.job.restart'} ? 'true' : 'false' %>;
    var canForceRollback = <% $c->stash->{user_action}->{'action.job.force_rollback'} ? 'true' : 'false' %>;
    var canReschedule = <% $c->stash->{user_action}->{'action.job.reschedule'} ? 'true' : 'false' %>;
    var canCreateJobOutsideSlots = <% $has_no_cal ? 'true' : 'false'  %>;
    var showCreateJobOutsideSlots = <% $show_no_cal ? 'true' : 'false'  %>;
    var dateFormat = Cla.js_date_to_moment_hash[Cla.user_js_date_format()];
    var preferencesDateFormat = Cla.user_js_date_format();

    var dataAnyTime = function() {
        var arr = [];
        var name = _('no calendar window');
        var today = moment().format(dateFormat);
        var dateSelected = moment(today, dateFormat).format("YYYY-MM-DD")

        var time = moment().format("HH:mm");
        var startHour = 0;
        var startTime = 0;

        for (var h = startHour; h < 24; h++) {
            var startMinute = startTime;
            for (var m = startMinute; m < 60; m++) {
                arr.push(
                    [String.leftPad(h, 2, '0') + ':' + String.leftPad(m, 2, '0'), name, 'F', dateSelected]
                );
            }
        }
        return arr;
    };

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
            {  name: 'release_cis' },
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
            {  name: 'progress' },
            {  name: 'job_family' },
            {  name: 'natures' },
            {  name: 'subapps' },
            {  name: 'can_restart' },
            {  name: 'force_rollback' },
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
        icon: '/static/images/icons/csv.svg',
        text: _('CSV'),
        handler: function() {
            form_report_submit({ no_html: true, url: '/topic/report_csv', target: 'FrameDownload' });
        }
    };

    var btn_reports = new Ext.Button({
        icon: '/static/images/icons/exports.svg',
        tooltip: _('Export'),
        iconCls: 'x-btn-icon',
        menu: [ btn_csv ]
    });

    var btn_clear_state = new Ext.Button({
        icon: '/static/images/icons/reset-grey.svg',
        tooltip: _('Reset Grid Columns'),
        iconCls: 'x-btn-icon',
        handler: function(){
            // deletes
            var cp=new Ext.state.CookieProvider();
            Ext.state.Manager.setProvider(cp);
            Ext.state.Manager.clear( stateId );
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
          text: _('All'),
          icon: '/static/images/icons/nature.svg',
          handler: function (item) {
            item.parentMenu.ownerCt.setText('');
            delete store.baseParams.filter_nature;
            store.reload();
          }
      },'-'
    ];
    nature_menu.push( natures.map(function (x) {

      var nature_name = x.name == 'ZOS'      ? 'z/OS'
                      : x.name == 'FICHEROS' ? 'Ficheros'
                      : x.name == 'TODAS'    ? 'Todas'
                      : x.name
                      ;
      return {
        text: nature_name,
        icon: '/static/images/icons/nature.svg',
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
      tooltip: _('Natures'),
      icon: '/static/images/icons/nature.svg',
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
    var item_job_states = [{
            text: _('All'),
            hideOnClick: false,
            icon: '/static/images/icons/state.svg',
            handler: function() {
                menu_job_states.items.each(function(i) {
                    if (i.checked === false) i.setChecked(true, false);
                });
            }
        }, {
            text: _('Check None'),
            hideOnClick: false,
            icon: '/static/images/icons/state.svg',
            handler: function() {
                menu_job_states.items.each(function(i) {
                    if (i.checked === true) i.setChecked(false, false);
                });
            }
        },
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

    Baseliner.ajaxEval('/project/user_projects', {
        collection: 'area'
    }, function(res_area) {
        Baseliner.ajaxEval('/project/user_projects', {}, function(res) {
            res.data = res.data.concat(res_area.data);

            if (res.data == undefined || res.data.length < 1) {
                menu_projects.disable();
                menu_projects.setText(_('No Projects'));
            } else {
                menu_projects.menu.add({
                    text: _('All'),
                    icon: '/static/images/icons/project.svg',
                    handler: function(item) {
                        item.parentMenu.ownerCt.setText('');
                        delete store.baseParams.filter_project;
                        store.reload();

                    }
                }, '-');
                Ext.each(res.data, function(data) {
                    menu_projects.menu.add({
                        text: data.name,
                        mid: data.mid,
                        icon: data.icon,
                        handler: function(item) {
                            var text = ('<b>' + _('Project: %1', data.name) + '</b>');
                            text = Cla.truncateText(text);
                            item.parentMenu.ownerCt.setText(text);
                            store.baseParams.filter_project = data.mid;
                            store.reload();
                        }
                    });
                });
            }
        });
    });

    var menu_projects = new Ext.Button({
        tooltip: _("Projects"),
        icon: '/static/images/icons/project.svg',
        cls: 'x-btn-icon-text',
        menu: {
            items: []
        }
    });

    // Baseline Filter

    var menu_list = [];
    menu_list.push({
      text: _('All'),
      icon: '/static/images/icons/baseline.svg',
      handler: function (item) {
        item.parentMenu.ownerCt.setText('');
        delete store.baseParams.filter_bl;
        store.reload();
      }
    },'-');
    menu_list.push( <%$envs_json%>.map(function (x) {
          return {
            text: String.format('{0}: {1}', x.bl, x.name ),
            icon: '/static/images/icons/baseline.svg',
            handler: function (item) {
              item.parentMenu.ownerCt.setText( '<b>' + _('Baseline: %1',  x.bl ) + '</b>' );
              store.baseParams.filter_bl = x.bl;
              store.reload();
            }
          };
        })
    );
    var menu_bl = new Ext.Button({
      tooltip: _("Baseline"),
      icon: '/static/images/icons/baseline.svg',
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
            icon: '/static/images/icons/arrow_right.svg',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( '<b>' + _('Type: %1', _('promote')) + '</b>' );
               store.baseParams.filter_type = 'promote';
               store.reload();
            }
          },{
            text: _('demote'),
            icon: '/static/images/icons/arrow_left.svg',
            handler: function (item) {
               item.parentMenu.ownerCt.setText( '<b>' + _('Type: %1', _('demote')) + '</b>' );
               store.baseParams.filter_type = 'demote';
               store.reload();
            }
          },{
            text: _('static'),
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
            baseParams: currentState.baseParams || { limit: ps, query_id: '<% $query_id %>', query: params.query },
            remoteSort: true,
            remoteGroup: true,
            sortInfo: { field: 'starttime', direction: "DESC" }
    });

    var paging = new Baseliner.PagingToolbar({
        store: store,
        pageSize: ps,
        plugins: [new Ext.ux.ProgressBarPager()],
        listeners: {
            pagesizechanged: function(pageSize) {
                searchField.setParam('limit', pageSize);
             }
        }
    });

    var next_start = 0;
    store.on('load', function(s,recs,opt) {
        next_start = s.reader.jsonData.next_start;
    });

    paging.on("beforechange", function(p,opts) {
        opts.next_start = next_start;
    });

    <& /comp/search_field.mas &>

    var searchField = new Baseliner.SearchField({
        store: store,
        params: {start: 0, limit: paging.pageSize},
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
            refresh_button_wait_on();
            var flag_running = false;
            store.each( function(rec) {
                var id = rec.data.mid;
                if( parseInt(id) > parseInt( top_id ) ) {
                    top_id = id;
                }
                ids.push(id);
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
    var refresh_button = new Ext.Button({ tooltip: _('Refresh'),
        icon: '/static/images/icons/refresh.svg',
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
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Retry')+'</b>', icon:'/static/images/icons/refresh.svg',
                        handler:function(){trap_do(mid,'retry')} },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('Retries the job task that failed') }]},
                { flex:1, layout:'hbox', padding: 20,
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Skip')+'</b>', icon:'/static/images/icons/skip.svg',
                        handler:function(){trap_do(mid,'skip')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('Skips the job task that failed, ignoring the error') }]},
                { flex:1, layout:'hbox', padding: 20,
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Abort')+'</b>', icon:'/static/images/icons/delete.svg',
                        handler:function(){trap_do(mid,'abort')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('The task will fail') }]},
                { flex:1, layout:'hbox', padding: 20,
                    items:[{ flex:1, xtype:'button', height: 50, text:'<b>'+_('Pause')+'</b>', icon:'/static/images/icons/control_pause.svg',
                        handler:function(){trap_do(mid,'pause')}  },
                        { flex:1, border: false, style: 'margin-left:10px', html: _('The trap timeout countdown will be paused') }]}
            ]
        });
        trap_win.show();
    }

    var htmlButton = new Ext.Toolbar.Button({ icon: '/static/images/icons/html.svg',
        tooltip: _('HTML'),
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
            var cons_pan = new Ext.Panel({ layout:'fit', items: cons_inproc, wait: _('LOADING') });
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
      cls: 'ui-menu-tools',
      tooltip: _('Tools'),
      icon: '/static/images/icons/wrench.svg',
      menu: [
% if( model->Permissions->user_has_action($c->username, 'action.job.run_in_proc') ) {
            { cls: 'ui-run-in-process', text: _('Run In-process'), handler:function(){ run_inproc() },
              icon: '/static/images/icons/job.svg'
            },
% }
            {
                text: _('Job Export'),
                icon:'/static/images/icons/downloads_favicon.svg',
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

    var do_backout = function() {
        var sm = grid.getSelectionModel();
        var sel = sm.getSelected();
        var message = '<b>' + sel.data.name + '</b>: ' + _('Are you sure you want to rollback the job?');
        if (sel) {
            Ext.Msg.confirm(_('Confirmation'), message, function(btn) {
                if (btn == 'yes') {
                    Baseliner.ajaxEval('/job/rollback', sel.data, function(res) {
                        if (res.needs_confirmation) {
                            message += '<br><br>' + _('Force Rollback Warning');
                            buttons = {
                                yes: _("Yes, I'm sure"),
                                no: _('Cancel')
                            };
                            Ext.Msg.show({
                                title: _('Confirmation'),
                                msg: message,
                                buttons: buttons,
                                animEl: 'elId',
                                icon: Ext.MessageBox.WARNING,
                                fn: function(btn_force) {
                                    if (btn_force == 'yes') {
                                        sel.data.force_confirmation = 1;
                                        Baseliner.ajaxEval('/job/rollback', sel.data, function(res) {
                                                Baseliner.message(_('Rollback'), res.msg);
                                                grid.getStore().reload();
                                        });
                                    }
                                }
                            });
                        } else {
                            // TODO use an extjs Grid with links that open the job dashboard for each, and cols for Project and BL
                            if (res.success) {
                                Baseliner.message(_('Rollback'), res.msg);
                                grid.getStore().reload();
                            } else {
                                var deps = Ext.isArray(res.deps) ? res.deps.map(function(r){ return { job: r } }) : [];
                                var msg = function(){/*
                                      <div id="boot">
                                      <div class="container_24">
                                        <div class="grid_24">
                                        <h4>
                                            <img src="/static/images/icons/error.svg" style="vertical-align:middle">
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
                                    width: 800,
                                    height: 400,
                                    layout: 'fit',
                                    title: _('Dependencies'),
                                    items: [{
                                        xtype: 'panel',
                                        autoScroll: true,
                                        padding: 20,
                                        html: msg
                                    }]
                                });
                                win.show();
                            }
                        }
                    });
                }
            });
        }
    }

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

    var resumeButton = new Ext.Toolbar.Button({
        text: _('Resume'),
        hidden: true,
        icon:'/static/images/icons/play.svg',
        cls: 'x-btn-text-icon',
        handler: function(){
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var mode;
            if( sel.data.status_code == 'PAUSED' ) {
                Baseliner.resume_job(sel.data.mid,sel.data.name);
                resumeButton.hide();
            }
            else if( sel.data.status_code == 'TRAPPED' || sel.data.status_code == 'TRAPPED_PAUSED' ) {
                Baseliner.trap_check(sel.data.mid);
                resumeButton.hide();
            }
        }
    });

    var msg_cancel_delete = [ _('Cancel'), _('Delete') ];
    var cancelButton = new Ext.Toolbar.Button({
        text: msg_cancel_delete[0],
        disabled: true,
        icon:'/static/images/icons/delete.svg',
        cls: 'ui-btn-cancel x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var sc = sel.data.status_code;
            var mode;
            if( sc == 'RUNNING' ) {
                msg = _('Killing the job will interrupt current local processing but no remote processes');
                msg += "\n" + _('Are you sure you want to %1 the job?', _('kill') );
                mode = 'kill';
            } else if( sc == 'FINISHED' || sc == 'ERROR' || sc == 'CANCELLED' || sc == 'ABORT' || sc == 'KILLED' || sc == 'EXPIRED' ) {
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
                            if( res.success ) {
                                grid.getStore().reload();
                                if(sel.data.can_cancel){
                                    cancelButton.setText( msg_cancel_delete[1] );
                                }
                            } else {
                                Ext.Msg.alert( _('Error'), _('Could not delete the job: %1', res.msg ) );
                            }
                        });
                    }
                } );
        }
    });


    var rollbackButton = new Ext.Toolbar.Button({
        text: _('Rollback'),
        disabled: true,
        icon:'/static/images/icons/left.svg',
        cls: 'x-btn-text-icon',
        handler: function() { do_backout() }
    });

    var rerunButton = new Ext.Toolbar.Button({
        text: _('Rerun'),
        disabled: true,
        icon:'/static/images/icons/restart.svg',
        cls: 'ui-btn-restart x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if ( ! sm.hasSelection()) {
                Ext.Msg.alert(_('Error'), _('Select a row first'));
            } else {
                var sel = sm.getSelected();
                var data_users = sel.data.username == '<% $c->username %>' ? [ [sel.data.username] ] : [ ['<% $c->username %>'], [sel.data.username] ];
                var users = new Ext.data.SimpleStore({
                    fields: ['username'],
                    data: data_users
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
                    value: '<% $c->username %>',
                    mode: 'local',
                    editable: true,
                    triggerAction: 'all',
                    displayField: 'username'
                });
                var step_field = sel.data.step_code == 'END' ? 'PRE' : sel.data.step_code;
                var run_now = sel.data.step_code == 'END' ? true : false;
                var mid = sel.data.mid;
                var radio_post = new Ext.form.RadioGroup({
                    name: 'job_status',
                    defaults: {
                        xtype: "radio",
                        name: "last_finish_status"
                    },
                    fieldLabel: _('Job Status'),
                    hidden: true,
                    items: [{
                        boxLabel: _('OK'),
                        inputValue: '',
                        checked: true
                    }, {
                        boxLabel: _('FAIL'),
                        inputValue: 'ERROR'
                    }]
                });
                var changeJobStatusCheckbox = new Ext.form.Checkbox({
                    hidden: true,
                    fieldLabel: _('Change Job Status'),
                    listeners: {
                        check: function(info) {
                            if (info.checked) {
                                radio_post.show()
                                form_res.doLayout();
                            } else {
                                radio_post.hide()
                            };
                        }
                    }
                });
                var step_buttons = new Ext.Container({
                    layout: {
                        type: 'hbox'
                    },
                    fieldLabel: _('Initial Step'),
                    border: false,
                    items: ['PRE', 'RUN', 'POST', 'END'].map(function(st) {
                        var step_button = new Ext.Button({
                            text: st,
                            enableToggle: true,
                            width: 45,
                            style: {
                                'font-weight': (step_field == st ? 'bold' : '')
                            },
                            toggleGroup: 'step_buttons',
                            allowDepress: false,
                            pressed: step_field == st,
                            handler: function() {
                                if (this.text == 'POST') {
                                    changeJobStatusCheckbox.show();
                                    form_res.doLayout();
                                } else {
                                    changeJobStatusCheckbox.hide();
                                    changeJobStatusCheckbox.reset();
                                    radio_post.hide();
                                }
                            },
                            listeners: {
                                afterrender: function() {
                                    if (step_field == 'POST') {
                                        changeJobStatusCheckbox.show();
                                        form_res.doLayout();
                                    }
                                }
                            }
                        });
                        return step_button;
                    })
                });
                var form_res = new Ext.FormPanel({
                    frame: false,
                    autoHeight: true,
                    defaults: { width:'100%' },
                    bodyStyle:'padding: 15px',
                    items: [
                        user_combo, {
                            xtype: 'hidden',
                            name: 'mid',
                            value: sel.data.mid
                        }, {
                            xtype: 'hidden',
                            name: 'job_name',
                            value: sel.data.name
                        }, {
                            xtype: 'hidden',
                            name: 'starttime',
                            fieldLabel: _('Start Date'),
                            value: sel.data.starttime
                        }, {
                            xtype: 'checkbox',
                            name: 'run_now',
                            fieldLabel: _("Run Now"),
                            checked: run_now
                        },
                        step_buttons,
                        changeJobStatusCheckbox,
                        radio_post,
                    ],
                    buttons: [
                        {text:_('Rerun'), handler:function(f){
                            var but = this;
                            but.disable();
                            var form_data = form_res.getForm().getValues();
                            step_buttons.items.each(function(btn){
                                if( btn.pressed ) form_data.step = btn.text;
                            });
                            if (!changeJobStatusCheckbox.checked) {
                                delete form_data.last_finish_status;
                            }
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
                    autoHeight: true,
                    bodyStyle:'padding: 10px',
                    shadow:false,
                    items: form_res
                });
                win_res.show();
            }
        }
    });

    var rescheduleButton = new Ext.Toolbar.Button({
        text: _('Reschedule'),
        icon: '/static/images/date_field.png',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                if (sel.data.status_code != 'READY' && sel.data.status_code != 'APPROVAL') {
                    Baseliner.error(_('Reschedule'),
                        _("Job cannot be rescheduled unless its status is '%1' (current: %2)", _('READY') + "|" + _('APPROVAL'), _(sel.data.status)));
                    return;
                }
                var dateToday = new Date();
                Baseliner.ajaxEval('/job/build_job_window', {
                        bl: sel.data.bl,
                        job_date: dateToday.format('Y-m-d'),
                        job_contents: JSON.stringify({
                            mid: sel.data.mid
                        }),
                        date_format: '%Y-%m-%d'
                    },
                    function(res) {
                        if (res.success) {
                            var timeStore = new Ext.data.SimpleStore({
                                id: 'time',
                                fields: ['time', 'name', 'type', 'env_date']
                            });
                            var timeTpl = new Ext.XTemplate(
                                '<tpl for=".">',
                                '<div class="search-item">',
                                '<span style="color:{[ values.type=="N"?"green":(values.type=="U"?"red":"#444") ]}"><b>{time}</b> - {name}</span>',
                                '<span style="margin-left:8px; color: #333;font-weight:bold">',
                                '@{[ Cla.user_date_job(values.env_date, Cla.js_date_to_moment_hash[Cla.user_js_date_format()]) + " " + Cla.user_date_timezone().zoneName() ]}</span>',
                                '</div>',
                                '</tpl>'
                            );
                            var commentsTextArea = new Ext.form.TextArea({
                                anchor: '100%',
                                height: 80,
                                fieldLabel: _('Comments'),
                                name: 'comments'
                            });
                            var timeComboBox = new Ext.form.ComboBox({
                                name: 'job_time',
                                anchor: '100%',
                                hiddenName: 'job_time',
                                valueField: 'time',
                                displayField: 'time',
                                fieldLabel: _('Time'),
                                mode: 'local',
                                store: timeStore,
                                allowBlank: false,
                                typeAhead: true,
                                forceSelection: true,
                                triggerAction: 'all',
                                tpl: timeTpl,
                                itemSelector: 'div.search-item',
                                selectOnFocus: false
                            });
                            var outsideOfSlotsCheckbox = new Ext.form.Checkbox({
                                name: 'check_no_cal',
                                fieldLabel: '',
                                boxLabel: _("Create a job outside of the available time slots."),
                                hidden: !showCreateJobOutsideSlots,
                                disabled: !canCreateJobOutsideSlots,
                                cls: 'ui-chk-no-cal',
                                handler: function(chk, val) {
                                    var timeNow = new Date();
                                    if (val) {
                                        updateBtn.enable();
                                        timeStore.removeAll();
                                        timeStore.loadData(dataAnyTime());
                                        if (calendarDateField.value == timeNow.format(preferencesDateFormat)) {
                                            setFirstDateAvailable(timeStore, timeComboBox);
                                        } else {
                                            timeComboBox.setValue('00:00');
                                        }
                                    } else {
                                        var selectedDate = calendarDateField.getValue().format('Y-m-d');
                                        reloadCalendar(sel.data.bl, selectedDate, sel.data.mid, timeStore, calendarDateField, timeComboBox, updateBtn);
                                    }
                                }
                            });
                            var calendarDateField = new Ext.ux.form.XDateField({
                                anchor: '100%',
                                fieldLabel: _('Date'),
                                name: 'date',
                                value: dateToday,
                                format: preferencesDateFormat,
                                listeners: {
                                    'select': function(picker, t) {
                                        if (!outsideOfSlotsCheckbox.checked) {
                                            reloadCalendar(sel.data.bl, t.format('Y-m-d'), sel.data.mid, timeStore, calendarDateField, timeComboBox, updateBtn)
                                        }
                                    }
                                }
                            });
                            timeStore.on('load', function() {
                                setFirstDateAvailable(timeStore, timeComboBox);
                            });

                            var updateFormPanel = new Baseliner.FormPanel({
                                frame: true,
                                padding: 15,
                                items: [
                                    calendarDateField,
                                    timeComboBox,
                                    outsideOfSlotsCheckbox,
                                    commentsTextArea
                                ]
                            });
                            var updateBtn = new Ext.Toolbar.Button({
                                text: _('Update'),
                                icon: IC('edit.svg'),
                                handler: function() {
                                    if (outsideOfSlotsCheckbox.checked && commentsTextArea.getValue().trim().length == 0) {
                                        Ext.Msg.show({
                                            title: _('Failure'),
                                            msg: _('For the jobs outside of window it is required to add a reason to the comment field'),
                                            width: 500,
                                            buttons: {
                                                ok: true
                                            }
                                        });
                                        return;
                                    }
                                    var formValues = updateFormPanel.getValues();
                                    formValues.date = formValues.date.split(" ");
                                    formValues.date[1] = formValues.job_time;
                                    formValues.date = formValues.date.join(" ");
                                    Baseliner.ci_call(sel.data.mid, 'reschedule', formValues, function(res) {
                                        Baseliner.message(_('Reschedule'), res.msg);
                                        store.reload();
                                        updateWindow.close();
                                    });
                                }
                            });
                            var updateWindow = new Baseliner.Window({
                                layout: 'fit',
                                height: 280,
                                width: 380,
                                tbar: [
                                    '->', {
                                        text: _('Cancel'),
                                        icon: IC('close.svg'),
                                        handler: function() {
                                            updateWindow.close();
                                        }
                                    },
                                    updateBtn
                                ],
                                title: _('Update time and date of the job'),
                                items: updateFormPanel
                            });
                            updateWindow.show();
                            if (!res.data || res.data == 0) {
                                Ext.Msg.alert(_('Error'), _('There are no allowed windows for the job'));
                                updateBtn.disable();
                            } else {
                                timeStore.loadData(res.data);
                            }
                        }
                    }
                );
            } else {
                Ext.Msg.alert(_('Error'), _('Select a row first'));
            };
        }
    });

    var logButton = new Ext.Toolbar.Button({
        icon: '/static/images/icons/moredata.svg',
        text: _('Log'),
        cls: 'x-btn-text-icon ui-job-log',
        handler: function() {
            var sm = grid.getSelectionModel();
            if (sm.hasSelection()) {
                var sel = sm.getSelected();
                Baseliner.addNewTabComp('/job/log/list?mid=' + sel.data.mid + '&auto_refresh=1', sel.data.name);
            } else {
                Cla.message(_('Error'), _('Select a row first'));
            };
        }
    });

    var newjobButton = new Ext.Toolbar.Button({
        text: _('New'),
        icon: '/static/images/icons/job.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            Baseliner.add_tabcomp('/job/create', _('New Job'), {
                tab_icon: '/static/images/icons/job.svg'
            });
        }
    });

    //------------ Renderers
    var render_contents = function(value,metadata,rec,rowIndex,colIndex,store) {
        var return_value = new Array();
        if ( rec.data.changeset_cis && rec.data.changeset_cis.length > 0 ) {
          Ext.each(rec.data.changeset_cis, function(cs) {
            var link = '<a id="topic_'+ cs.mid +'_<% $iid %>" onclick="javascript:Baseliner.show_topic_colored(\''+ cs.mid + '\', \''+ cs.category.name + '\', \''+ cs.category.color + '\')" style="cursor:pointer;">'+ cs.category.name + ' #' + cs.mid + ' - ' + cs.title + '</a>';
            return_value.push(link);
          });
        } else {
          return_value = value;
        }
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
                String.format('<div style="height:20px;"><img style="float:left" src="/static/images/icons/{0}.svg" />&nbsp;{1}</div>', nat.icon, nat.name )
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

    function statusCodeToStatusName(statusCode) {
        var map = {
            REJECTED: _('Rejected'),
            CANCELLED: _('Cancelled'),
            TRAPPED: _('Trapped'),
            TRAPPED_PAUSED: _('Trapped_Paused'),
            ERROR: _('Error'),
            RUNNING: _('Running'),
            FINISHED: _('Finished'),
            KILLED: _('Killed'),
            'IN-EDIT': _('In-Edit'),
            WAITING: _('Waiting'),
            READY: _('Ready'),
            APPROVAL: _('Approval'),
            SUSPENDED: _('Suspended'),
            RESUME: _('Resume'),
            PAUSED: _('Paused'),
            REJECTED: _('Rejected'),
            ROLLBACK: _('Rollback'),
            ROLLBACKFAIL: _('Rollbackfail'),
            ROLLEDBACK: _('Rolledback'),
            PENDING: _('Pending'),
            SUPERSEDED: _('Superseded'),
            EXPIRED: _('Expired')
        };

        return map[statusCode] || statusCode;
    }

    var blRenderer = function(value) {
        return '<span id="boot" style="background-color: transparent">' +
            '<span class="label monitor-env-tag">' + value + '</span></span>';
    };

    var render_level = function(value,metadata,rec,rowIndex,colIndex,store,status) {
        var rollback = rec.data.rollback;
        var status = rec.data.status_code;
        var icon = Baseliner.getJobStatusIcon(status, rollback);
        var type   = rec.data.type_raw;
        var value = '<b>'+ statusCodeToStatusName(status) + '</b>';

        if( status == 'FINISHED' && rollback == 1 )  {
            value += ' (' + _('Rollback OK') + ')';
            icon = 'active.svg';
        }
        else if( status == 'ERROR' && rollback == 1 )  {
            value += ' (' + _('Rollback Failed') + ')';
        }
        else if( rollback == 1 )  {
            value += ' (' + _('Rollback') + ')';
        }

        if( status == 'APPROVAL' ) {
            value = String.format("<a href='javascript:Baseliner.request_approval(\"{0}\",\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id );
        }
        if( canResumeJob ) {
            if( status == 'PAUSED' ) {
                value = String.format("<a href='javascript:Baseliner.resume_job(\"{0}\",\"{3}\",\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id, rec.data.name );
            }
        }
        if( status == 'TRAPPED' || status == 'TRAPPED_PAUSED' ) { // add a link to the trap
            value = String.format("<a href='javascript:Baseliner.trap_check(\"{0}\",\"{2}\");'><b>{1}</b></a>", rec.data.mid, value, grid.id );
        }
        if( icon!=undefined ) {
            var err_warn = '';
            err_warn += rec.data.has_warnings > 0 ? '<img src="/static/images/icons/log_w_1.svg" />' : '';
            return div1
                + "<table><tr><td><img alt='"+status+"' border=0 src='/static/images/icons/"+icon+"' /></td>"
                + '<td>' + value + '</td><td>'+err_warn+'</td></tr></table>' + div2 ;
        } else {
            return value;
        }
    };

    var STATUSES = {
       'RUNNING': { cls: "info", active: true },
       'READY': { cls: "info" },
       'APPROVAL': { cls: "info" },
       'FINISHED': { cls:"success" },
       'IN-EDIT': { cls:"info" },
       'WAITING': { cls:"info" },
       'PAUSED': { cls:"info" },
       'TRAPPED': { cls:"warning" },
       'TRAPPED_PAUSED': { cls:"warning" },
       'CANCELLED': { cls: "danger" },
       'none': { cls: "danger" }
    };

    function progressBarRenderer(value, meta, rec) {
        var status = STATUSES[rec.data.status_code] || STATUSES['none'];
        var cls = status.cls || "info";
        var active = status.active;
        var prog = progressBar({
            content: '',
            progress: value,
            cls: cls,
            status,
            active: active
        });

        return prog;
    };

    function progressBar(args) {
        var template = {
            width: args.progress,
            content: args.progress + '%',
            color: 'white',
            cls: args.cls,
            active: args.active
        };
        var progress = template.width;
        if (progress == 0) {
            if (template.cls == 'danger') {
                template.color = 'red';
            } else {
                template.color = 'black';
            }
        }
        return function(){/*
            <span id="boot" style="background: transparent">
            <div class="progress progress-[%= cls %] [% if(active) { %] progress-striped active [% } %]" style="width: 100%; height: 12px">
                <div class="bar" style="color:[%= color %];font-size: 10px; line-height: 13px; width: [%= width %]%">[%= content %]</div>
            </div>
            </span>
        */}.tmpl(template);
    };

    var render_job = function(value, metadata, record){
        var contents = ''; record.data.contents.join('<br />');
        var execs = record.data.exec > 1 ? " ("+record.data.exec+")" : '';
        return String.format(
                '<b><a href="javascript:Baseliner.openLogTab(\'{1}\', \'{2}\');" style="font-family: Tahoma;">{0}{3}</a></b><br />',
                value, record.data.mid, record.data.name, execs );
    };

    function renderLast(value, p, r){
        return String.format('{0}<br/>by {1}', value.dateFormat('M j, Y, g:i a'), r.data['lastposter']);
    }

    function renderChangesetList(data) {
        var changesetTemplate;
        var changesetHtml = [];

        if (data.changeset_cis && data.changeset_cis.length) {
            changesetTemplate = new Ext.XTemplate([
                '<span',
                '  style="font-size: .92em; border-left: 4px solid {category_color}; padding-left: 4px;">',
                '  <a id="topic_{mid}_<% $iid %>"',
                '    onclick="',
                '      javascript:Baseliner.show_topic_colored(\'{mid}\', \'{category_name}\', \'{category_color}\')',
                '    "',
                '    style="cursor:pointer">',
                '    <span style="font-weight: bolder;">',
                '      {category_name} #{mid}',
                '    </span> - {title}',
                '  </a>',
                '  <tpl if="hasComments == true">',
                '      &nbsp;',
                '  <img',
                '     src="/static/images/icons/paperclip.svg"',
                '     style="cursor:pointer;height:12px;width:12px;"',
                '     onclick="javascript:(new Baseliner.view_field_content(\'{viewFieldContentData}\'))" />',
                '  </tpl>',
                '</span>'
            ], {
                compiled: true
            });

            Ext.each([].concat(data.changeset_cis, data.release_cis), function(changeset) {
                var comments = data.cs_comments[changeset.mid];
                var changesetRendered = changesetTemplate.apply({
                    mid: changeset.mid,
                    title: changeset.title,
                    category_name: changeset.category.name,
                    category_color: changeset.category.color,
                    hasComments: !!comments,
                    viewFieldContentData: Ext.util.JSON.encode({
                        username: "<% $c->username %>",
                        mid: changeset.mid,
                        field: comments,
                        title: changeset.category.name + ' #' + changeset.mid + ' - ' + changeset.title
                    })
                });
                changesetHtml.push(changesetRendered);
            });
        } else {
            changesetHtml.push(data.contents);
        }

        return new Ext.XTemplate([
            '<tpl if="description">',
            '  <div style="color: #333; font-weight: bold; padding: 2px 0px 10px 30px; white-space: pre">',
            '    <img style="vertical-align:middle" src="/static/images/icons/post.svg" />&nbsp;{description}',
            '  </div>',
            '</tpl>',
            '<tpl if="changesets">',
            '  <div style="color: #505050; margin: 0px 0px 5px 20px;">',
            '    <tpl for="changesets"><div>{.}</div></tpl>',
            '  </div>',
            '</tpl>',
        ], {
            compiled: true
        }).apply({
            description: data.comments,
            changesets: changesetHtml
        });
    }

    var gview = new Ext.grid.GroupingView({
        forceFit: true,
        enableRowBody: true,
        autoWidth: true,
        autoSizeColumns: true,
        deferredRender: true,
        startCollapsed: false,
        stripeRows: true,
        hideGroupedColumn: true,
        getRowClass: function(record, index, p, store) {
            var css = [];

            if (!Ext.isEmpty(record.data.comments) || record.data.changeset_cis) {
                css.push('x-grid3-row-expanded');
            }

            css.push(index % 2 > 0 ? 'level-row info-odd' : 'level-row info-even');

            p.body = renderChangesetList(record.data);

            return css.join(' ');
        }
    });

    var row_sel = new Ext.grid.RowSelectionModel({singleSelect:true});

    var filters = new Cla.GridFilters({
        menuFilterText: _('Filters'),
        encode: true,
        local: false,
        filters: [
           { type: 'date', dataIndex: 'starttime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'endtime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'maxstarttime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') },
           { type: 'date', dataIndex: 'schedtime', dateFormat: 'Y-m-d', beforeText: _('Before'), afterText: _('After'), onText: _('On') }
        ]
    });

    var tbar = new Ext.Toolbar({
        items: is_portlet ? [] : [
            searchField,
            htmlButton,
            menu_projects,
            menu_bl, nature_menu_btn, {
                icon: '/static/images/icons/state.svg',
                text: _('Status'),
                menu: menu_job_states
            },
            menu_type_filter, '-',
            canCreateJob ? newjobButton : [],
            logButton,
            canResumeJob ? resumeButton : [],
            canDeleteJob || canCancelJob ? cancelButton : [],
            canRestartJob || canForceRollback ? rollbackButton : [],
            canRestartJob ? rerunButton : [],
            canRestartJob || canReschedule ? rescheduleButton : [],
            '->',
            menu_tools,
            btn_reports,
            btn_clear_state,
            refresh_button
        ]
    });

    var grid = new Ext.grid.EditorGridPanel({
        cls: 'ui-job-monitor-grid',
        title: _('Monitor'),
        plugins: [ filters ],
        header: false,
        tab_icon: '/static/images/icons/television.svg',
        autoScroll: true,
        family: 'jobs',
        loadMask: true,
        stripeRows: true,
        stateful: true,
        stateId: stateId,
        store: store,
        view: gview,
        selModel: row_sel,
        columns: [
                { header: _('ID'), width: 60, dataIndex: 'id', sortable: true, hidden: true, groupable: false },
                { header: _('MID'), width: 60, dataIndex: 'mid', sortable: true, hidden: true, groupable: false },
                { header: _('Env'), width: 50, id: 'env-tag' , dataIndex: 'bl', sortable: true, renderer: blRenderer },
                { header: _('Job'), width: 140, dataIndex: 'name', sortable: true, renderer: render_job, groupable: false },
                { header: _('Job Status'), width: 130, dataIndex: 'status', renderer: render_level, sortable: true },
                { header: _('Status Code'), width: 60, dataIndex: 'status_code', hidden: true, sortable: true },
                { header: _('Progress'), width: 30, dataIndex: 'progress', sortable: false, hidden: true,  renderer: progressBarRenderer, groupable: false },
                { header: _('Step'), width: 50, dataIndex: 'step_code', sortable: true , hidden: false },
                { header: _('Project'), width: 70, dataIndex: 'applications', renderer: render_app, sortable: true, hidden: is_portlet ? true : false },
                { header: _('Natures'), width: 120, hidden: view_natures, dataIndex: 'natures', sortable: false, renderer: render_nature }, // not in DB
                { header: _('Subapplications'), width: 120, dataIndex: 'subapps', sortable: false, hidden: true, renderer: render_subapp }, // not in DB
                { header: _('Job Type'), width: 100, dataIndex: 'type', sortable: true, hidden: true },
                { header: _('User'), width: 80, dataIndex: 'username', sortable: true , renderer: Baseliner.render_user_field, hidden: is_portlet ? true : false},
                { header: _('Execution'), width: 80, dataIndex: 'exec', sortable: true , hidden: true },
                { header: _('Last Message'), width: 180, dataIndex: 'last_log', sortable: true , hidden: is_portlet ? true : true, groupable: false },
                { header: _('Changesets'), width: 100, dataIndex: 'changesets', renderer: render_contents, sortable: true, hidden: true, groupable: false },
                { header: _('Releases'), width: 100, dataIndex: 'releases', renderer: render_releases, sortable: true, hidden: true, groupable: false },
                { header: _('Local Scheduled'), width: 130, dataIndex: 'schedtime', sortable: true, renderer: Cla.render_date , hidden: true, groupable: false},
                { header: _('Local Start Date'), width: 130, dataIndex: 'starttime', sortable: true, renderer: Cla.render_date , hidden: true, groupable: false},
                { header: _('Local Max Start Date'), width: 130, dataIndex: 'maxstarttime', renderer: Cla.render_date, sortable: true, hidden: true, groupable: false },
                { header: _('Local End Date'), width: 130, dataIndex: 'endtime', renderer: Cla.render_date, sortable: true , hidden: true, groupable: false},
                { header: _('Scheduled'), width: 130, dataIndex: 'schedtime', sortable: true, renderer: Cla.render_date_format, hidden: is_portlet ? true : false, groupable: false},
                { header: _('Start Date'), width: 130, dataIndex: 'starttime', sortable: true, renderer: Cla.render_date_format, hidden: is_portlet ? true : false, groupable: false},
                { header: _('Max Start Date'), width: 130, dataIndex: 'maxstarttime', sortable: true, renderer: Cla.render_date_format, hidden: true, groupable: false },
                { header: _('End Date'), width: 130, dataIndex: 'endtime', sortable: true, renderer: Cla.render_date, hidden: is_portlet ? true : false, groupable: false},
                { header: _('Approval expiration'), width: 130, dataIndex: 'approval_expiration', sortable: true, hidden: true, groupable: false },
                { header: _('PID'), width: 50, dataIndex: 'pid', sortable: true, hidden: true, groupable: false },
                { header: _('Host'), width: 120, dataIndex: 'host', sortable: true, hidden: true },
                { header: _('Owner'), width: 120, dataIndex: 'owner', sortable: true, hidden: true },
                { header: _('Family'), width: 120, dataIndex: 'job_family', sortable: true, hidden: true },
                { header: _('Runner'), width: 80, dataIndex: 'runner', sortable: true, hidden: true },
                { header: _('Rule'), width: 80, dataIndex: 'rule_name', sortable: false, hidden: true },
                { header: _('When'), width: 120, dataIndex: 'when', hidden: true, sortable: true, renderer: render_ago, groupable: false },
                { header: _('Comments'), hidden: true, width: 150, dataIndex: 'comments', sortable: true, groupable: false },
                { header: _('PRE Start Date'), width: 130, dataIndex: 'pre_start', sortable: true , hidden: true, groupable: false },
                { header: _('PRE End Date'), width: 130, dataIndex: 'pre_end', sortable: true , hidden: true, groupable: false },
                { header: _('RUN Start Date'), width: 130, dataIndex: 'run_start', sortable: true , hidden: true, groupable: false },
                { header: _('RUN End Date'), width: 130, dataIndex: 'run_end', sortable: true , hidden: true, groupable: false }

            ],
        bbar: paging,
        tbar: tbar
    });

        grid.on("rowdblclick", function(grid, rowIndex, e ) {
            var r = grid.getStore().getAt(rowIndex);
            Baseliner.showLoadingMask( grid.getEl());
            Baseliner.openLogTab(r.get('mid') , r.get('name') );
            Baseliner.hideLoadingMaskFade(grid.getEl());
        });

    var first_load = true;
        row_sel.on('rowselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).addClass('x-grid3-row-selected-yellow');
        var sc = rec.data.status_code;
        resumeButton.hide();
        if ( rec.data.can_cancel || rec.data.can_delete ) {
            if( (sc == 'FINISHED' || sc == 'ERROR' || sc == 'CANCELLED' || sc == 'ABORT' || sc == 'KILLED' || sc == 'EXPIRED' ) && rec.data.can_delete == '1' ) {
                cancelButton.setText( msg_cancel_delete[1] );
                cancelButton.enable();
            } else if (rec.data.can_cancel == '1') {
                cancelButton.setText( msg_cancel_delete[0] );
                cancelButton.enable();
            } else {
                cancelButton.disable();
            }
        } else {
            cancelButton.disable();
        };
        if( rec.data.status_code === 'PAUSED' || rec.data.status_code === 'TRAPPED' || rec.data.status_code === 'TRAPPED_PAUSED' ) {
            resumeButton.show();
        }
        if (rec.data.can_restart == '1'){
            rollbackButton.enable();
            rerunButton.enable();
        } else if (rec.data.force_rollback) {
            rollbackButton.enable();
        } else {
            rollbackButton.disable();
            rerunButton.disable();
        };
    });
    row_sel.on('rowdeselect', function(row, index, rec) {
        Ext.fly(grid.getView().getRow(index)).removeClass('x-grid3-row-selected-yellow');
    });
    function reloadCalendar(bl, jobDate, mid, timeStore, calendarDateField, timeComboBox, updateBtn) {
        Baseliner.ajaxEval('/job/build_job_window', {
            bl: bl,
            job_date: jobDate,
            job_contents: JSON.stringify({
                mid: mid
            }),
            date_format: '%Y-%m-%d'
        }, function(res) {
            timeStore.loadData(res.data);
            var timeNow = new Date();
            var existsTimeAvailable = false;
            if (calendarDateField.value == timeNow.format(preferencesDateFormat)) {
                for (var i = 0; i < timeStore.totalLength; i++) {
                    if (timeStore.getAt(i).data.time >= timeNow.format('H:i')) {
                        timeComboBox.setValue(timeStore.getAt(i).data.time);
                        existsTimeAvailable = true;
                        break;
                    }
                }
                if (!existsTimeAvailable) {
                    thereAreNoSlots(updateBtn);
                    return;
                }
            } else {
                if (!timeStore.getAt(0)) {
                    thereAreNoSlots(updateBtn);
                    return;
                }
                timeComboBox.setValue(timeStore.getAt(0).data.time);
            }
            updateBtn.enable();
        });
    }

    function setFirstDateAvailable(timeStore, timeComboBox) {
        var timeNow = new Date();
        for (var i = 0; i < timeStore.totalLength; i++) {
            if (timeStore.getAt(i).data.time >= timeNow.format('H:i')) {
                timeComboBox.setValue(timeStore.getAt(i).data.time);
                break;
            }
        };
    }

    function thereAreNoSlots(updateBtn) {
        Ext.Msg.alert(_('Error'), _('There are no allowed windows for the job'));
        updateBtn.disable();
    }

    grid.on("activate", function() {
        if( first_load ) {
            Baseliner.showLoadingMask( grid.getEl());
            first_load = false;
        }
    });
    store.load({params:{start:0 , limit: ps }, callback: function(){
      Baseliner.hideLoadingMaskFade(grid.getEl());
    } });

    grid.on('destroy', function(){
        autorefresh.stop(task);
    });

    grid.get_current_state = function(){
        return { baseParams: grid.store.baseParams }
    }
    return grid;
})
