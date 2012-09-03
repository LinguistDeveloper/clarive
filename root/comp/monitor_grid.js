<%args>
  $natures_json    => $ARGS{natures_json} 
  $job_states_json => $ARGS{job_states_json}
  $envs_json       => $ARGS{envs_json}
  $types_json      => $ARGS{types_json}
</%args>
(function(){
   
    // Eric
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
            {  name: 'key' },
            {  name: 'starttime' },
            {  name: 'schedtime' },
            {  name: 'last_log' },
            {  name: 'contents' },
            {  name: 'applications' },
            {  name: 'maxstarttime' },
            {  name: 'endtime' },
            {  name: 'runner' },
            {  name: 'rollback' },
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
            {  name: 'natures' }, // Eric
            {  name: 'subapps' }  // Eric
        ]
    );

    // Eric
    // Filtro por naturaleza
    var natures = <% $natures_json %>;
    var nature_menu = natures.map(function (x) {
      // Por defecto siempre se van a mostrar en uppercase, pero tampoco está de más filtrar un poco esto.
      var nature_name = x.name == 'ZOS'      ? 'z/OS' 
                      : x.name == 'FICHEROS' ? 'Ficheros'
                      : x.name == 'TODAS'    ? 'Todas'
                      : x.name
                      ;
      return {
        text: nature_name,
        icon: '/static/images/' + x.icon + '.png',
        handler: function (item) { 
            item.parentMenu.setText( '>> ' + nature_name );
          // alert("Filtrando por naturaleza " + nature_name);
          store.load({
            params: {
              current_nature: x.key
            }
          });
          return;
        }
      }
    });
    nature_menu.push({
      icon: '/static/images/nature.all.png',
      text: 'TODAS',
      handler: function () {
        // alert("Mostrando todas las naturalezas.");
        store.load({
          params: {
            current_nature: 'ALL'
          }
        });
      }
    });
    var naturalezas = new Ext.Button({
      text: 'Naturalezas',
      icon: '/static/images/reload.gif',
      menu: nature_menu
    });
    // Filtro por estado del job
    var job_states_json = <% $job_states_json %>;
    var job_states_check_state = {
      CANCELLED: true,
      ERROR: true,
      EXPIRED: true,
      FINISHED: true,
      KILLED: true,
      RUNNING: true,
      WAITING: true
    };
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
        id: x.name,
        text: _(x.name),
        checked: job_states_check_state[x.name],
        checkHandler: function (obj) {
          modify_job_states_check_state(obj.id);
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
    // Filtro por entorno...
    var menu_list = <%$envs_json%>.map(function (x) {
      return {
        text: x.name,
        icon: '/static/images/icons/' + x.name + '.png',
        handler: function () {
          store.load({
            params: {
              env_filter: x.name
            }
          });
        }
      };
    });
    var menu_env = new Ext.Button({
      text: "Entorno",
      menu: menu_list
    });
    // Ahora ponemos un filtro por tipo... de momento chapu y hard-coded.
    var menu_filter_type_list = <%$types_json%>.map(function (x) {
      return {
        text: x.text,
        icon: '/static/images/icons/type.' + x.name + '.png',
        handler: function () {
          // alert('Filtrando por tipo ' + x.text);
          store.load({
            params: {
              type_filter: x.name
            }
          });
        }
      }
    });
    var menu_type_filter = new Ext.Button({
      text: 'Tipo',
      menu: menu_filter_type_list
    });
    // end

    var group_field = 'grouping';

    var store = new Baseliner.GroupingStore({
            reader: reader,
            url: '/job/monitor_json',
            baseParams: { limit: ps },
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
    paging.on('beforechange', function(){ refresh_stop(); });

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
    var task = {
        run: function() {
            var ids=[];
            var top_id=0;
            var q = store.baseParams['query']; //current search query 
            if( q != undefined && q !='' ) { return; } //no refresh while querying
            refresh_button_on();
            store.each( function(rec) {
                var id = rec.data.id;
                if( id>top_id ) top_id = id;
                ids.push(id);
            });
            Ext.Ajax.request({
                url: '/job/refresh_now',
                params: { ids: ids, top: top_id },
                failure: function(xhr) { },
                success: function(xhr) {
                    refresh_button_off();
                    try {
                        var res = xhr.responseText;
                        var data = Ext.util.JSON.decode( res );
                        if( last_magic>0 && data.magic!=last_magic ) {
                            store.load();
                        } 
                        if( data.need_refresh > 0 ) {
                            store.load();
                        }
                        last_magic = data.magic;
                    } catch(e) { }
                }
            });
        },
        interval: 30000
    };
    var autorefresh = new Ext.util.TaskRunner();
    var refresh_set = function( item, checked ) {
        if( checked && item.value>0 ) {
            task.interval = item.value * 1000;
            autorefresh.start(task); 
        } 
        else if( checked && item.value<1 ) {
            autorefresh.stop( task );
        }
    };
    var refresh_button_on = function() { refresh_button.getEl().setOpacity( .3 ); };
    var refresh_button_off = function() { refresh_button.getEl().setOpacity( 1 ); };
    var refresh_menu = new Ext.menu.Menu({
            items: [
                { text: _('Stopped'), value: 0, checked: true, group: 'refresh', checkHandler: refresh_set },
                { text: _('%1 seconds', 15), value: 15, checked: true, group: 'refresh', checkHandler: refresh_set },
                { text: _('%1 seconds', 30), value: 30, checked: true, group: 'refresh', checkHandler: refresh_set },
                { text: _('%1 minute', 1), value: 60, checked: true, group: 'refresh', checkHandler: refresh_set },
                { text: _('%1 minutes', 5), value: 300, checked: true, group: 'refresh', checkHandler: refresh_set }
            ]
    });
    var refresh_button = new Ext.Toolbar.Button({
                    text: _('Refresh'),
                    icon: '/static/images/icons/time.gif', 
                    cls: 'x-btn-text-icon',
                    menu: refresh_menu
    });
    var refresh_stop = function() {
        refresh_menu.items.first().setChecked(true);
        autorefresh.stop(task);
    };

    var button_html = new Ext.Toolbar.Button({ icon: '/static/images/icons/html.gif',
        style: 'width: 30px', cls: 'x-btn-icon', hidden: false,
        handler: function(){
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            if( sel != undefined && sel.data.key != undefined ) {
                var win = window.open( '/job/log/html/' + sel.data.key  );
            }
        } 
    });

    var msg_cancel_delete = [ _('Cancel Job'), _('Delete Job') ];
    var button_cancel = new Ext.Toolbar.Button({
        text: msg_cancel_delete[0],
        icon:'/static/images/del.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var sm = grid.getSelectionModel();
            var sel = sm.getSelected();
            var mode;
            if( sel.data.status_code == 'RUNNING' ) {
                msg = _('Killing the job will interrupt current local processing but no remote processes');
                msg += "\n" + _('Are you sure you want to %1 the job?', _('kill') );
                mode = 'kill';
            } else if( sel.data.status_code == 'CANCELLED' ) {
                msg = _('Are you sure you want to %1 the job?', _('delete') );
                mode = 'delete';
            } else {
                msg = _('Are you sure you want to %1 the job?', _('cancel') );
                mode = 'cancel';
            }
            Ext.Msg.confirm(_('Confirmation'),  '<b>' + sel.data.name + '</b>: ' + msg, 
                function(btn){ 
                    if(btn=='yes') {
                        Baseliner.ajaxEval( '/job/submit',  { action: 'delete', mode: mode, id_job: sel.data.id }, function(res){
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
        if( value.length < 2 ) return value[0];
        return value.join('<br />');
    };

    var render_nature = function(v,meta,rec,rowIndex,colIndex,store) {
        if( ! v ) return '' ;
        var ret = new Array();
        Ext.each( v, function( r ) {
            if( ! r ) return;
            ret.push( 
                String.format('<div style="height:20px;"><img style="float:left" src="/static/images/icons/nature/{0}.png" />&nbsp;{1}</div>', r, r.toUpperCase() )
            );
        });
        return ret.join('');
    };

    var render_subapp = function(v,meta,rec,rowIndex,colIndex,store) {
        if( ! v ) return '';
        if( typeof v != 'object' ) return v;
        return Baseliner.render_wrap( v.join(', ') );
    };

    var render_job = function(value,metadata,rec,rowIndex,colIndex,store) {
        return '<b><span style=\'font-family: "Verdana"; font-size: "7pt" \'>' + value + '</span></b>';
    };
    var render_level = function(value,metadata,rec,rowIndex,colIndex,store) {
        var icon;
        var bold = false;
        var status = rec.data.status_code;
        var type   = rec.data.type_raw;
        var rollback = rec.data.rollback;
        if( status=='RUNNING' ) { icon='gears.gif'; bold=true }
        else if( status=='READY' ) icon='waiting.png';
        else if( status=='APPROVAL' ) icon='verify.gif';
        else if( status=='FINISHED' && rollback!=1 ) { icon='log_i.gif'; bold=true; }
        else if( status=='IN-EDIT' ) icon='log_w.gif';
        else if( status=='WAITING' ) icon='waiting.png';
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
        //else if( type == 'demote' || type == 'rollback' ) value += ' ' + _('(Rollback)');
        if( status == 'APPROVAL' ) { // add a link to the approval main
            value = String.format("<a href='javascript:Baseliner.addNewTabComp(\"{0}\", \"{1}\");'>{2}</a>", "/request/main", _('Approvals'), value ); 
        }
        if( icon!=undefined ) {
            return div1 
                + "<img alt='"+status+"' style='vertical-align:middle' border=0 src='/static/images/"+icon+"' />"
                + value + div2 ;
        } else {
            return value;
        }
    };

    Baseliner.openLogTab = function(id, name) {
        Baseliner.addNewTabComp('/job/log/list?id_job=' + id, _('Log') + ' ' + name, { tab_icon: '/static/images/icons/moredata.gif' } );
    };

    var render_topic = function(value, p, record){
        var contents = ''; record.data.contents.join('<br />');
        return String.format(
                '<b><a href="javascript:Baseliner.openLogTab({1}, \'{2}\');" style="font-family: Tahoma;">{0}</a></b><br />',
                value, record.id, record.data.name ); 
    };

    function renderLast(value, p, r){
        return String.format('{0}<br/>by {1}', value.dateFormat('M j, Y, g:i a'), r.data['lastposter']);
    }
    

    var fupdatepanel = new Ext.FormPanel({
        frame: true,
        url: '/job/job_update', 
        buttons: [
            {  text: 'Actualizar', handler: function(){ return false; } }
            ,{  text: 'Cancelar', handler: function(){ winupdate.hide(); } }
        ],
        items: [
            {  xtype: 'hidden', name: 'id_job', value: '' },
            {
                xtype: 'datefield',
                fieldLabel: _('Date'),
                name:'_job_calendar',
                value: new Date(),
                format: 'd/m/y'
            },
          {
            xtype: 'uxspinner', 
            name: '_job_time', 					
            fieldLabel: _('Time'),
            allowBlank: false,
            value: new Date().format('H:i'),
            strategy: new Ext.ux.form.Spinner.TimeStrategy()				  
          }		   
        ]
    });

    var winupdate = new Ext.Window({
        layout: 'fit',
        closeAction: 'hide',
        height: 150, width: 280,
        title: 'Modificar fecha y hora del pase.',
        items: fupdatepanel
    });
    
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
                    p.body +='<div style="color: #333; font-weight: bold; margin: 0 0 5 30;">';
                    p.body += '<img style="vertical-align:middle" src="/static/images/icons/post.gif">';
                    p.body += '&nbsp;' + desc + '</img></div>';
                    css += ' x-grid3-row-expanded '; 
                }
                var cont = record.data.contents;
                if( cont != undefined ) {
                    p.body +='<div style="color: #505050; margin: 0 0 5 30;">';
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
                { header: _('ID'), width: 30, dataIndex: 'id', sortable: true, hidden: true },
                { header: _('MID'), width: 30, dataIndex: 'mid', sortable: true, hidden: true },
                { header: _('Job'), width: 140, dataIndex: 'name', sortable: true, renderer: render_topic },    
                { header: _('Job Status'), width: 130, dataIndex: 'status', renderer: render_level, sortable: true },
                { header: _('Application'), width: 70, dataIndex: 'applications', renderer: render_app, sortable: true, hidden: is_portlet ? true : false },
                { header: _('Baseline'), width: 50, dataIndex: 'bl', sortable: true },
                { header: _('Natures'), width: 120, dataIndex: 'natures', sortable: true, renderer: render_nature }, // Eric
                { header: _('Subapplications'), width: 120, dataIndex: 'subapps', sortable: false, renderer: render_subapp }, // Eric
                { header: _('Job Type'), width: 100, dataIndex: 'type', sortable: true, hidden: false },
                { header: _('User'), width: 80, dataIndex: 'username', sortable: true , renderer: Baseliner.render_user_field, hidden: is_portlet ? true : false},	
                { header: _('Step'), width: 80, dataIndex: 'step', sortable: true , hidden: true },	
                { header: _('Execution'), width: 80, dataIndex: 'exec', sortable: true , hidden: true },	
                { header: _('Last Message'), width: 180, dataIndex: 'last_log', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Contents'), width: 100, dataIndex: 'contents', renderer: render_contents, sortable: true, hidden: true },
                { header: _('Scheduled'), width: 130, dataIndex: 'schedtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Start Date'), width: 130, dataIndex: 'starttime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('Max Start Date'), width: 130, dataIndex: 'maxstarttime', sortable: true, hidden: true },	
                { header: _('End Date'), width: 130, dataIndex: 'endtime', sortable: true , hidden: is_portlet ? true : false},	
                { header: _('PID'), width: 50, dataIndex: 'pid', sortable: true, hidden: true },	
                { header: _('Host'), width: 120, dataIndex: 'host', sortable: true, hidden: true },	
                { header: _('Owner'), width: 120, dataIndex: 'owner', sortable: true, hidden: true },	
                { header: _('Grouping'), width: 120, dataIndex: 'grouping', hidden: true },	
                { header: _('Comments'), hidden: true, width: 150, dataIndex: 'comments', sortable: true }
            ],
        bbar: paging,        
        tbar: is_portlet ? [] : [ _('Search') + ': ', ' ',
                search_field,
                // Eric
                naturalezas, { text: 'Estado', menu: menu_job_states }, menu_env, menu_type_filter, '-',
                // end
% if( $c->stash->{user_action}->{'action.job.create'} ) {
                new Ext.Toolbar.Button({
                    text: _('New Job'),
                    icon:'/static/images/star_on.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        Baseliner.addNewTabComp('/job/create', _('New Job') );
                    }
                }),
% }
                new Ext.Toolbar.Button({
                    text: _('View Log'),
                    icon:'/static/images/icons/moredata.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            Baseliner.addNewTabComp('/job/log/list?id_job=' + sel.data.id, _('Log') + ' ' + sel.data.name );
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
% if( $c->stash->{user_action}->{'action.job.create'} ) {
                button_cancel,
% }
% if( $c->stash->{user_action}->{'action.job.restart'} ) {
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
                            var form_res = new Ext.FormPanel({ 
                                url: '/job/restart',
                                frame: false,
                                height: 150,
                                defaults: { width:'100%' },
                                bodyStyle:'padding: 10px',
                                items: [
                                    user_combo,
                                    { xtype: 'hidden', name:'id_job', value: sel.data.id },
                                    { xtype: 'hidden', name:'job_name', value: sel.data.name },
                                    { xtype: 'hidden', name:'starttime',fieldLabel: _('Start Date'), value: sel.data.starttime },
                                    { xtype: 'checkbox', name: 'run_now', fieldLabel : _("Run Now"), checked: run_now },
                                    step_combo
                                ],
                                buttons: [
                                    {text:_('Rerun'), handler:function(f){ form_res.getForm().submit({
                                            success: function(resp,opt) {
                                                Baseliner.message( sel.data.name, _('Job Restarted') );
                                                store.load();
                                                win_res.close();
                                            },
                                            failure: function(resp,opt) { Baseliner.message(_('Error'), _('Could not rerun the job.')); }
                                    }) }
                                    },
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
                                            params: { action: 'rerun', id_job: sel.data.id },
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
% if( $c->stash->{user_action}->{'action.job.reschedule'} ) {
                new Ext.Toolbar.Button({
                    text: _('Modify Job'),
                    icon:'/static/images/date_field.png',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            var fecha = Date.parseDate(sel.data.starttime, 'Y-m-d H:i:s' );
                            winupdate.show();
                            fupdatepanel.getForm().findField("_job_calendar").setValue(fecha.format("d/m/Y"));
                            //fupdatepanel.getForm().findField("_job_timer").setValue(fecha.format("H:i"));
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
% }
                new Ext.Toolbar.Button({
                    text: _('Export'),
                    icon:'/static/images/download.gif',
                    cls: 'x-btn-text-icon',
                    handler: function() {
                        var sm = grid.getSelectionModel();
                        if (sm.hasSelection())
                        {
                            var sel = sm.getSelected();
                            Baseliner.message( _('Job Export'), _('Job export started. Wait a few minutes...') );
                            var fd = document.all.FD || document.all.FrameDownload;
                            fd.src =  '/job/export?id_job=' + sel.data.id ;
                        } else {
                            Ext.Msg.alert(_('Error'), _('Select a row first'));   
                        };
                    }
                }),
                '->',
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
        if( rec.data.status_code === 'CANCELLED' ) {
            button_cancel.setText( msg_cancel_delete[1] );
        } else {
            button_cancel.setText( msg_cancel_delete[0] );
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
})();
