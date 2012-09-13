// Cookies
Baseliner.cookie = new Ext.state.CookieProvider({
        expires: new Date(new Date().getTime()+(1000*60*60*24*300)) //300 days
});

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
    // Baseliner.loadFile( '/site/lifecycle.js', 'js' ); // doesnt work since the lifecycle is global
    Baseliner.loadFile( '/site/portal/Portal.js', 'js' );
    Baseliner.loadFile( '/site/portal/Portlet.js', 'js' );
    Baseliner.loadFile( '/site/portal/PortalColumn.js', 'js' );
    Baseliner.loadFile( '/comp/topic/topic_lib.js', 'js' );

    Baseliner.loadFile( '/static/site.css', 'css' );

    Baseliner.message(_('JS'), _('Reloaded successfully') );  
};

Baseliner.alert = function(title, format){
    var s = String.format.apply(String, Array.prototype.slice.call(arguments, 1));
    Ext.Msg.alert({
        title: title,
        msg: s,
        icon: Ext.Msg.WARNING
        //buttons: Ext.Msg.OK,
    });
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

Baseliner.render_wrap = Baseliner.columnWrap;

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

Baseliner.render_identicon = function(v) {
    return '<img src="/user/avatar/' + v + '/avatar.png" width=32 />';
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
    if( val == '*' ) val = _('Common');
    return String.format('<b>{0}</b>', val );
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

/*
    parameters:
         {
            mid:
            category_name:
            category_color: 
            category_icon:
            is_changeset: 1|0
            is_release: 1|0
         }
*/
Baseliner.topic_name = function(args) {
        var mid = args.mid; //Cambiarlo en un futuro por un contador de categorias
        if( ! mid ) 
            mid = args.topic_mid; 
        if( mid )
            mid = '#' + mid;
        else
            mid = '';
        var cat_name = args.category_name; //Cambiarlo en un futuro por un contador de categorias
        if( cat_name )
            cat_name = cat_name + ' ';
        else
            cat_name = ''
        var color = args.category_color;
        var cls = 'label';
        var icon = args.category_icon;
        var size = args.size ? args.size : '10';

        var top,bot,img;
        top=2, bot=4, img=2;

        if( ! color ) 
            color = '#999';

        // set default icons
        if( icon==undefined ) {
            if( args.is_changeset > 0  ) {
                icon = '/static/images/icons/package-white.png';
            }
            else if( args.is_release > 0  ) {
                icon = '/static/images/icons/release-white.png';
            }
        }

        // prepare icon background
        var style_str;
        if( icon && ! args.mini ) {
            style_str = "padding:{2}px 8px {3}px 18px;background: {0} url('{1}') no-repeat left {4}px; font-size: {5}px";
        }
        else {
            style_str = "padding:{2}px 8px {3}px 8px;background-color: {0}; font-size: {5}px";
        }
        var style = String.format( style_str, color, icon, top, bot, img, size );
        //if( color == undefined ) color = '#777';
        var ret = args.mini 
            ? String.format('<span id="boot" style="background: transparent"><span class="{0}" style="{1};padding: 1px 1px 1px 1px; margin: 0px 4px -10px 0px;border-radius:0px">&nbsp;</span><span style="font-weight:bolder;font-size:11px">{2}{3}</span></span></span>', cls, [style,args.style].join(';'), cat_name, mid )
            : String.format('<span id="boot"><span class="{0}" style="{1}">{2}{3}</span>', cls, [style,args.style].join(';'), cat_name, mid );
        return ret;
};

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
        if( r.logged_out ) {
            Baseliner.login({ no_reload: 1, scope: store, on_login: function(s){ s.reload() } });
        } 
        else if( r.msg ) {
            Ext.Msg.alert( _('Server Error'), r.msg );
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
    listeners: {
        exception: Baseliner.store_exception_handler,
        beforeload: Baseliner.store_exception_params 
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
		    icon:'/static/images/icons/add.gif',
		    cls: 'x-btn-text-icon'
	    }, config);
	    Baseliner.Grid.Buttons.Add.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Edit = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
	    config = Ext.apply({
		    text: _('Edit'),
		    icon: '/static/images/icons/edit.gif',
		    cls: 'x-btn-text-icon',
		    disabled: true
	    }, config);
	    Baseliner.Grid.Buttons.Edit.superclass.constructor.call(this, config);
    }
});

Baseliner.Grid.Buttons.Delete = Ext.extend( Ext.Toolbar.Button, {
    constructor: function(config) {
	    config = Ext.apply({
		    text: _('Delete'),
		    icon:'/static/images/icons/delete.gif',
		    cls: 'x-btn-text-icon',
		    disabled: true
	    }, config);
	    Baseliner.Grid.Buttons.Delete.superclass.constructor.call(this, config);
    }
});

Baseliner.gantt = function( format ) {
    var divTag = document.createElement("div");  
    divTag.setAttribute("align", "center");           
    var g = new JSGantt.GanttChart( 'g', divTag, format );

    g.Draw();
    
    return g;
};

