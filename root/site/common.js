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

Baseliner.confirm = function( msg, foo ) {
    Ext.Msg.confirm(_('Confirmation'),  msg , function(btn) {
        if( btn == 'yes' ) {
            if( foo != undefined ) foo();
        }
    });
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

// open a window given a username link
Baseliner.render_user_field  = function(value,metadata,rec,rowIndex,colIndex,store) {
    if( value==undefined || value=='null' || value=='' ) return '';
    var script = String.format('javascript:Baseliner.showAjaxComp("/user/info/{0}")', value);
    return String.format("<a href='{0}'>{1}</a>", script, value );
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
        ret += v + '&nbsp;</span>';
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
    if( val == '*' ) val = _('All');
    return String.format('<b>{0}</b>', val );
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

Baseliner.isArray = function(obj) {
    return Object.prototype.toString.call(obj) === '[object Array]';
};

Baseliner.isFunction = function(obj) {
};

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

