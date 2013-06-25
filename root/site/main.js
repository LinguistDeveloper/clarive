<%args>
    $show_main => $c->config->{site}{show_main} // 0
    $show_search => $c->config->{site}{show_search} // 1
    $show_calendar => $c->config->{site}{show_calendar} // 1
    $show_portal => $c->config->{site}{show_portal} // 0
    $show_dashboard => $c->config->{site}{show_dashboard} // 1
    $show_menu => $c->config->{site}{show_menu} // 1
    $show_lifecycle => $c->config->{site}{show_lifecycle} // 1
    $show_js_reload => $c->config->{site}{show_js_reload} // 0
    $show_tabs => $c->config->{site}{show_tabs} // 1
    $banner => $c->config->{site}{banner}
</%args>

<%perl>
    if( $c->stash->{site_raw} ) {
        $show_tabs = 0;
        $show_portal = 0;
        $show_menu  = 0;
        $show_main  = 0;
    }
    $show_lifecycle = $show_lifecycle && $c->stash->{'can_lifecycle'};
    $show_menu and $show_menu = $c->stash->{'can_menu'};
</%perl>

Ext.onReady(function(){
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    Ext.QuickTips.init();
    Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
    Baseliner.VERSION = '<% $Baseliner::VERSION %>';
    Baseliner.help_menu = new Ext.menu.Menu({});
    Baseliner.help_button = new Ext.Button({
       icon: '/static/images/icons/lightbulb_off.gif',
       cls: 'x-btn-icon',
       hidden: true,
       menu: Baseliner.help_menu
    });
    var search_box = new Ext.form.TextField({ width: '120', enableKeyEvents: true, name: 'search-box' });
    search_box.on('focus', function(f, e){ search_box.setSize( 300 ); });
    search_box.on('keydown', function(f, e){ search_box.setSize( 300 ); });
    Baseliner.search_box_go = function(q) {
        Baseliner.add_tabcomp('/comp/search_results.js', undefined,
                { query: q || Baseliner.search_box.getValue(), tab_icon: '/static/images/icons/search.png' });
    };
    search_box.on('specialkey', function(f, e){
        if(e.getKey() == e.ENTER){
            Baseliner.search_box_go();
            search_box.setSize( 120 );
        }
    });
    Baseliner.search_box = search_box;
    Baseliner.toggleCalendar = function(){
        var bc = Baseliner.calpanel;
        //if( bc.collapsed ) bc.toggleCollapse()
        if( bc.isVisible() ) {
            bc.hide();
        } else {
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
    Baseliner.main_toolbar = new Ext.Toolbar({
        id: 'mainMenu',
        region: 'north',
        height: <% $c->config->{toolbar_height} // 28 %>,
        items: [
% if( $c->config->{logo_file} ) {
            '<img src="<% $c->config->{logo_file} %>" style="border:0px;"/>',
% } else {
            '<img src="<% $c->stash->{theme_dir} %>/images/<% $c->config->{logo_filename} || 'logo.jpg' %>" style="border:0px;"/>',
% }
            '-',
% if( $show_menu && scalar @{ $c->stash->{menus} || [] } ) {  print join ',',@{ $c->stash->{menus} }; } else { print '{ }' }
            ,
            '->',
% if( $show_search ) {
            search_box,
% }
            Baseliner.help_button,
% if( $show_js_reload && $c->debug ) {
            '<img src="/static/images/icons/js-reload.png" style="border:0px;" onclick="Baseliner.js_reload()" onmouseover="this.style.cursor=\'pointer\'" />',
% }
% if( $show_calendar ) {
            '<img src="/static/images/icons/calendar.png" style="border:0px;" onclick="Baseliner.toggleCalendar()" onmouseover="this.style.cursor=\'pointer\'" />',
% }
            '<img src="/static/images/icons/application_double.gif" style="border:0px;" onclick="Baseliner.detachCurrentTab()" onmouseover="this.style.cursor=\'pointer\'" />',
            '<img src="/static/images/icons/refresh.gif" style="border:0px;" onclick="Baseliner.refreshCurrentTab()" onmouseover="this.style.cursor=\'pointer\'" />',
            '-', 
            <%perl>
                my $user = $c->username;
                if( defined $user ) {
                    use Moose::Autobox;
                    my $menu = [
                         { text=>_loc('Inbox'),
                             handler=>\'function(){ Baseliner.addNewTabComp("/message/inbox", _("Inbox"), { tab_icon: "/static/images/icons/envelope.gif" } ); }',
                             icon   =>'/static/images/icons/envelope.gif' },
                         { text=>_loc('Permissions'), handler=>\'function(){ Baseliner.user_actions(); }' },
                         # XXX  { text=>_loc('Preferences'), handler=>\'function(){ Baseliner.preferences(); }' },
                         { text=>_loc('Preferences'), icon=>'/user/avatar/image.png', handler=>\'function(){ Baseliner.change_avatar(); }' },
                         { text=>_loc('Logout') , handler=>\'function(){ Baseliner.logout(); }', index=>99, icon=>'/static/images/logout.gif' }
                    ];
                    if( $c->config->{authentication}->{default_realm} eq 'none' ) { 
                        $menu->push( { text=>_loc('Change password'), handler=>\'function(){ Baseliner.change_password(); }' });
                    }
                    $c->stash->{can_surrogate} and $menu->push( { text=>_loc('Surrogate...'), handler=> \'function(){ Baseliner.surrogate();}', index=>80, icon=>'/static/images/icons/users.gif' } );
                    print js_dumper { xtype=>'button', text=>'<b>'.$c->username.'</b>' , menu=> [
                        sort {
                            $a->{index}||=0;
                            $b->{index}||=0;
                            $a->{index} <=> $b->{index}
                        } _array($menu) ] };
                }else{
                    print js_dumper { text=>_loc('Login'), handler=>\'function(){ Baseliner.login(); }' };
                }
            </%perl>
        ]
    });

    var icon_home = '/static/images/icons/home.gif';

% if( $show_calendar ) {
    Baseliner.calpanel = new Baseliner.Calendar({
        region: 'south',
        split: true,
        //collapsible: true,
        //collapsed: true,
        hidden: true,
        height: 300,
        tbar_end: [ '->', { xtype:'button', text:'#', handler:function(){ Baseliner.tabCalendar() } } ],
        fullCalendarConfig: {
            events: Baseliner.calendar_events,
            timeFormat: { '':'H(:mm)', agenda:'H:mm{ - H:mm}' }
        }
    });
% }

    var tab_panel = new Ext.TabPanel({  region: 'center', id:'main-panel',
            defaults: { closable: true, autoScroll: true }, 
            enableTabScroll: true,
            layoutOnTabChange: true,
            activeTab: 0, 
            items: [
% if( $show_main eq '1' ) {
                {title:_loc('Main'), closable: false, autoLoad: '/site/main.html', scripts: true, cls: 'tab-style' }
% } elsif( $show_portal ) {
                { xtype: 'panel', title:_loc('Portal'), layout: 'border', closable: false, items: Baseliner.portal }
% } else { print '' } 

% if( $show_dashboard ) {
%    $show_portal and print ',';
                //{title:_loc('Dashboard'), closable: false, autoLoad: '/dashboard/list', scripts: true, cls: 'tab-style', tab_icon: icon_home }
                {title:_loc('Dashboard'), closable: false, autoLoad: {url:'/dashboard/list', scripts: true}, cls: 'tab-style', tab_icon: '/static/images/icons/dashboard.png' }
% }
            ]
    });

%   if( $show_lifecycle ) {
        Baseliner.explorer = new Baseliner.Explorer({ fixed: 1 }),
%   }

    Baseliner.main = new Ext.Panel({
        layout: 'border',
        items: [
% if( ! $show_tabs ) {
            new Ext.TabPanel({ 
                region: 'center',
                id:'main-panel',
                defaults: { closable: false, autoScroll: true }, 
                resizeTabs: true,
                enableTabScroll: true,
                layoutOnTabChange: true,
                //resizeTabs: true,
                activeTab: 0
            })
% } else {
            Baseliner.main_toolbar,
%   if( $show_lifecycle ) {
            Baseliner.explorer,
%   }
%   if( $show_calendar ) {
            Baseliner.calpanel,
%   }
            tab_panel
% } # site_raw
        ]
    });

%   if( $banner ) {
        var banner = <% Baseliner::Utils::encode_json( $banner ) %>;
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
%   } 

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


% if( $show_portal eq '1' ) {
%   for my $portlet ( _array $c->stash->{portlets} ) {
%       if( my $pcomp = $portlet->url_comp ) {
            Baseliner.portalAddCompUrl({ title: _('<% $portlet->title %>'),
                portlet_key: '<% $portlet->key %>', url_portlet: '<% $pcomp %>', url_max: '<% $portlet->url_max %>' });
%       } else {
            Baseliner.portalAddUrl({ title: _('<% $portlet->title %>'), 
                portlet_key: '<% $portlet->key %>', url_portlet: '<% $portlet->url %>', url_max: '<% $portlet->url_max %>' });
%       }
%   } 
% }
    // Start background tasks 
    //  ----- disabled for now ---- Baseliner.startRunner();

    // Check open tab
    var getParams = document.URL.split("?");
    var tab_params = {};
    if( getParams!=undefined && getParams[1] !=undefined ) {
        tab_params = Ext.urlDecode(getParams[1]);
    }

% my @tab_list = @{ $c->stash->{tab_list} || [] };
% foreach my $tab ( @tab_list ) {
    // This is used by /tab and /raw in raw_mode
%    if( $tab->{type} eq 'page' ) {
        Baseliner.addNewTab('<% $tab->{url} %>', undefined, tab_params );
%    } else {
        Baseliner.addNewTabComp('<% $tab->{url} %>', undefined,  tab_params );
%    }
% }

    // useful for debugin portal load errors on /tab: }, 250);

% foreach my $tab ( _array $c->stash->{alert} ) {
    Ext.Msg.alert('<% $tab->{title} %>', '<% $tab->{message} %>');
% }

% if( ! $show_tabs ) {
    var tabpanel = Ext.getCmp('main-panel');
    tabpanel.header.setVisibilityMode(Ext.Element.DISPLAY);
    tabpanel.header.hide();
% }    
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
        
setTimeout(function(){
    Ext.get('bali-loading').remove();
    Ext.get('bali-loading-mask').fadeOut({
        remove:true,
        callback: function(){
            /* var bw = $('#bali-browser-warn').show();
            var bw = $('#bali-browser-warn-mid').show();
            $("#bali-browser-version").html('4.5');
            */
        }
    });
}, 2050);

if( ! Ext.isIE ) {  // ie shows this for javascript: links and all sort of weird stuff
    window.onbeforeunload=  function(){ if( Baseliner.is_in_edit() ) return '' };
}

