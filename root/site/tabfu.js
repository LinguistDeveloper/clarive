/*

 tabfu.js - window, tab and component management

*/

// Routing
if( Prefs.routing ) {
    Baseliner.route_regex = /^#!\/(\w+)\:(.*)$/;
    Baseliner.route = function (path) {
        var match = Baseliner.route_regex.exec( path );
        if( ! match || ! Ext.isArray(match) || match.length < 2 ) return;
        var action = match[1];
        var route  = match[2];
        switch( action ) {
            case 'tab': 
                if( Ext.getCmp( route ) ) {
                    Baseliner.tabpanel().setActiveTab( route );
                } else {
                    // not good, messes up history: Baseliner.route_clean();
                }
                break;
       }
    }
    Baseliner.route_clean = function () {
        window.location.hash = '';
    }

    $(window).bind('hashchange', function(e)
    {
        Baseliner.route(window.location.hash);
    });
    $('a').click(function(event) {
        event.preventDefault();
        $(this).attr('href', '/#!/'+$(this).attr('href'));
    });
}

/* if (false && typeof history.pushState !== 'undefined') 
{
    $(window).bind('popstate', function(e)
    {
        Baseliner.route(window.location.pathname);
    });
    $('a').click(function(event) {
        event.preventDefault();
        history.pushState({},'',this.href);
    });
} else {
}
*/

    Baseliner.tabpanel = function() { return Ext.getCmp('main-panel') };
    Baseliner.eventKey = function(key) {
        var f = Baseliner.keyMap[ key ];
        if( f!=undefined ) {
            return f();
        } else {
            //alert( key );
        }
    };

    Baseliner.tab_switch = function(step) {
        var tabpanel = Baseliner.tabpanel();
        var tab = tabpanel.getActiveTab();
        var tab_index = tabpanel.items.findIndex('id', tab.id );
        if( step < 0 && tab_index > 0 ) {
            var next = tabpanel.items.get( tab_index + step );
            tabpanel.setActiveTab( next );
        } else if( step > 0 && tab_index < tabpanel.items.getCount()-1 ) {
            var next = tabpanel.items.get( tab_index + step );
            tabpanel.setActiveTab( next );
        }
    };

    // F5
    Baseliner.keyMap[ 116 ] = function() { Baseliner.refreshCurrentTab(); return false };
    // left arrow = 37 , F9 = 120
    Baseliner.keyMap[ 120 ] = function() { Baseliner.tab_switch(-1); return true };
    // right arrow = 39, F10 = 121
    Baseliner.keyMap[ 121 ] = function() { Baseliner.tab_switch(1); return true };

    // Generates a pop-in message
    // User stuff
    Baseliner.user_actions = function( params ) {
        Ext.Ajax.request({
            //url: '/user/actions',
            url: '/user/info',
            params: params,
            success: function(xhr) {
                try {
                    var comp = eval(xhr.responseText);
                    var win = new Ext.Window({
                        //layout: 'fit', 
                        autoScroll: true,
                        title: "<% _loc('User Actions') %>",
                        //height: 400,
            autoHeight: true,
            width: 730, 
                        items: [ { 
                                //xtype: 'panel', 
                                //layout: 'fit', 
                                items: comp
                        }]
                    });
                    win.show();
                } catch(err) {
                    //TODO something
                }
            },
            failure: function(xhr) {
                //TODO something
            }
        });

    };

    /* qtip: ''
    Ext.override(Ext.form.Field, {
        afterRender : Ext.form.Field.prototype.afterRender.createSequence(function() {
                var qt = this.qtip;
                if (qt) {
                    Ext.QuickTips.register({
                        target:  this,
                        title: '',
                        text: qt,
                        enabled: true,
                        showDelay: 20
                    });
                }
        })
    });
    */
    Ext.override(Ext.form.Field, {
        setFieldLabel : function(text) {
            if (this.rendered) {
                this.el.up('.x-form-item', 10, true).child('.x-form-item-label').update(text + ':');
            }
            this.fieldLabel = text;
        }
    });

    Baseliner.DropTarget = Ext.extend(Ext.dd.DropTarget, {
        constructor : function(el, config){
            Baseliner.DropTarget.superclass.constructor.call(this, el, config);        
            
            if( this.comp ) {
                this.comp.on( 'beforedestroy', function(){
                    this.destroy();
                }, this);    
            }
        }
    });    



    Baseliner.openWindowPage = function(params) {
    };

    Baseliner.openWindowComp = function(params) {
    };

    // open a window given a username link
    Baseliner.render_user_field  = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value==undefined || value=='null' || value=='' ) return '';
        
        if (rec && rec.data){
            if (rec.data.active == undefined){
                var script = String.format('javascript:Baseliner.showAjaxComp("/user/info/{0}")', value);
                return String.format("<a href='{0}'>{1}</a>", script, value );
            }
            else{
                if (rec.data.active > 0){
                    var script = String.format('javascript:Baseliner.showAjaxComp("/user/info/{0}")', value);
                    return String.format("<a href='{0}'>{1}</a>", script, value );                    
                }
                else{
                    return String.format('<span style="text-decoration: line-through">{0}</span>',value);
                }
            }
        }
        else{
            var script = String.format('javascript:Baseliner.showAjaxComp("/user/info/{0}")', value);
            return String.format("<a href='{0}'>{1}</a>", script, value );  
        }
    };

    Baseliner.render_active  = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value==undefined || value=='null' || value=='' || value==0 || value=='0' ) return _('No');
        return _('Yes');
    };

    Baseliner.quote = function(str) {
        return str.replace( /\"/g, '\\"' );
    };

    Baseliner.render_job = function(value,metadata,rec,rowIndex,colIndex,store) {
        if( value!=undefined && value!='' ) {
            var id_job = rec.data.id_job;
            return "<a href='#' onclick='javascript:Baseliner.addNewTabComp(\"/job/log/list?mid="+id_job+"\",\""+ _("Log") + " " +value+"\"); return false;'>" + value + "</a>" ;
        } else {
            return '';
        }
    };
    
    Baseliner.doLoginForm = function(lf, params, cb ){
        var ff = lf.getForm();
        params = params==undefined ? {} : params;
        ff.submit({
            success: function(form, action) {
                            var last_login = form.findField('login').getValue();
                            if( params.cook ) {
                                Baseliner.cookie.set( 'last_login', last_login ); 
                            }
                            if( params.no_reload ) {
                                cb();	
                                params.on_login( params.scope );
                            } else {
                                document.location.href = document.location.href;
                                //window.location.reload();
                            }
                     },
            failure: function(form, action) {
                            Ext.Msg.alert('<% _loc('Login Failed') %>', action.result.msg );
                            form.findField('login').focus('',100);
                      }
        });
   };

   Baseliner.change_password = function() {
       var change_pass_form = new Ext.FormPanel({
            url: '/user/change_pass',
            frame: true,
            labelWidth: 100, 
            timeout: 120,
            defaults: { width: 175,
            inputType:'password'
        },
        defaultType: 'textfield',	    
        items: [
        {
          fieldLabel: _('Old Password'),
          name: 'oldpass'
        },		
        {
          fieldLabel: _('New Password'),
          name: 'newpass',
          id: 'newpass'
        },{
          fieldLabel: _('Confirm Password'),
          name: 'pass-cfrm',
          vtype: 'password',
          initialPassField: 'newpass'
        }],
            buttons: [
                { text: _('Aceptar'),
                  handler: function() {
            var form = change_pass_form.getForm();
            
            if (form.isValid()) {
                   form.submit({
                   success: function(f,a){
                    Baseliner.message(_('Success'), a.result.msg );
                    win_change.close(); 
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
                { text: _('Cancelar'),
                  handler: function() {
                win_change.close();  
                           }
                }
            ]	    
        });
       
        var win_change = new Ext.Window({
        id: 'win_change',
            title: _('Change password'),
            width: 350,
        modal: true,
        autoHeight: true,
            items: [ change_pass_form ]
         });
    
        win_change.show();       
    }
    
    Ext.apply(Ext.form.VTypes, {
    password : function(val, field) {
        if (field.initialPassField) {
        var pwd = Ext.getCmp(field.initialPassField);
        return (val == pwd.getValue());
        }
        return true;
    },
    
    passwordText : 'Passwords do not match'
    });    


    Baseliner.surrogate = function() {
       var login_form = new Ext.FormPanel({
            url: '/auth/surrogate',
            frame: true,
            labelWidth: 100, 
            timeout: 120,
            defaults: { width: 150 },
            buttons: [
                { text: '<% _loc('Change User') %>',
                  handler: function() { Baseliner.doLoginForm(login_form) }
                },
                { text: '<% _loc('Reset') %>',
                  handler: function() {
                                login_form.getForm().findField('login').focus('',100);
                                login_form.getForm().reset()
                           }
                }
            ],
            items: [ 
                {  xtype: 'textfield', name: 'login', fieldLabel: "<% _loc('Username') %>", selectOnFocus: true }
            ]
        });
        var win_surr = new Ext.Window({ layout: 'fit', 
            id: 'surr-win',
            autoScroll: true, title: "<% _loc('Surrogate') %>",
            height: 110, width: 300, 
            items: [ login_form ]
            });
        win_surr.show();
        var map = new Ext.KeyMap("surr-win", [{
            key : [10, 13],
            scope : win_surr,
            fn : function() { Baseliner.doLoginForm(login_form) }
        }]); 
        login_form.getForm().findField('login').focus('',100);
    };

    Baseliner.login = function(params) {
       params = params==undefined ? {} : params;
       params.cook = true;
       var win;
       var cb = function(){ win.close(); };
       var login_form = new Ext.FormPanel({
            url: '/login',
            frame: true,
            labelWidth: 100, 
            defaults: { width: 150 },
            buttons: [
                { text: '<% _loc('Login') %>',
                  handler: function() { Baseliner.doLoginForm(login_form, params, cb ); }
                },
                { text: '<% _loc('Reset') %>',
                  handler: function() {
                                login_form.getForm().findField('login').focus('',100);
                                login_form.getForm().reset()
                           }
                }
            ],
            items: [
                {  xtype: 'textfield', name: 'login', fieldLabel: "<% _loc('Username') %>", selectOnFocus: true }, 
                {  xtype: 'textfield', name: 'password', inputType:'password', fieldLabel: "<% _loc('Password') %>" } 
            ]
        });
        win = new Ext.Window({ layout: 'fit', 
            autoScroll: true, title: _('Login'),
            height: 150, width: 300, 
            items: [ login_form ]
            });
        win.on('afterrender', function(){
            var map = new Ext.KeyMap( win.id , [{
                key : [10, 13],
                scope : win,
                fn : function() { Baseliner.doLoginForm(login_form, params, cb ) }
            }]); 
        });
        win.show();
        var last_login = Baseliner.cookie.get( 'last_login'); 
        if( last_login!=undefined && last_login.length > 0 )  {
            login_form.getForm().findField('login').setValue( last_login );
            login_form.getForm().findField('password').focus('',100);
        } else {
            login_form.getForm().findField('login').focus('',100);
        }
    };

    Ext.override(Ext.TabPanel, {
      changeTabIcon : function(item, icon){
        var el = this.getTabEl(item);
        if(el && icon!=undefined && icon!='' ){
            Ext.fly(el).addClass('x-tab-with-icon').child('span.x-tab-strip-text').setStyle({backgroundImage:'url('+icon+')'});
        }
      }
    });

    Baseliner.addNewTabDiv = function( div, ptitle){
            var tab = Ext.getCmp('main-panel').add( div );
            Ext.getCmp('main-panel').setActiveTab(tab); 
    };

    //adds a new object to a tab 
    Baseliner.addNewTabItem = function( comp, title, params, json_key ) {
        if( params == undefined ) params = { active: true };
        var found = false;
        json_key = json_key || Ext.util.JSON.encode( { title: title, type: 'item', params: params } );
        json_key = json_key.replace(',"active":true','');

        if ( title != 'REPL' ) {
            Ext.each(Object.keys(Baseliner.tabInfo), function(tab) {
                var cmp_tab = Ext.getCmp(tab);
                if ( cmp_tab && Baseliner.tabInfo[tab].json_key == json_key ) {
                    // var r = confirm(_('Tab is already opened.  Do you want to activate it? (Cancel to open a new one)'));
                    // if (r == true) {
                        Ext.getCmp('main-panel').setActiveTab(cmp_tab);
                        // Baseliner.refreshCurrentTab();
                        found = true;
                        return;
                    // }
                }
            });
        }
        if (found) return;

        var tabpanel = Ext.getCmp('main-panel');
        var tab;
        // if tab_index not defined -> add current tab for tab_index or add new tab.
        if( params.tab_index != undefined ) {
            tab = tabpanel.insert( params.tab_index, comp );
        } else {
            tab = tabpanel.add(comp);
        }
        // force change title style if: tabTopic_force value is: 1 on Topic.pm and defined new icon and new title on topic_lib.js
        if( comp && comp.title_force && comp.title_force.length ) title = comp.title_force;
        if( params.tab_icon!=undefined && comp && comp.tab_icon===undefined ) tabpanel.changeTabIcon( tab, params.tab_icon );
        else if( comp && comp.tab_icon!=undefined ) tabpanel.changeTabIcon( tab, comp.tab_icon );
        if( params.active==undefined ) params.active=true;
        if( params.active ) tabpanel.setActiveTab(comp);
        if( title == undefined || title=='' ) { 
            title = comp.title; 
            if( title == undefined || title == '' ) { // probably a slow load and deferred title
                tabpanel.changeTabIcon( tab, "/static/images/loading-fast.gif" );
                title = '&nbsp;';
            }
            tab.setTitle( title );
        } else { 
            tab.setTitle( title );
        }
        var tab_id = tab.getId();
        if( comp!=undefined && comp.tab_info!=undefined ) {
            comp.tab_info[json_key] = json_key;
            Baseliner.tabInfo[tab_id] = comp.tab_info;
        }
        return tab_id; 
    };

    Baseliner.is_logged_on = function() {
        Ext.Ajax.request({
            url: '/auth/is_logged_on',
            success: function(xhr) {
                alert('yes');
            },
            failure: function(xhr) {
                alert('no');
            }
        });
        
    };

    Baseliner.family_notify = function(params) {
        var tabpanel = Ext.getCmp('main-panel');
        if( !tabpanel ) return;
        tabpanel.cascade( function(c){ 
            if( c.family == params.family ) {
                if( c.store && c.store.reload ) {
                    c.store.reload();
                }
            }
        });
    }

    //adds a new fragment component with html or <script>...</script>
    Baseliner.addNewTab = function(purl, ptitle, params, obj_tab, json_key ){
        var info_args = arguments;
        var found = false;
        json_key = json_key || Ext.util.JSON.encode( { url: purl, title: ptitle, type: 'script', params: params } );
        json_key = json_key.replace(',"active":true','');

        if ( ptitle != 'REPL') {
            Ext.each(Object.keys(Baseliner.tabInfo), function(tab) {
                var cmp_tab = Ext.getCmp(tab);
                if ( cmp_tab && Baseliner.tabInfo[tab].json_key == json_key ) {
                    // var r = confirm(_('Tab is already opened.  Do you want to activate it? (Cancel to open a new one)'));
                    // if (r == true) {
                        Ext.getCmp('main-panel').setActiveTab(cmp_tab);
                        // if ( ptitle != 'REPL' && ptitle != _('Rules') ) Baseliner.refreshCurrentTab();
                        found = true;
                        return;
                    // }
                }
            });
        }
        if (found) return;

        var tabpanel;
        var newpanel; 
        if(obj_tab) {
            newpanel = new Ext.Panel({ layout: 'fit', title: ptitle, closable:true});
            tabpanel = obj_tab;
        }
        else{
            newpanel = new Ext.Panel({ layout: 'fit', title: ptitle, padding: 10 });
            tabpanel = Ext.getCmp('main-panel');
        }
        //var tabpanel = Ext.getCmp('main-panel');
        var tab = tabpanel.add( newpanel );
        tabpanel.setActiveTab(tab); 
        if( params == undefined ) params={};
        if( params.tab_icon!=undefined ) tabpanel.changeTabIcon( tab, params.tab_icon );
        params.fail_on_auth = true;
        newpanel.load({
            url: purl,
            scripts:true,
            params: params,
            callback: function(el,success,res,opts){
                if( success ) {
                    var id = tab.getId();
                    Baseliner.tabInfo[id] = { url: purl, title: ptitle, type: 'script', params: params, json_key: json_key,
                        favorite_this: function(){ return { foo:'Baseliner.addNewTab', args:info_args } },
                        copy: function(){ Baseliner.addNewTab(purl, ptitle, params, obj_tab, Ext.id() ); }
                    };
                    if( params.callback != undefined ) params.callback();
                    try { 
                        if (Baseliner.explorer.fixed == 0) {
                            Baseliner.explorer.collapse(); 
                        }
                    } catch(e) {}
                } else {
                    Ext.getCmp('main-panel').remove( newpanel );
                    if( res.status == 401 ) {
                        Baseliner.login({ no_reload: 1, on_login: function(){ Baseliner.addNewTab(purl,ptitle,params)} });
                    } else {
                        Ext.getCmp('main-panel').remove( newpanel );
                        if( res.status == 401 ) {
                            Baseliner.login({ no_reload: 1, on_login: function(){ Baseliner.addNewTab(purl,ptitle,params)} });
                        } else {
                            //Baseliner.message( _('Error %1', res.status), res.responseText );
                            Baseliner.message( 'Error', '<% _loc('Server unavailable') %>' ); // XXX necessary? 
                        }
                    }
                }

            }
        });
    };   

    Baseliner.addNewWindow = function(purl, ptitle, params ){
        var newpanel = new Ext.Panel({ layout: 'fit' });
        var base = {
            layout: 'fit', 
            autoScroll: true,
            title: ptitle,
            maximizable: true,
            height: 400, width: 700, 
            items: [ newpanel ]
        }; 
        base = Baseliner.mergeArr( params, base );
        var win = new Ext.Window(base);
        win.show();
        newpanel.load({
            url: purl,
            scripts:true,
            params: { fail_on_auth: true },
            callback: function(el,success,res,opts){
                if( success ) {
                    //var id = tab.getId();
                    //Baseliner.tabInfo[id] = { url: purl, title: ptitle, type: 'script' };
                } else {
                    Ext.getCmp('main-panel').remove( newpanel );
                    if( res.status == 401 ) {
                        Baseliner.login({ no_reload: 1, on_login: function(){ Baseliner.addNewWindow(purl,ptitle,params)} });
                    } else {
                        //Baseliner.message( _('Error %1', res.status), res.responseText );
                        Baseliner.message( 'Error', '<% _loc('Server unavailable') %>' ); // XXX necessary? centralize?
                    }
                }

            }
        }); 
    };

    Baseliner.mergeArr = function(src,dest) {
        if( src == undefined ) return dest;
        for( var prop in src ) {
            dest[prop] = src[prop];
        }
        return dest;
    };

    // Objeto buscador para Tabs enteros con addNewTabSearch
    Ext.app.TextSearchField = Ext.extend(Ext.form.TwinTriggerField, {
        initComponent : function(){
            Ext.app.TextSearchField.superclass.initComponent.call(this);
            this.on('specialkey', function(f, e){
                if(e.getKey() == e.ENTER){
                    this.onTrigger2Click();
                }
            }, this);
        },
        validationEvent:false,
        validateOnBlur:false,
        trigger1Class:'x-form-clear-trigger',
        trigger2Class:'x-form-search-trigger',
        hideTrigger1:true,
        width:280,
        hasSearch : false,
        paramName : 'query',
        lastcnt   : 0,
        laststr   : '',

        onTrigger1Click : function(){
            if(this.hasSearch){
                this.el.dom.value = '';
                this.triggers[0].hide();
                this.hasSearch = false;
                this.lastcnt = 0;
                this.laststr = '';
            }
        },

        onTrigger2Click : function(){
            var v = this.getRawValue();
            if(v.length < 1){ //>
                this.onTrigger1Click();
                return;
            }
            var html = this.pcom.body.dom.innerHTML;
            var cnt=0;
            var arr = html.split("\n");
            var vlo = v.toLowerCase();
            var start = 0;
            if( v == this.laststr ) start = this.lastcnt + 1;
            if( start >= arr.length ) {
                start = 0;
                this.pcom.body.scroll('u', 999999999 );
            }
            this.laststr = v;
            var found=false;
            for( var i=start; i<arr.length; i++ ) {
                var str = arr[i];
                if( str.toLowerCase().indexOf( vlo ) > -1 ) {
                    found=true;
                    break;
                }
                cnt++;
            }
            if( found ) {
                this.pcom.body.scroll('b', 15 * cnt );
                this.lastcnt = cnt;
            }
            this.hasSearch = true;
            this.triggers[0].show();
        }
    });

    Baseliner.addNewTabSearch = function(purl, ptitle, params ){
            var info_args = arguments;
            var search = new Ext.app.TextSearchField({
                            emptyText: _('<Enter your search string>')
                        });
            var tabpanel = new Ext.Panel({
                    layout: 'fit', 
                    autoLoad: {url: purl, scripts:true }, 
                    tbar: [
                        search, 
                        { icon: '/static/images/icons/html.gif', style: 'width: 30px', cls: 'x-btn-icon', hidden: false,
                            handler: function(){
                                var win = window.open( purl );
                            } 
                        }
                    ],
                    title: ptitle
            });
            search.pcom = tabpanel;
            var tab = Ext.getCmp('main-panel').add(tabpanel); 
            Ext.getCmp('main-panel').setActiveTab(tab); 
            var id = tab.getId();
            Baseliner.tabInfo[id] = { url: purl, title: ptitle, type: 'script', 
                favorite_this: function(){ return { foo:'Baseliner.addNewTabSearch', args:info_args } },
                copy: function(){ Baseliner.addNewTabSearch(purl,ptitle,params) } };
    };

    Baseliner.runUrl = function(url) {
        Ext.get('run-panel').load({ url: url, scripts:true }); 
    };

    // used by the url_eval menu option
    Baseliner.evalUrl = function(url) {
        Baseliner.ajaxEval( url, {}, function(){} ); 
    };

    Baseliner.addNewBrowserWindow = function(url,title) {
        title = title==undefined || title.length==0 ? '_blank' : title; 
        window.open(url,'_blank');
    };

    Baseliner.addNewIframe = function(url,title,params) {
        var info_args = arguments;
        var tabpanel = Baseliner.tabpanel();
        var idif = Ext.id();
        var tab = tabpanel.add({ 
                    xtype: 'panel', 
                    layout: 'fit', 
                    autoScroll: false,
                    style: { overflow: 'hidden' },
                    html: '<iframe id="'+idif+'" style="margin: -2px" border=0 width="100%" height="100%" src="' + url + '"></iframe>',
                    title: title
        }); 
        Ext.getCmp('main-panel').setActiveTab(tab); 
        if( params == undefined ) params={};
        if( params.tab_icon!=undefined  ) tabpanel.changeTabIcon( tab, params.tab_icon );
        var id = tab.getId();
        Baseliner.tabInfo[id] = { url: url, title: title, type: 'iframe',
                favorite_this: function(){ return { foo:'window.open', args:info_args } },
                copy: function(){ 
                    // iframe are different, copying opens in a new browser window
                    window.open( url, title );
                } 
        };
    };

    Baseliner.add_iframe = function(url,title,params) {
        var info_args = arguments;
        var tabpanel = Baseliner.tabpanel();
        var panel = new Ext.Panel({
            layout: 'fit', 
            autoScroll: false,
            tbar: [
                { xtype:'button', cls: 'x-btn-icon', icon: '/static/images/icons/arrow_left_black.png', handler:function(){ 
                      var dom = panel.body.dom;
                      var iframe = dom.childNodes[0];
                      iframe.contentWindow.history.back();
                  }
                },
                { xtype:'button', cls: 'x-btn-icon', icon: '/static/images/icons/arrow_right_black.png', handler:function(){ 
                      var dom = panel.body.dom;
                      var iframe = dom.childNodes[0];
                      iframe.contentWindow.history.forward();
                  }
                }
            ],
            style: { overflow: 'hidden' },
            html: '<iframe style="margin: -2px" border=0 width="100%" height="100%" src="' + url + '"></iframe>',
            title: title
        });
        var tab = tabpanel.add(panel); 
        Ext.getCmp('main-panel').setActiveTab(tab); 
        if( params == undefined ) params={};
        if( params.tab_icon!=undefined  ) tabpanel.changeTabIcon( tab, params.tab_icon );
        var id = tab.getId();
        Baseliner.tabInfo[id] = { url: url, title: title, type: 'iframe',
                favorite_this: function(){ return { foo:'Baseliner.add_iframe', args:info_args } },
                copy: function(){ Baseliner.add_iframe(url,title,params) } 
        };
    };

    Baseliner.error_parse = function( err, xhr ) {
        var arr=[]; 
        for(var i in err) {
            arr.push(  i + "=" + err[i] );
        }
        if( err.message ) arr.push(  "Message =" + err['message'] );
        if( err.line ) arr.push(  "Line Num =" + err['line'] );

        str = "<li>" + arr.join('</li><li>') + '</li>';
        var res = xhr.responseText;
        res.replace(/\</,'&lt;');
        res.replace(/\>/,'&gt;');
        str += "<hr><pre>" + res;
        Baseliner.errorWin(_('Error Rendering Tab Component'), str);
    };

    //adds a new tab from a function() type component
    Baseliner.addNewTabComp = function( comp_url, ptitle, params, json_key ){
        var req_params = params != undefined ? params : {};
        var info_args = arguments;
        Baseliner.ajaxEval( comp_url, req_params, function(comp) {
            var found = false;
            json_key = json_key || Ext.util.JSON.encode( { url: comp_url, title: comp.tab_title || ptitle, params: params, type: 'comp' } );
            json_key = json_key.replace(',"active":true','');

            if ( ptitle != 'REPL' ) {
                Ext.each(Object.keys(Baseliner.tabInfo), function(tab) {
                    var cmp_tab = Ext.getCmp(tab);
                    if ( cmp_tab && Baseliner.tabInfo[tab].json_key == json_key ) {
                        // var r = confirm(_('Tab is already opened.  Do you want to activate it? (Cancel to open a new one)'));
                        // if (r == true) {
                            Ext.getCmp('main-panel').setActiveTab(cmp_tab);
                            // if ( ptitle != 'REPL' && ptitle != _('Rules') ) Baseliner.refreshCurrentTab();
                            found = true;
                            return;
                        // }
                    }
                });
            }
            if (found) return;

            var id = Baseliner.addNewTabItem( comp, comp.tab_title || ptitle, params );
            Baseliner.tabInfo[id] = { url: comp_url, title: comp.tab_title || ptitle, params: params, type: 'comp', json_key: json_key,
                favorite_this: function(){ return { foo:'Baseliner.addNewTabComp', args:info_args } },
                copy: function(){ Baseliner.addNewTabComp(comp_url,ptitle,params,Ext.id()) } 
            };
            try { 
                if (Baseliner.explorer.fixed == 0) {
                    Baseliner.explorer.collapse(); 
                }
            } catch(e) {}
        });
    }

    ;

    //adds a new tab from a function() type component - XXX this is a mod with full params sending
    Baseliner.add_tab = function( comp_url, ptitle, params ){
        if( params == undefined ) params = {};
        Baseliner.addNewTab( comp_url, ptitle, params );

    };
    Baseliner.add_tabcomp = function( comp_url, ptitle, params, json_key ){
        var info_args = arguments;
        if( params == undefined ) params = {};

        Baseliner.ajaxEval( comp_url, params, function(comp) {
            var found = false;
            var unescape_title = comp.tab_title || ptitle ? unescape(comp.tab_title || ptitle):null;
            var unescape_ptitle = ptitle ? unescape(ptitle):null;
            var params_json = params;
            delete params_json.title;
            json_key = json_key || Ext.util.JSON.encode( { url: comp_url, params: params_json, type: 'comp' } );
            json_key = json_key.replace(',"active":true','');

            if ( ptitle != 'REPL' ) {
                Ext.each(Object.keys(Baseliner.tabInfo), function(tab) {
                    var cmp_tab = Ext.getCmp(tab);
                    if ( cmp_tab && Baseliner.tabInfo[tab].json_key == json_key ) {
                        // var r = confirm(_('Tab is already opened.  Do you want to activate it? (Cancel to open a new one)'));
                        // if (r == true) {
                            Ext.getCmp('main-panel').setActiveTab(cmp_tab);
                            // if ( ptitle != 'REPL' && ptitle != _('Rules') ) Baseliner.refreshCurrentTab();
                            found = true;
                            return;
                        // }
                    }
                });
            }
            if (found) return;
            var id = Baseliner.addNewTabItem( comp, unescape_ptitle, params );
            Baseliner.tabInfo[id] = { url: comp_url, title: unescape_title, params: params, type: 'comp', json_key: json_key,
                favorite_this: function(){ return { foo:'Baseliner.add_tabcomp', args:info_args } },
                copy: function(){ Baseliner.add_tabcomp(comp_url, ptitle, params, Ext.id()) }
            };
            try { 
                if (Baseliner.explorer.fixed == 0) {
                    Baseliner.explorer.collapse(); 
                }
            } catch(e) {}
        });
    };


    // deprecated : use add_wincomp( url, title, params, opts );
    Baseliner.addNewWindowComp = function( comp_url, ptitle, params ){
        //params ||= {};
        Baseliner.ajaxEval( comp_url, params, function(comp) {
            var win = new Ext.Window({
                layout: 'fit', 
                autoScroll: true,
                title: ptitle,
                height: 400, width: 700, 
                maximizable: true,
                items: comp
            });
            win.show();
        });
    };

    //shows window comp
    Baseliner.add_wincomp = function( comp_url, ptitle, params, callback ){
        if( params == undefined ) params = {};
        Baseliner.ajaxEval( comp_url, params, function(comp) {
            if( comp == undefined ) {
                Ext.Msg.alert( _('Component Error'), _('Invalid component') );
                return;
            }
            var height = params.height || comp.height;
            if( height != undefined ) height += 20;
            height = (height==undefined ? '80%' : height );
            var win = new Ext.Window({ 
                title: ptitle || comp.title,
                height: height,
                width: (comp.width==undefined ? '80%' : comp.width) ,
                items: comp 
            });
            if( callback != undefined ) {
                win.on( callback.event, callback.func );
            }
            win.show();
        });
    };

    // check timeout errors
    /*
    //  Add observability to the Connection class
    Ext.util.Observable.observeClass(Ext.data.Connection);
    Ext.data.Connection.on('requestcomplete', responseHandler);
    Ext.data.Connection.on('requestexception', exceptionHandler);
    Ext.lib.Ajax.on('timeout', function() {
        Baseliner.message(_('Timeout'), _('Server Timeout. Check connection') ); 
        return true; 
    });
    */
    var parse_json_res = function(res) {
        var json;
        try { json=eval(res) } 
        catch(e1) { try { json=eval("("+res+")") } catch(e2) {} }
        return json;
    };
    Baseliner.error_win_textarea_style = 'font: 12px Consolas,Courier New,monotype';

    Baseliner.ErrorWindow = Ext.extend( Baseliner.Window, {
        title: _('Error'), 
        height: 300, width: 480, 
        layout:'border', 
        msg:'',
        initComponent : function(){
            var msg = this.msg;
            this.title = String.format('<span id="boot" style="background:transparent"><span class="label" style="background:red">{0}</span></span>', this.title );
            this.items = [
                { xtype:'textarea', border:false, region:'center', layout:'fit', frame:false,
                    readOnly: true,
                      style: { font: '13px Verdana,Consolas,Helvetica,Verdana,sans-serif', 'background':'#eee', 'background-image':'none' } ,
                      value: ""+msg },
                { xtype:'tabpanel', height: 160, region:'south', split:true, activeTab:0, margins: '2 0 0 0', collapsible: true,
                  collapsed: !Baseliner.DEBUG,  items: [
                      { xtype:'textarea', title: _('Response'), value: msg, style: Baseliner.error_win_textarea_style }
                  ]} 
             ]
            Baseliner.ErrorWindow.superclass.initComponent.call(this);
        }
    });

    Baseliner.error_win = function(url,params,xhr,e){
        var eo = { name: e }; // build my own error object
        try { eo.name = e.name } catch(e2){}
        try { eo.msg = e.message } catch(e2){}
        try { eo.stack = e.stack } catch(e2){}
        try { eo.code = e.number } catch(e2){}
        try { eo.file = e.fileName } catch(e2){}
        try { eo.line = e.lineNumber } catch(e2){}
        if( eo.line == undefined && eo.stack !=undefined ) {
            var mat = eo.stack.match(/<anonymous>:([0-9]+:[0-9]+)/);
            if( Ext.isArray( mat ) ) eo.line = mat[1]
                else eo.line = mat;
        }
        var e_params, e_xhr;
        if( params!=undefined && !Ext.isIE ) {
            if( Ext.isFunction( JSON.stringify ) ) {
                try { e_params = JSON.stringify(params); } catch(e){ e_params='[could not encode]' }
            } else {
                try { e_params = Ext.encode(params); } catch(e){ e_params='[could not encode]' }
            }
        }
        if( xhr !=undefined && !Ext.isIE ) {
            if( Ext.isFunction( JSON.stringify ) ) {
                try { e_xhr = JSON.stringify(xhr); } catch(e){ e_xhr='[could not encode]' }
            } else {
                try { e_xhr = Ext.encode(xhr); } catch(e){ e_xhr='[could not encode]' }
            }
        }
        var emsg = String.format('name: {0}\nmessage: {1}\nline: {2}\ncode: {3}\nfile: {4}\nstack: {5}', eo.name, eo.msg, eo.line, eo.code, eo.file, eo.stack );
        var msg = ""+e; 
        var main_field;
        var width = 480;
        var height = 300;
        var collapsed = !Baseliner.DEBUG;
        if( /^(<!DOCTYPE html|<html)/.test(msg) ) {
            main_field = { xtype:'panel', html: msg, layout:'fit', region:'center', frame:false, readOnly: true };
            collapsed = true;
            width = 800;
            height = 600;
        } else {
            main_field = { xtype:'textarea', border:false, region:'center', layout:'fit', frame:false,
                    readOnly: true,
                      style: { font: '13px Verdana,Consolas,Helvetica,Verdana,sans-serif', 'background':'#eee', 'background-image':'none' } ,
                      value: msg };
        }
        var win = new Baseliner.Window({
            title: String.format('<span id="boot" style="background:transparent"><span class="label" style="background:red">{0}</span></span>', _('Error') ),
            height: height, width: width, 
            layout:'border', 
            items:[
                main_field,
                { xtype:'tabpanel', height: 160, region:'south',  plugins: [ new Ext.ux.panel.DraggableTabs()], split:true, activeTab:0, margins: '2 0 0 0', collapsible: true,
                  collapsed: collapsed,  items: [
                      { xtype:'textarea', title: _('Response'), value: xhr.responseText, style: Baseliner.error_win_textarea_style },
                      { xtype:'panel', title: _('Code'), items: new Baseliner.CodeMirror({ value: xhr.responseText }) },
                      { xtype:'textarea', title: _('Error'), value: emsg, style: Baseliner.error_win_textarea_style },
                      { xtype:'textarea', title: _('Params'), value: e_params, style: Baseliner.error_win_textarea_style },
                      { xtype:'textarea', title: _('XHR'), value: e_xhr, style: Baseliner.error_win_textarea_style },
                      { xtype:'textarea', title: _('URL'), value: url, style: Baseliner.error_win_textarea_style }
                  ]} 
             ]
        });
        win.show();
    };

    Baseliner.eval_response = function( text, params, url, compiled_func ) {
        var comp;
        // search cache, if exists
        if( Ext.isObject( Baseliner.eval_cache ) && Baseliner.eval_cache[url] !=undefined ) {
            var comp = Baseliner.eval_cache[url];
            if( Ext.isFunction(comp) ) return comp(params);
        }
        // eval
        try { comp = JSON.parse(text) } catch(e) {}
        if( comp == undefined ) try { eval("comp = " + text ) } catch(e) {} // this is for (function(){})(); with semicolon, etc.
        if( comp == undefined ) eval("comp = ( " + text + " )");  // json, pure js, closures (function(){ })
        
        if( Ext.isFunction( comp ) && !compiled_func ) {
            var ret = comp(params);
            if( Ext.isObject( Baseliner.eval_cache ) ) Baseliner.eval_cache[url]=comp;
            return ret;
        } else {
           return comp;
        }
    };

    Baseliner.broadcast_process = function(chn){
        Ext.each(chn.system_messages, function(sms){ Baseliner.system_message(sms) });
    }
    Baseliner.system_message_rcvd = {};
    Baseliner.system_message = function(msg) {
        if( !msg._id ) return; 
        var _id = msg._id;
        // control that if the message is visible, don't show it again 
        if( $('#'+_id).length > 0 ) return; 
        if( Baseliner.system_message_rcvd[ _id ] != undefined ) return; 
        Baseliner.ajax_json('/systemmessages/sms_get', { _id: _id }, function(res){
            var msg_data = res.msg;
           if( !msg_data ) msg_data={};
           msg_data = Ext.apply({ title: _('Attention'), text: _('Unknown') }, msg_data);
           Baseliner.system_message_rcvd[ _id ]=msg_data;
           msg_data.div_id = 'sms-' + _id;
           var msg = function(){/* 
            <div class="alert" id="[%= div_id %]" style="margin: 0;">
              <button type="button" class="close" data-dismiss="alert">&times;</button>
              <strong>[%= title %]</strong>: [%= text %]
              [% if( more && more.length>0 ) { %]
                <div style="float: right">
                <a href="javascript:Baseliner.system_more('[%= _id %]')">[%= _('Read More...') %]</a>
                </div>
              [% } %]
            </div>
            */}.tmpl(msg_data);
            $(msg).appendTo("#main-alert").hide().fadeIn();
            $('#'+msg_data.div_id).on('remove',function(){ 
                Baseliner.ajax_json('/systemmessages/sms_ack', { _id: _id }, function(res){ },function(){ });
            });
        });
    };
    Baseliner.system_more = function(_id){
        var msg = Baseliner.system_message_rcvd[ _id ];
        if(!msg) return;
        var html = function(){/*
            <div id="boot">
            <div style="padding: 10px 10px 10px 10px;">
              <h2>[%= title %]</h2>
              <h4>[%= text %]</h4>
              <hr />
              <p>
              [%= more %]
              </p>
            </div>
            </div>
         */}.tmpl(msg);
        new Baseliner.Window({ width:800, height:600, layout:'fit', html: html, bodyStyle:'background: #fff' }).show();
    }
    // sends request with application/json
            // TODO consider making this a RESTful engine, with GET, PUT, POST, DELETE, etc.., and changing the CI interface too
    Baseliner.ajax_json = function( url, params, foo, scope ){
        if( Ext.isObject( params ) ) { 
            params._merge_with_params = 1;
            params.as_json = true;
        }
        Baseliner.ajaxEval( url, params, foo, scope );
    }
    Baseliner.ci_call = function( coll_or_mid, method, params, foo, scope ){
        var url = String.format( '/ci/{0}/{1}', coll_or_mid, method );
        if( !Ext.isObject(params) ) params = {};
        params.as_json = true;
        params._merge_with_params = 1;
        Baseliner.ajaxEval( url, params, foo, scope );
    }

    Baseliner.ajaxEval = function( url, params, foo, scope ){
        if(params == undefined ) params = {};

        if( params._bali_login_count == undefined ) params._bali_login_count = 0;
        params['_bali_notify_valid_session'] = true;
        
        var login_and_go = function(url,params,foo,scope){
              Baseliner.login({ no_reload: 1, on_login: function(){ Baseliner.ajaxEval(url,params,foo,scope)} });
        };
        
        var login_or_error = function(){
            if( params._bali_login_count >= 2 ) {  // 2 attempts to authorize, then abort
                Baseliner.error_win(url,params,xhr, _('Login not available') );       
            } else {
                params._bali_login_count++;
                login_and_go(url,params,foo,scope);
            }
        }
    
        if( Ext.isIE7 || Ext.isIE8 ) Ext.fly( document.body ).mask( _('Sending Request...') );  // so slow, better to mask the whole thing
        var timeout = params.timeout || 120000; // in milliseconds, use zero 0 to disable
        
        var request_data = {
            url: url,
            timeout: timeout,
            callback: function(opts,success,xhr) {
                if( Ext.isIE7 || Ext.isIE8 ) Ext.fly( document.body ).unmask();
                if( !success ) {
                    if( params._ignore_conn_errors ) return;
                    if( params._catch_conn_errors  ) {
                        if(Ext.isFunction(scope)) scope( comp, foo );
                        return;
                    }
                    var msg;
                    if( xhr.status==401 ) {
                        var comp = Baseliner.eval_response( xhr.responseText, params, url );
                        if( Ext.isObject( comp ) && comp.logged_out ) {
                            login_or_error();
                        }
                        return;
                    } else if( xhr.status==404 ) {
                        msg = _("Not found: %1", url );
                    } else if( xhr.status==0 || xhr.status==502 ) {
                        var yn = confirm( _('Server not available. Retry?') );  // an alert does not ask for images from the server
                        if( yn ) {
                            the_request();
                        }
                        return;
                    } else {
                        msg = xhr.responseText;
                    }
                    // get rid of Unknown errors
                    if( msg ) {
                        if( Ext.isFunction(scope) ) {  // scope is catch
                            scope( comp, foo );
                        }

                        Baseliner.error_win(url,params,xhr, msg);
                    }
                    else Baseliner.message( _('Connection lost?'), _('Server communication error'), { image:'/static/images/disconnected.png' });
                    return;
                }
                try {
                    // this is for js components that return a component
                    var has_errors = false; // for component eval errors
                    var comp = Baseliner.eval_response( xhr.responseText, params, url );
                    var is_object = Ext.isObject( comp );
                    // system message
                    if( is_object && comp.__broadcast ) {
                        Baseliner.broadcast_process( comp.__broadcast );
                        delete comp.__broadcast;
                    }
                    // detect logout
                    if( is_object && comp.logged_out && !params._ignore_conn_errors ) {               
                        login_or_error();
                    }
                    else if( !params._handle_res && is_object && comp.success!=undefined && !comp.success ) {  // XXX this should come after the next else
                        if( Ext.isFunction(scope) ) {  // scope is catch
                            scope( comp, foo );
                        } else {
                            has_errors = true;
                            Baseliner.error( _('Loading Error'), comp.msg );
                        }
                    }
                    else if( Ext.isFunction( foo ) ) {  // XXX this should come before the next else
                        foo( comp, scope );
                    }
                    else if( !params._ignore_conn_errors ) {
                        has_errors = true;
                        Baseliner.error_win(url,params,xhr,e);
                    }
                    
                    if( has_errors ) {
                        Baseliner.version_check(false); // maybe error is due to new UI version
                        Baseliner.js_reload(false);  // let's reload common.js, model.js, etc., may fix the problem
                    }
                }
                catch(e){
                    Baseliner.version_check(false);
                    Baseliner.js_reload(false);  // let's reload common.js, model.js, etc., may fix the problem
                    if( params._ignore_conn_errors ) return;
                    Baseliner.error_win(url,params,xhr,e);
                    if( Baseliner.DEBUG ) {
                        // XXX dangerous on delete, confusing otherwise: Baseliner.loadFile( url, 'js' );  // hopefully this will generate a legit error for debugging, but it may give strange console errors
                        //    consider writing the output into an innerHTML of a <script></script> tag 
                        throw e;
                    }
                    //if( Baseliner.DEBUG && ! Ext.isIE && console != undefined ) { console.log( xhr ) }
                }
            }
        };

        if( params.as_json ) {
            request_data.jsonData = params; //jsonData: params,  // sends application/json, goes in the body
            // TODO consider sending _merge_with_params: true, to make ajax_json a full replacement for current ajaxEval without touching controllers
        } else {
            request_data.params = params;
        }
            
        var the_request = function() { Ext.Ajax.request(request_data); };
        if( params.confirm != undefined ) {          
            var msg = params.confirm;
            delete params['confirm'];
            Ext.Msg.confirm(_('Confirmation'),  msg , function(btn) {
                if( btn == 'yes' ) {
                    if( params.onconfirm != undefined ) {  // a callback
                        params.onconfirm(); delete params['onconfirm'] }
                    the_request();
                }
            });
        } else {
            the_request();
        }
    };

    Baseliner.get_selected = function( grid ) {
        var sm = grid.getSelectionModel();
        if (sm.hasSelection()) {
            var sel = sm.getSelected();                         
            return sel;
        } else {
            Ext.Msg.alert( _('Error') , _('Select at least one row') );  
            return undefined;
        };
    };

    Baseliner.closeCurrentTab = function() {
        var tabpanel = Ext.getCmp('main-panel');
        var panel = tabpanel.getActiveTab();
        tabpanel.remove( panel );
        // try to reload the previous tab store
        try {
            var panel_prev = tabpanel.getActiveTab();
            panel_prev.getStore().reload();
        } catch(e) { };
    };

    Baseliner.panel_info = function( panel ) {
        var id = panel.getId();
        if( id !== undefined )  {
            var info = Baseliner.tabInfo[id];
            if( info.params==undefined ) info.params={};
            return info;
        }
    };

    Baseliner.refreshCurrentTab = function() {
        var tabpanel = Ext.getCmp('main-panel');
        var panel = tabpanel.getActiveTab();
        var activeTabIndex = tabpanel.items.findIndex('id', panel.id );
        var id = panel.getId();
        var info = Baseliner.tabInfo[id];
        delete Baseliner.tabInfo[id];
        

        if( panel.refresh_tab ) {
            // I have my own "cloner"
            var clone = panel.refresh_tab();
            tabpanel.remove( panel );
            var new_comp = tabpanel.insert( activeTabIndex, clone );
            var new_id = new_comp.id;
            if( clone.tab_icon ) tabpanel.changeTabIcon( clone, clone.tab_icon );
            tabpanel.setActiveTab( new_comp );
            Baseliner.tabInfo[new_id] = info;
        }
        else if( info!=undefined ) {
            // standard component
            if( info.params==undefined ) info.params={};
            info.params.tab_index = activeTabIndex;
            if( info.type == 'comp' ) {
                tabpanel.remove( panel );
                Baseliner.addNewTabComp( info.url, info.title, info.params, info.json_key );
            }
            else if( info.type=='script') {
                tabpanel.remove( panel );
                Baseliner.addNewTab( info.url, info.title, info.params, info.json_key );
            } 
            else if( info.type == 'object' ) {  // created with a addNewTabItem directly, like the kanban in tab
                var clone = panel.cloneConfig(); 
                tabpanel.remove( panel );
                var new_id = Baseliner.addNewTabItem( clone, clone.title, info.params, info.json_key );
            }
        } 
        else {
            // non-components: portal, etc.
            var closable = panel.initialConfig.closable;
            var tab_index = tabpanel.items.findIndex('id', panel.id );
            var p = panel.cloneConfig();
            var conf = p.initialConfig;
            conf.xtype = 'panel';
            tabpanel.remove( panel );
            var new_comp = tabpanel.insert( tab_index, conf );
            if( conf.tab_icon != undefined ) tabpanel.changeTabIcon( new_comp, conf.tab_icon );
            tabpanel.setActiveTab( new_comp );
        }
        
        // in case an alert box has scroll everything down, restore view by grabbing the viewport's first div
        Baseliner.scroll_top_into_view();
    };

    Baseliner.duplicate_tab = function() {
        var tabpanel = Ext.getCmp('main-panel');
        var panel = tabpanel.getActiveTab();
        var id = panel.getId();
        var info = Baseliner.tabInfo[id];
        if(info.copy) info.copy() 
        else Cla.message(_('Detach'),_('Tab detach not available for current tab'));
    };
    
    // expects success=>true|false, msg=>""
    Baseliner.requestJSON = function( p ) {
        var conn = new Ext.data.Connection();
        conn.request({
            url: p.url,
            params: p.params,
            success: function(xhr) {
                try {
                    var res = Ext.util.JSON.decode( xhr.responseText );
                    if( res.success ) {
                        p.success(res);
                    } else {
                        p.failure(res);
                    }
                } catch(err) {
                    Baseliner.message(_('Data Error'), err.description);
                }
            },
            failure: function(xhr) {
                Baseliner.message(_('Connection Error'),  xhr.responseText );
            }
        });
    };

    Baseliner.formSubmit = function( form ) {
            var title = form.title;
            if( title == undefined || title == '' ) title = '<% _loc("Submit") %>';
            form.submit({
                success: function(f,a){ Baseliner.message( title , 'Datos actualizados con exito.'); },
                failure: function(f,a){ 
                    // OSCAR: He cambiado los mensajes de error para que soporten validaciones..
                    switch (a.failureType) {
                        case Ext.form.Action.CLIENT_INVALID:
                            Ext.Msg.alert("Error", "El formulario contiene errores.").setIcon(Ext.MessageBox.ERROR);
                            break;
                        case Ext.form.Action.CONNECT_FAILURE:
                            Ext.Msg.alert("Error", "Fallo de comunicacion").setIcon(Ext.MessageBox.ERROR);
                            break;
                        case Ext.form.Action.SERVER_INVALID:
                           Ext.Msg.alert("Error", a.result.msg).setIcon(Ext.MessageBox.ERROR);                  
                    }
                }
            });
    };
    Baseliner.templateLoader = function(){
        var that = {};
        var map = {};
        that.getTemplate = function(url, callback) {
            if (map[url] === undefined) {
                Ext.Ajax.request({
                    url: url,
                    success: function(xhr){
                        var template = new Ext.XTemplate(xhr.responseText);
                        template.compile();
                        map[url] = template;
                        callback(template);
                    }
                });
            } else {
                callback(map[url]);
            }
        };
     
        return that;
    };

    Baseliner.server_failure = function( text ) {
        //Ext.Msg.alert( _('Error'), _('Server communication failure. Check your connection.<br>%1', text) );
        // using ext to show an alert is ugly, since it can't find some of its images
        if( text==undefined || text.length <= 40 ) {  //TODO Server communication failure
            alert( _('Server communication failure. Check your connection.') );
        } else {
            Baseliner.errorWin(_('Error Rendering Component'), text );
        }
    };

    // grabs an Ext component and does a show() on it - ie. a Window
    Baseliner.showAjaxComp = function(purl,pparams){
        Ext.Ajax.request({
            url: purl,
            params: pparams,
            success: function(xhr) {
                try {
                    comp = eval(xhr.responseText);
                    comp.show();
                } catch(err) {
                    Baseliner.errorWin(_('Error Rendering Component'), err);
                }
            },
            failure: function(xhr) {
                Baseliner.server_failure( xhr.responseText );
            }
        });
    };


    
    // He añadido este metodo para poder parsear facilmente records desde grids
    // Ejemplo de uso:
    //  var selectedRecord = grid.getSelectionModel().getSelected();
    //  miFormPanel.getForm().loadRecord(selectedRecord);

    Ext.form.Action.LoadRecord = Ext.extend(Ext.form.Action.Load, {
        run : function(){
            this.success({
                success: true,
                data: this.options.record.data
            });
        },
        processResponse : function(response){
            return response;
        }
    }); 
    
    Ext.form.Action.ACTION_TYPES['loadRecord'] = Ext.form.Action.LoadRecord;
    Ext.override(Ext.form.BasicForm, {
        loadRecord : function(record){
            this.doAction('loadRecord', {record: record});
            return this;
        }
    });
    
    Ext.override(Ext.form.Hidden, {
        setValue: function(v)
        {
            var o = this.getValue();
            Ext.form.Hidden.superclass.setValue.call(this, v);
            this.fireEvent('change', this, this.getValue(), o);
            return this;
        }
    });

    function createBox(t, s){
        return ['<div class="msg">',
                '<div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>',
                '<div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc"><h3>', t, '</h3>', s, '</div></div></div>',
                '<div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>',
                '</div>'].join('');
    }
    
    Baseliner.showLoadingMask = function (el, msg){
        Baseliner._defaultLoadingMask = el.mask( msg || _('Loading'), 'x-mask-loading' ).setHeight( 99999 );
        //Baseliner._defaultLoadingMask = new Ext.LoadMask(cmp ,{
        //    removeMask: true, msg : msg
        //});
        //Baseliner._defaultLoadingMask.show();
        return Baseliner._defaultLoadingMask;
    };
    Baseliner.showLoadingMaskFade = function (cmp, msg){
        if( cmp ) {
            Baseliner.showLoadingMask(cmp, msg);
        }
    };
    
    Baseliner.hideLoadingMask = function ( cmp ){
        if(Baseliner._defaultLoadingMask != undefined){
            if( Ext.isObject( cmp ) ) {
                cmp.unmask();
            }
            else if( Ext.isObject( Baseliner._defaultLoadingMask ) ) { 
                 try { Baseliner._defaultLoadingMask.el.unmask(); } catch(e){} // not sure there is el or not
                 try { Baseliner._defaultLoadingMask.unmask(); } catch(e){} // not sure there is el or not
                 try { Baseliner._defaultLoadingMask.hide(); } catch(e){} // not sure there is el or not
            }
            // Baseliner._defaultLoadingMask.el.unmask();
        }
    };
    
    Baseliner.hideLoadingMaskFade = function (cmp){
        if(Baseliner._defaultLoadingMask != undefined){
            if( cmp ) {
                cmp.fadeIn();
                cmp.unmask();
            } 
            // Baseliner._defaultLoadingMask.hide();
            //Baseliner._defaultLoadingMask.getEl().fadeOut();
        }
    };
    
    Baseliner._activeMask = new Array();    
    Baseliner.showCustomMask = function (cmp, msg){
        if(cmp != null){
            if(cmp.el != null){
                //var loadingMask = new Ext.LoadMask(cmp ,{ msg : msg});
                var loadingMask = cmp.el;
                Baseliner._defaultLoadingMask = loadingMask;
                Baseliner._activeMask[cmp.id] = loadingMask;
                loadingMask.mask(msg,'x-mask-loading');
                //loadingMask.show();
            }
        }
    };
    
    Baseliner.hideCustomMask = function (){
        if(Baseliner._defaultLoadingMask != undefined){
            Baseliner.hideLoadingMask(Baseliner._defaultLoadingMask);
        }
    };
    
    Baseliner.hideCustomMask = function (cmp){
        if(cmp != null){
            if(cmp.el != null){
                if(Baseliner._activeMask[cmp.id] != undefined){
                    //Baseliner._activeMask[cmp.id].hide();
                    Baseliner._activeMask[cmp.id].unmask();
                }
            }
        }
    };

    //Bug fix: Permite tratar un Selection Model de un EditorGrid como un GridPanel
    // Gracias a este parche podemos usar el metodo getSelected en vez de getSelectedCell
    Ext.override(Ext.grid.CellSelectionModel, {
        getSelected: function() {
            if (this.selection) {
                return this.selection.record;
            }
        }
    });
    
    
/*!
 * Ext JS Library 3.0+
 * Copyright(c) 2006-2009 Ext JS, LLC
 * licensing@extjs.com
 * http://www.extjs.com/license
 */
Ext.ns('Ext.ux.form');

/**
 * @class Ext.ux.form.FileUploadField
 * @extends Ext.form.TextField
 * Creates a file upload field.
 * @xtype fileuploadfield
 */
Ext.ux.form.FileUploadField = Ext.extend(Ext.form.TextField,  {
    /**
     * @cfg {String} buttonText The button text to display on the upload button (defaults to
     * 'Browse...').  Note that if you supply a value for {@link #buttonCfg}, the buttonCfg.text
     * value will be used instead if available.
     */
    buttonText: 'Browse...',
    /**
     * @cfg {Boolean} buttonOnly True to display the file upload field as a button with no visible
     * text field (defaults to false).  If true, all inherited TextField members will still be available.
     */
    buttonOnly: false,
    /**
     * @cfg {Number} buttonOffset The number of pixels of space reserved between the button and the text field
     * (defaults to 3).  Note that this only applies if {@link #buttonOnly} = false.
     */
    buttonOffset: 3,
    /**
     * @cfg {Object} buttonCfg A standard {@link Ext.Button} config object.
     */

    // private
    readOnly: true,

    /**
     * @hide
     * @method autoSize
     */
    autoSize: Ext.emptyFn,

    // private
    initComponent: function(){
        Ext.ux.form.FileUploadField.superclass.initComponent.call(this);

        this.addEvents(
            /**
             * @event fileselected
             * Fires when the underlying file input field's value has changed from the user
             * selecting a new file from the system file selection dialog.
             * @param {Ext.ux.form.FileUploadField} this
             * @param {String} value The file value returned by the underlying file input field
             */
            'fileselected'
        );
    },

    // private
    onRender : function(ct, position){
        Ext.ux.form.FileUploadField.superclass.onRender.call(this, ct, position);

        this.wrap = this.el.wrap({cls:'x-form-field-wrap x-form-file-wrap'});
        this.el.addClass('x-form-file-text');
        this.el.dom.removeAttribute('name');

        this.fileInput = this.wrap.createChild({
            id: this.getFileInputId(),
            name: this.name||this.getId(),
            cls: 'x-form-file',
            tag: 'input',
            type: 'file',
            size: 1
        });

        var btnCfg = Ext.applyIf(this.buttonCfg || {}, {
            text: this.buttonText
        });
        this.button = new Ext.Button(Ext.apply(btnCfg, {
            renderTo: this.wrap,
            cls: 'x-form-file-btn' + (btnCfg.iconCls ? ' x-btn-icon' : '')
        }));

        if(this.buttonOnly){
            this.el.hide();
            this.wrap.setWidth(this.button.getEl().getWidth());
        }

        this.fileInput.on('change', function(){
            var v = this.fileInput.dom.value;
            this.setValue(v);
            this.fireEvent('fileselected', this, v);
        }, this);
    },

    // private
    getFileInputId: function(){
        return this.id + '-file';
    },

    // private
    onResize : function(w, h){
        Ext.ux.form.FileUploadField.superclass.onResize.call(this, w, h);

        this.wrap.setWidth(w);

        if(!this.buttonOnly){
            var w = this.wrap.getWidth() - this.button.getEl().getWidth() - this.buttonOffset;
            this.el.setWidth(w);
        }
    },

    // private
    onDestroy: function(){
        Ext.ux.form.FileUploadField.superclass.onDestroy.call(this);
        Ext.destroy(this.fileInput, this.button, this.wrap);
    },


    // private
    preFocus : Ext.emptyFn,

    // private
    getResizeEl : function(){
        return this.wrap;
    },

    // private
    getPositionEl : function(){
        return this.wrap;
    },

    // private
    alignErrorIcon : function(){
        this.errorIcon.alignTo(this.wrap, 'tl-tr', [2, 0]);
    }

});

Ext.reg('fileuploadfield', Ext.ux.form.FileUploadField);

// backwards compat
Ext.form.FileUploadField = Ext.ux.form.FileUploadField;


// - - - - - - - - - - - - - - - - - - - - - - - - Ampliar TIMEOUT en treeloader
Ext.tree.TreeLoader.override({
    requestData : function(node, callback){
        if(this.fireEvent("beforeload", this, node, callback) !== false){
            this.transId = Ext.Ajax.request({
                method:this.requestMethod,
                url: this.dataUrl||this.url,
                success: this.handleResponse,
                failure: this.handleFailure,
                timeout: this.timeout || 120000,
                scope: this,
                argument: {callback: callback, node: node},
                params: this.getParams(node)
            });
        }else{
            // if the load is cancelled, make sure we notify
            // the node that we are done
            if(typeof callback == "function"){
                callback();
            }
        }
    }
});

Baseliner.print_current_tab = function(share){
    var tabpanel = Ext.getCmp('main-panel');
    var comp = tabpanel.getActiveTab();
    var title = comp.title;
    var grid_trans = function(i){
        return Ext.isFunction(i.getGridEl) ? Baseliner.grid_scroller(i) : i;
    }
    if( Ext.isFunction( comp.print_hook ) ) {
        Baseliner.print(comp.print_hook(), share);
    } else if( Ext.isObject( comp.print_hook ) ) {
        Baseliner.print(comp.print_hook, share);
    } else {
        comp = grid_trans(comp);
        var id = comp.id;
        Baseliner.print({ title: title, id: id }, share);
    }
}

/* 
 *  Baseliner.print({ title: title, id: el.id });
 *
 */
Baseliner.print = function(opts, share) {
    function add_css(doc,url){ 
        var boot = doc.createElement( 'link' );
        boot.rel = 'stylesheet';
        boot.type = 'text/css';
        boot.href = url;
        if( doc.head ) {
            doc.head.appendChild( boot );
        } else {
            // needed by IE apparently
            var head = doc.createElement('head');
            doc.appendChild( head );
            head.appendChild( boot );
        }
    }
    var add_script = function(doc,url){
        var obj = dw.createElement( 'script' );
        obj.src = url;
        obj.type = 'text/javascript';
        if( doc.head ) {
            doc.head.appendChild( obj );
        } else {
            // needed by IE apparently
            var head = doc.createElement('head');
            doc.appendChild( head );
            head.appendChild( obj );
        }
    }

    var title = opts.title || _('Print');
    
    var ww = window.open('about:blank', '_blank'); //, 'resizable=yes, scrollbars=yes' );
    var dw = ww.document;
    var html = opts.html;
    if( html == undefined ) {
        var el = opts.el || Ext.get(opts.id).dom;
        html = el.innerHTML;
    }
    dw.write( html );
    dw.close();
    dw.title = title;
    //add_script( dw, '/site/graph.js' );
    add_css( dw, '/site/960-Grid-System/code/css/960_24_col.css' );
    add_css( dw, '/site/boot.css' );
    add_css( dw, '/static/ext/resources/css/ext-all.css');
    add_css( dw, '/static/ext/examples/ux/css/ux-all.css');
    add_css( dw, '/static/site.css' );
    add_css( dw, '/static/gritter/css/jquery.gritter.css' );

    add_css( dw, "/static/datepickerplus/datepickerplus.css" );
    add_css( dw, "/static/pagedown/pagedown.css" );
    add_css( dw, "/static/cleditor/jquery.cleditor.css" );
    add_css( dw, "/static/codemirror/lib/codemirror.css" );
    add_css( dw, "/static/codemirror/theme/elegant.css" );
    add_css( dw, "/static/codemirror/theme/night.css" );
    add_css( dw, "/static/codemirror/theme/eclipse.css" );
    add_css( dw, "/static/codemirror/theme/lesser-dark.css" );
    add_css( dw, "/static/codemirror/lib/util/simple-hint.css" );
    add_css( dw, "/site/portal/portal.css"  );
    add_css( dw, "/site/portal/sample.css"  );
    add_css( dw, "/static/livegrid/resources/css/ext-ux-livegrid.css"  );
    add_css( dw, "/static/valums/fileuploader.css"  );
    add_css( dw, "/static/superbox/superbox.css"  );
    add_css( dw, '/static/fullcalendar/fullcalendar.css'  );
    add_css( dw, '/static/fullcalendar/fullcalendar.print.css' );
    add_css( dw, '/static/gridtree/css/treegrid.css'  );
    add_css( dw, "/static/final.css"  );
    add_css( dw, "/static/sprites.css"  );
    add_css( dw, "/static/c3/c3.css"  );
        
    add_css( dw, '/static/final.css' );

    dw.body.style.overflow = 'auto';
    dw.body.style['-webkit-print-color-adjust'] = 'exact';
    dw.body.style['margin'] = '10px';
    
    if( opts.cb ) {
        opts.cb( ww, dw );
    }
    if(!Ext.isIE8){
        if((share)) {
            var html_final = $(dw).contents().html();
            ww.close();
            Baseliner.ajax_json('/share_html', { title: title, html: html_final }, function(res){
                window.open( res.url, title );
            });
        }
        // ww.print(); // needs to be called after all styles are loaded
    }
}

Baseliner.grid_scroller = function( grid ) {
    // from Ext.GridView
     var Element  = Ext.Element,
        el       = Ext.get(grid.getGridEl().dom.firstChild),
        mainWrap = new Element(el.child('div.x-grid3-viewport')),
        scroller = new Element(mainWrap.child('div.x-grid3-scroller'));
    return scroller;
}

Baseliner.whereami = function(cons){
    var e = new Error('dummy');
    var stack = e.stack.replace(/^[^\(]+?[\n$]/gm, '')
        .replace(/^\s+at\s+/gm, '')
        .replace(/^Object.<anonymous>\s*\(/gm, '{anonymous}()@')
        .split('\n');
    //if( cons ) console.log(stack);
    return stack;
}

Cla.log = function(msg){
    console.log(msg); 
}
