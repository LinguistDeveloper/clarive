Ext.ns('Baseliner');

// Cookies
Baseliner.cookie = new Ext.state.CookieProvider({
		expires: new Date(new Date().getTime()+(1000*60*60*24*300)) //300 days
});

//Ext.state.Manager.setProvider(Baseliner.cookie);
//Baseliner.cook= Ext.state.Manager.getProvider();

// Errors
Baseliner.errorWin = function( p_title, p_html ) {
	var win = new Ext.Window({ layout: 'fit', 
		autoScroll: true, title: p_title,
		height: 600, width: 1000, 
		html: p_html });
	win.show();
};


Baseliner.error = function(title, format){
    var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
    Ext.Msg.show({
        title: title,
        msg: s,
        buttons: Ext.Msg.OK,
        icon: Ext.Msg.ERROR
    });
};

Baseliner.message = function(title, format){
	Baseliner.messageRaw({ title: title, pause: 2 }, format );
};

Baseliner.messageRaw = function(params, format){
	var title = params.title;
    var pause = params.pause || 2;
    var width = params.width || 200;
	var msgCt;
	if(!msgCt){
		msgCt = Ext.DomHelper.insertFirst(document.body, {id:'msg-div'}, true);
	}
	msgCt.alignTo(document, 't-t');
	var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
	var m = Ext.DomHelper.append(msgCt, {html:createBox(title, s)}, true);
    msgCt.setWidth( width );
	m.slideIn('t').pause(pause).ghost("t", {remove:true});
};

Baseliner.now = function() {
    var now = new Date();
    return now.format( "Y-m-d H:i:s" );
}

Baseliner.logout = function() {
	Ext.Ajax.request({
		url: '/logout',
		success: function(xhr) {
            document.location.href='/';
		},
		failure: function(xhr) {
		   Baseliner.errorWin( 'Logout Error', xhr.responseText );
		}
	});
};

// Renderers

Baseliner.columnWrap = function (val){
    if( val == null || val == undefined ) return '';
    return '<div style="white-space:normal !important;">'+ val +'</div>';
}


var onemeg = 1024 * 1000;
Baseliner.byte_format = function(val) {
    var ret;
    if( val >= onemeg ) {
        ret = Math.round( ( val /onemeg) * 10) / 10;
        ret += 'MB';
    } else {
        ret = Math.round( ( val /1024) * 10) / 10;
        if( ret === 0 && val>0 ) ret = 0.1;
        ret += 'KB';
    }
    return ret;
}

Baseliner.render_ns = function (val){
    if( val == null || val == undefined ) return '';
    if( val == '/' ) return _('All');
    return String.format('<img src="{0}" />', val );
}

Baseliner.render_bl = function (val){
    if( val == null || val == undefined ) return '';
    if( val == '*' ) return _('All');
    return String.format('<img src="{0}" />', val );
}

Baseliner.render_icon = function (val){
    if( val == null || val == undefined ) return '';
    return String.format('<img src="{0}" />', val );
}

Baseliner.render_bytes = function(value,metadata,rec,rowIndex,colIndex,store) {
    return Baseliner.byte_format( value );
}

// from /root/static/images/icons/mime/*
var extensions_available = {
"3gp":0, "7z":0, "ace":0, "ai":0, "aif":0, "aiff":0, "amr":0, "asf":0, "asx":0, "bat":0, "bin":0,
"bmp":0, "bup":0, "cab":0, "cbr":0, "cda":0, "cdl":0, "cdr":0, "chm":0, "dat":0, "divx":0, "dll":0,
"dmg":0, "doc":0, "dss":0, "dvf":0, "dwg":0, "eml":0, "eps":0, "exe":0, "fla":0, "flv":0, "gif":0, "gz":0,
"hqx":0, "htm":0, "html":0, "ifo":0, "indd":0, "iso":0, "jar":0, "jpeg":0, "jpg":0, "lnk":0, "log":0, "m4a":0,
"m4b":0, "m4p":0, "m4v":0, "mcd":0, "mdb":0, "mid":0, "mov":0, "mp2":0, "mp4":0, "mpeg":0, "mpg":0, "msi":0,
"mswmm":0, "ogg":0, "pdf":0, "png":0, "pps":0, "ps":0, "psd":0, "pst":0, "ptb":0, "pub":0, "qbb":0, "qbw":0,
"qxd":0, "ram":0, "rar":0, "rm":0, "rmvb":0, "rtf":0, "sea":0, "ses":0, "sit":0, "sitx":0, "ss":0, "swf":0,
"tgz":0, "thm":0, "tif":0, "tmp":0, "torrent":0, "ttf":0, "txt":0, "vcd":0, "vob":0, "wav":0, "wma":0, "wmv":0,
"wps":0, "xls":0, "xpi":0, "zip":0
};

var extension_map = {
     pptx: 'pps'
    ,xls: 'pps'
};

Baseliner.render_extensions = function(value,metadata,rec,rowIndex,colIndex,store) {
    var alternative = extension_map[ value ];
    if( alternative != undefined ) value = alternative;
    if( value == '' || value == undefined ) value = 'txt';
    value = value.toLowerCase();
    var extension = extensions_available[ value ];
    if( extension == undefined ) value = 'bin'; // no icon available
    return _('<img src="%1" alt="%2">', '/static/images/icons/mime/file_extension_' + value + '.png', value );
}

Baseliner.json_store = Ext.extend( Ext.data.JsonStore, {
    root: 'data', 
    remoteSort: true,
    totalProperty: 'totalCount', 
    id: 'id', 
    baseParams: {  start: 0, limit: this.ps || 99999999 }
});

Baseliner.new_jsonstore = function(params) {
    if( params == undefined ) params={};
    var store = new Ext.data.JsonStore({
        root: 'data', 
        remoteSort: true,
        totalProperty: params.totalProperty || 'totalCount', 
        id: 'id', 
        fields: params.fields || [],
        url: params.url || '',
        baseParams: {  start: 0, limit: params.ps || 99999999 }
    });
    return store;
};

Baseliner.combo_remote = Ext.extend( Ext.form.ComboBox, {
       name: this.value,
       hiddenName: this.value,
       //fieldLabel: _("Providers"),
       mode: 'remote', 
       //store: this.store,
       valueField: this.value,
       displayField: this.display,
       editable: false,
       forceSelection: true,
       triggerAction: 'all',
       allowBlank: false,
       width: 300
});
//combo_create.store.on('load',function(store) {
    //combo_create.setValue(store.getAt(0).get('url'));
//});

Baseliner.button = function(text,icon,handler){ 
    return new Ext.Button({
       text: text,
       icon: icon || '/static/images/icons/revision_create.gif',
       cls: 'x-btn-text-icon',
       handler: handler || function(){} 
    });
};

Baseliner.close_parent = function(comp) {
    if( comp== undefined ) return;
    try { comp.findParentByType('window').close() }
    catch(e) {
        try { comp.findParentByType('tabpanel').close() } catch(e2) {
            try { comp.findParentByType('panel').close() } catch(e3) {}
        }
    }
};

/*

    Baseliner.combo_project({ value:'project/11221' });

*/
Baseliner.combo_project = function(params) {
    if( params==undefined) params={};
    var store = new Ext.data.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: params.request || {},
        id: 'ns', 
        url: '/project/user_projects',
        fields: ['ns','name','description'] 
    });
    var valueField = params.valueField || 'ns';
    var combo = new Ext.form.ComboBox({
           fieldLabel: _("Project"),
           name: params.name || 'ns',
           hiddenName: params.hiddenName || 'ns',
           valueField: valueField, 
           displayField: params.displayField || 'name',
           typeAhead: false,
           minChars: 1,
           mode: 'remote', 
           store: store,
           editable: true,
           forceSelection: true,
           triggerAction: 'all',
           allowBlank: false
    });
    if( params.select_first ) {
        combo.store.on('load',function(store) {
            combo.setValue(store.getAt(0).get( valueField ));
        });
    } else if( params.value ) {
        combo.store.on('load',function(store) {
            var ix = store.find( valueField, params.value ); 
            if( ix > -1 ) combo.setValue(store.getAt(ix).get( valueField ));
        });
    }
    return combo;
};
