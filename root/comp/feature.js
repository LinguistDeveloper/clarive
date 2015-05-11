(function(){
   Baseliner.ProgressBar = Ext.extend( Ext.ProgressBar, {
       border: false,
       style: 'padding: 20px 20px 20px 20px',
       initComponent: function(){
           Baseliner.ProgressBar.superclass.initComponent.call(this);
           this.addEvents('log');
           this.$log = [];
       },
       current: function( msg ) {
           this.log( msg );
           this.updateText( msg );
       },
       log: function( msg ) {
           if( Ext.isObject( msg ) ) 
               msg = Ext.util.JSON.encode( msg );
           this.$log.push( msg );
           this.fireEvent('log', msg );
       },
       message : function(msg) {
           this.log( msg );
           this.update( String.format( '<img src="/static/images/icons/save.png" /> <b style="line-height: 16px">{0}</b>', msg ) );
           this.ownerCt.doLayout();
       },
       error: function(msg) {
           this.log( msg );
           this.update( '<span style="color: red; font-weight: bold">' + msg + '</span>' );
           this.ownerCt.doLayout();
       }
   });
   Baseliner.ProgressWindow = Ext.extend( Baseliner.Window, {
        modal: true,
        layout: 'border',
        width: 800, height: 450,
        initComponent: function(){
            var self = this;
            Baseliner.ProgressWindow.superclass.initComponent.call( this );
            this.card = new Ext.Panel({ 
                layout:'card', region: 'center',
                //layoutConfig: { activeItem: 0 },
                activeItem: 0,
                tbar: [ 
                    { text: _('Upgrades'), pressed:true,allowDepress:false, enableToggle:true, toggleGroup:'progress-btn',
                        handler:function(){ self.card.getLayout().setActiveItem( self.pull_list ) }  },
                    '-',
                    { text: _('Log'), allowDepress:false, enableToggle:true, toggleGroup:'progress-btn',
                        handler:function(){ self.card.getLayout().setActiveItem( self.log ) }  }
                ]
            });
            this.add( this.card );
            this.pull_list = new Ext.FormPanel({ 
                autoScroll: true,
                bodyStyle: 'padding: 10px 10px 10px 10px',
                defaults: {
                    border: false,
                    labelStyle: 'font-weight:bold;',
                    labelWidth: 150
                },
                frame: false, 
                border: false
            });
            self.card.add( self.pull_list );
            this.log = new Ext.form.TextArea({ style:'font-family: Consolas, Courier New, Courier, mono;' });
            this.$last_log_id = '';
            this.card.add( this.log );
            this.show();
        }, 
        push_progress: function(id, label, text){
            var self = this;
	        var pb = new Baseliner.ProgressBar({ 
            	fieldLabel: _( label ),
                text: text });
			this.pull_list.add( pb );
            this.pull_list.doLayout();
            pb.on('log', function(msg){
                if( Ext.isArray( msg ) ) 
                    msg = msg.join("\n");
                self.log.setValue( self.log.getValue() + "\n"
                    + ( self.$last_log_id === id ? msg : String.format('===========[ {0} ]===========\n{1}', id, msg ) ) );
                self.$last_log_id = id;
            });
            return pb;
        }
    });
   
    Baseliner.FeatureUpgrade = Ext.extend( Ext.Panel, {
        layout: 'border',
        initComponent: function(){
            var self = this;
            Baseliner.FeatureUpgrade.superclass.initComponent.call(this);
            self.store = new Baseliner.JsonStore({
                autoLoad: true,
                
            root: 'data' , 
            remoteSort: true,
            totalProperty: "totalCount", 
            id: 'id', 
                fields: [ 'feature', 'dir','refs','date','branch','tag','tags','version','versions','fetch_head' ], 
                url:'/feature/list_repositories'
            });
            self.sm = new Ext.grid.CheckboxSelectionModel();
            self.cm = new Ext.grid.ColumnModel({
                columns: [
                    self.sm,
                    { header:_('Feature'), dataIndex:'feature', renderer: self.render_bold },
                    { header:_('Date'), dataIndex:'date' },
                    { header:_('Version'), dataIndex:'version', editable:true },
                    { header:_('Branch'), dataIndex:'branch' },
                    { header:_('Last Fetch'), dataIndex:'fetch_head' },
                    { header:_('Versions'), hidden: true, dataIndex:'versions' },
                    { header:_('Refs'), hidden: true, dataIndex:'refs' },
                    { header:_('Repository'), dataIndex:'dir' }
                ],
                getCellEditor: function( col, row) {
                    var rec = self.store.getAt( row );
                    var arr = [];
                    Ext.each(rec.data.versions, function(v){ 
                        // rename refs/heads/ to branch:
                        var name = v.replace('refs/heads/', 'branch: ');
                        arr.push( [v,name] )
                    });
                    var editor = new Ext.form.ComboBox({
                       typeAhead: true,
                       minChars: 1,
                       mode: 'local', 
                       store: arr,
                       editable: true,
                       //forceSelection: true,
                       triggerAction: 'all',
                       allowBlank: false
                    });
                    this.setEditor( col, editor );
                    return Ext.grid.ColumnModel.prototype.getCellEditor.call(this, col, row);
                }
            });
            self.list = new Ext.grid.EditorGridPanel({
                selModel: self.sm, 
                region:'center',
                store: self.store, 
                loadMask:'true',
                stripeRows: true,
                autoScroll: true,
                autoWidth: true,
                autoSizeColumns: true,
                viewConfig: { forceFit: true },
                tbar: [
                    { icon:'/static/images/icons/refresh.png', handler: function(){ self.store.reload() }, tooltip:_('Reload')  }, '-',
                    { text:_('Download Patches'), icon:'/static/images/icons/local.png', handler: function(){ self.pull() } }, '-',
                    { text:_('Checkout'), icon:'/static/images/icons/features/checkout.png', handler: function(){ 
                         if( self.sm.hasSelection() ) {
                             Baseliner.confirm( _('Selected features will be overwritten. A server restart may be necessary. If any changes are found, they will be stashed and the current version saved to the __rollback__ branch. Ok?'), 
                                    function(){
                                      self.checkout(true)
                                    }
                             );
                         }
                    } }, '-',
                    { text:_('Diff Only'), icon:'/static/images/icons/features/good.png', handler: function(){ self.checkout(false) } }
                ],
                cm: self.cm
            });
            self.add( self.list );
        },
        repos : function(confirm,cb){
            var self = this;
            var sels = self.sm.getSelections();
            var repos = [];
            var dirty = false;
            Ext.each( sels, function(row){
                dirty = dirty || row.dirty;
                repos.push( row.data );
            });
            if( ! dirty && confirm && cb ) {
                // TODO - confirm
                Baseliner.confirm(_('No versions were changed, checking out over anyway?'), function(){ cb(repos) } );
            } else {
                if( cb ) {
                    cb(repos);
                }
            }
            return repos;
        },
        pull : function(){
            var self = this;
            if (self.sm.hasSelection()) {
                var repos = self.repos(false);
                //self.el.mask();
                var win_pull = new Baseliner.ProgressWindow({ title: _('Download Patches'), maximized: true });
                win_pull.on('destroy', function(){
                    self.store.reload();
                });
                Ext.each( repos, function(repo){
                    var pb = win_pull.push_progress( repo.feature,
                        String.format('{0}' , repo.feature ),
                        _('Creating patch...')  ); 
                    pb.log( _('Starting download for %1...', repo.feature ) );
                    pb.log( repo ); 
                    var k = 0, freq = 100;
                    var pb_update = function(){ pb.updateProgress( ++k/100 ); if( freq>0 && k<=95 ) setTimeout( pb_update, freq ) };
                    pb_update();
                    repo.branch = repo.branch || 'master';
                    var data = {
                            feature: repo.feature,
                            sha: repo.fetch_head,
                            branch: repo.branch  // TODO get local repo current branches
                        };
                    var data_str = String.format('sha: {0}, feature: {1}, branch: {2}', data.sha, data.feature, data.branch ) 
                    pb.log( data_str );
                    // request file
                    $.ajax({
                        type: 'GET',
                        url: 'http://patch.vasslabs.com',
                        data: data,
                        crossDomain: true,
                        success: function(res, textStatus, jqXHR) {
                            if( res.success ) {
                                k = 0;
                                freq = Math.floor( res.size/100000 );
                                var size = (res.size/1024).toFixed(2) + ' KB'; 
                                pb.current( _('Downloading, total %1', size ) ); 
                                var pull_id = res.id;
                                var pull_file = res.file;
                                // download file
                                $.ajax({
                                    type: 'GET',
                                    url: String.format('http://patch.vasslabs.com/patch/{0}', pull_file),
                                    crossDomain: true,
                                    success: function(res, textStatus, jqXHR) {
                                        k=0;
                                        pb.current( _('Uploading and importing, total %1', size ) ); 
                                        // save file to server and fetch
                                        //Baseliner.message( _('Download Patches'), _('Download finished. Uploading...') );
                                        $.ajax({
                                            type: 'POST',
                                            url: '/feature/pull',
                                            data: { data: res, feature: repo.feature, id: pull_id, branch: repo.branch },
                                            success: function(res){
                                                pb.log( res.log ); 
                                                pb.message( _('Upload and Fetch finished ok') );
                                            },
                                            error: function(res, textStatus){
                                                pb.log( _('status: %1', textStatus ) );
                                                if( Ext.isObject(res) ) {
                                                    pb.log( res.log ); 
                                                    pb.error( res.msg );
                                                } else if( res ) {
                                                    pb.log( res );
                                                } else {
                                                    pb.log( _('Upload response empty.') );
                                                }
                                                self.store.reload();
                                            }
                                        });
                                    }
                                });
                            } else {
                                freq = 0;  // stop progress
                                if( /Refusing to create empty bundle/.test( res.msg ) ) {
                                    pb.log( res.msg + "\n" );
                                    pb.message( _('Nothing to do. Already up to date.') );
                                } else {
                                    var err = [
                                        _('Patch pull failed: %1', res.msg ),
                                        data_str
                                    ].join("<br>");
                                    pb.error( err );
                                }
                            }
                        },
                        error: function (res, textStatus, errorThrown) {
                            freq = 0;  // stop progress
                            var err = _('Patch request failed: %1', errorThrown );
                            pb.error( err );
                        }
                    });
                });
            }
        },
        checkout : function(checkout){
            var self = this;
            if (self.sm.hasSelection()) {
                self.repos(checkout, function(repos){
                    self.el.mask();
                    Baseliner.ajaxEval('/feature/checkout', { repos: Ext.util.JSON.encode( repos ), checkout: checkout ? 1 : 0}, function(res){
                        self.el.unmask();
                        var log = res.log.join("\n");
                        var win = new Baseliner.Window({ width: 940, height: 400, layout:'fit', modal:true, items: [
                            new Ext.form.TextArea({ value: log, readOnly:true, style:'font-family:Consolas, Courier New, Courier, mono' }) ] });
                        win.show();
                    });
                });
            }
        },
        render_bold : function(v){
            return String.format('<b>{0}</b>', v );
        }
    });
    
    var features = new Baseliner.FeatureUpgrade();
    var cpan = new Baseliner.CPANDownloader();
    
    var card = new Ext.Panel({
        layout:'card',
        activeItem: 0,
        tbar: [
            { text: _('Features'),
                icon: '/static/images/icons/features/plugin.png',
                pressed: true, allowDepress: false, enableToggle:true, toggleGroup:'upgrades-btn',
                handler: function(){ card.getLayout().setActiveItem( features ) }
            },
            { text: _('Modules'),
                icon: '/static/images/icons/perl.png',
                pressed: false, allowDepress: false, enableToggle:true, toggleGroup:'upgrades-btn',
                handler: function(){ card.getLayout().setActiveItem( cpan ) }
            },
            '->',
            { text: _('Restart Server'),
                icon: '/static/images/icons/server_restart.png',
                handler: function(){
                    Baseliner.confirm( _('You are about to attempt to restart the server. Are you sure?'), function(){
                        $.ajax({ type:'POST', url: '/feature/restart_server' });
                    });
                }
            }
        ]
    });
    card.add( features );
    card.add( cpan );
    return card;
})
