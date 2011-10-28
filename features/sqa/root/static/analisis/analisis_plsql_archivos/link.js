/**
 * Link manager, acts as a onclick event controller for links in checking panels
 *
 * Sample usage:
 * a.link(null, 'FBUG-1.0', 'FBUG/panel/detailsPackage', this, {package: 'com.als.paquete', startdate: ''})
 * a.popup('nombrePopup', 'http://jiraserver/jira/view', {id: '127', startdate: ''}, 'popupGeom')
 * a.page('http://jiraserver/jira/view', {id: '127'})
 * a.help('/checking','category','item')
 * a.source('','/group/project','com.myorg.pkg.Class',{language:'java',isClass:'true',basedir:'/home/src'})
 */
var a = {
  url: '/ajax/panel/view.run',
  fullBaseUrl: '',
  helpUrl: '/ajax/help/help.run',
  manualUrl: '/manual/CHKM',
  sourceUrl: '/codeviewer/getfile.run',
  fileByPathUrl: '/codeviewer/getfilebypath.run',
  popupGeometry:  'toolbar=0,scrollbars=1,location=0,statusbar=0,menubar=0,width=450,height=350,resizable=1',
  helpGeometry:   'toolbar=0,scrollbars=1,location=0,statusbar=0,menubar=0,width=500,height=350,resizable=1',
  sourceGeometry: 'toolbar=0,scrollbars=1,location=0,statusbar=0,menubar=0,width=800,height=600,resizable=1',
  manualGeometry: 'toolbar=0,scrollbars=1,location=0,statusbar=0,menubar=0,width=800,height=600,resizable=1',
/**
 * Reloads via Ajax the panelWindow
 *
 * @param refreshUrl (s) The refresh URL (could be null, to use the default url)
 * @param plugin (s) The plugin name
 * @param panel (s) The panel name
 * @param element (s or element) The element source of the link event
 * @param params (o) A JavaScript optional element with the param:value pairs to send
 * @return The (refreshed) DashboardPanel object
 */
  link: function(refreshUrl, plugin, panel, element, params) {
    var panelWindow = this._fetchPanelWindow(element);
    if (!panelWindow) return null; // The source element has no enclosing panel: do nothing
    if (refreshUrl && refreshUrl[0] != '/') refreshUrl = this._getAppContext() + '/' + refreshUrl;  // If relative URL, prepend appcontext
    var dest = refreshUrl? refreshUrl : this._getAppContext() + this.url; // No explicit URL, use appcontext + this.url
    params = params || {};
    params.plugin_name = plugin;
    params.panel_name = panel;
    params.navigations = this._getNavigation(panelWindow);
    params.paintDiv = 'no';
    panelWindow.send(dest, params, false, false);
    if (!panelWindow.navigation) {
      panelWindow.navigation = new YAHOO.widget.NavigationHistory();
    }
    panelWindow.navigation.add(dest, params);
    return panelWindow;
  },
/**
 * Opens a popup window with the contents of the given url, centered in the screen
 *
 * @param name (s) Name of the popup window
 * @param url (s) URL
 * @param params (s,o) Params of the query (if object, will be encoded in the url)
 * @param useAsIs (b) If true, do not prepend fullBaseUrl to the url even if relative url
 */
  popup: function(name, url, params, geometry, useAsIs) {
    if (!useAsIs) url = this._convertToAbsoluteUrl(url);
    geometry = geometry || this.popupGeometry;
    url = this._getUrl(url, params);
    // center popup
    var top = (screen.height - this._getDimension(geometry, 'height')) / 2;
    var left = (screen.width - this._getDimension(geometry, 'width')) / 2;
    return window.open(url, name, geometry + ', top=' + top + ',left=' + left);
  },
  // Alias for popup()
  linkExt: function(name, url, params, geometry, useAsIs) {
    return this.popup(name, url, params, geometry, useAsIs);
  },
/**
 * Returns the width or heigth from the popupGeometry
 * @param geometry data with geometry
 * @param dimension width or height
 * @return Value of the requested attribute encoded in the popupGeometry string
 */
  _getDimension : function(geometry, dimension) {
    var array = geometry.split(',');
    for (var i = 0; i < array.length; i++) {
      var aux = array[i].split('=');
      if (aux[0] == dimension) {
        return aux[1];
      }
    }
  },
/**
 * Opens a popup window with the contents of the given url
 * @param context AppContext prefix (e.g. /checking) - Could be null, the ctx will be extracted from window.location
 * @param category Name of the help category
 * @param item Name of the help item
 */
  help: function(context, category, item) {
    context = context || this._getUrlPrefix();
    var url = context + this.helpUrl;
    var params = {'category':category,'item':item};
    this.popup('help', url, params, this.helpGeometry, false);
  },
  /**
   * Opens a popup window with contents of the given manual item
   * @param context The webapp context, like '/checking' (could be null, to be extracted from current URL)
   * @param item Manual page (e.g. 'Checking Administration Guide.html')
   */
  manual: function(context, item) {
    context = context || this._getUrlPrefix();
    var url = context + this.manualUrl + '/' + item;
    this.popup('manual', url, {}, this.manualGeometry);
  },
/**
 * Changes the current page to the new url.
 * @param url (s) URL (could be absolute or relative; if relative, fullBaseUrl may be prepended)
 * @param params (s,o) Params of the query (if object, will be encoded in the url)
 * @param useAsIs (b) If true, do not prepend fullBaseUrl to the url even if relative url
 */
  page: function(url, params, useAsIs) {
    if (!useAsIs) url = this._convertToAbsoluteUrl(url);
    window.location.href = this._getUrl(url, params);
  },
  
/**
 * Opens a popup window with highlighted source code.
 * @param context AppContext prefix (e.g. /checking) - Could be null or empty, the ctx will be extracted from window.location
 * @param project Name of the project
 * @param path relative path file from project
 * @param parameters object with language, lineStart, lineEnd, linePos
 */
  source: function(context, project, path, parameters, geometry) {
    context = context || this._getUrlPrefix();
    var url = context + this.sourceUrl;
    var language  = '';
    var lineStart = '';
    var lineEnd   = '';
    var linePos   = '';
    var isClass   = 'true';
    var basedir = '';
    
    if(parameters) {
      if(parameters.language)  language  = parameters.language;
      if(parameters.lineStart) lineStart = parameters.lineStart;
      if(parameters.lineEnd)   lineEnd   = parameters.lineEnd;
      if(parameters.linePos)   linePos   = parameters.linePos;
      if(parameters.isClass)   isClass   = parameters.isClass;
      if(parameters.basedir)   basedir   = parameters.basedir;
    }
    var params = {'project':project, 'path':path, 'language':language, 'lineStart':lineStart, 'lineEnd':lineEnd, 'linePos':linePos, 'isClass':isClass};
    if(basedir) params.basedir = basedir;
    var popupGeometry = geometry || this.sourceGeometry;
    if (!url.indexOf('http://')){
    	this.popup('source', url, params, popupGeometry, false);
    }else{
    	alert('This report cannot resolve the path to the source code');
    }
  }, 
  // Show a file (not related to a project) in a popup
  showfile: function(context, path, parameters, geometry) {
    context = context || this._getUrlPrefix();
    var url = context + this.fileByPathUrl;
    var language  = '';
    var lineStart = '';
    var lineEnd   = '';
    var linePos   = '';
    if(parameters) {
      if(parameters.language)  language  = parameters.language;
      if(parameters.lineStart) lineStart = parameters.lineStart;
      if(parameters.lineEnd)   lineEnd   = parameters.lineEnd;
      if(parameters.linePos)   linePos   = parameters.linePos;
    }
    var params = {'path':path, 'language':language, 'lineStart':lineStart, 'lineEnd':lineEnd, 'linePos':linePos};
    
    var popupGeometry = geometry || this.sourceGeometry;
    this.popup('source', url, params, popupGeometry, false);
  },
  // Return the URL up to the application context prefix:
  // http://host:port/appctx
  _getUrlPrefix: function() {
    // If fullBaseUrl, return it
    if (this.fullBaseUrl) return this.fullBaseUrl;
    // If not, extract from window.location
    var url = window.location;
    var p = url.pathname.indexOf('/', 1);
    return url.protocol + '//' + url.host + url.pathname.substring(0, p);
  },
  _getAppContext: function() {
    if (this.fullBaseUrl) {
      var pos = this.fullBaseUrl.indexOf('://');
      if(pos>=0) pos += 3; else return this.fullBaseUrl;
      pos = this.fullBaseUrl.indexOf('/', pos);
      var end = this.fullBaseUrl.indexOf('/', pos+1);
      return end==-1? this.fullBaseUrl.substring(pos) : this.fullBaseUrl.substring(pos, end);
    } else {
      var url = window.location.pathname;
      var pos2 = url.indexOf('/', 1);
      return url.substring(0, pos2);
    }
  },
  // Search for JavaScript panel matching the <div class='checKingPanel'> that contains the clicked element (e.g. a link)
  _fetchPanelWindow: function(element) {
    var item;
    var parent = $($(element).parentNode);
    while (parent) {
      // if(parent.tagName == 'DIV' && parent.hasClassName('checKingPanel')) {
      if (parent.tagName == 'DIV' && parent.className.indexOf('checKingPanel') != -1) {
        item = YAHOO.checking[parent.id];
        break;
      }
      parent = parent.parentNode;
    }
    return item;
  },
  // If fullBaseUrl and the url starts with http: or https:, prepend the fullBaseUrl
  _convertToAbsoluteUrl: function(url) {
    if (this.fullBaseUrl && url.indexOf('http:') == -1 && url.indexOf('https:') == -1) {
      url = this.fullBaseUrl + ((url.charAt(0) != '/')? '/' + url : url);
    }
    return url;
  },
  // Formats a url with parameters (ignoring function attributes)
  _getUrl: function(url, params) {
    
    var hasProperties = false;
    params = params || {};
    for (var p in params) {
      if (typeof params[p] == 'function') continue;
      url += (hasProperties)? '&' : '?';
      hasProperties = true;
      url += encodeURIComponent(p) + '=' + encodeURIComponent(params[p]);
    }
    return url;
  },
  // Get a comma-separated list of plugin:panel present in panel navigation stack
  _getNavigation: function(panelWindow) {
    var nav = '';
    if(panelWindow.navigation) {
      panelWindow.navigation.panels().each( function(i){
        if(nav) nav += ',';
        nav += i.plugin_name + ':' + i.panel_name;
      });
    }
    return nav;
  }
};
