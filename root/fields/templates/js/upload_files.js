/*
name: Upload files
params:
    origin: 'template'
    type: 'upload_files'
    html: '/fields/templates/html/upload_files.html'
    js: '/fields/templates/js/upload_files.js'
    relation: 'system'
    get_method: 'get_files'    
    field_order: 3
    section: 'details'
    allowBlank: true
---
*/
////////(function(params){
////////	var meta = params.topic_meta;
////////	var data = params.topic_data;
////////    var form = params.form;
////////	var ff;
////////    ff = params.form.getForm();
////////	var obj_topic_mid = ff .findField("topic_mid");
////////	
////////    var allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
////////    var readonly = meta.readonly == undefined ? true : meta.readonly;
////////	
////////    var check_sm = new Ext.grid.CheckboxSelectionModel({
////////        singleSelect: false,
////////        sortable: false,
////////        checkOnly: true
////////    });
////////	
////////    var record = Ext.data.Record.create([
////////        {name: 'filename'},
////////        {name: 'versionid'},
////////        {name: 'filesize'},     
////////        {name: 'size'},     
////////        {name: 'md5'},     
////////        {name: '_id', type: 'int'},
////////        {name: '_parent', type: 'auto'},
////////        {name: '_level', type: 'int'},
////////        {name: '_is_leaf', type: 'bool'}
////////    ]); 	
////////	
////////    var store_file = new Ext.ux.maximgb.tg.AdjacencyListStore({  
////////       autoLoad : true,  
////////       url: '/topic/file_tree',
////////	   baseParams: { topic_mid: data ? data.topic_mid : obj_topic_mid.getValue() == -1 ? '' : obj_topic_mid.getValue(), filter: meta.id_field },
////////       reader: new Ext.data.JsonReader({ id: '_id', root: 'data', totalProperty: 'total', successProperty: 'success' }, record )
////////    });
////////	
////////    var render_file = function(value,metadata,rec,rowIndex,colIndex,store) {
////////        var md5 = rec.data.md5;
////////        if( md5 != undefined ) {
////////            value = String.format('<a target="FrameDownload" href="/topic/download_file/{1}">{0}</a>', value, md5 );
////////        }
////////        value = '<div style="height: 20px; font-family: Consolas, Courier New, monospace; font-size: 12px; font-weight: bold; vertical-align: middle;">' 
////////            //+ '<input type="checkbox" class="ux-maximgb-tg-mastercol-cb" ext:record-id="' + record.id +  '"/>&nbsp;'
////////            + value 
////////            + '</div>';
////////        return value;
////////    };
////////
////////    var file_del = function(){
////////        var sels = checked_selections();
////////        if ( sels != undefined ) {
////////            var sel = check_sm.getSelected();
////////            Baseliner.confirm( _('Are you sure you want to delete these artifacts?'), function(){
////////                var sels = checked_selections();
////////				Baseliner.ajaxEval( '/topic/file/delete', { md5 : sels.md5, topic_mid: data ? data.topic_mid : obj_topic_mid.getValue() }, function(res) {
////////                    Baseliner.message(_('Deleted'), res.msg );
////////                    var rows = check_sm.getSelections();
////////                    Ext.each(rows, function(row){ store_file.remove(row); })                    
////////                    store_file.reload();
////////                });
////////            });
////////        } 
////////        //Baseliner.Topic.file_del('', '', '' );
////////    };
////////
////////    var checked_selections = function() {
////////        if (check_sm.hasSelection()) {
////////            var sel = check_sm.getSelections();
////////            var name = [];
////////            var md5 = [];
////////            for( var i=0; i<sel.length; i++ ) {
////////                md5.push( sel[i].data.md5 );
////////                name.push( sel[i].data.name );
////////            }
////////            return { count: md5.length, name: name, md5: md5 };
////////        }
////////        return undefined;
////////    };
////////	
////////    var filelist = new Ext.ux.maximgb.tg.GridPanel({
////////		fieldLabel:  _(meta.name_field),
////////		allowBlank: allow,
////////		readOnly: readonly,		
////////        height: 120,
////////        stripeRows: true,
////////        autoScroll: true,
////////        autoWidth: true,
////////        sortable: false,
////////        header: true,
////////        hideHeaders: false,
////////        sm: check_sm,
////////        store: store_file,
////////        tbar: [
////////            { xtype: 'checkbox', handler: function(){ if( this.getValue() ) check_sm.selectAll(); else check_sm.clearSelections() } },
////////            '->',
////////            { xtype: 'button', cls:'x-btn-icon', icon:'/static/images/icons/delete.gif', handler: file_del }
////////        ],
////////        viewConfig: {
////////            headersDisabled: true,
////////            enableRowBody: true,
////////            scrollOffset: 2,
////////            forceFit: true
////////        },
////////        master_column_id : 'filename',
////////        autoExpandColumn: 'filename',
////////        columns: [
////////          check_sm,
////////          { width: 16, dataIndex: 'extension', sortable: true, renderer: Baseliner.render_extensions },
////////          { id:"filename", header: _('File'), width: 250, dataIndex: 'filename', renderer: render_file },
////////          { header: _('Id'), hidden: true, dataIndex: '_id' },
////////          { header: _('Size'), width: 40, dataIndex: 'size' },
////////          { header: _('Version'), width: 40, dataIndex: 'versionid' }
////////        ]
////////    });
////////	
////////    var filedrop = new Ext.Panel({
////////        border: false,
////////        style: { margin: '10px 0px 10px 0px' },
////////        height: '100px'
////////    });
////////
////////    filedrop.on('afterrender', function(){
////////        var el = filedrop.el.dom;
////////        var uploader = new qq.FileUploader({
////////            element: el,
////////            action: '/topic/upload',
////////            //debug: true,  
////////            // additional data to send, name-value pairs
////////            //params: {
////////			//	topic_mid: data ? data.topic_mid : obj_topic_mid.getValue()
////////            //},
////////            template: '<div class="qq-uploader">' + 
////////                '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
////////                '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
////////                '<ul class="qq-upload-list"></ul>' + 
////////             '</div>',
////////            onComplete: function(fu, filename, res){
////////                Baseliner.message(_('Upload File'), _(res.msg, filename) );
////////                if(res.file_uploaded_mid){
////////                    var form2 = params.form.getForm();
////////                    var files_uploaded_mid = form2.findField("files_uploaded_mid").getValue();
////////                    files_uploaded_mid = files_uploaded_mid ? files_uploaded_mid + ',' + res.file_uploaded_mid : res.file_uploaded_mid;
////////                    form2.findField("files_uploaded_mid").setValue(files_uploaded_mid);
////////                    var files_mid = files_uploaded_mid.split(',');
////////                    store_file.baseParams = { files_mid: files_mid };
////////                    store_file.reload();
////////                }
////////                else{
////////					store_file.baseParams = {topic_mid: data ? data.topic_mid : obj_topic_mid.getValue() == -1 ? '' : obj_topic_mid.getValue(), filter: meta.id_field };
////////                    store_file.reload();                    
////////                }
////////            },
////////            onSubmit: function(id, filename){
////////                var mid = data && data.topic_mid ? data.topic_mid : obj_topic_mid.getValue();
////////                var config_parms = function(mid) { uploader.setParams({topic_mid: mid, filter: meta.id_field }); };
////////                if( mid == undefined || mid<0 ) {
////////                    Ext.Msg.confirm( _('Confirmation'), _('To upload files, the form needs to be created. Save form before submitting?'),
////////                        function(btn){ 
////////                            if(btn=='yes') {
////////                                form.main.save_topic({ success: function(res){
////////                                    // resubmit form hack
////////                                    config_parms(res.topic_mid);
////////                                    var fc = uploader._handler._files[0];
////////                                    var id = uploader._handler.add(fc);
////////                                    var fileName = uploader._handler.getName(id);
////////                                    uploader._onSubmit(id, fileName);
////////                                    uploader._handler.upload(id, uploader._options.params);
////////                                }});
////////                            };
////////                        }
////////                    );
////////                    return false;
////////                } else {
////////                    config_parms(mid);
////////                }
////////            },
////////            onProgress: function(id, filename, loaded, total){},
////////            onCancel: function(id, filename){ },
////////            classes: {
////////                // used to get elements from templates
////////                button: 'qq-upload-button',
////////                drop: 'qq-upload-drop-area',
////////                dropActive: 'qq-upload-drop-area-active',
////////                list: 'qq-upload-list',
////////                            
////////                file: 'qq-upload-file',
////////                spinner: 'qq-upload-spinner',
////////                size: 'qq-upload-size',
////////                cancel: 'qq-upload-cancel',
////////
////////                // added to list item when upload completes
////////                // used in css to hide progress spinner
////////                success: 'qq-upload-success',
////////                fail: 'qq-upload-fail'
////////            }
////////        });
////////    });	
////////
////////	return [
////////		{ xtype: 'hidden', name: 'files_uploaded_mid' },
////////		//Baseliner.field_label_top( _(meta.name_field), meta.hidden, allow, readonly ),
////////		{
////////			xtype: 'panel',
////////			border: false,
////////			layout: 'form',
////////            style: 'margin-top: 10px', 
////////			disabled: meta ? meta.readonly : true,
////////			//hidden: rec.fields_form.show_files ? false : true,
////////			items: [
////////				filelist,
////////				filedrop
////////			]
////////			//,fieldLabel: _(meta.name_field)
////////		}
////////    ]
////////})

 


(function(params){
    var meta = params.topic_meta;
    var data = params.topic_data;
    var form = params.form;
	
    var allow = meta.allowBlank == undefined ? true : ( meta.allowBlank == 'false' || !meta.allowBlank ? false : true );
    var readonly = meta.readonly == undefined ? true : meta.readonly;	

    var up = new Baseliner.UploadFilesPanel({
		name:  meta.id_field,
		fieldLabel: _(meta.name_field),
        allowBlank  : allow,
        height: ( meta.height ? parseInt(meta.height) : 200 ),
        readOnly    : readonly,
		disabled: readonly,
        id_field    : meta.id_field,
        form : form
    });
    return [
        up
    ]
})


