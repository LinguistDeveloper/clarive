Ext.onReady(function(){
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    Ext.QuickTips.init();
    Ext.state.Manager.setProvider(new Ext.state.CookieProvider());

    Baseliner.VERSION = '<% $Baseliner::VERSION %>';


    Baseliner.help_menu = new Ext.menu.Menu({
        fresh_menu: true,
        items: [ Cla.help_base_items[0] ]
    });
    Baseliner.help_menu.on('beforeadd', function(ev,hp){
        if( hp.fresh_menu ) {
            Baseliner.help_menu.removeAll();
        }
        hp.fresh_menu = false;
    });

    Baseliner.help_button = new Ext.Button({
       icon: '/static/images/icons/lightbulb_off.png',
       cls: 'x-btn-icon',
       hidden: false,
       tooltip: _('Clarive Help'),
       menu: Baseliner.help_menu
    });
    Baseliner.help_button.on('click', function(ev,hp){
        // when the user sees the menu, switch the bulb off
        Cla.help_button.setIcon(IC('lightbulb_off.png'));
    });
    var search_box = new Ext.form.TextField({ width: '120', enableKeyEvents: true, name: 'search-box' });
    search_box.on('focus', function(f, e){ search_box.setSize( 300 ); });
    search_box.on('keydown', function(f, e){ search_box.setSize( 300 ); });
    Baseliner.search_box_go = function(q,opts) {
        if( !q ) q=Baseliner.search_box.getValue();
        if( q==undefined || q.length== 0 ) return;
        var res = /^#(\S+)$/.exec(q);
        if( res && res.length > 1 ) { // [0] is the full match
            Baseliner.ajaxEval( '/topic/title_row',{ mid: res[1] },function(result){
                Baseliner.add_tabcomp( "/topic/view", null, { topic_mid: res[1], topic_name: result.row.title, category_color: result.row.category_color, category_name: result.row.category_name  } );
                });
        } else {
            Baseliner.add_tabcomp('/comp/search_results.js', undefined,
                { query: q, opts: opts || {}, tab_icon: '/static/images/icons/search.png' });
        }
    };
    search_box.on('specialkey', function(f, e){
        if(e.getKey() == e.ENTER){
            var opts = {};
            if( e.ctrlKey || e.altKey || e.shiftKey ) opts.force_new_tab = true;
            Baseliner.search_box_go(null,opts);
            search_box.setSize( 120 );
        }
    });
    Baseliner.search_box = search_box;
    Baseliner.favorite_this = function(){
        var tabpanel = Baseliner.tabpanel();
        var tab = tabpanel.getActiveTab();
        var tab_id = tab.getId();
        var info = Baseliner.tabInfo[tab_id];
        //console.log( info );
        // current_state from within tab
        var current_state = tab.get_current_state ? tab.get_current_state() : {};
        var title = current_state.title!=undefined 
                ? current_state.title : tab.get_title 
                ? tab.get_title() : tab.title;
        var title_field = new Ext.form.TextField({ fieldLabel: _('Favorite Name'), value: title });
        if( !info.favorite_this ) {
            Cla.message(_('Favorite'),_('Current tab does not support saving as favorite'));
            return; // tab opening mode does not favoriting
        }
        var tabfav = info.favorite_this(); 
        var opp = function(){
            var icon = current_state.icon || info.tab_icon || tab.tab_icon || IC('favorite');
            var fav_data = {
                title: title_field.getValue(),
                click: {
                    url: '/comp/open_favorite.js',
                    icon: icon,
                    title: title_field.getValue(),
                    tabfav: tabfav,
                    current_state: current_state,
                    type:'eval'
                }
            };
            //console.log( tabfav );
            Cla.ajaxEval( '/lifecycle/favorite_add',
                {
                    text: title_field.getValue(),
                    icon: icon,
                    data: Ext.encode(fav_data),
                    menu: Ext.encode({})
                },
                function(res) {
                    if( Cla.explorer && Cla.explorer.$tree_favorites ) Cla.explorer.$tree_favorites.refresh();
                    Baseliner.message( _('Favorite'), res.msg );
                }
            );
        };
        var win = new Cla.Window({
            height: 300, width: 800,
            layout:'form',
            labelWidth: 100, 
            defaults: { anchor:'100%' },
            bodyStyle: 'padding: 20px; background-color: #fff',
            title: _('Save Favorite: %1', title),
            tbar: [ '->', {  xtype:'button', text:'Save', icon: IC('save'), handler:opp } ],
            items: [ title_field ]
        });
        win.show();
        
    };
    Baseliner.toggleCalendar = function(btn){
        var bc = Baseliner.calpanel;
        //if( bc.collapsed ) bc.toggleCollapse()
        if( bc.isVisible() ) {
            btn.toggle(false);
            bc.hide();
        } else {
            btn.toggle(true);
            bc.show();
            //bc.expand();
        }
        Baseliner.viewport.doLayout();
    };
    Baseliner.tabCalendar = function(){
        var tabpanel = Baseliner.tabpanel();
        var cal = new Baseliner.Calendar({
            fullCalendarConfig: { timeFormat: { '':'H(:mm)', agenda:'H:mm{ - H:mm}' } }
        });
        var tab = tabpanel.add( cal );
        tabpanel.setActiveTab( tab );
        tabpanel.changeTabIcon( tab, '/static/images/icons/calendar.png' );
        tab.setTitle( '&nbsp;' );
    };
    Baseliner.help_button.on('click', Baseliner.help_off );
    

    var tbar_items = [];
    if( Prefs.logo_file ) { 
            tbar_items.push( '<img src="'+Prefs.logo_file+'" style="border:0px;"/>' );
    } else {
            tbar_items.push( '<img src="'+Prefs.stash.theme_dir+'/images/'+ Prefs.logo_filename +'" style="border:0px;"/>' );
    }
    tbar_items.push('-');

    if( Prefs.site.show_menu && Prefs.stash.can_menu ) { 
        Ext.each( Prefs.menus, function(menu){
            tbar_items.push( menu );    
        });
    }
    tbar_items.push('->');
    if( Prefs.site.show_search ) 
        tbar_items.push( search_box );
    
    tbar_items.push( Baseliner.help_button );

    tbar_items.push( '<img src="/static/images/icons/favorite.png" title="' + _("Add to Favorites...") + '" style="border:0px;" onclick="Cla.favorite_this()" onmouseover="this.style.cursor=\'pointer\'" />' );

    Prefs.site.show_calendar = true;
    if( Prefs.site.show_calendar ) {
        var south_panel = new Ext.Button({
            icon: "/static/images/icons/calendar.png",
            enableToggle: true,
            pressed: false, handler: function(){
                Baseliner.toggleCalendar( south_panel );
            }
        });
        tbar_items.push( south_panel ); 
    }

    tbar_items.push( String.format('<img src="/static/images/icons/share_this.png" title="' + _("Share") + '" style="border:0px;" onclick="Baseliner.print_current_tab(true)" onmouseover="this.style.cursor=\'pointer\'" />' ) );
    tbar_items.push( '<img src="/static/images/icons/printer.png" style="border:0px;" title="' + _("Print") + '" onclick="Baseliner.print_current_tab()" onmouseover="this.style.cursor=\'pointer\'" />');
    if( Prefs.stash.show_js_reload && Baseliner.DEBUG )
        tbar_items.push( '<img src="/static/images/icons/js-reload.png" title="' + _("JS reload") + '" style="border:0px;" onclick="Baseliner.js_reload(true)" onmouseover="this.style.cursor=\'pointer\'" />' );
    tbar_items.push( String.format('<img src="/static/images/icons/detach.png" title="' + _("Duplicate active tab") + '" style="border:0px;" onclick="Baseliner.duplicate_tab()" onmouseover="this.style.cursor=\'pointer\'" />', _('Duplicate current tab')) );
    tbar_items.push( '<img src="/static/images/icons/refresh.png" style="border:0px;" title="' + _("Refresh") + '" onclick="Baseliner.refreshCurrentTab()" onmouseover="this.style.cursor=\'pointer\'" />');
    tbar_items.push( '-');

    if( Prefs.is_logged_in ) { 
        var user_menu = [
             { text: _('Inbox'),
                 handler: function(){ Baseliner.addNewTabComp("/message/inbox", _("Inbox"), { tab_icon: "/static/images/icons/envelope.png" } ); },
                 icon : '/static/images/icons/envelope.png' 
             },
             { text: _('Permissions'), handler: function(){ Baseliner.user_actions(); }, icon:'/static/images/icons/lock_small.png' },
             { text: _('Preferences'), icon: '/user/avatar/image.png', handler: function(){ Prefs.open_editor(); } }
        ];
        
        if( Prefs.stash.can_change_password ) {
            user_menu.push({ text: _('Change password'), handler: function(){ Baseliner.change_password(); }, icon:'/static/images/icons/password.png' });
        }
        if( Prefs.stash.can_surrogate ) {
            user_menu.push({ text: _('Surrogate...'), handler: function(){ Baseliner.surrogate();}, index: 80, icon: '/static/images/icons/surrogate.png' });
        }
        
        user_menu.push({ text: _('Logout') , handler: function(){ Baseliner.logout(); }, index: 999, icon: '/static/images/icons/logout.png', cls: 'ui-user-menu-logout' });
        tbar_items.push({ xtype:'button', text: '<b>'+Prefs.username+'</b>', menu: user_menu, cls: 'ui-user-menu' });
    } else {
        tbar_items.push({ text: _('Login'), handler: function(){ Baseliner.login(); } });
    }
    
    Baseliner.main_toolbar = new Ext.Toolbar({
        id: 'mainMenu',
        region: 'north',
        height: Prefs.toolbar_height,
        items: tbar_items 
    });

    var icon_home = '/static/images/icons/home.gif';

    if( Prefs.site.show_calendar ) {
        Baseliner.calpanel = new Baseliner.Calendar({
            region: 'south',
            split: true,
            //collapsible: true,
            //collapsed: true,
            hidden: true,
            height: 300,
            tbar_end : [ '->', { xtype:'button', icon: IC('tab.png'), handler:function(){ Baseliner.tabCalendar() } } ],
            fullCalendarConfig: {
                events: Baseliner.calendar_events,
                timeFormat: { '':'H(:mm)', agenda:'H:mm{ - H:mm}' }
            }
        });
    }
    
    var tabs = [];
    if( Prefs.site.show_main ) {
        tabs.push({title:_('Main'), closable: false, autoLoad: '/site/main.html', scripts: true, cls: 'tab-style' });
    } else if( Prefs.site.show_portal ) {
        tabs.push({ xtype: 'panel', title:_('Portal'), layout: 'border', closable: false, items: Baseliner.portal });
    } 

    var menuTab = new Ext.ux.TabCloseMenu({
        closeTabText: _('Close Tab'),
        closeOtherTabsText: _('Close Other Tabs'),
        closeAllTabsText: _('Close All Tabs')        
    });

    var tab_panel = new Ext.TabPanel({  region: 'center', id:'main-panel',
            defaults: { autoScroll: true }, 
            //plugins: [menuTab],
            plugins: [menuTab,  new Ext.ux.panel.DraggableTabs({  block_first_tab: true })],
            enableTabScroll: true,
            layoutOnTabChange: true,
            listeners:{
                beforeadd: function(tabp,panel){
                    if( panel.closable === undefined ) panel.closable = true; 
                }
            },
            activeTab: 0, 
            items: tabs
    });
    if( Prefs.site.show_dashboard ) {
        tab_panel.on('afterrender', function(){
            var dash = new Cla.Dashboard({ closable: false});
            Baseliner.tabInfo[dash.id] = { };
            Cla.addNewTabItem(dash);
        });
    }

    if( Prefs.site.show_lifecycle && Prefs.stash.can_lifecycle ) 
        Baseliner.explorer = new Baseliner.Explorer({ fixed: 1 });

    var mains = [];
    if( !Prefs.site.show_tabs ) {
        mains.push(
            new Ext.TabPanel({ 
                region: 'center',
                id:'main-panel',
                defaults: { closable: false, autoScroll: true }, 
                 plugins: [menuTab,  new Ext.ux.panel.DraggableTabs({ block_first_tab: true })],
                resizeTabs: true,
                enableTabScroll: true,
                layoutOnTabChange: true,
                //resizeTabs: true,
                activeTab: 0
            })
        );
    } else {
        mains.push( Baseliner.main_toolbar );
        if( Prefs.site.show_lifecycle && Baseliner.explorer ) {
            mains.push( Baseliner.explorer );
        } 
        if( Prefs.site.show_calendar ) {
            mains.push( Baseliner.calpanel );
        } 
        mains.push( tab_panel );
    }
    
    Baseliner.main = new Ext.Panel({
        layout: 'border', items: mains
    });

    if( Prefs.site.banner ) {
        var banner = Prefs.site.banner;
        var height = parseInt( banner.height );
        var banner_panel = new Ext.Panel({ region:'north', 
            style: { height: height + 'px', 'z-index': 1000, position: 'absolute', background: 'transparent' }, //'height: 80px; z-index: 10000; position: absolute; background: transparent', 
            bodyStyle: 'z-index: 10000; position: absolute; background: transparent;', 
            bodyCfg: { height: '1000px' },
            autoLoad:{ url: banner.url, scripts: true } });
        var banner_bottom = Ext.apply( Baseliner.main.initialConfig, { region: 'center', style: { top: height } } );
        Baseliner.main = new Ext.Panel({
            layout: 'border',
            items: [ banner_panel, new Ext.Panel(banner_bottom) ]
        });
        //banner = new Ext.Component({ });
        //banner.on( 'afterrender', function(){ 
       // banner.update({ url: "$banner", scripts: true });
        //});
    } 

    Baseliner.viewport = new Ext.Viewport({
        layout: 'card',
        activeItem: 0,
        id: 'main-view',
        renderTo: 'main-div',
        items: [ Baseliner.main ]
    });

    var tabpanel = Ext.getCmp('main-panel');
    
    if( false ) // disabled for now
        tabpanel.on('tabchange', function(tp,tab){
            if( tab && tab.id ) 
                window.location.hash = '!/tab:' + tab.id;   
        });
    
    var first_comp = tabpanel.getComponent( 0 );
    if( first_comp != undefined ) {
        if( first_comp.tab_icon ) 
            tabpanel.changeTabIcon( first_comp, first_comp.tab_icon );
        else
            tabpanel.changeTabIcon( first_comp, icon_home );
    }


    if( Prefs.site.show_portal ) {
        Ext.each( Prefs.stash.portlets, function(portlet) {
            if( !portlet ) return;
            if( portlet.url_comp ) {
                Baseliner.portalAddCompUrl({ title: _( portlet.title ),
                    portlet_key: portlet.key, url_portlet: portlet.url_comp, url_max: portlet.url_max });
            } else {
                Baseliner.portalAddUrl({ title: _(portlet.title), 
                    portlet_key: portlet.key, url_portlet: portlet.url, url_max: portlet.url_max });
            }
        });
    }
    // Start background tasks 
    //  ----- disabled for now ---- Baseliner.startRunner();

    // Check open tab
    var getParams = document.URL.split("?");
    var tab_params = {};
    if( getParams!=undefined && getParams[1] !=undefined ) {
        tab_params = Ext.urlDecode(getParams[1]);
    }

    // This is used by /tab and /raw in raw_mode
    Ext.each( Prefs.stash.tab_list, function(tab) {
        if( tab.type == 'page' ) {
            Baseliner.addNewTab( tab.url, undefined, tab_params );
        } else {
            Baseliner.addNewTabComp( tab.url, undefined,  tab_params );
        }
    });

    // useful for debugin portal load errors on /tab: }, 250);

    Ext.each( Prefs.stash['alert'], function(tab){
        Ext.Msg.alert( tab.title, tab.message);
    });

    if( Prefs.stash.site_raw || !Prefs.site.show_tabs ) {
        var tabpanel = Ext.getCmp('main-panel');
        tabpanel.header.setVisibilityMode(Ext.Element.DISPLAY);
        tabpanel.header.hide();
    }    

    // VERSION checker
    //
    Baseliner.version = -1;
    Baseliner.version_refresh = 180000;
    Baseliner.version_check = function(repeat){
        $.ajax({ url:'/static/version.json', type: 'GET',
            success: function(res){
                if(!res) return;
                if( !Ext.isObject(res) ) try { res = Ext.decode(res) } catch(ee){};
                if( !Ext.isObject(res) ) return;
                if( Baseliner.version == -1 ) {
                    Baseliner.version = res.version;
                    if(repeat) setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh);
                } else if( Baseliner.version != res.version ) {
                    Baseliner.confirm(_('Your interface version is not up-to-date (%1 != %2). Do you want to refresh now?', 
                        Baseliner.version, res.version), function(){
                            window.location.href = window.location.href; 
                        if(repeat) setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh * 2 );
                    },function(){
                        Baseliner.message( _('Please, refresh the page as soon as possible'),null,{ image:'/static/images/warnmsg.png' } );
                        if(repeat) setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh * 2 );
                    });
                } else {
                    if(repeat) setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh );
                }
            },
            error: function(res){
                if(repeat) setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh * 2 );
            }    
        });
    };
    
    if( Baseliner.version_started == undefined ) {
        setTimeout( function(){ Baseliner.version_check(true) }, Baseliner.version_refresh );
        Baseliner.version_started = true;
    }

    // create the global moment object
    Cla.moment = moment;
    moment.locale( Prefs.language );

    // global key captures
    /* 
    window.history.forward(1);
    document.onkeydown = function disableKeys(evt) {
        evt = (evt) ? evt : ((event) ? event : null);
        if( evt ) {
            try {
                var k = evt.keyCode;
                return Baseliner.eventKey( k );
            } catch(e){}
        }
    };  
    */
       
});
        
if( ! Ext.isIE ) {  // ie shows this for javascript: links and all sort of weird stuff
    window.onbeforeunload=  function(){ if( Baseliner.is_in_edit() ) return '' };
}

