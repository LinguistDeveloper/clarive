// Cookies
Baseliner.cookie = new Ext.state.CookieProvider({
        expires: new Date(new Date().getTime()+(1000*60*60*24*300)) //300 days
});


window._bool = function(v,undef){
    if( undef===undefined ) undef=false;
    return v==undefined ? undef
        : v===true ? true
        : v===false ? false
        : v===1 ? true
        : v==='1' ? true
        : v===0 ? false
        : v==='0' ? false
        : v==='' ? false
        : v=='true' ? true
        : v=='false' ? false
        : v=='on' ? true
        : undef;
}

// File loader
Baseliner.loadFile = function(filename, filetype){

    var rnd = Math.floor(Math.random()*80000);
    filename += '?balirnd=' + rnd;
    if (filetype=="js"){ //if filename is a external JavaScript file
       var fileref=document.createElement('script')
       fileref.setAttribute("type","text/javascript")
       fileref.setAttribute("src", filename)
    }
    else if (filetype=="css"){ //if filename is an external CSS file
       var fileref=document.createElement("link")
       fileref.setAttribute("rel", "stylesheet")
       fileref.setAttribute("type", "text/css")
       fileref.setAttribute("href", filename)
    }
    if (typeof fileref!="undefined")
       document.getElementsByTagName("head")[0].appendChild(fileref)
};

Baseliner.require = function(url, cb){
    require([url + '?' + Date.now()], cb );
};

// In-edit counter - keep the window for closing if it's more than > 0
Baseliner.is_in_edit = function(){
    var flag = false;
    for( var k in Baseliner.in_edit ) {
        if( Baseliner.in_edit[k] ) flag=true;
    }
    return flag;
}
// Watch when something blocks the window from closing
Baseliner.edit_check = function( comp, auto_start ){
    var id = comp.id;
    if( auto_start == undefined ) auto_start = true;
    comp.edit_start = function(){ Baseliner.in_edit[ id ] = true }
    comp.edit_end = function(){ Baseliner.in_edit[ id ] = false }
    comp.on('afterrender', function(){ comp.edit_start() });
    comp.on('destroy', function() { delete Baseliner.in_edit[ id ]  } );
}

//Ext.state.Manager.setProvider(Baseliner.cookie);
//Baseliner.cook= Ext.state.Manager.getProvider();
Baseliner.unload_warning = function() {
    var r = confirm( _("Are you sure you want to close the window?") );
    return r;
};


// Errors
Baseliner.errorWin = function( p_title, p_html ) {
    var win = new Ext.Window({ layout: 'fit', 
        autoScroll: true, title: p_title,
        height: 600, width: 1000, 
        html: p_html });
    win.show();
};

Baseliner.js_reload = function() {
    // if you reload globals.js, tabs lose their info, and hell breaks loose
    Baseliner.loadFile( '/i18n/js', 'js' );
    Baseliner.loadFile( '/site/common.js', 'js' );
    Baseliner.loadFile( '/site/tabfu.js', 'js' );
    Baseliner.loadFile( '/site/model.js', 'js' );
    Baseliner.loadFile( '/site/explorer.js', 'js' ); 
    Baseliner.loadFile( '/site/editors.js', 'js' ); 
    Baseliner.loadFile( '/site/graph.js', 'js' );
    Baseliner.loadFile( '/site/portal/Portal.js', 'js' );
    Baseliner.loadFile( '/site/portal/Portlet.js', 'js' );
    Baseliner.loadFile( '/site/portal/PortalColumn.js', 'js' );
    Baseliner.loadFile( '/comp/topic/topic_lib.js', 'js' );

    Baseliner.loadFile( '/static/site.css', 'css' );
    Baseliner.loadFile( '/static/final.css', 'css' );

    Baseliner.message(_('JS'), _('Reloaded successfully') );  
};

Baseliner.alert = function(title, format){
    var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
    Ext.Msg.alert({
        title: title,
        msg: s,
        icon: Ext.Msg.WARNING
        //buttons: Ext.Msg.OK
    });
};

Baseliner.error = function(title, format){
    var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
    s = Baseliner.error_msg( s );
    Ext.Msg.show({
        title: title,
        msg: s,
        buttons: Ext.Msg.OK,
        icon: Ext.Msg.ERROR
    });
};

$.extend($.gritter.options, { position: 'bottom-right' } );

Baseliner.error_msg = function( msg ){
    if( ! Baseliner.DEBUG ) {
        var ix = msg.indexOf( 'Stack:' );
        if( ix > -1 ) {
            msg = msg.substring(0,ix);
        }
        // XXX consider logging the stack somewhere else (button or tab details)
    }
    return msg;
}

Baseliner.message = function(title, msg, config){
    if( ! config ) config = {};
    if( !msg ) {
        msg = title;
        title = _('Notification');
    }
    if( !msg ) {
        msg = _('(empty message)');
    }
    
    msg = Baseliner.error_msg( msg );
    var id = $.gritter.add( Ext.apply({
        title: title, text: msg, fade: true, 'class': 'baseliner-message',
        time: 2200,
        image: '/static/images/infomsg.png'
    }, config));
    /*
    setTimeout( function(){ $.gritter.remove( id, { fade: true }); }, timeout);
    */
};

Baseliner.warning = function(title, msg, config){
    Baseliner.message( title, msg, { image: '/static/images/warnmsg.png' } );
};

Baseliner.message_gray = function(title, format){
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

Baseliner.confirm = function( msg, foo, foo_no ) {
    Ext.Msg.confirm(_('Confirmation'),  msg , function(btn) {
        if( btn == 'yes' ) {
            if( foo != undefined ) foo();
        } else {
            if( foo_no != undefined ) foo_no();
        }
    });
};

Baseliner.now = function() {
    var now = new Date();
    return now.format( "Y-m-d H:i:s" );
}

Baseliner.logout = function() {
    Ext.Ajax.request({
        url: '/logoff',
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

Baseliner.render_wrap = Baseliner.columnWrap;

Baseliner.render_active  = function(value,metadata,rec,rowIndex,colIndex,store) {
    if( value==undefined || value=='null' || value=='' || value==0 || value=='0' ) return _('No');
    return _('Yes');
};

Baseliner.render_identicon = function(v) {
    return '<img src="/user/avatar/' + v + '/avatar.png" width=32 />';
};

Baseliner.quote = function(str) {
    return str.replace( /\"/g, '\\"' );
};

Baseliner.escape_lt_gt = function(str) {
    if( ! str ) return '';
    str = str.replace( /\</g, '&lt;' );
    return str.replace( /\>/g, '&gt;' );
};

Baseliner.render_job = function(value,metadata,rec,rowIndex,colIndex,store) {
    if( value!=undefined && value!='' ) {
        var id_job = rec.data.id_job;
        return "<a href='#' onclick='javascript:Baseliner.addNewTabComp(\"/job/log/list?id_job="+id_job+"\",\""+ _("Log") + " " +value+"\"); return false;'>" + value + "</a>" ;
    } else {
        return '';
    }
};

Baseliner.render_tags = function(value,metadata,rec,rowIndex,colIndex,store) {
    if( value==undefined ) return value;
    var ret = '';
    for( var i=0; i< value.length; i++ ) {
        var color = '#ddd';
        var bgcolor = '#333';
        var v = value[i];
        if( v === '__new__' ) {
            color = '#222';
            bgcolor = '#ffd700';
            v = _('new');
        }
        ret += '<span class="curved" style="background-color: '+ bgcolor +'; ';
        ret += ' color: ' + color + '; font-size: 9px; padding: 3 3 3 3; margin: 2 2 2 2;">&nbsp;'
        ret += v + '&nbsp;</span><br />';
    }
    ret += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
    ret += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
    //return ret;
    return Baseliner.columnWrap(ret);
};


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
    if( val == '/' ) val = _('All');
    return String.format('<b>{0}</b>', val );
}

Baseliner.render_bl = function (val){
    if( val == null || val == undefined ) return '';
    if( val == '*' ) val = _('Common');
    return String.format('<b>{0}</b>', val );
}

Baseliner.render_bl_name = function(val,metadata,rec,rowIndex,colIndex,store) {
    if( val == null || val == undefined ) return '';
    if( val == '*' ) val = _('Common');
    return String.format('<b>{0}</b>', rec.data.bl_name );
}

Baseliner.render_loc = function (val){
    return _(val);
}

Baseliner.render_icon = function (val){
    if( val == null || val == undefined ) return '';
    return String.format('<img src="{0}" />', val );
}

Baseliner.render_bytes = function(value,metadata,rec,rowIndex,colIndex,store) {
    return Baseliner.byte_format( value );
}


//return String.format('<a href="javascript:Baseliner.show_ci({3})">{2}</a>', mid, value );

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

// JsonStore with Error Handling
Baseliner.store_exception_handler = function( proxy, type, action, opts, res, arg ) {
    var store = this;
    // type = response
    try {
        var r = Ext.util.JSON.decode( res.responseText );
        if( res.status == 401 || r.logged_out ) {
            Baseliner.login({ no_reload: 1, scope: store, on_login: function(s){ s.reload() } });
        } 
        else if( r.msg ) {
            //Baseliner.error( _('Server Error'), r.msg );
            new Baseliner.ErrorWindow({ title: _('Server Error'), msg: r.msg  }).show();
        }
        else if( res.status == 0 ) {
            alert( _('Server not available') );  // an alert does not ask for images from the server
        }
    } catch(e) {
        Ext.Msg.alert( _('Server Error'), _('Error getting response from server. Code: %1. Status: %2', res.status, res.statusText ) );
        //if( console != undefined ) console.log( res );
        //Ext.Msg.alert( _('Server Error'), _('Error getting response from server: %1', res.responseText ) );
    }
    //alert( String.format('TYPE={0}, ACTION={1}, {2}' , type, action, Ext.util.JSON.encode( res )  ) );
};
Baseliner.store_exception_params = function( store, opts ) {
    opts.params['_bali_notify_valid_session'] = true;
    opts.params['_bali_client_context'] = 'json';
}

Baseliner.JsonStore = Ext.extend( Ext.data.JsonStore, {
    is_loaded: false,
    constructor: function(c){
        Baseliner.JsonStore.superclass.constructor.call(this,c);
        var self =this;
        this.on('exception', Baseliner.store_exception_handler );
        this.on('beforeload', Baseliner.store_exception_params );
        this.on('load', function(){ self.is_loaded=true });
    }
});

Baseliner.GroupingStore = Ext.extend( Ext.data.GroupingStore, {
    listeners: {
        exception: Baseliner.store_exception_handler,
        beforeload: Baseliner.store_exception_params 
    }
});


// deprecated:
Baseliner.json_store = Ext.extend( Baseliner.JsonStore, {
    root: 'data', 
    remoteSort: true,
    totalProperty: 'totalCount', 
    id: 'id', 
    baseParams: {  start: 0, limit: this.ps || 99999999 }
});

Baseliner.new_jsonstore = function(params) {
    if( params == undefined ) params={};
    var store = new Baseliner.JsonStore({
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

Baseliner.button = function(text,icon,handler){ 
    return new Ext.Button({
       text: text,
       icon: icon || '/static/images/icons/revision_create.gif',
       cls: 'x-btn-text-icon',
       handler: handler || function(){} 
    });
};

Baseliner.img_button = function(icon,handler){ 
    return new Ext.Button({
       icon: icon || '/static/images/icons/revision_create.gif',
       cls: 'x-btn-icon',
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
    var store = new Baseliner.JsonStore({
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
    if( params.on_select ) {
        combo.on( 'select', params.on_select );
    }
    return combo;
};

Baseliner.ArrayGrid = Ext.extend( Ext.grid.EditorGridPanel, {
    anchor: '100%',
    height: 200,
    frame: true,
    clicksToEdit: 1,
    name: 'array_field', 
    hideHeaders: true,
    initComponent: function(){
        var self = this;
        self.store = new Ext.data.SimpleStore({ fields:[ self.name ] });
        self.store.on('beforeaction', self.update_fields, self);
        self.store.on('create', self.update_fields, self);
        self.store.on('remove', self.update_fields, self);
        self.store.on('update', self.update_fields, self);
        if( self.description == undefined ) self.description = '';
        self.fieldset = new Ext.Container({ hidden: false });
        if( self.value != undefined ) {
            if( Ext.isString( self.value ) ) self.value = [self.value];
            Ext.each( self.value, function(v){
                self.push_item( self.name, v ); 
            });
            self.update_fields();
        }
        
        self.viewConfig = { scrollOffset: 2, forceFit: true };
        self.cm = new Ext.grid.ColumnModel([{
            dataIndex: self.name,
            width: '100%',
            renderer: function(v){ return String.format('<span style="font: 12px Consolas, Courier New, monotype">{0}</span>', v) },
            editor: new Ext.form.TextField({
                allowBlank: false, 
                style: 'font-family: Consolas, Courier New, monotype',
                renderer: function(v) {  return "a" }
            })
        }]);
        self.sm = new Ext.grid.RowSelectionModel({ singleSelect: true });
        self.tbar = [{
                text: _('Add'),
                icon: '/static/images/drop-add.gif',
                cls: 'x-btn-text-icon',
                handler: function () {
                    self.push_item( self.name, self.default_value );
                }
            }, {
                text: _('Delete'),
                icon: '/static/images/del.gif',
                cls: 'x-btn-text-icon',
                handler: function (e) {
                    var __selectedRecord = self.getSelectionModel().getSelected();
                    if (__selectedRecord != null) {
                        self.store.remove(__selectedRecord);
                    }
                }
            }, self.fieldset, '->', self.description ];
        Baseliner.ArrayGrid.superclass.initComponent.call( this );
    },
    push_item : function( f, v ) {
        var self = this;
        var rr = new Ext.data.Record.create([{
            name: f,
            type: 'string'
        }]);
        var h = {}; 
        h[ self.name ] = v;
        // put it in the grid store
        //fgrid.stopEditing();
        self.store.add( new rr( h ) );
        //fgrid.startEditing(0, 0);
        self.store.commitChanges();
    },
    get_save_data : function(){
        var self = this;
        var arr = [];
        self.store.each( function(r) {
            arr.push( r.data[ self.name ] );
        });
        return arr;
    },
    update_fields : function () {
        var self = this;
        var arr = [];
        self.store.each( function(r) {
            arr.push( r.data[ self.name ] );
        });
        self.fieldset.removeAll();
        if( arr.length > 0 ) {
            var fields = [];
            Ext.each( arr, function(v) {
                fields.push( new Ext.form.Hidden({ hidden: false, name: self.name, value: v, allowBlank: self.allowBlank || true }) );
            });
            self.fieldset.add( fields );
            self.fieldset.doLayout();
        }
        self.raw_value = arr;
    }, 
    getValue : function() {
        var self = this;
        return self.raw_value;
    },
    get_save_data : function(){
        var self = this;
        var arr = [];
        self.store.each( function(r) {
            arr.push( r.data[ self.name ] );
        });
        return arr;
    }
});

Baseliner.array_field = function( args ) {
    var field_name = args.name;
    var title = args.title;
    var label = args.label;
    var value = args.value;
    var description = args.description || '';
    var default_value = args.default_value;

    var fstore = new Ext.data.SimpleStore({ fields:[ field_name ] });
    if( value != undefined ) {
        var push_item = function(f, v ) {
            var rr = new Ext.data.Record.create([{
                name: f,
                type: 'string'
            }]);
            var h = {}; h[ field_name ] = v;
            // put it in the grid store
            fstore.insert( x, new rr( h ) );
        };
        try {
            // if it's an Array or Hash
            if( typeof( value ) == 'object' ) {
                for( var x=0; x < value.length ; x++ ) {
                    push_item( field_name, value[ x ] ); 
                }
                // save 
                try { value =Ext.util.JSON.encode( value ); } catch(f) {} 
            } else if( value.length > 0 ) {  // just one element
                push_item( field_name, value ); 
            }
        } catch(e) {}
    }

    var fdata = new Ext.form.Hidden({ name: field_name, value: value, allowBlank: 1 });
    var fgrid = new Ext.grid.EditorGridPanel({
            name: field_name + '_grid',
            fieldLabel: label,
            width: 410,
            height: 200,
            title: title,
            frame: true,
            clicksToEdit: 1,
            viewConfig: {
                scrollOffset: 2,
                forceFit: true
            },
            store: fstore,
            cm: new Ext.grid.ColumnModel([{
                dataIndex: field_name,
                width: 390,
                editor: new Ext.form.TextField({
                    allowBlank: false, 
                    renderer: function(v) {  return "a" }
                })
            }]),
            sm: (function () {
                var rsm = new Ext.grid.RowSelectionModel({
                    singleSelect: true
                });
                rsm.addListener('rowselect', function () {
                    var __record = rsm.getSelected();
                    return __record;
                });
                return rsm;
            })(),
            tbar: [{
                text: _('Add'),
                icon: '/static/images/drop-add.gif',
                cls: 'x-btn-text-icon',
                handler: function () {
                    var ___record = Ext.data.Record.create([{
                        name: field_name,
                        type: 'string'
                    }]);
                    var h = {};
                    h[ field_name ] = _( default_value );
                    var p = new ___record( h );
                    //fgrid.stopEditing();
                    fstore.add(p);
                    //fgrid.startEditing(0, 0);
                }
            }, {
                text: _('Delete'),
                icon: '/static/images/del.gif',
                cls: 'x-btn-text-icon',
                handler: function (e) {
                    var __selectedRecord = fgrid.getSelectionModel().getSelected();
                    if (__selectedRecord != null) {
                        fstore.remove(__selectedRecord);
                    }
                }
            }, '->', description ]
    });

    var write_to_field = function () {
        var arr = new Array();
        fstore.each( function(r) {
            arr.push( r.data[ field_name ] );
        });
        fdata.setValue( Ext.util.JSON.encode( arr ) );
    };
    fstore.on('beforeaction', write_to_field );
    fstore.on('create', write_to_field );
    fstore.on('remove', write_to_field );
    fstore.on('update', write_to_field );
    return { data: fdata, grid: fgrid };
};

Baseliner.combo_baseline = function(params) {
    if( params==undefined) params={};
    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        autoLoad: true,
        totalProperty:"totalCount", 
        baseParams: params.request || {},
        id: 'id', 
        url: '/baseline/json',
        fields: ['id','name','description', 'active'] 
    });
    var valueField = params.valueField || 'id';
    var combo = new Ext.form.ComboBox({
           fieldLabel: _("Baseline"),
           name: params.name || 'bl',
           hiddenName: params.hiddenName || 'bl',
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
    if( params.on_select ) {
        combo.on( 'select', params.on_select );
    }
    return combo;
};

Baseliner.isArray = function(obj) {
    return Object.prototype.toString.call(obj) === '[object Array]';
};

// Multiple provider search
Baseliner.SearchField = Ext.extend(Ext.form.TwinTriggerField, {
    initComponent : function(){
        Baseliner.SearchField.superclass.initComponent.call(this);
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
    emptyText: '<% _loc("<Enter your search string>") %>',
    paramName : 'query',

    onTrigger1Click : function(){
        if(this.hasSearch){
            this.el.dom.value = '';
            var o = {start: 0};
            this.store.baseParams = this.store.baseParams || {};
            this.store.baseParams[this.paramName] = '';
            this.store.reload({params:o});
            this.triggers[0].hide();
            this.hasSearch = false;
        }
    },

    onTrigger2Click : function(){
        var v = this.getRawValue();
        if(v.length < 1){ //>
            this.onTrigger1Click();
            return;
        }
        var o = {start: 0};
        this.store.baseParams = this.store.baseParams || {};
        this.store.baseParams[this.paramName] = v;
        this.store.reload({params:o});
        this.hasSearch = true;
        this.triggers[0].show();
    }
});
    

Baseliner.merge = function() {
    // copy reference to target object
    var target = arguments[0] || {}, i = 1, length = arguments.length, deep = true, options;

    // Handle a deep copy situation
    if ( typeof target === "boolean" ) {
        deep = target;
        target = arguments[1] || {};
        // skip the boolean and the target
        i = 2;
    }

    // Handle case when target is a string or something (possible in deep copy)
    if ( typeof target !== "object" ) 
        target = {};

    /* if ( typeof target !== "object" && !jQuery.isFunction(target) )
        target = {};
    */

    // extend jQuery itself if only one argument is passed
    if ( length == i ) {
        target = this;
        --i;
    }

    for ( ; i < length; i++ )
        // Only deal with non-null/undefined values
        if ( (options = arguments[ i ]) != null )
                // Extend the base object
                for ( var name in options ) {
                        var src = target[ name ], copy = options[ name ];

                        // Prevent never-ending loop
                        if ( target === copy )
                                continue;
                        var is_arr = Baseliner.isArray( copy );
                        // Recurse if we're merging object values
                        if ( deep && copy && typeof copy === "object" && ! is_arr && !copy.nodeType )
                                target[ name ] = Baseliner.merge( deep, 
                                        // Never move original objects, clone them
                                        src || ( copy.length != null ? [ ] : { } )
                                , copy );
                        else if ( deep && copy && is_arr && !copy.nodeType ) {
                            if( src === undefined ) src = []; 
                                target[ name ]= src.concat( copy );
                        }
                 
                        // Don't bring in undefined values
                        else if ( copy !== undefined )
                                target[ name ] = copy;

                }

    // Return the modified object
    return target;
};

Baseliner.openLogTab = function(id_job,title) {
    if( id_job!=undefined ) {
        Baseliner.addNewTabComp("/job/log/list?id_job="+id_job, title);
    }
};

/**
 * Page Size Plugin for Paging Toolbar
 *
 * @author rubensr, http://extjs.com/forum/member.php?u=13177
 * @see http://extjs.com/forum/showthread.php?t=14426
 * @author Ing. Jozef Sakalos, modified combo for editable, enter key handler, config texts
 * @date 27. January 2008
 * @version $Id: Ext.ux.PageSizePlugin.js 11 2008-02-22 17:13:52Z jozo $
 * @package perseus
 */
Ext.ux.PageSizePlugin = function (config) {
    var data = config.data != undefined ? config.data : [
        ['5', 5],
        ['10', 10],
        ['15', 15],
        ['20', 20],
        ['25', 25],
        ['50', 50],
        ['100', 100]
    ];

    Ext.ux.PageSizePlugin.superclass.constructor.call(this, Ext.apply({
        store: new Ext.data.SimpleStore({
            fields: ['text', 'value'],
            data: data
        }),
        mode: 'local',
        displayField: 'text',
        valueField: 'value',
        allowBlank: false,
        triggerAction: 'all',
        width: 50,
        maskRe: /[0-9]/
    }, config ));
};

Ext.extend(Ext.ux.PageSizePlugin, Ext.form.ComboBox, {
    beforeText: 'Show',
    afterText: 'rows/page',
    init: function (paging) {
        paging.on('render', this.onInitView, this);
    },

    onInitView: function (paging) {
        paging.add('-', this.beforeText, this, this.afterText);
        this.setValue(paging.pageSize);
        this.on('select', this.onPageSizeChanged, paging);
        this.on('specialkey', function (combo, e) {
            if (13 === e.getKey()) {
                this.onPageSizeChanged.call(paging, this);
            }
        });

    },

    onPageSizeChanged: function (combo) {
        this.pageSize = parseInt(combo.getValue(), 10);
        this.doLoad(0);
    }
});

Baseliner.open_topic = function(mid,opts) {
    if( ! opts ) opts = {};
    var title = opts.title || opts.topic_name || String.format('#{0}', mid );
    Baseliner.add_tabcomp( '/comp/topic/topic_main.js', title, { topic_mid:mid, _parent_grid: opts.grid });
    return false;
};

Baseliner.Grid = {};


Baseliner.Grid.Buttons = {};

Baseliner.Grid.Buttons.Add = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
        config = Ext.apply({
            text: _('New'),
            //icon:'/static/images/icons/add.gif',
            //cls: 'x-btn-text-icon'
            iconCls: 'sprite add'
        }, config);
        Baseliner.Grid.Buttons.Add.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Edit = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
        config = Ext.apply({
            text: _('Edit'),
            //icon: '/static/images/icons/edit.gif',
            //cls: 'x-btn-text-icon',
            disabled: true,
            iconCls: 'sprite edit'
        }, config);
        Baseliner.Grid.Buttons.Edit.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Delete = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
        config = Ext.apply({
            text: _('Delete'),
            //icon:'/static/images/icons/delete.gif',
            //cls: 'x-btn-text-icon',
            disabled: true,
            iconCls: 'sprite delete'
        }, config);
        Baseliner.Grid.Buttons.Delete.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Start = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
        config = Ext.apply({
            text: _('Activate'),
            icon:'/static/images/start.gif',
            cls: 'x-btn-text-icon',         
            disabled: true
            //iconCls: 'sprite delete'
        }, config);
        Baseliner.Grid.Buttons.Start.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Stop = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
        config = Ext.apply({
            text: _('Deactivate'),
            icon:'/static/images/stop.gif',
            disabled: true,
            cls: 'x-btn-text-icon'
                //iconCls: 'sprite delete'
        }, config);
        Baseliner.Grid.Buttons.Stop.superclass.constructor.call(this, config);
    }
});

// Baseliner.gantt = function( format ) {
//     var divTag = document.createElement("div");  
//     divTag.setAttribute("align", "center");           
//     var g = new JSGantt.GanttChart( 'g', divTag, format );

//     g.Draw();
    
//     return g;
// };


//Baseliner.loadFile('/static/pdfjs/build/pdf.js', 'js' );
Baseliner.PDFJS = function(config){
    var self = this;
    var prev = new Ext.Button({ icon: '/static/images/icons/arrow_left_black.png' });
    var next = new Ext.Button({ icon: '/static/images/icons/arrow_right_black.png' });
  var page_num = new Ext.form.TextField({ width:'30', readOnly:true  });
  var page_count = new Ext.form.TextField({ width:'30', readOnly:true });

    Baseliner.PDFJS.superclass.constructor.call( this, Ext.apply( {
        tbar: [
           prev, next,
           _('Page:'), page_num, _('Total:'), page_count
        ], 
        bodyCfg: { tag:'canvas', style:{ 'background-color':'#fff' } }
    }, config ) );

    self.on( 'afterrender', function(){
        var id = this.body.id;

        //
        // NOTE: 
        // Modifying the URL below to another server will likely *NOT* work. Because of browser
        // security restrictions, we have to use a file server with special headers
        // (CORS) - most servers don't support cross-origin browser requests.
        //
        var url = self.url;
      
         // var url = 'http://cdn.mozilla.net/pdfjs/tracemonkey.pdf';
        // url = '/static/pdfjs/build/tracemonkey.pdf';
        //
        // Disable workers to avoid yet another cross-origin issue (workers need the URL of
        // the script to be loaded, and currently do not allow cross-origin scripts)
        //
        PDFJS.disableWorker = true;

        var pdfDoc = null,
            pageNum = 1,
            scale = 0.8,
            canvas = document.getElementById( id ),
            ctx = canvas.getContext('2d');

        //
        // Get page info from document, resize canvas accordingly, and render page
        //
        function renderPage(num) {
          // Using promise to fetch the page
          pdfDoc.getPage(num).then(function(page) {
            var viewport = page.getViewport(scale);
            canvas.height = viewport.height;
            canvas.width = viewport.width;

            // Render PDF page into canvas context
            var renderContext = {
              canvasContext: ctx,
              viewport: viewport
            };
            page.render(renderContext);
          });

          // Update page counters
          page_num.setValue( pageNum );
          page_count.setValue( pdfDoc.numPages );
        }

        //
        // Go to previous page
        //
        function goPrevious() {
          if (pageNum <= 1)
            return;
          pageNum--;
          renderPage(pageNum);
        }

        //
        // Go to next page
        //
        function goNext() {
          if (pageNum >= pdfDoc.numPages)
            return;
          pageNum++;
          renderPage(pageNum);
        }
        prev.handler = goPrevious;
        next.handler = goNext;
        //
        // Asynchronously download PDF as an ArrayBuffer
        //
        PDFJS.getDocument(url).then(function getPdfHelloWorld(_pdfDoc) {
          pdfDoc = _pdfDoc;
          renderPage(pageNum);
        });
    });
};
Ext.extend( Baseliner.PDFJS, Ext.Panel ); 

// Usage: Baseliner.read_pdf( '/static/pdfjs/build/tracemonkey.pdf' );
Baseliner.read_pdf = function( url ) {
  var win = new Ext.Window({
      layout:'fit', width:650, height: 760,
      maximizable: true,
      items: new Baseliner.PDFJS({ url: url })
  });
  win.show();
};

Baseliner.show_revision = function( mid ) {
    Baseliner.ajaxEval( '/ci/url', { mid: mid }, function(res){
        if( res.url ) {
            if( res.url.type == 'iframe' ) {
                Baseliner.add_iframe( res.url.url, _( res.title ), {} );
            }
        }
    });
};

Baseliner.show_ci = function( mid ) {
    Baseliner.add_tabcomp( '/ci/edit', null, { load: true, mid: mid } );
};

function returnOpposite(hexcolor) {
    var r = parseInt(hexcolor.substr(0,2),16);
    var g = parseInt(hexcolor.substr(2,2),16);
    var b = parseInt(hexcolor.substr(4,2),16);
    var yiq = ((r*299)+(g*587)+(b*114))/1000;
    return (yiq >= 128) ? '#000000' : '#FFFFFF';
}    

Baseliner.loading_panel = function(msg){
    if( ! msg ) 
        msg = _('Loading');
    return new Ext.Container({
        margin: 70,
        html: [ 
            '<div style="position:absolute; left:0; top:0; width:100%; height:100%; background-color:white;"></div>',
            '<div style="position:absolute; left:45%; top:40%; padding:2px; height:auto;">',
            '<center>',
            '<img style="" src="/static/images/loading.gif" />',
            '<div style="text-transform: uppercase; font-weight: normal; font-size: 11px; color: #999; font-family: Calibri, OpenSans, Tahoma, Helvetica Neue, Helvetica, Arial, sans-serif;">',
            msg,
            '</div>',
            '</center>',
            '</div>' ].join('')
    });
}

Baseliner.editSlot =  function(panel, id_cal, dia,ini,fin, date) {
    var comp = Baseliner.showAjaxComp( '/job/calendar_slot_edit',
        {  panel: panel, id_cal: id_cal, pdia: 'day-'+dia, pini: ini, pfin: fin, date: date } );
}

Baseliner.editId = function( panel, id_cal, id, date) {
    var comp = Baseliner.showAjaxComp( '/job/calendar_slot_edit',
        { id: id, id_cal: id_cal, panel: panel, date: date} );
}

Baseliner.createRange = function(panel, id_cal, id, pdia, date) {
    var comp = Baseliner.showAjaxComp( '/job/calendar_slot_edit',
        { id: id,  pdia: 'day-'+pdia, id_cal: id_cal, panel: panel, date: date, pini: "00:00", pfin: "24:00"} );
}   

Baseliner.Window = Ext.extend( Ext.Window, {
    tabifiable: false,
    minimizable: true,
    maximizable: true,
    initComponent: function(){
        var self = this;
        if( self.tabifiable ) {
            self.addTool({
                id: 'down',
                handler: function(a,b,c){ self.tabify(a,b,c) }
            });
        }
        Baseliner.Window.superclass.initComponent.call(this);
    },
    minimize: function(){
        var self = this;
        if( Baseliner.main_toolbar ) {
            self.min_obj = new Ext.Button({
                xtype: 'button',
                icon: '/static/images/icons/window_min.png',
                tooltip: self.title,
                handler: function(){
                    self.show();
                    self.min_obj.destroy();
                }
            });
            Baseliner.main_toolbar.insert( -2, self.min_obj );
            Baseliner.main_toolbar.doLayout();
            self.hide( self.min_obj.el );
        }
        this.fireEvent('minimize', this);
        return this;
    },
    tabify : function(a,b,c){
        var self = this;
        var comp = self.items.items[0]; 
        if( comp ) {
            comp.title = null;
            comp.header = false;
            Baseliner.addNewTabItem( comp, self.title, {});
            self.close();
        }
    }
});

Baseliner.LogWindow = Ext.extend( Baseliner.Window, {
    width: 940, height: 400, layout:'fit',
    modal: true,
    constructor: function(c){
        Baseliner.LogWindow.superclass.constructor.call(this, c);
        var v = c.value;
        if( Ext.isArray( v ) ) v=v.join("\n");
        this.add( new Ext.form.TextArea({
            value: v, readOnly:true, style:'font-family:Consolas, Courier New, Courier, mono' }) );
    }
});

Baseliner.ImportWindow = Ext.extend( Baseliner.Window, {
    title: _('Import'),
    width: 800, height: 400, layout:'fit',
    url: '',
    initComponent : function(){
        var self = this;
        self.data_paste = new Baseliner.MonoTextArea({});
        self.items = self.data_paste;
        self.tbar = [
            { text: self.title, 
                icon: '/static/images/icons/import.png',
                handler: function(){
                    Baseliner.ajaxEval( self.url, { yaml: self.data_paste.getValue() }, function(res){
                        if( !res.success ) {
                            Baseliner.error( self.title, res.msg );
                            return;
                        } else {
                            Baseliner.message(self.title, res.msg );
                        }
                    });
                }
            }
        ]
        Baseliner.ImportWindow.superclass.initComponent.call(this);
    }
});

Baseliner.button.CSVExport = Ext.extend( Ext.Toolbar.Button, {
        text: _('CSV'),
        icon:'/static/images/download.gif',
        cls: 'x-btn-text-icon',
        handler: function() {
            var self = this;
            if( !self.grid ) {
                self.grid = self.findParentByType('grid');
            }
            var cfg = self.grid.getColumnModel().config;
            var s = self.store ? self.store : self.grid.getStore();
            var html = '';
            var cols = [], col_names = [];
            for( var i=0; i<cfg.length; i++ ) {
                if( ! cfg[i].hidden )
                    var n = cfg[i].report_header || cfg[i].header;
                    col_names.push( n );
                    cols.push({ id: cfg[i].dataIndex, name: n });
            }
            html += col_names.join(',') + "\n";
            s.each( function(row){
                var arr = [];
                Ext.each( cols, function(col){
                    var v = row.data[ col.id ];
                    if( v == null ) {
                        v='';
                    } else {
                        v = v.replace( '"', '\\"' );
                    }
                    arr.push( '"' + v + '"'  );
                })
               html += arr.join(',') + "\n";
            });
            var ww = window.open('about:blank', '_blank' );
            ww.document.title = _('config.csv');
            ww.document.write( '<pre>' + html + '</pre>' );
            ww.document.close();
        }
});

Baseliner.open_pre_page = function(title,txt) {
    var ww = window.open('about:blank', '_blank' );
    ww.document.title = title || _('Text');
    ww.document.write( '<pre>' + txt + '</pre>' );
    ww.document.close();
}

Baseliner.Base64 = (function() {
    "use strict";

    var _keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    var _utf8_encode = function (string) {

        var utftext = "", c, n;

        string = string.replace(/\r\n/g,"\n");

        for (n = 0; n < string.length; n++) {

            c = string.charCodeAt(n);

            if (c < 128) {

                utftext += String.fromCharCode(c);

            } else if((c > 127) && (c < 2048)) {

                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);

            } else {

                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);

            }

        }

        return utftext;
    };

    var _utf8_decode = function (utftext) {
        var string = "", i = 0, c = 0, c1 = 0, c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {

                string += String.fromCharCode(c);
                i++;

            } else if((c > 191) && (c < 224)) {

                c1 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c1 & 63));
                i += 2;

            } else {

                c1 = utftext.charCodeAt(i+1);
                c2 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c1 & 63) << 6) | (c2 & 63));
                i += 3;

            }

        }

        return string;
    };

    var _hexEncode = function(input) {
        var output = '', i;

        for(i = 0; i < input.length; i++) {
            output += input.charCodeAt(i).toString(16);
        }

        return output;
    };

    var _hexDecode = function(input) {
        var output = '', i;

        if(input.length % 2 > 0) {
            input = '0' + input;
        }

        for(i = 0; i < input.length; i = i + 2) {
            output += String.fromCharCode(parseInt(input.charAt(i) + input.charAt(i + 1), 16));
        }

        return output;
    };

    var encode = function (input, utf8) {
        var output = "", chr1, chr2, chr3, enc1, enc2, enc3, enc4, i = 0;

        if( utf8 ) 
            input = _utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output += _keyStr.charAt(enc1);
            output += _keyStr.charAt(enc2);
            output += _keyStr.charAt(enc3);
            output += _keyStr.charAt(enc4);

        }

        return output;
    };

    var decode = function (input, utf8) {
        var output = "", chr1, chr2, chr3, enc1, enc2, enc3, enc4, i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = _keyStr.indexOf(input.charAt(i++));
            enc2 = _keyStr.indexOf(input.charAt(i++));
            enc3 = _keyStr.indexOf(input.charAt(i++));
            enc4 = _keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output += String.fromCharCode(chr1);

            if (enc3 !== 64) {
                output += String.fromCharCode(chr2);
            }
            if (enc4 !== 64) {
                output += String.fromCharCode(chr3);
            }

        }

        return utf8 ? _utf8_decode(output) : output;
    };

    var decodeToHex = function(input) {
        return _hexEncode(decode(input));
    };

    var encodeFromHex = function(input) {
        return encode(_hexDecode(input));
    };

    return {
        'encode': encode,
        'decode': decode,
        'decodeToHex': decodeToHex,
        'encodeFromHex': encodeFromHex
    };
}());

Baseliner.CPANDownloader = Ext.extend( Ext.Panel, {
   layout: 'card',
   activeItem: 0,
   constructor: function(c){
       var store_remote = new Ext.data.SimpleStore({
           fields: ['name', 'archive', 'abstract', 'version', 'author', 
                    'url', 'date', 'release', 'size' ]
       });
       
       var ic = '/static/images/icons/downloads_favicon.png';
       this.btns = {
           download: new Ext.Button({ text:_('Download'), icon: ic, handler: function(){ self.download() } }),
           get: new Ext.Button({ text:_('Get'), icon: ic, hidden: true, handler: function(){ self.get() } }),
           del: new Ext.Button({ text:_('Delete'), icon: '/static/images/icons/delete.gif', 
               hidden: true, handler: function(){ self.del() } }),
           install: new Ext.Button({ text:_('Install'), icon: '/static/images/icons/database_save.png',
               hidden: true, handler: function(){ self.install() } })
       };

       var tbar = [
           { text:_('Remote'), pressed: true,
                icon: '/static/images/icons/cloud.png',
               allowDepress:false, enableToggle:true, toggleGroup:'cpan_btns', handler: function(){ self.show_remote() } },
           { text:_('Local'), pressed: false,
                icon: '/static/images/icons/local.png',
               allowDepress:false, enableToggle:true, toggleGroup:'cpan_btns', handler: function(){ self.show_local() } },
           { text:_('Installed'), pressed: false,
                icon: '/static/images/icons/perl.png',
               allowDepress:false, enableToggle:true, toggleGroup:'cpan_btns', handler: function(){ self.show_installed() } },
           new Baseliner.SearchField({ store: store_remote }),
           this.btns.download,
           this.btns.get,
           this.btns.del,
           this.btns.install
       ];
       Baseliner.CPANDownloader.superclass.constructor.call(this, Ext.apply({ tbar: tbar }, c));
       var self = this;
       
       // ------- Remote CPAN
       var sm = new Ext.grid.CheckboxSelectionModel();
       var columns = [
           sm,
          { header:_('Name'), dataIndex: 'name' },
          { header:_('Release'), width: 30, dataIndex: 'release', renderer: Baseliner.render_bold },
          { header:_('Version'), width: 30, dataIndex: 'version' }, 
          { header:_('Date'), width: 30, dataIndex: 'date' },
          { header:_('Size'), width: 30, dataIndex: 'size', renderer: Baseliner.render_bytes },
          { header:_('URL'), dataIndex: 'url' }              
       ];
       var cm = new Ext.grid.ColumnModel({ columns: columns });
       
       self.store_remote = store_remote;
       self.grid_remote = new Ext.grid.EditorGridPanel({
           store: self.store_remote, cm: cm, selModel: sm,
           viewConfig: { forceFit: true }
       });
       
       // ------- Local CPAN
       self.store_local = new Baseliner.JsonStore({
           url: '/feature/local_cpan',
           root: 'data' , 
           remoteSort: true,
           totalProperty: 'totalCount', 
           id: 'id', 
           fields: ['name', 'archive', 'abstract', 'version', 'file', 
                    'url', 'date', 'release', 'size' ]
       });
       var sm2 = new Ext.grid.CheckboxSelectionModel();
       self.grid_local = new Ext.grid.EditorGridPanel({
           store: self.store_local, 
           viewConfig: { forceFit: true },
           selModel: sm2,
           cm : new Ext.grid.ColumnModel({ columns: [
               sm2,
              { header:_('Name'), dataIndex: 'name' },
              { header:_('Date'), width: 30, dataIndex: 'date' },
              { header:_('Size'), width: 30, dataIndex: 'size', renderer: Baseliner.render_bytes },
              { header:_('File'), dataIndex: 'file' }
           ]})
       });
       self.grid_installed = new Ext.grid.EditorGridPanel({
           store: new Baseliner.JsonStore({
               url: '/feature/installed_cpan', 
               root: 'data' , 
               remoteSort: true,
               totalProperty: 'totalCount', 
               id: 'id', 
               fields: ['name', 'version' ]
           }),
           viewConfig: { forceFit: true },
           cm : new Ext.grid.ColumnModel({ columns: [
              { header:_('Name'), dataIndex: 'name' },
              { header:_('Version'), width: 30, dataIndex: 'version' }
           ]})
       });
       self.add( self.grid_remote );
       self.add( self.grid_local );
       self.add( self.grid_installed );
       self.store_remote.reload = function(){
           self.search_cpan(this.baseParams.query);
       };
   },
   search_cpan: function(q){
       var self = this;
       self.el.mask();
       $.ajax({
           type: 'GET',
           url: 'http://patch.vasslabs.com/cpan_search',
           data: { q: q },
           crossDomain: true,
           success: function(res, textStatus, jqXHR) {
               var k = 0;
               if( res.success ) {
                   self.store_remote.removeAll();
                   Baseliner.message( _('CPAN'), _('Found %1 results', res.results.length ));
                   Ext.each( res.results, function(r){
                       var rec = new self.store_remote.recordType(r,k++);
                       self.store_remote.add( rec );
                   });
                   self.store_remote.commitChanges();
               } else {
                   Baseliner.error(_('Error'), res.msg );
               }
               self.el.unmask();
           },
           error: function (res, textStatus, errorThrown) {
               Baseliner.message(_('Error'), _('CPAN Search failed: %1', res) );
               self.el.unmask();
           }
       });           
   }, 
   download: function(){
       var self = this;
       var sels = self.grid_remote.getSelectionModel().getSelections();
       self.el.mask( _('Downloading...') );
       Ext.each( sels, function(sel){
           var url = sel.data.url;
           //url = url.replace(/http:\/\/cpan.metacpan.org\//, '');
           $.ajax({
               type: 'GET',
               //url: String.format('http://patch.vasslabs.com/cpan_download/{0}', url),
               url: 'http://patch.vasslabs.com/cpan_get',
               data: { url: sel.data.url },
               crossDomain: true,
               success: function(res, textStatus, jqXHR) {
                   self.el.mask( _('Uploading...') );
                   // submit to server
                   /*
                   var arrBuf = new ArrayBuffer(res.length);
                    var writer = new Uint8Array(arrBuf);
                    for (var i = 0, len = res.length; i < len; i++) {
                        writer[i] = res.charCodeAt(i);
                    }*/
                   var filename = sel.data.name + '-' + sel.data.version + '.tar.gz' ;
                   Baseliner.ajaxEval('/feature/upload_cpan',{ data: res.data, filename: filename }, function(res){
                       self.el.unmask();
                       if( res.success ) {
                           Baseliner.message( _('CPAN'), _('Uploaded file %1 ok', res.filepath ) );
                       } else {
                           Baseliner.error( _('CPAN'), _('Error uploading file %1', res.msg ) );
                       }
                   });
               },
               error: function (res, textStatus, errorThrown) {
                   Baseliner.message('Error', 'Search CPAN failed.');
                   //console.log( res );
               }
           });
        });
   },
   del: function(){
       var self = this;
       var sels = self.grid_remote.getSelectionModel().getSelections();
       self.el.mask( _('Deleting...') );
       var files = [];
       Ext.each( sels, function(s){
           files.push( s.data.file );
       });
       Baseliner.ajaxEval( '/feature/local_delete', { files: Ext.util.JSON.encode( files ) }, function(res){
           self.el.unmask();
           Baseliner.message( _('Delete'), res.msg );
       });
   },
   get: function(){
       var self = this;
       var sels = self.grid_local.getSelectionModel().getSelections();
       var files = []; Ext.each( sels, function(s){ files.push( s.data.file ); });
       var fd = document.all.FD || document.all.FrameDownload;
       fd.src =  '/feature/local_get?file=' + files[0];
   },
   get_multi: function(){
       // not working
       var self = this;
       var sels = self.grid_local.getSelectionModel().getSelections();
       var files = []; Ext.each( sels, function(s){ files.push( s.data.file ); });
       var fd = document.all.FD || document.all.FrameDownload;
       var req = function(file, id){ fd.src =  '/feature/local_get?file=' + file + '&id=' + id };
       var ix = 0;
       var first = true;
       var id=0;
       var check_cookie = function(){
               Baseliner.message( 22,  '=>' + Baseliner.cookie.get( id ) );
           if( first || Baseliner.cookie.get( id ) ) {
               // download next?
               if( ix!=0 && ix >= files.length ) return;
               // yes
               var f = files[ix++];
               Baseliner.message( 11, f );
               id = "fd_" + (new Date()).getTime() + Math.floor( Math.random() );
               Baseliner.cookie.set( id, null);  // clear cookie
               req( f, id);
               first = false;
           }
           setTimeout( check_cookie, 1500);
       };
       check_cookie();
   },
   install : function(){
       var self = this;
       var sels = self.grid_local.getSelectionModel().getSelections();
       self.el.mask( _('Installing...') );
       var files = [];
       Ext.each( sels, function(s){
           files.push( s.data.file );
       });
       Baseliner.ajaxEval( '/feature/install_cpan', { files: Ext.util.JSON.encode( files ) }, function(res){
           self.el.unmask();
           Baseliner.message( _('Install'), res.msg );
           ( new Baseliner.LogWindow({ value: res.log }) ).show();
       });
   },
   show_remote : function(){
       var self = this;
       self.btns.download.show();
       self.btns.install.hide();
       self.btns.del.hide();
       self.btns.get.hide();
       self.getLayout().setActiveItem( self.grid_remote );
   },
   show_local : function(){
       var self = this;
       self.btns.download.hide();
       self.btns.install.show();
       self.btns.del.show();
       self.btns.get.show();
       self.grid_local.getStore().reload();
       self.getLayout().setActiveItem( self.grid_local );
   },
   show_installed : function(){
       var self = this;
       self.btns.download.hide();
       self.btns.install.hide();
       self.btns.del.hide();
       self.btns.get.hide();
       self.grid_installed.getStore().reload();
       self.getLayout().setActiveItem( self.grid_installed );
   }
});

Baseliner.RowSelectionModel = Ext.extend( Ext.grid.RowSelectionModel, {
    handleMouseDown : function(g, rowIndex, e){
        if(e.button !== 0 || this.isLocked()){
            return;
        }
        var view = this.grid.getView();
        if(e.shiftKey && !this.singleSelect && this.last !== false){
            var last = this.last;
            this.selectRange(last, rowIndex, e.ctrlKey);
            this.last = last; // reset the last
            view.focusRow(rowIndex);
        }else{
            var isSelected = this.isSelected(rowIndex);
            if(e.ctrlKey && isSelected){
                this.deselectRow(rowIndex);
            }else if(!isSelected || this.getCount() > 1){
                this.selectRow(rowIndex, e.ctrlKey || e.shiftKey);
                view.focusRow(rowIndex);
            }
        }
    }
});

Baseliner.CheckboxSelectionModel = Ext.extend( Ext.grid.CheckboxSelectionModel, {
    handleMouseDown : function(g, rowIndex, e){
        if(e.button !== 0 || this.isLocked()){
            return;
        }
        var view = this.grid.getView();
        if(e.shiftKey && !this.singleSelect && this.last !== false){
            var last = this.last;
            this.selectRange(last, rowIndex, e.ctrlKey);
            this.last = last; // reset the last
            view.focusRow(rowIndex);
        }else{
            var isSelected = this.isSelected(rowIndex);
            if(e.ctrlKey && isSelected){
                this.deselectRow(rowIndex);
            }else if(!isSelected || this.getCount() > 1){
                this.selectRow(rowIndex, e.ctrlKey || e.shiftKey);
                view.focusRow(rowIndex);
            }
        }
    }
});

Baseliner.RowDragger = Ext.extend(Ext.util.Observable, {
    //expandOnEnter : true,
    //expandOnDblClick : true,
    header : '',
    width : 20,
    sortable : false,
    //fixed : true,
    //hideable: false,
    menuDisabled : true,
    dataIndex : '',
    id : 'dragger',
    //lazyRender : true,
    //enableCaching : true,
    constructor: function(config){
        Ext.apply(this, config);
        this.addEvents({
            dragging: true
        });

        Baseliner.RowDragger.superclass.constructor.call(this);
    },

    getRowClass : function(record, rowIndex, p, ds){
        return 'x-grid3-row-expanded';
        p.cols = p.cols-1;
        var content = this.bodyContent[record.id];
        if(!content && !this.lazyRender){
            content = this.getBodyContent(record, rowIndex);
        }
        if(content){
            p.body = content;
        }
        return this.state[record.id] ? 'x-grid3-row-expanded' : 'x-grid3-row-collapsed';
    },

    init : function(grid){
        this.grid = grid;
        var view = grid.getView();
        //view.getRowClass = this.getRowClass.createDelegate(this);
        //view.enableRowBody = true;
        //grid.on('render', this.onRender, this);
        //grid.on('destroy', this.onDestroy, this);
    },

    onRender: function() {
        var grid = this.grid;
        var mainBody = grid.getView().mainBody;
    },
    renderer : function(v, p, record){
        //p.cellAttr = 'rowspan="2"';
        //return '<div class="x-grid3-row-expander">&#160;</div>';
        //return '<div class="x-grid3-row-expander"><img src="/static/images/icons/handle.png" />&#160;</div>';
        return '<img src="/static/images/icons/handle.png" />';
    }
});

Baseliner.render_ci = function(value,metadata,rec,rowIndex,colIndex,store) {
    var mid = rec.data.mid;
    return String.format('<a href="javascript:Baseliner.show_ci({0})">{1}</a>', mid, value );
};

Baseliner.CIGrid = Ext.extend( Ext.grid.GridPanel, {
    height: 220,
    hideHeaders: false,
    disabled: false,
    enableDragDrop: true, // enable drag and drop of grid rows
    readOnly: false,
    constructor: function(c){
        //var dragger = new Baseliner.RowDragger({});
        var sm = new Baseliner.CheckboxSelectionModel({
            checkOnly: true,
            singleSelect: false
        });
        //self.sm = new Baseliner.RowSelectionModel({ singleSelect: true }); 

        var cols = [
            //dragger,
            sm
        ];
        var cols_keys = ['icon', 'mid', 'name', 'versionid', 'collection', 'properties' ];
        var cols_templates = {
          icon : { width: 40, dataIndex: 'icon', renderer: Baseliner.render_icon },
          mid: { width: 40, dataIndex: 'mid', header: _('ID') },
          name: { header: _('Name'), width: 240, dataIndex: 'name', renderer: Baseliner.render_ci },
          'class': { header: _('Class'), width: 120, dataIndex: 'class' },
          collection: { header: _('Collection'), width: 120, dataIndex: 'collection' },
          rel_type: { header: _('Relationship'), width: 120, dataIndex: 'rel_type' },
          properties: { header: _('Properties'), width: 240, dataIndex: 'pretty_properties' },
          versionid: { header: _('Version'), width: 80, dataIndex: 'versionid' }
        };
        var col_prefs = Ext.isArray( c.columns ) ? c.columns : Ext.isString(c.columns) ? c.columns.split(';') : [];
        if( col_prefs.length > 0 ) {
            Ext.each( col_prefs, function(colt){
                if( Ext.isObject( colt ) ) {
                    cols.push( colt );
                } else {
                    var ct = cols_templates[ colt ];
                    if( ct ) cols.push( ct );
                }
            });
        } else {
            Ext.each( cols_keys, function(colt){
                var ct = cols_templates[ colt ];
                if( ct ) cols.push( ct );
            });
        }
        delete c['columns'];
        var store = new Ext.data.SimpleStore({
            fields: ['mid','name','versionid', 'icon', 'bl', 'item', 'pretty_properties', 'class', 'collection','rel_type' ],
            data: [ ]
        });
        Baseliner.CIGrid.superclass.constructor.call( this, Ext.apply({
            store: store,
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            },
            columns: cols
        },c) );
    },
    initComponent: function(){
        var self = this;
        if( self.ci == undefined ) self.ci = {};
        if( self.ci_role) self.ci.role = self.ci_role;
        if( self.ci_class) self.ci['class'] = self.ci_class;
        if( self.ci_grid == undefined ) self.ci_grid = {};
        self.ci_store = new Baseliner.store.CI({ 
            baseParams: Ext.apply({ _whoami: 'CIGrid_combo_store', no_vars: 1 }, self.ci )
        });
        self.ci_box = new Baseliner.model.CICombo({
            store: self.ci_store, 
            height: 400,
            width: 400,
            singleMode: true, 
            fieldLabel: _('CI'),
            name: 'ci',
            hiddenName: 'ci', 
            allowBlank: true
        }); 
        self.ci_box.on('select', function(combo,rec,ix) {
            if( combo.id != self.ci_box.id ) return; // strange bug: this event gets fired with TopicGrid and CIGrid in the same page
            self.add_to_grid( rec.data );
        });
        self.ddGroup = 'bali-grid-data-' + self.id;
        var btn_delete = new Baseliner.Grid.Buttons.Delete({
            handler: function() {
                var sm = self.getSelectionModel();
                if (sm.hasSelection()) {
                    Ext.each( sm.getSelections(), function( sel ){
                        self.getStore().remove( sel );
                    });
                    btn_delete.disable();
                    self.refresh_field();
                } else {
                    Baseliner.message( _('ERROR'), _('Select at least one row'));    
                };                
            }
        });
        var tbar_items = []; //[ self.ci_box, btn_delete ];
        if( ! self.field ) {
            self.field = new Ext.form.Hidden({ name: self.name, value: self.value });
            tbar_items.push( self.field );
        }
        self.tbar = new Ext.Toolbar({ hidden: self.readOnly, items: tbar_items });
        self.on('rowclick', function(grid, rowIndex, e) {
            btn_delete.enable();
        });     

        var val = self.value;
        if( Ext.num(val) != undefined ) val=[val];
        
        if( Ext.isArray(val) ) {
            var p = { mids: val, _whoami: 'CIGrid_mids' };
            if( self.ci.role ) p.role = self.ci.role;
            Baseliner.ajaxEval( '/ci/store', Ext.apply(self.ci_grid, p ), function(res){
                Ext.each( res.data, function(r){
                    if( ! r ) return;
                    self.add_to_grid( r );
                });
            });
        }
        else if( self.from_mid || self.to_mid ) {
            Baseliner.ajaxEval( '/ci/children', Ext.apply(self.ci_grid, { from_mid: self.from_mid, to_mid: self.to_mid,  _whoami: 'CIGrid_from_mid' }), function(res){
                Ext.each( res.data, function(r){
                    if( ! r ) return;
                    self.add_to_grid( r );
                    self.field.originalValue = self.field.getValue();  // prevent forms from being dirty
                });
            });
        }
    
        Baseliner.CIGrid.superclass.initComponent.call( this );
        
        self.on('afterrender', function(){
            var width = self.el.getWidth();
            self.ci_box.width = width -100;
            var tbar = self.getTopToolbar();
            tbar.add( self.ci_box, btn_delete );
            tbar.doLayout();
            var ddrow = new Baseliner.DropTarget(self.container, {
                comp: self,
                ddGroup : self.ddGroup,
                copy: false,
                notifyDrop : function(dd, e, data){
                    var ds = self.store;
                    var sm = self.getSelectionModel();
                    var rows = sm.getSelections();
                    if(dd.getDragData(e)) {
                        var cindex=dd.getDragData(e).rowIndex;
                        if(typeof(cindex) != "undefined") {
                            for(i = 0; i <  rows.length; i++) {
                                ds.remove(ds.getById(rows[i].id));
                            }
                            ds.insert(cindex,data.selections);
                            sm.clearSelections();
                        }
                        self.refresh_field();
                    }
                }
            }); 
        });
    },
    refresh_field : function(){
        var self = this;
        var mids = [];
        self.store.each(function(row){
            mids.push( row.data.mid ); 
        });
        self.field.setValue( mids.join(',') );
    },
    add_to_grid : function(rec){
        var self = this;
        var f = self.store.find( 'mid', rec.mid );
        if( f != -1 ) {
            Baseliner.warning( _('Warning'), _('Row already exists: %1', rec.name + '(' + rec.mid + ')' ) );
            return;
        }
        if( !rec.rel_type ) 
            rec.rel_type = self.rel_type || ( self.collection + '_' + rec.collection );
        var r = new self.store.recordType( rec );
        self.store.add( r );
        self.store.commitChanges();
        self.refresh_field();
    }
});

Baseliner.CheckColumn = Ext.extend(Ext.grid.Column, {
    processEvent : function(name, e, grid, rowIndex, colIndex){
        if (name == 'mousedown') {
            var record = grid.store.getAt(rowIndex);
            record.set(this.dataIndex, !record.data[this.dataIndex]);
            return false; // Cancel row selection.
        } else {
            return Ext.grid.ActionColumn.superclass.processEvent.apply(this, arguments);
        }
    },

    renderer : function(v, p, record){
        p.css += ' x-grid3-check-col-td'; 
        return String.format('<div class="x-grid3-check-col{0}">&#160;</div>', v ? '-on' : '');
    },
    init: Ext.emptyFn
});

/*
 * Baseliner.Tree
 *
 * Features:
 *
 *   - context menu from node
 *   - drag and drop ready
 *   - auto topic style rendering (if attributes are set: topic_name.category_color
 *   - paging (TODO)
 *
 */

Baseliner.Tree = Ext.extend( Ext.tree.TreePanel, {
    useArrows: true,
    autoScroll: true,
    animate: true,
    enableDD: true,
    containerScroll: true,
    rootVisible: false,
    constructor: function(c){
        var self = this;
        
        Baseliner.Tree.superclass.constructor.call(this, Ext.apply({
            loader: new Baseliner.TreeLoader({ 
                        dataUrl: c.dataUrl,
                        requestMethod: this.requestMethod, 
                        baseParams: c.baseParams }),
            root: { nodeType: 'async', text: '/', draggable: false, id: '/' }
        }, c) );
        
        self.on('contextmenu', self.menu_click );
        self.on('beforenodedrop', self.drop_handler );
        // auto Topic drawing
        self.on('beforechildrenrendered', function(node){
            node.eachChild(function(n) {
                if(n.attributes.topic_name ) {
                    var tn = n.attributes.topic_name;
                    n.setIconCls('no-icon');  // no icon on this node

                    if( !tn.category_color ) 
                        tn.category_color = '#999';
                    var span = String.format( Baseliner.tree_topic_style, tn.category_color );
                    n.setText( String.format( '{0}<b>{1} #{2}</b>: {3}', span, tn.category_name, tn.mid, n.text ) );
                    n.ui = new Baseliner.TreeMultiTextNode( n );  // DD support for the whole node
                } else if(n.attributes.category_name ) {
                    var tn = n.attributes.category_name;
                    n.setIconCls('no-icon');  // no icon on this node
                    var span = String.format( Baseliner.tree_topic_style, tn.category_color );
                    n.setText( String.format( '{0}<b>{1}</b>', span, tn.category_name ) );
                } else if(n.attributes.category_color ) {
                    // color box and nothing else
                    var span = String.format( Baseliner.tree_topic_style, n.attributes.category_color );
                    n.setIconCls('no-icon');  // no icon on this node
                    n.setText( String.format( '{0}{1}', span, n.text ) );
                    n.ui = new Baseliner.TreeMultiTextNode( n );  // DD support for the whole node
                }
            });
        });
        self.on('dblclick', function(n, ev){     
            if( n.leaf ) 
                self.click_handler({ node: n });
        });
    },
    drop_handler : function(e) {
        var self = this;
        // from node:1 , to_node:2
        e.cancel = true;
        e.dropStatus = true;
        var n1 = e.source.dragData.node;
        var n2 = e.target;
        if( n1 == undefined || n2 == undefined ) return false;
        
        var node_data1 = n1.attributes.data;
        var node_data2 = n2.attributes.data;
        if( node_data1 == undefined ) node_data1={};
        if( node_data2 == undefined ) return false;
        if( node_data2.on_drop != undefined ) {
            var on_drop = node_data2.on_drop;
            if( on_drop.url != undefined ) {
                var p = { tree: self, node1: n1, node2: n2, id_file: node_data1.id_file  };
                if( n2.parentNode && n2.parentNode.attributes.data ) 
                    p.id_project = n2.parentNode.attributes.data.id_project
                        
                Baseliner.ajaxEval( on_drop.url, p, function(res){
                    if( res ) {
                        if( res.success ) {
                            Baseliner.message(  _('Drop'), res.msg );
                            //e.target.appendChild( n1 );
                            //e.target.expand();
                            self.refresh_node( e.target );
                        } else {
                            Baseliner.message( _('Drop'), res.msg );
                            //Ext.Msg.alert( _('Error'), res.msg );
                            return false;
                        }
                    } else {
                        return true;
                    }
                });
            }else{
                if(on_drop.handler != undefined ){
                    eval(on_drop.handler + '(n1, n2);');                
                }
            }
        }
        return true;
    },
    click_handler: function(item){
        var n = item.node;
        var c = n.attributes.data.click;
        var params = n.attributes.data;
        
        if(n.attributes.text == _('Topics')){
            params.id_project = n.parentNode.attributes.data.id_project;
        }
        if( params.tab_icon == undefined ) params.tab_icon = c.icon;

        if( c.type == 'comp' ) {
            if(n.attributes.topic_name) {
                var topic = n.attributes.topic_name;
                var title = Baseliner.topic_title( topic.mid, _(topic.category_name), topic.category_color );
                Baseliner.show_topic( topic.mid, title, { topic_mid: topic.mid, title: title, _parent_grid: undefined } );
            } else if(n.attributes.category_name) {
                var category = n.attributes.category_name;
                var title = Baseliner.category_title( category.category_id, category.category_name, category.category_color );
                Baseliner.show_category( category.category_id, title, { category_id: category.category_id, title: title } );
            }

            else Baseliner.add_tabcomp( c.url, _(c.title), params );
            
        } else if( c.type == 'html' ) {
            Baseliner.add_tab( c.url, _(c.title), params );
        } else if( c.type == 'iframe' ) {
            Baseliner.add_iframe( c.url, _(c.title), params );
        } else {
            Baseliner.message( 'Invalid or missing click.type', '' );
        }
    },
    refresh : function(){
        var self = this;
        var sm = self.getSelectionModel();
        var node = sm.getSelectedNode();
        if( node )
            self.refresh_node( node );
        else 
            self.refresh_all();
    },
    refresh_all : function(){
        var self = this;
        this.loader.load(self.root);
    },
    refresh_node : function(node){
        var self = this;
        if( node != undefined ) {
            var is = node.isExpanded();
            self.loader.load( node );
            if( is ) node.expand();
        }
    }
});

Baseliner.CheckBoxField = Ext.extend( Ext.grid.GridPanel, {
    height: 220,
    hideHeaders : true,
    stripeRows : true,
    initComponent: function(){
        var self = this;
        
        // load checkboxes if value is set
        self.$updating = false;
        if( self.value != undefined && self.store ) {
            self.store.on('load', function(){
                self.setValue( self.value );
            });
        } else {
            self.value = [];
        }
    
        // setup form field
        self.field = new Ext.form.Hidden({ name: self.name, value: self.value });
        self.ps = 100;
        self.tbar = self.tbar || new Ext.Toolbar({});
        self.search = new Baseliner.SearchField({
                    store: self.store, params: {start: 0, limit: self.ps}
                });
        self.tbar.insert( 0, self.search );
        self.tbar.add( self.field );
        
        self.viewConfig = Ext.apply({
            headersDisabled: true,
            enableRowBody: true,
            forceFit: true
        }, self.viewConfig );
        self.sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        self.sm.on('selectionchange', function(grid,ix){
            self.refresh_field();
        });
        
        var columns = [ self.sm ];
        Ext.each( self.columns, function(col){
            columns.push( col );
        });
        self.columns = columns;
        Baseliner.CheckBoxField.superclass.initComponent.call( this );
    },
    getValue : function(){
        return self.field.getValue();
    },
    setValue : function(v){
        var self = this;
        var arr;
        if( Ext.isArray( v ) ) {
            arr = v;
        } else {
            v = '' + v;
            arr = v.split(',');
        }
        var recs = [];
        Ext.each( arr, function(id){
            // check each one
            var r = self.getStore().getById( id );
            //alert( r );
            recs.push( r );
        });
        self.$updating = true;
        self.getSelectionModel().selectRecords( recs );
        self.$updating = false;
        self.value = arr;
        self.refresh_field();
        return self.field.getValue();
    },
    refresh_field: function(){
        var self = this;
        if( self.$updating ) return;
        var ids = [];
        self.getSelectionModel().each( function(r){
            ids.push( r.data.id ); 
        });
        var value = ids.join(',');
        self.field.setValue( value );
        //self.fireEvent('change', this, ids, value);
    }
});

Baseliner.CICheckBox = Ext.extend( Baseliner.CheckBoxField, {
    height: 220,
    hideHeaders: false,
    disabled: false,
    initComponent: function(){
        var self = this;
        self.store = new Baseliner.store.CI({ 
            baseParams: Ext.apply({ pretty: true }, self.ci )
        });
        
        self.columns = [
          { width: 40, dataIndex: 'icon', renderer: Baseliner.render_icon },
          { width: 40, dataIndex: 'mid', header: _('ID') },
          { header: _('Name'), width: 240, dataIndex: 'name', renderer: Baseliner.render_ci },
          { header: _('Class'), width: 120, dataIndex: 'class' },
          //{ header: _('Collection'), width: 120, dataIndex: 'collection' },
          { header: _('Properties'), width: 240, dataIndex: 'pretty_properties' },
          { header: _('Version'), width: 80, dataIndex: 'versionid' }
        ];
        Baseliner.CICheckBox.superclass.initComponent.call( this );
    }
});

Baseliner.FormPanel = Ext.extend( Ext.FormPanel, {
    labelAlign: 'right',
    is_valid : function(){
        var self = this;
        var form2 = this.getForm();
        var is_valid = form2.isValid();
		var first_novalid_top = -1;
		Ext.getCmp('main-panel').getActiveTab().body.dom.scrollTop = 0;
		this.cascade(function(obj){
			var sty = 'border: solid 1px rgb(255,120,112); margin_bottom: 0px';
			//console.dir(obj.name, obj.allowBlank, obj.is_valid);
			//if( obj.name && !obj.allowBlank && obj.is_valid ) {
			if( obj.name && !obj.allowBlank ) {
				if (obj.is_valid) {
					if( !obj.is_valid() ) {
						is_valid = false;
						var id_objHTML = obj.getEl().dom.id;
						var objHTML = $('#' + id_objHTML);
						var offset = objHTML.offset();
						if(first_novalid_top == -1) first_novalid_top = offset.top - obj.getEl().dom.offsetHeight;
						obj.getEl().applyStyles(sty);
						if( !obj.on_change_lab ) {
							var lab = Ext.DomHelper.insertAfter(obj.getEl(),{id: 'lbl_required_'+obj.name, html:'<div class="x-form-invalid-msg">'+_('This field is required')+'</div>'});
							obj.on_change_lab = lab;
							obj.on('change', function(){
								if( obj.is_valid() ) {
									obj.getEl().applyStyles('border: none; margin_bottom: 0px');
									obj.on_change_lab.style.display = 'none';
								} else {
									obj.getEl().applyStyles(sty);
									obj.on_change_lab.style.display = 'block';
									
								}
							});
						}
					}
				}
				else{
					if(obj.validate && typeof obj.validate == 'function'){
						if(!obj.validate()){
							var id_objHTML = obj.getEl().dom.id;
							var objHTML = $('#' + id_objHTML);
							var offset = objHTML.offset();
							if(first_novalid_top == -1) first_novalid_top = offset.top - 125;
						}
					}
				}
			}
		});
		Ext.getCmp('main-panel').getActiveTab().body.dom.scrollTop = first_novalid_top;	
        return is_valid;
    },
    getValues : function(a,b,c){
        var form2 = this.getForm();
        var form_data = form2.getValues() || {};
        this.cascade(function(obj){
            if( obj.name && obj.get_save_data ) {
                form_data[ obj.name ] = obj.get_save_data();
            }
        });
        for( var k in form_data ) {
            if( k.indexOf('ext-comp-')==0 ) delete form_data[k];
        }
        return form_data;
    }
});

Baseliner.FormEditor = Ext.extend( Baseliner.FormPanel, {
    frame: false, forceFit: true, 
    defaults: { msgTarget: 'under', anchor:'100%' },
    width: 800, height: 600,
    autoScroll: true,
    bodyStyle: { padding: '4px', "background-color": '#eee' },
    initComponent : function(){
        var self = this;
        var data = this.data || {};
        //var de = new Baseliner.DataEditor({ data: data, hide_cancel: true, hide_save: true });
        //this.items = [ ];
        Baseliner.FormEditor.superclass.initComponent.call(this);
        Baseliner.ajaxEval( self.form_url, data, function(comp){
            self.add( comp );
            self.doLayout();
        }, function(res){
            Baseliner.error( _('Form Editor'), _('Could not find form `%1`', self.form) );
        });
    },
    getData : function(){
        return this.getValues();
    }
});

Baseliner.run_service = function(params, service){
    var mask = { xtype:'panel', items: Baseliner.loading_panel(), flex: 1 };
    //var initial_data = Ext.apply( { timeout:0 }, service, params );
    var initial_data = { service: service, data: service.data };
    var deditor = service.form 
        ? new Baseliner.FormEditor({ data: initial_data, form_url: service.form })
        : new Baseliner.DataEditor({ data: initial_data, hide_cancel:true, hide_save:true });
    var btn_run = new Ext.Button({ icon:'/static/images/icons/run.png', text:_('Run'), handler: function(){ 
            btn_run.disable();
            if(!params) params = {};
            var run_data = Ext.apply({ key: service.key, _merge_with_params: 1, as_json: true }, params);
            run_it( Ext.apply(run_data, { data: deditor.getData() }) );
            win.removeAll();
            win.add( mask );
            win.doLayout();
        } })
    var run_it = function(data){
        Baseliner.ajax_json( '/ci/service_run', data, function(res){
            btn_run.enable();
            win.removeAll();
            var tabp = new Ext.TabPanel({ activeTab: res.msg ? 0 : 1 });
            win.add( tabp );
            if( !res.success ) {
                tabp.add(new Baseliner.MonoTextArea({ title: 'Message', value: res.msg, style:'color:#f23' }) );
                tabp.add(new Baseliner.MonoTextArea({ title: 'Console', value: res.console, style:'color:#f23' }) );
                tabp.add(new Baseliner.MonoTextArea({ title: 'Log', value: res.log }) );
            } else {
                if( res.js_output ) {
                    Baseliner.ajaxEval( res.js_output, { data: res.data }, function(comp){
                        comp.title = _('Data');
                        tabp.insert(0, comp );
                        tabp.doLayout();
                        win.doLayout();
                        tabp.setActiveTab( comp );
                    });
                } else {
                    tabp.add(new Baseliner.MonoTextArea({ title: 'Data', value: res.data }) );
                }
                tabp.add(new Baseliner.MonoTextArea({ title: 'Console', value: res.console }) );
                tabp.add(new Baseliner.MonoTextArea({ title: 'Return', value: res.ret }) );
            }
            win.doLayout();
        });
    };
    var tbar = [ btn_run ];
    var win = new Baseliner.Window({ width: 800, tbar: tbar, height: 400, layout:'fit', items:[ deditor ], title: service.name });
    win.show();
}

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
// rgo: heredoc quote fix
Baseliner.HEREDOC_SLICE_START = Ext.isSafari ? 15 : Ext.isIE ? 13 : 14;
Baseliner.HEREDOC_SLICE_END   = Ext.isSafari ? -4 : -3;
Function.prototype.heredoc = function(s){ return this.toString().slice(Baseliner.HEREDOC_SLICE_START,Baseliner.HEREDOC_SLICE_END) };
Function.prototype.tmpl = function(data){ return Baseliner.tmpl(this.heredoc(),data) };
String.prototype.tmpl = function(data){ return Baseliner.tmpl(this+"",data) };
Baseliner.tmpl_cache = {};
Baseliner.tmpl = function (str, data){
    // Figure out if we're getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var st = Baseliner.HEREDOC_SLICE_START;
    var en = Baseliner.HEREDOC_SLICE_END;
    var he = ['function(){/*', '*/}.toString().slice('+st+','+en+')']; 
    var fn = !/\W/.test(str) ?
      Baseliner.tmpl_cache[str] = Baseliner.tmpl_cache[str] ||
        Baseliner.tmpl(document.getElementById(str).innerHTML) :
     
      // Generate a reusable function that will serve as a template
      // generator (and which will be cached).
     new Function("obj",
        "var p=[],print=function(){p.push.apply(p,arguments);};" +

        // Introduce the data as local variables using with(){}
        "with(obj){p.push("+he[0]+

        // Convert the template into pure JavaScript
         str
          .replace(/[\r\t\n]/g, " ")    
          .split("[%").join("\t")
          .replace(/((^|%\])[^\t]*)/g, "$1\r")
          .replace(/\t=(.*?)%\]/g, he[1]+",$1,"+he[0])
          .split("\t").join(he[1]+");")
          .split("%]").join("p.push("+he[0])
          .split("\r").join("")
      + he[1]+");}return p.join('');");

    // Provide some basic currying to the user
    return data ? fn( data ) : fn;
};

Baseliner.Pills = Ext.extend(Ext.form.Field, {
    //shouldLayout: true,
    value: '',
    initComponent : function(){
        Baseliner.Pills.superclass.initComponent.apply(this, arguments);
    },
    defaultAutoCreate : {tag: 'div', 'class':'', style:'margin-top: 0px; height: 30px;' },
    onRender : function(){
        Baseliner.Pills.superclass.onRender.apply(this, arguments);
        this.list = [];
        var self = this;
        self.anchors = [];
        if( this.options != undefined ) {
            var opts = Ext.isArray( this.options ) ? this.options : this.options.split(';');
            Ext.each(opts, function(opt){
                var vv = opt.split(',');
                var v = vv[0];
                var bg = vv[1] ;
                var li = document.createElement('li');
                li.className = self.value == v ? 'active' : '';
                li.style['marginTop'] = '0px';
                var anchor = document.createElement('a');
                if( bg && self.value == v ) anchor.style['backgroundColor'] = bg;
                anchor.href = '#'; 
                anchor.onclick = function(){ 
                    for( var i=0; i<self.list.length; i++) {
                        self.list[i].className = '';
                    }
                    for( var i=0; i<self.anchors.length; i++) {
                        self.anchors[i].style['backgroundColor'] = '';
                    }
                    li.className = 'active'; 
                    if( bg ) anchor.style['backgroundColor'] = bg;
                    self.value = v;
                    self.$field.value = v;
                    return false;
                }
                anchor.innerHTML = v;
                anchor.style['marginTop'] = '0px';
                anchor.style['lineHeight'] = '6px';
                //anchor.style['fontWeight'] = 'bold';
                li.appendChild( anchor );
                self.list.push( li );
                self.anchors.push( anchor );
            });
        }
        
        // a boot, for styling 
        var boot = document.createElement('span');
        boot.id = 'boot';
        this.el.dom.appendChild( boot );

        // the main navbar
        var ul = document.createElement('ul');
        ul.className = "nav nav-pills";
        for( var i=0; i<self.list.length; i++) ul.appendChild( self.list[i] );
        boot.appendChild( ul );
        
        // the hidden field
        self.$field = document.createElement('input');
        self.$field.type = 'hidden';
        self.$field.value = self.value;
        self.$field.name = self.name;
        this.el.dom.appendChild( self.$field );
    },
    // private
    redraw : function(){ 
    },
    initEvents : function(){
        this.originalValue = this.getValue();
    },
    // These are all private overrides
    getValue: function(){
        return this.value || '';
    },
    setValue: function( v ){
        this.value = v || '';
        this.redraw();
    },
    setSize : Ext.emptyFn,
    setWidth : Ext.emptyFn,
    setHeight : Ext.emptyFn,
    setPosition : Ext.emptyFn,
    setPagePosition : Ext.emptyFn,
    markInvalid : Ext.emptyFn,
    clearInvalid : Ext.emptyFn
});

Baseliner.MonoTextArea = Ext.extend( Ext.form.TextArea, {
    style: 'font-size: 13px; font-family: Consolas, Courier New, monotype'
});

Baseliner.ComboSingle = Ext.extend( Ext.form.ComboBox, {
    name: 'item',
    mode: 'local',
    triggerAction: 'all',
    editable: false,
    anchor: '100%',
    forceSelection: true,
    allowBlank: false,
    selectOnFocus: false,
    initComponent: function(){
        var self = this;
        var data = [];
        if( self.data ) {
            Ext.each( self.data, function(v){
                data.push( [v] );
            });
        }
        self.store = self.buildStore(data);

        self.fieldLabel = self.fieldLabel || self.name;
        self.valueField = self.field || self.name;
        self.displayField = self.displayField || self.field || self.name;
        if( !self.value ) self.value = data.length>0 ? data[0][0] : null;
        
        Baseliner.ComboSingle.superclass.initComponent.call(this); 
    },
    buildStore : function(data){
        var self = this;
        return new Ext.data.SimpleStore({
            fields: [ self.name ],
            data : data 
        });  
    }
});

Baseliner.ComboSingleRemote = Ext.extend( Baseliner.ComboSingle, {
    mode: 'remote',
    buildStore : function(){
        return new Ext.data.JsonStore({
            root: this.root || 'data', 
            remoteSort: true,
            totalProperty: this.totalProperty || 'totalCount', 
            id: 'id', 
            baseParams: Ext.apply({  start: 0, limit: this.ps || 99999999 }, this.baseParams ),
            url: this.url,
            fields: this.fields || [ this.name ]
        });  
    }
});

Baseliner.ComboDouble = Ext.extend( Ext.form.ComboBox, {
    name: 'item',
    mode: 'local',
    triggerAction: 'all',
    editable: false,
    anchor: '100%',
    forceSelection: true,
    allowBlank: false,
    selectOnFocus: false,
    initComponent: function(){
        var self = this;
        var data = [];
        if( self.data ) {
            Ext.each( self.data, function(v){
                data.push(v);
            });
        }
        self.store = self.buildStore(data);

        self.fieldLabel = self.fieldLabel || self.name;
        self.valueField = self.field || self.name;
        self.displayField = self.displayField || self.field || 'display_name';
        self.hiddenField = self.name;
        if( !self.value ) self.value = data.length>0 ? data[0][0] : null;
        
        Baseliner.ComboDouble.superclass.initComponent.call(this); 
    },
    get_save_data : function(){  // otherwise, getForm().getValues() returns the displayField
        return this.getValue();
    },
    buildStore : function(data){
        var self = this;
        return new Ext.data.SimpleStore({
            fields: [ self.name, 'display_name' ],
            data : data 
        });  
    }
});

Baseliner.ComboDoubleRemote = Ext.extend( Baseliner.ComboDouble, {
    mode: 'remote',
    initComponent: function(){
        var self = this;
        var value = self.value;
        delete self.value;
        Baseliner.ComboDoubleRemote.superclass.initComponent.call(this); 
        self.store.on('load', function(){
            if( value != undefined ) {
                var ix = self.store.find( self.valueField, value ); 
                if( ix > -1 ) self.setValue(self.store.getAt(ix).get( self.valueField ));
            } else {
                self.setValue(self.store.getAt(0).get( self.valueField ));
            }
        })
    },
    buildStore : function(){
        return new Ext.data.JsonStore({
            root: this.root || 'data', 
            remoteSort: true,
            autoLoad: true,
            totalProperty: this.totalProperty || 'totalCount', 
            id: 'id', 
            baseParams: Ext.apply({  start: 0, limit: this.ps || 99999999 }, this.baseParams ),
            url: this.url,
            fields: this.fields || [ self.name, 'display_name' ]
        });  
    }
});

// a hidden field that updates the store for a grid, used in list_topics
Baseliner.HiddenGridField = Ext.extend( Ext.form.Hidden, {
    setValue : function(v) {
        //if( loading_field ) return; // control so that we don't go into an infinite loop
        Baseliner.HiddenGridField.superclass.setValue.call(this, v);
        if( !Ext.isString( v ) ) return;
        var nv = Ext.decode( v );
        this.store.removeAll();
        this.store.loadData( nv );
    }
});

Baseliner.field_label_top = function( label, hidden, allowBlank, readOnly ) {

    return [
        {
          xtype: 'label',
          //autoEl: {cn: style_label},
          fieldLabel: _(label),
          hidden: hidden!=undefined ? hidden : false,
          allowBlank: allowBlank,
          readOnly: readOnly == undefined ? false: readOnly
        }/*,
        {
          xtype: 'box',
          autoEl: {cn: '<br>'},
          hidden: hidden!=undefined ? hidden : false
        }*/
    ]
};

Baseliner.render_date = function(v){
    var d;
    if( !v ) return '';
    try { d=new Date(v) } catch(ee){}
    return Ext.isDate(d) ? d.format( Prefs.js_date_format ) : v;
};
Baseliner.render_checkbox = function(v){
    return v 
        ? '<img src="/static/images/icons/checkbox.png">'
        : '<img src="/static/images/icons/delete.gif">';
};
        
Baseliner.cols_templates = {
      id : function(){ return {width: 10 } },
      index : function(){ return {width: 10, renderer:function(v,m,r,i){return i+1} } },
      htmleditor: function(){ return { editor: new Ext.form.HtmlEditor({submitValue: false}), default_value:'' } },
      cleditor: function(){ return { editor: new Baseliner.CLEditorField({submitValue: false}), default_value:'' } },
      textfield : function(){ return { width: 100, editor: new Ext.form.TextField({submitValue: false}), default_value:'' } },
      datefield : function(){ return { width: 30, 
          editor: new Ext.form.DateField({ format: Prefs.js_date_format, submitValue: false }), 
          renderer: Baseliner.render_date
      }},
      checkbox  : function(){ return { align: 'center', width: 10, editor: new Ext.form.Checkbox({submitValue: false}), default_value: false, renderer: Baseliner.render_checkbox } },
      ci_box    : function(p){ return { editor: Baseliner.ci_box( p || {} ), default_value:'' } },
      password  : function(){ return { editor: new Ext.form.TextField({submitValue: false, inputType:'password' }), default_value:'', renderer: function(v){ return '********' } } },
      textarea  : function(){ return { editor: new Ext.form.TextArea({submitValue: false}), default_value:'', renderer: Baseliner.render_wrap } }
};


Baseliner.CSV = Ext.extend( Ext.util.Observable, {
    /*
     * Andy VanWagoner (http://stackoverflow.com/questions/1293147/javascript-code-to-parse-csv-data)
     */
    parse: function(csv, reviver) {
        reviver = reviver || function(r, c, v) { return v; };
        var chars = csv.split(''), c = 0, cc = chars.length, start, end, table = [], row;
        while (c < cc) {
                table.push(row = []);
                while (c < cc && '\r' !== chars[c] && '\n' !== chars[c]) {
                        start = end = c;
                        if ('"' === chars[c]){
                                start = end = ++c;
                                while (c < cc) {
                                        if ('"' === chars[c]) {
                                                if ('"' !== chars[c+1]) { break; }
                                                else { chars[++c] = ''; } // unescape ""
                                        }
                                        end = ++c;
                                }
                                if ('"' === chars[c]) { ++c; }
                                while (c < cc && '\r' !== chars[c] && '\n' !== chars[c] && ',' !== chars[c]) { ++c; }
                        } else {
                                while (c < cc && '\r' !== chars[c] && '\n' !== chars[c] && ',' !== chars[c]) { end = ++c; }
                        }
                        end = reviver(table.length-1, row.length, chars.slice(start, end).join(''));
                        row.push(isNaN(end) ? end : +end);
                        if (',' === chars[c]) { ++c; }
                }
                if ('\r' === chars[c]) { ++c; }
                if ('\n' === chars[c]) { ++c; }
        }
        return table;
    },
    constructor: function(config){
        Ext.apply(this, config);
        Baseliner.CSV.superclass.constructor.call(this);
    },
    stringify: function(table, replacer) {
        replacer = replacer || function(r, c, v) { return v; };
        var csv = '', c, cc, r, rr = table.length, cell;
        for (r = 0; r < rr; ++r) {
                if (r) { csv += '\r\n'; }
                for (c = 0, cc = table[r].length; c < cc; ++c) {
                        if (c) { csv += ','; }
                        cell = replacer(r, c, table[r][c]);
                        if (/[,\r\n"]/.test(cell)) { cell = '"' + cell.replace(/"/g, '""') + '"'; }
                        csv += (cell || 0 === cell) ? cell : '';
                }
        }
        return csv;
    },
    load: function(csv, replace){
        var self = this;
        var tab = self.parse( csv ); 
        // load data into a store ? 
        if( self.store ) {
            if( replace ) {
                self.store.removeAll();
            }
            Ext.each( tab, function(row) {
                var i=0;
                var rec={};
                self.store.fields.each(function(field){
                    var v = row[i++];
                    rec[ field.name ] = v==undefined ? '' : v;
                });
                var r = new self.store.recordType( rec );
                self.store.add( r );
            });
            self.store.commitChanges();
        }
        return tab;
    },
    show: function(){
        var self = this;
        var csv = self.stringify( self.value || '' );
        var ta = new Baseliner.MonoTextArea({ value: csv || '' });
        var button_load = new Baseliner.Grid.Buttons.Add({ text: _('Add Rows'),
            handler: function() { self.load(ta.getValue()) }
        });
        var button_replace = new Ext.Button({ text: _('Replace'), icon:'/static/images/icons/edit.png', 
            handler: function() { self.load(ta.getValue(), true) }
        });
        var button_close = new Ext.Button({ text: '', tooltip: _('Close'), icon:'/static/images/icons/close.png', 
            handler: function() { win.close() }
        });
        var win = new Baseliner.Window({
            modal: true,
            layout: 'fit',
            tbar:[ '->', button_load, button_replace, button_close ],
            width: 800, height: 300,
            items: ta 
        });
        win.show();
    }
});

Baseliner.GridEditor = Ext.extend( Ext.grid.GridPanel, {
    width: '100%',
    height: 250,
    enableDragDrop: true,
    use_row_editor: true,
    initComponent: function(){
        var self = this;
        self.viewConfig = Ext.apply({
            forceFit: true
        }, self.viewConfig );
        
        self.sm = new Baseliner.RowSelectionModel({ singleSelect: true }); 
        //var sm = new Baseliner.CheckboxSelectionModel({ checkOnly: true, singleSelect: false });
        
        var cols, fields;
        
        if( self.columns != undefined ) {
            cols=[]; fields=[];
            var cc = Ext.isArray( self.columns ) ? self.columns : self.columns.split(';');
            Ext.each( cc, function(col){
                var ct;
                var store_field = {};
                if( Ext.isObject( col ) ) {
                    ct = col;
                } else {
                    // Header[dataIndex],Type,Width,DefaultValue
                    var col_s = col.split(',');
                    if( col_s[0] == undefined ) return;
                    ct = Baseliner.cols_templates[ col_s[1] ] || Baseliner.cols_templates['textarea'];
					//console.dir(ct);
                    ct = ct();  // templates are functions
                    if( col_s[2] != undefined ) ct.width = col_s[2];
                    if( col_s[3] ) ct.default_value = col_s[3];
                    ct.sortable = true;
                    // now test for Header[dataIndex]
                    var name_and_id = col_s[0].match(/^([^\[]+)\[([^\]]+)\]/);
                    if( name_and_id ) {
                        ct.header = _(name_and_id[1]);
                        ct.dataIndex = name_and_id[2];
                    } else {
                        ct.header = _(col_s[0]);
                        ct.dataIndex = Baseliner.name_to_id( col_s[0] );
                    }
                    ct.meta_col = col_s[1];
                }
                store_field.name = ct.dataIndex;
                if( ct.meta_col == 'datefield' )  {
                    store_field.type =  'date';
                    store_field.dateFormat = 'Y-m-d 00:00:00';
                }
                cols.push( ct );
                fields.push( store_field );
            });
        } else {
            cols = [
              {dataIndex: 'description', header: _('Description'), width: 100, editor: new Ext.form.TextArea({}) }
            ];
            fields = [
                {name: 'description'}
            ];
        }
        
        // default record for adding
        if( !Ext.isObject(self.default_record) ) {
            var rec_default = {}; 
            Ext.each( cols, function(col){
                rec_default[ col.dataIndex ] = Ext.isFunction(col.default_value) 
                    ? col.default_value() 
                    : col.default_value!=undefined 
                        ? col.default_value 
                        : '';
            });
            self.default_record = rec_default;
        } 

        var reader = new Ext.data.JsonReader({
            totalProperty: 'total',
            successProperty: 'success',
            idProperty: 'id',
            fields: fields
        });
       
        // records is JSON?
        if( Ext.isString( self.records ) ) {
            self.records = Ext.decode( self.records );
        } 
        // now recheck
        if( !Ext.isArray(self.records) ) {
            self.records = [];
        }
        
        self.store = new Ext.data.Store({
            reader: reader,
            data: self.records 
        });
		
        self.store.on('add', function(){ self.fireEvent( 'change', self ) });
        self.store.on('remove', function(){ self.fireEvent( 'change', self ) });
            
        var button_add = new Baseliner.Grid.Buttons.Add({
            text:'',
            tooltip: _('Create'),
            disabled: self.readOnly ? self.readOnly : false,
            handler: function() { self.add_row() }
        });
        
        var button_delete = new Baseliner.Grid.Buttons.Delete({
            text: '',
            tooltip: _('Delete'),
            cls: 'x-btn-icon',  
            disabled: self.readOnly ? self.readOnly : false,
            handler: function() { self.del_row() }
        });
        
        var button_load = new Ext.Button({
            text: '',
            tooltip: _('Load'),
            icon: '/static/images/icons/csv.png',
            disabled: self.readOnly ? self.readOnly : false,
            handler: function() { self.show_load_csv() }
        });
        
        // use RowEditor for editing
        if( self.use_row_editor ) {
            self.editor = new Ext.ux.grid.RowEditor({
                clicksToMoveEditor: 1,
                autoCancel: false,
                enableDragDrop: true, 
                listeners: {
                    afteredit: function(roweditor, changes, record, rowIndex){
                        // after editing a row, serialize data to hidden field
                        self.store.commitChanges();
                        delete record.data.id;
                    }
                }       
            }); 
            self.plugins = [ self.editor ];
        }
        
        self.columns = cols;
		self.fields = fields;
        self.ddGroup = 'grid_editor_' + Ext.id();
        self.tbar = [
            button_add,
            '-',
            button_delete,
            '-',
            button_load
        ];

        Baseliner.GridEditor.superclass.initComponent.call(this);

        self.on( 'afterrender', function(){
            //self.ddGroup = 'bali-grid-html-' + self.id;
            var ddrow = new Baseliner.DropTarget(self.container, {
                comp: self,
                ddGroup : self.ddGroup,
                copy: false,
                notifyDrop : function(dd, e, data){
                    var ds = self.store;
                    var sm = self.getSelectionModel();
                    var rows_grid = sm.getSelections();
                    if(dd.getDragData(e)) {
                        var rows = self.get_save_data();
                        var cindex=dd.getDragData(e).rowIndex;
                        if(typeof(cindex) != "undefined") {
                            for(i = 0; i <  rows_grid.length; i++) {
                                var index = ds.indexOf(ds.getById(rows_grid[i].id));
                                ds.remove(ds.getById(rows_grid[i].id));
                                delete rows[index];
                            }
                            ds.insert(cindex,data.selections);
                            sm.clearSelections();
                        }
                        ds.commitChanges();
                        self.getView().refresh();   
                    }
                }
            }); 
        });
    },
    add_row : function(){
        var self = this;
        var u = new self.store.recordType( Ext.decode(Ext.encode(self.default_record)) );
        var index = self.store.getCount();
        if( self.editor ) self.editor.stopEditing();
        self.store.insert(index, u);
        self.getSelectionModel().selectRow(index);          
        if( self.editor ) self.editor.startEditing(index);
    },
    del_row : function(){
        var self = this;
        var sm = self.getSelectionModel();
        Ext.each( sm.getSelections(), function(r) {
            var index = self.store.indexOf(r);
            self.store.remove( r );
            var rows = self.get_save_data();
            rows.splice(index, 1);
            self.store.commitChanges();
            self.getView().refresh();
        });
    },
    show_load_csv : function(){
        var self = this;
        var csv = new Baseliner.CSV({ store: self.store, value: self.get_array_in_array() });
        csv.show();
    },
    get_array_in_array : function(){
        var self = this;
        var arr = [];
        self.store.each( function(r) {
			if(r.data[self.fields[0].name] != '') {
                var arr2 = [];
                Ext.iterate( r.data, function(k,v){
                    arr2.push( v );
                });
                arr.push( arr2 );
            }
        });
        return arr;
    },
    get_save_data : function(){
        var self = this;
        var arr = [];
        self.store.each( function(r) {
			if(r.data[self.fields[0].name] != '') arr.push( r.data );
        });
        return arr;
    }, 
    is_valid : function(){
        var self = this;
        var cont = 0;
        self.store.each( function(r) {
			if(r.data[self.fields[0].name] != '') cont++;
        });
        return cont > 0 ;
    }
});

Baseliner.encode_tree = function( root ){
    var arr = [];
    root.eachChild( function(n){
        var d = Ext.apply({}, n.attributes);
        d.leaf = n.isLeaf();
        d.expanded = n.isExpanded();
        delete d.loader;
        delete d.id;
        Ext.apply(d, { children: Baseliner.encode_tree( n ) });
        arr.push(d);
    });
    return arr;
};


Baseliner.timeline = function(args){ 
    var mid = args.mid;
    var render_to = args.render_to; 
    var parent_id = args.parent_id;  // optional
    
    require(['/static/timeline/jquery.timeline.js'], function(){
        Timeline.urlPrefix = '/static/timeline/';
        Baseliner.ajaxEval( '/ci/'+mid+'/timeline', { mid: mid }, function(res){
            if( ! 'Timeline' in window ) return;
            var data = { "events": res.events };
            var max_same_date = res.max_same_date;
            var height = max_same_date <= 8 ? 400 : 400+( max_same_date*30);
            var eventSource = new Timeline.DefaultEventSource();
            var bandInfos = [
                /*
                Timeline.createBandInfo({
                    eventSource:    eventSource,
                    //date:           "Jun 28 2006 00:00:00 GMT",
                    width:          "60%", 
                    intervalUnit:   Timeline.DateTime.HOUR, 
                    intervalPixels: 100
                }),
                */
                Timeline.createBandInfo({
                    eventSource:    eventSource,
                    //date:           "Jun 28 2006 00:00:00 GMT",
                    width:          "90%", 
                    intervalUnit:   Timeline.DateTime.DAY, 
                    intervalPixels: 50
                })
                ,Timeline.createBandInfo({
                    overview:       true,
                    eventSource:    eventSource,
                    //date:           "Jun 28 2006 00:00:00 GMT",
                    width:          "10%", 
                    intervalUnit:   Timeline.DateTime.MONTH, 
                    intervalPixels: 200
                })
            ];
            bandInfos[1].syncWith = 0;
            bandInfos[1].highlight = true;

            var el = document.getElementById(render_to);
            $(el).height( height );
            $(el).width( $('#'+parent_id).width() - 80 );  // set my width to the topicmain panel width 

            tl = Timeline.create(el, bandInfos);
            eventSource.loadJSON(data, document.location.href);

            var resizeTimerID = null;

            var parent_comp = Ext.getCmp( parent_id );
            if( parent_comp && parent_comp.body ) 
                $(parent_comp.body.dom).animate({ scrollTop: $('#'+parent_id).height() + 3000 }, "slow");

            function xonResize() {
                if (resizeTimerID == null) {
                    resizeTimerID = window.setTimeout(function() {
                        resizeTimerID = null;
                        tl.layout();
                    }, 500);
                }
            }
        }); // ajaxeval
    });  // require
};

// checkbox with 1 and 0 in a hidden field
//    new Baseliner.CBox({ fieldLabel: _('Really?'), name: 'really', checked: params.rec.really, default_value: true }),
Baseliner.CBox = Ext.extend( Ext.form.Checkbox, {
    submitValue: false,
    default_value: false,
    initComponent: function(){
        var self = this;
        var value = self.checked;
        if( value === undefined )  {
            value= self.default_value;
            self.checked = value;
        }
        this.on('afterrender', function(){
            self.hidden_field = this.wrap.createChild({tag: 'input', type:'hidden', name: self.name, value: value ? 1 : 0 }, this.el);
        });
        this.on('check', function(obj,checked) {
            if( self.hidden_field ) self.hidden_field.dom.value = checked ? 1 : 0;
        });
        Baseliner.CBox.superclass.initComponent.call(this);
    }
});


Ext.apply(Ext.layout.FormLayout.prototype, {
    originalRenderItem: Ext.layout.FormLayout.prototype.originalRenderItem || Ext.layout.FormLayout.prototype.renderItem,
    renderItem: function(c, position, target){
        if ( c.fieldLabel != undefined ) {
		    //c.fieldLabel = "(SF: "+ c.system_force + ", LA: " + c.labelAlign + ", RO:" + c.readOnly + ",DIS:" + c.disabled + ",AB:" + c.allowBlank + "= " + readonly + ") " + c.fieldLabel;
            //if ( c.labelAlign != undefined && c.labelAlign == 'top') {
			if ( c.origin == 'custom') {
                c.labelSeparator = '';
                var readonly = c.readOnly !=undefined ? c.readOnly:true;
                readonly = readonly || c.disabled;
                
                if ( !c.system_force) c.disabled = readonly;

                if (c && !c.rendered &&  c.fieldLabel && !c.allowBlank && c.allowBlank != undefined && !readonly ) {
                    c.fieldLabel = c.fieldLabel + " <span " +
                    ((c.requiredFieldCls !== undefined) ? 'class="' + c.requiredFieldCls + '"' : 'style="color:red;"') +
                    " ext:qtip=\"" +
                    ((c.blankText !== undefined) ? c.blankText : "This field is required") +
                    "\">*</span>";
                }
                if ( readonly && c.fieldLabel != undefined ) {
                    c.fieldLabel = "<span style='color:#AAAAAA'>" + c.fieldLabel + "</span>";
                }
            }
        }
        this.originalRenderItem.apply(this, arguments);
    }
});

 
/* 
 *  new Baseliner.UploadFilesPanel({
 *      allowBlank  : meta.allowBlank,
 *      readonly    : meta.readonly,
 *      id_field    : meta.id_field,
 *      name_field  : meta.name_field,
 *      [ form : <FormPanel> | mid: <Num> ] 
 *  });
 */
Baseliner.UploadFilesPanel = Ext.extend( Ext.Panel, {
    border: false,
    layout: 'form',
    style: 'margin-top: 10px', 
    id_field: 'upload_files_panel',
    url_delete : '/topic/file/delete', 
    url_list : '/topic/file_tree',
    url_download : '/topic/download_file',
    url_upload : '/topic/upload',
    get_mid : function(){ // the form may not have a mid in the beginning, but later it does, so this is dynamic
        var self = this;
        if( self.mid ) return self.mid;
        if( !self.mid && self.form ) {
            var ff;
            ff = self.form.getForm();
            var mid_field = ff.findField("topic_mid");
            var mid = mid_field ? mid_field.getValue() : null;
            if( !mid ) {
                return null;
            } else {
                self.mid = mid;
                return self.mid;
            }
        } else {
            return null;
        }
    },
    initComponent : function(){
        var self = this;
        var form = self.form;
        //self.disabled = self.readonly;
        //if( !self.name ) self.name_field = self.fieldLabel;
        
        var check_sm = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });
        
        var record = Ext.data.Record.create([
            {name: 'filename'},
            {name: 'versionid'},
            {name: 'filesize'},     
            {name: 'size'},     
            {name: 'md5'},     
            {name: '_id', type: 'int'},
            {name: '_parent', type: 'auto'},
            {name: '_level', type: 'int'},
            {name: '_is_leaf', type: 'bool'}
        ]);     
        
        self.store_file = new Ext.ux.maximgb.tg.AdjacencyListStore({  
           autoLoad : true,  
           url: self.url_list, 
           baseParams: { topic_mid: self.get_mid() == -1 ? '' : self.get_mid(), filter: self.id_field },
           reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, record )
        });
        
        self.store_file.on('load', function(){ self.fireEvent( 'change', self ) });
        //self.store_file.on('remove', function(){ self.fireEvent( 'change', self ) });
		
        var render_file = function(value,metadata,rec,rowIndex,colIndex,store) {
            var md5 = rec.data.md5;
            if( md5 != undefined ) {
                value = String.format('<a target="FrameDownload" href="{2}/{1}">{0}</a>', value, md5, self.url_download );
            }
            value = '<div style="height: 20px; font-family: Consolas, Courier New, monospace; font-size: 12px; font-weight: bold; vertical-align: middle;">' 
                //+ '<input type="checkbox" class="ux-maximgb-tg-mastercol-cb" ext:record-id="' + record.id +  '"/>&nbsp;'
                + value 
                + '</div>';
            return value;
        };

        var file_del = function(){
            var sels = checked_selections();
            if ( sels != undefined ) {
                var sel = check_sm.getSelected();
                Baseliner.confirm( _('Are you sure you want to delete these artifacts?'), function(){
                    var sels = checked_selections();
                    Baseliner.ajaxEval( self.url_delete, { md5 : sels.md5, topic_mid: self.get_mid() }, function(res) {
                        Baseliner.message(_('Deleted'), res.msg );
                        var rows = check_sm.getSelections();
                        Ext.each(rows, function(row){ self.store_file.remove(row); })                    
                        self.store_file.reload();
                    });
                });
            } 
            //Baseliner.Topic.file_del('', '', '' );
        };

        var checked_selections = function() {
            if (check_sm.hasSelection()) {
                var sel = check_sm.getSelections();
                var name = [];
                var md5 = [];
                for( var i=0; i<sel.length; i++ ) {
                    md5.push( sel[i].data.md5 );
                    name.push( sel[i].data.name );
                }
                return { count: md5.length, name: name, md5: md5 };
            }
            return undefined;
        };
        
        var filelist = new Ext.ux.maximgb.tg.GridPanel({
            height: 120,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            sortable: false,
            header: true,
            hideHeaders: false,
            sm: check_sm,
            store: self.store_file,
            tbar: [
                { xtype: 'checkbox', handler: function(){ if( this.getValue() ) check_sm.selectAll(); else check_sm.clearSelections() } },
                '->',
                { xtype: 'button', cls:'x-btn-icon', icon:'/static/images/icons/delete.gif', handler: file_del }
            ],
            viewConfig: {
                headersDisabled: true,
                enableRowBody: true,
                scrollOffset: 2,
                forceFit: true
            },
            master_column_id : 'filename',
            autoExpandColumn: 'filename',
            columns: [
              check_sm,
              { width: 16, dataIndex: 'extension', sortable: true, renderer: Baseliner.render_extensions },
              { id:"filename", header: _('File'), width: 250, dataIndex: 'filename', renderer: render_file },
              { header: _('Id'), hidden: true, dataIndex: '_id' },
              { header: _('Size'), width: 40, dataIndex: 'size' },
              { header: _('Version'), width: 40, dataIndex: 'versionid' }
            ]			
        });
        
        var filedrop = new Ext.Panel({
            border: false,
            style: { margin: '10px 0px 10px 0px' },
            height: '100px'
        });

        filedrop.on('afterrender', function(){
            var el = filedrop.el.dom;
            var uploader = new qq.FileUploader({
                element: el,
                action: self.url_upload,
                //debug: true,  
                // additional data to send, name-value pairs
                //params: {
                //  topic_mid: data ? data.topic_mid : self.get_mid()
                //},
                template: '<div class="qq-uploader">' + 
                    '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
                    '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
                    '<ul class="qq-upload-list"></ul>' + 
                 '</div>',
                onComplete: function(fu, filename, res){
                    Baseliner.message(_('Upload File'), _(res.msg, filename) );
                    //if(res.file_uploaded_mid){
                        //var form2 = self.form.getForm();
                        //var files_uploaded_mid = form2.findField("files_uploaded_mid").getValue();
                        //files_uploaded_mid = files_uploaded_mid ? files_uploaded_mid + ',' + res.file_uploaded_mid : res.file_uploaded_mid;
                        //form2.findField("files_uploaded_mid").setValue(files_uploaded_mid);
                        //var files_mid = files_uploaded_mid.split(',');
                        //self.store_file.baseParams = { files_mid: files_mid };
                    //    self.store_file.reload();
                    //}
                    //else{
                        self.store_file.baseParams = {topic_mid: self.get_mid() == -1 ? '' : self.get_mid(), filter: self.id_field };
                        self.store_file.reload();
                    //}
                },
                onSubmit: function(id, filename){
                    var mid = self.get_mid(); // data && data.topic_mid ? data.topic_mid : self.get_mid();
                    var config_parms = function(mid) { uploader.setParams({topic_mid: mid, filter: self.id_field }); };
                    if( mid == undefined || mid<0 ) {
                        Ext.Msg.confirm( _('Confirmation'), _('To upload files, the form needs to be created. Save form before submitting?'),
                            function(btn){ 
                                if(btn=='yes') {
                                    form.main.save_topic({ 
                                        no_refresh: true,
                                        success: function(res){
                                            // resubmit form hack
                                            config_parms(res.topic_mid);
                                            var fc = uploader._handler._files[0];
                                            var id = uploader._handler.add(fc);
                                            var fileName = uploader._handler.getName(id);
                                            uploader._onSubmit(id, fileName);
                                            uploader._handler.upload(id, uploader._options.params);
                                        }
                                    });
                                };
                            }
                        );
                        return false;
                    } else {
                        config_parms(mid);
                    }
                },
                onProgress: function(id, filename, loaded, total){},
                onCancel: function(id, filename){ },
                classes: {
                    // used to get elements from templates
                    button: 'qq-upload-button',
                    drop: 'qq-upload-drop-area',
                    dropActive: 'qq-upload-drop-area-active',
                    list: 'qq-upload-list',
                                
                    file: 'qq-upload-file',
                    spinner: 'qq-upload-spinner',
                    size: 'qq-upload-size',
                    cancel: 'qq-upload-cancel',

                    // added to list item when upload completes
                    // used in css to hide progress spinner
                    success: 'qq-upload-success',
                    fail: 'qq-upload-fail'
                }
            });
        }); 
        
        //{ xtype: 'hidden', name: 'files_uploaded_mid' },
        self.items = [ filelist, filedrop ];
        Baseliner.UploadFilesPanel.superclass.initComponent.call(this);
    },
	get_save_data : function(){
		var self = this;
		var mids = [];
		self.store_file.each(function(row){
			mids.push( row.id ); 
		});
		return mids;
	}, 
	is_valid : function(){
		var self = this;
		return self.store_file.getCount();
	}	
});

// TODO this should be a Job Dashboard style page, in a separate, reusable component
Baseliner.BOM = Ext.extend( Ext.Panel, {
    title: _('Bill Of Materials'),
    autoScroll: true,
    padding: 10,
    initComponent: function(){
        var self = this;
        if( !self.params ) self.params = {};
        self.build_tmpl();
        Baseliner.BOM.superclass.initComponent.call(this);
        self.on('afterrender', function(){
            Baseliner.ci_call( self.mid, 'bom', self.params, function(res){
                console.log( res );
                var html = Baseliner.BOM_tmpl(res);
                self.body.update( html );
                self.doLayout();
            });
        });
    },
    build_tmpl : function(){
        if( Baseliner.BOM_tmpl ) return;
        Baseliner.BOM_tmpl = function(){/*
            <div id="boot" style="overflow: yes">
            <h2>[%= _('BOM') %]</h2>
            <table class="table table-bordered table-condensed dashboard">
                <tbody>
                    <tr>
                        <td>[%= _('Baselines') %]</td>
                        <td>[%= bl %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('Status') %]</td>
                        <td>[%= _(status) %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('Type') %]</td>
                        <td>[%= _(job_type) %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('Scheduled') %]</td>
                        <td>[%= _(starttime) %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('Start') %]</td>
                        <td>[%= _(starttime) %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('End') %]</td>
                        <td>[%= _(endtime) %]</td>
                    </tr>
                    <tr>
                        <td>[%= _('User') %]</td>
                        <td>[%= _(username) %]</td>
                    </tr>
                </tbody>    
            </table>
            <h3>Changesets</h3>
            <table class="table table-bordered table-condensed dashboard">
                <tbody>
                    [% for( var i=0; i<changesets.length; i++) { %]
                    <tr>
                    </tr>
                    [% } %]
                </tbody>    
            </table>
            </div>
        */}.tmpl();
    }
});

Baseliner.request_approval = function(mid,id_grid){
    var grid = Ext.getCmp( id_grid );
    var user_comments = new Ext.form.TextArea({ title: _('Comments'), value:'' });
    
    Baseliner.ci_call( mid, 'can_approve', { }, function(res){
        if( res.data == '0' ) {
            Baseliner.error( _('Approval'), _('User is not authorized to approve this job') );
            return;
        }
        //console.log( res );
        var btn_approve = new Ext.Button({
            text: _('Approve'),
            icon: '/static/images/yes.png',
            handler: function(){
                var comments = user_comments.getValue();
                Baseliner.ci_call(mid,'approve', { comments: comments }, function(res){
                    if( grid ) grid.getStore().reload();
                    Baseliner.message( _('Approved'), _('Job Approved') );
                    win.close();
                });
            }
        });
        var btn_reject = new Ext.Button({
            text: _('Reject'),
            icon: '/static/images/del.gif',
            handler: function(){
                var comments = user_comments.getValue();
                if( comments.length == 0 ) {
                    Baseliner.error( _('Reject'), _('Rejection requires a commentary') );
                    return;
                }
                Baseliner.ci_call(mid,'reject', { comments: comments }, function(res){
                    if( grid ) grid.getStore().reload();
                    Baseliner.message( _('Rejected'), _('Job Rejected') );
                    win.close();
                });
            }
        });
        //var bom = new Baseliner.BOM({ mid: mid, hidden: true });
        var tab_approve = new Ext.TabPanel({ activeTab:0, items: [ user_comments ] });
        tab_approve.on('afterrender', function(){
            //tab_approve.changeTabIcon( bom, '/static/images/icons/log_16.png' ); 
            tab_approve.changeTabIcon( user_comments, '/static/images/icons/comment_blue.gif' ); 
        });
        var win = new Baseliner.Window({ width: 800, height: 600, layout:'fit', 
            title: _('Job') + ': ' + _('Approve') + ' / ' + _('Reject'), 
            tbar: [ btn_approve, btn_reject ],
            items:[ tab_approve ] 
         });
        win.show();
    });
};

