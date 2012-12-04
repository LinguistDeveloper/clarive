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
    Baseliner.loadFile( '/static/final.css', 'css' );

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

Baseliner.change_avatar = function() {
    var upload = new Ext.Container();
    upload.on('afterrender', function(){
        var uploader = new qq.FileUploader({
            element: upload.el.dom,
            action: '/user/avatar_upload',
            allowedExtensions: ['png'],
            template: '<div class="qq-uploader">' + 
                '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
                '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
                '<ul class="qq-upload-list"></ul>' + 
             '</div>',
            onComplete: function(fu, filename, res){
                //Baseliner.message(_('Upload File'), _('File %1 uploaded ok', filename) );
                Baseliner.message(_('Upload File'), _(res.msg, filename) );
                reload_avatar_img();
            },
            onSubmit: function(id, filename){
				//uploader.setParams({topic_mid: data ? data.topic_mid : obj_topic_mid.getValue(), filter: meta.rel_field });
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
    var img_id = Ext.id();
    var reload_avatar_img = function(){
            // reload image
            var el = Ext.get( img_id );
            var rnd = Math.floor(Math.random()*80000);
            el.dom.src = '/user/avatar/image.png?' + rnd;
    };
    var gen_avatar = function(){
        Baseliner.ajaxEval('/user/avatar_refresh', {}, function(res){
            Baseliner.message( _('Avatar'), res.msg );
            reload_avatar_img();
        });
    };
    var rnd = Math.floor(Math.random()*80000); // avoid caching
    Baseliner.ajaxEval('/user/user_data', {}, function(res){
        if( !res.success ) {
            Baseliner.error( _('User data'), res.msg );
            return;
        }
        var img = String.format('<img width="32" id="{0}" style="border: 2px solid #bbb" src="/user/avatar/image.png?{1}" />', img_id, rnd );
        var api_key = res.data.api_key;
        var gen_apikey = function(){
            Baseliner.ajaxEval('/user/gen_api_key', {}, function(res){
                Baseliner.message( _('API Key'), res.msg );
                if( res.success ) {
                    api_key.setValue( res.api_key );
                }
            });
        };
        var api_key = new Ext.form.TextArea({ height: 50, anchor:'90%',fieldLabel:_('API Key'), value: api_key });
        var api_key_form = [
            api_key,
            { xtype:'button',  fieldLabel: _('Generate api key'), scale:'large', text:_('Generate API Key'), handler:gen_apikey }
        ];
        var win = new Ext.Window({
            title: _('Manage your Avatar'),
            layout:'fit', width: 600, height: 400, 
            bodyStyle: { 'background-color':'#fff', padding: 20 },
            items: [
                { xtype:'panel', layout:'form', frame: false,
                    items: [
                        api_key_form,
                        { xtype:'container', fieldLabel:_('Current avatar'), html: img },
                        { xtype:'button', width: 80, fieldLabel: _('Change avatar'), scale:'large', text:_('Generate Avatar'), handler:gen_avatar },
                        { xtype:'container', fieldLabel: _('Upload avatar'), items: [ upload ] }
                      ]
                }
            ]
        });
        win.show(); 
    });
};

$.extend($.gritter.options, { position: 'bottom-right' } );

Baseliner.message = function(title, msg, config){
    if( ! config ) config = {};
    
    var id = $.gritter.add( Ext.apply({
        title: title, text: msg, fade: true, 'class': 'baseliner-message',
        time: 2200,
        image: '/static/images/infomsg.png'
    }, config));
    /*
    setTimeout( function(){ $.gritter.remove( id, { fade: true }); }, timeout);
    */
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
//Baseliner.render_user_field  = function(value,metadata,rec,rowIndex,colIndex,store) {
//    if( value==undefined || value=='null' || value=='' ) return '';
//	
//	//if (rec.data.active > 0){
//	//	    var script = String.format('javascript:Baseliner.showAjaxComp("/user/info/{0}")', value);
//	//	    return String.format("<a href='{0}'>{1}</a>", script, value );
//	//}
//	//else{
//	//	return String.format('<span style="text-decoration: line-through">{0}</span>',value);
//	//}
//};

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

Baseliner.JitTree = function(c){
    var self = this;
    Baseliner.JitTree.superclass.constructor.call( this, Ext.apply( {
        layout: 'fit' ,
        bodyCfg: { style:{ 'background-color':'#111' } }
    }, c ) );

    self.on( 'afterrender', function(cont){
        setTimeout( function(){
            do_tree( self.body );
        }, 500);
    });
    
    var do_tree = function( el ) {
        var json = {id:"node02", name:"0.2", data:{},
                children:[{id:"node13", name:"1.3", data:{},
                children:[{id:"node24", name:"2.4", data:{}, children:[]}]}]};
        json = [
            { "id": "1", "name": "1", "adjacencies": [
                    { "nodeTo": "2", "data": { "$direction": ["1", "2"] } },
                    { "nodeTo": "3", "data": { "$direction": ["1", "3"] } }
                ]
            },
            { "id": "2", "name": "2", "adjacencies": [
                    { "nodeTo": "4", "data": { "$direction": ["2", "4"] } }
                ]
            },
            { "id": "3", "name": "3", "adjacencies": [
                    { "nodeTo": "4", "data": { "$direction": ["3", "4"] } }
                ]
            },
            { "id": "4", "name": "4", "adjacencies": [
                    { "nodeTo": "2", "data": { "$direction": ["2", "4"] } },
                    { "nodeTo": "3", "data": { "$direction": ["3", "4"] } }
                ]
            }
        ];
        //A client-side tree generator
        var getTree = (function() {
            var i = 0;
            return function(nodeId, level) {
                var json_str = Ext.util.JSON.encode( json );
                var subtree = eval('(' + json_str.replace(/id:\"([a-zA-Z0-9]+)\"/g, 
                            function(all, match) {
                                return "id:\"" + match + "_" + i + "\""  
                            }) + ')');
                $jit.json.prune(subtree, level); i++;
                return {
                    'id': nodeId,
                    'children': subtree.children
                };
            };
        })();
    

        //Implement a node rendering function called 'nodeline' that plots a straight line
        //when contracting or expanding a subtree.
        $jit.ST.Plot.NodeTypes.implement({
            'nodeline': {
              'render': function(node, canvas, animating) {
                    if(animating === 'expand' || animating === 'contract') {
                      var pos = node.pos.getc(true), nconfig = this.node, data = node.data;
                      var width  = nconfig.width, height = nconfig.height;
                      var algnPos = this.getAlignedPos(pos, width, height);
                      var ctx = canvas.getCtx();
                      var ort = 'top';
                      ctx.beginPath();
                      if(ort == 'left' || ort == 'right') {
                          ctx.moveTo(algnPos.x, algnPos.y + height / 2);
                          ctx.lineTo(algnPos.x + width, algnPos.y + height / 2);
                      } else {
                          ctx.moveTo(algnPos.x + width / 2, algnPos.y);
                          ctx.lineTo(algnPos.x + width / 2, algnPos.y + height);
                      }
                      ctx.stroke();
                  } 
              }
            }
              
        });

        //init Spacetree
        //Create a new ST instance
        //alert( self.body.getHeight() );
        //console.log( self.body );

        var st = new $jit.ST({
            'injectInto': el.id,
            height: el.getHeight(),
            //set duration for the animation
            duration: 500,
            //set animation transition type
            transition: $jit.Trans.Quart.easeInOut,
            //set distance between node and its children
            levelDistance: 50,
            //set max levels to show. Useful when used with
            //the request method for requesting trees of specific depth
            levelsToShow: 2,
            //set node and edge styles
            //set overridable=true for styling individual
            //nodes or edges
            Node: {
                height: 20,
                width: 40,
                //use a custom
                //node rendering function
                type: 'nodeline',
                color:'#23A4FF',
                lineWidth: 2,
                align:"center",
                overridable: true
            },
            
            Edge: {
                type: 'bezier',
                lineWidth: 2,
                color:'#23A4FF',
                overridable: true
            },
            
            //Add a request method for requesting on-demand json trees. 
            //This method gets called when a node
            //is clicked and its subtree has a smaller depth
            //than the one specified by the levelsToShow parameter.
            //In that case a subtree is requested and is added to the dataset.
            //This method is asynchronous, so you can make an Ajax request for that
            //subtree and then handle it to the onComplete callback.
            //Here we just use a client-side tree generator (the getTree function).
            request: function(nodeId, level, onComplete) {
              var ans = getTree(nodeId, level);
              onComplete.onComplete(nodeId, ans);  
            },
            
            onBeforeCompute: function(node){
               // Log.write("loading " + node.name);
            },
            
            onAfterCompute: function(){
                //Log.write("done");
            },
            
            //This method is called on DOM label creation.
            //Use this method to add event handlers and styles to
            //your node.
            onCreateLabel: function(label, node){
                label.id = node.id;            
                label.innerHTML = node.name;
                label.onclick = function(){
                    st.onClick(node.id);
                };
                //set label styles
                var style = label.style;
                style.width = 40 + 'px';
                style.height = 17 + 'px';            
                style.cursor = 'pointer';
                style.color = '#fff';
                //style.backgroundColor = '#1a1a1a';
                style.fontSize = '0.8em';
                style.textAlign= 'center';
                style.textDecoration = 'underline';
                style.paddingTop = '3px';
            },
            
            //This method is called right before plotting
            //a node. It's useful for changing an individual node
            //style properties before plotting it.
            //The data properties prefixed with a dollar
            //sign will override the global node style properties.
            onBeforePlotNode: function(node){
                //add some color to the nodes in the path between the
                //root node and the selected node.
                if (node.selected) {
                    node.data.$color = "#ff7";
                }
                else {
                    delete node.data.$color;
                }
            },
            
            //This method is called right before plotting
            //an edge. It's useful for changing an individual edge
            //style properties before plotting it.
            //Edge data proprties prefixed with a dollar sign will
            //override the Edge global style properties.
            onBeforePlotLine: function(adj){
                if (adj.nodeFrom.selected && adj.nodeTo.selected) {
                    adj.data.$color = "#eed";
                    adj.data.$lineWidth = 3;
                }
                else {
                    delete adj.data.$color;
                    delete adj.data.$lineWidth;
                }
            }
        });
        //load json data
        st.loadJSON( json );
        //compute node positions and layout
        st.compute();
        //emulate a click on the root node.
        st.onClick(st.root);
        //st.switchPosition('top', "animate", { });
    };
};
Ext.extend( Baseliner.JitTree, Ext.Panel ); 

Baseliner.HtmlEditor = Ext.extend(Ext.form.HtmlEditor, {
    initComponent : function(){
        var self = this;
        Baseliner.HtmlEditor.superclass.initComponent.call(this);
        if( Ext.isChrome ) {
            this.on('initialize', function(ht){
                ht.iframe.contentDocument.onpaste = function(e){ 
                    var items = e.clipboardData.items;
                    var blob = items[0].getAsFile();
                    var reader = new FileReader();
                    reader.onload = function(event){
                        self.insertAtCursor( String.format('<img src="{0}" />', event.target.result) );
                    }; 
                    reader.readAsDataURL(blob); 
                };
            }, this);
        }
    }
});

function returnOpposite(hexcolor) {
    var r = parseInt(hexcolor.substr(0,2),16);
    var g = parseInt(hexcolor.substr(2,2),16);
    var b = parseInt(hexcolor.substr(4,2),16);
    var yiq = ((r*299)+(g*587)+(b*114))/1000;
    return (yiq >= 128) ? '#000000' : '#FFFFFF';
}    


Baseliner.JitRGraph = function(c){
    var self = this;
    var json = c.json;

    Baseliner.JitRGraph.superclass.constructor.call( this, Ext.apply( {
        layout: 'fit' ,
        bodyCfg: { style:{ 'background-color':'#fff' } }
    }, c ) );

    self.on( 'afterrender', function(cont){
        setTimeout( function(){
            do_tree( self.body );
        }, 500);
    });

    self._resize = self.resize;
    self.resize = function(args){
        if( self._resize ) self._resize( args ); 
        do_tree( self.body ); 
    };

    self.images = {}; // indexed by mid

    $jit.RGraph.Plot.NodeTypes.implement({
       'icon': {
           'render': function(node, canvas) { 
               var ctx = canvas.getCtx(); 
               var pos = node.getPos().getc(); 
               var img = self.images[ node.id ];
               if( !img ) { 
                   img = new Image(); 
                   img.src = node.data.icon;
                   self.images[ node.id ] = img;
               }
               //img.onload = function(){ 
               ctx.drawImage(img, pos.x-8, pos.y-8 );
               //} 
           },
           'contains': function(node, pos) { 
                var npos = node.pos.getc(true), 
                    dim = node.getData('dim'); 
                    return this.nodeHelper.square.contains(npos, pos, dim); 
           } 
       } 
    });
    
    var do_tree = function( el ) {
        var rgraph = new $jit.RGraph({
            //Where to append the visualization
            injectInto: el.id,
            //Optional: create a background canvas that plots
            //concentric circles.
            background: {
              CanvasStyles: {
                strokeStyle: '#bbb'
              }
            },
            //Add navigation capabilities:
            //zooming by scrolling and panning.
            Navigation: {
              enable: true,
              panning: true,
              zooming: 20
            },
            //Set Node and Edge styles.
            Node: {
                type: 'icon',
                color: '#ddeeff'
            },
            
            Edge: {
              color: '#C17878',
              lineWidth:1.5
            },

            onBeforeCompute: function(node){
                //Log.write("centering " + node.name + "...");
                //Add the relation list in the right column.
                //This list is taken from the data property of each JSON node.
                //$jit.id('inner-details').innerHTML = node.data.relation;
            },
            
            //Add the name of the node in the correponding label
            //and a click handler to move the graph.
            //This method is called once, on label creation.
            onCreateLabel: function(domElement, node){
                domElement.innerHTML = node.name;
                domElement.onclick = function(){
                    rgraph.onClick(node.id, {
                        onComplete: function() {
                            //Log.write("done");
                        }
                    });
                };
            },
            //Change some label dom properties.
            //This method is called each time a label is plotted.
            onPlaceLabel: function(domElement, node){
                var style = domElement.style;
                style.display = '';
                style.cursor = 'pointer';
                var d = node.data;
                var icon = d.icon;

                if (node._depth <= 1) {
                    style.fontSize = "0.8em";
                    style.color = "#111";
                
                } else {
                    style.fontSize = "0.7em";
                    style.color = "#333";
                    //style['margin-top'] = '20px'; 
                } 
                //else {
                   // style.display = 'none';
                //}

                //console.log( node );
                //style.background = String.format("#fff url('{0}') no-repeat", icon );

                var left = parseInt(style.left);
                var w = domElement.offsetWidth;
                style.left = (left - w / 2) + 'px';

                var top = parseInt(style.top);
                var h = domElement.offsetHeight;
                style.top = (top - h / 2 + 15)  + 'px';
            }
        });
        //load JSON data
        rgraph.loadJSON(json);
        //trigger small animation
        /* rgraph.graph.eachNode(function(n) {
          var pos = n.getPos();
          pos.setc(-200, -200);
        }); */
        rgraph.compute('end');
        rgraph.fx.animate({
          modes:['polar'],
          duration: 500
        });

    }
};
Ext.extend( Baseliner.JitRGraph, Ext.Panel ); 

Baseliner.loading_panel = function(){
    return new Ext.Container({
        html: [ 
            '<div id="bali-loading-mask" style="position:absolute; left:0; top:0; width:100%; height:100%; z-index:20000; background-color:white;"></div>',
            '<div id="bali-loading" style="position:absolute; left:45%; top:40%; padding:2px; z-index:20001; height:auto;">',
            '<center>',
            '<img style="" src="/static/images/loading.gif" />',
            '<div style="text-transform: uppercase; font-weight: normal; font-size: 11px; color: #999; font-family: Calibri, OpenSans, Tahoma, Helvetica Neue, Helvetica, Arial, sans-serif;">',
            _('Loading'),
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
    initComponent: function(){
        Baseliner.Window.superclass.initComponent.call(this);
    },
    width: 800, // consider using percentages
    height: 600,
    minimizable: true,
    maximizable: true,
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
    }
});

