(function(params){
    if( ! params.rec ) params.rec = {};
    var data = params.rec;
    
    var store = new Ext.data.ArrayStore({
        fields: [ 'parse_type' ],
        data : [ ['Path'], ['Source'] ]
    });  
    var combo =  new Ext.form.ComboBox({
        name: 'parse_type',
        xtype: 'combo',
        fieldLabel: _('Parse Type'),
        store: store,
        triggerAction: 'all',
        valueField: 'parse_type',
        editable: false,
        displayField: 'parse_type',
        mode: 'local',
        anchor: '100%',
        value: params.rec.parse_type || 'Path',
        forceSelection: true,
        allowBlank: false,
        selectOnFocus: true
    });  
    
    var topic_box_store = new Baseliner.store.Topics({ 
        baseParams: { mid: data ? data.mids : '', show_release: 0, filter:'' } });
    var topic_box = new Baseliner.model.Topics({
		fieldLabel: _('Topics'),
		name: 'tag_topic',
        hiddenName: 'tag_topic',
        store: topic_box_store,
		disabled: false,
		singleMode: false
    });
    topic_box_store.on('load',function(){
        topic_box.setValue( data.tag_topic ) ;            
    });
    
    Baseliner.TopicCombo = Ext.extend( Ext.form.ComboBox, {
        minChars: 2,
        name: 'topic',
        displayField: 'name',
        hiddenName: 'topic',
        valueField: 'mid',
        msgTarget: 'under',
        forceSelection: true,
        typeAhead: false,
        loadingText: _('Searching...'),
        resizable: true,
        allowBlank: false,
        lazyRender: false,
        pageSize: 20,
        triggerAction: 'all',
        xxxitemSelector: 'div.search-item',
        initComponent: function(){
            self.listeners = {
                beforequery: function(qe){
                    delete qe.combo.lastQuery;
                }
            };
            self.xxtpl = new Ext.XTemplate( '<tpl for="."><div class="search-item">{name} {title}</div></tpl>');
            self.xtpl = new Ext.XTemplate( '<tpl for="."><div class="search-item">',
                '<span id="boot" style="width:200px"><span class="badge" ', 
                ' style="float:left;padding:2px 8px 2px 8px;background: {color}"',
                ' >{name}</span></span>',
                '&nbsp;&nbsp;<b>{title}</b></div></tpl>' );
            self.xdisplayFieldTpl = new Ext.XTemplate( '<tpl for=".">',
                '<span id="boot"><span class="badge" style="float:left;padding:2px 8px 2px 8px;background: {color}; cursor:pointer;"',
                ' onclick="javascript:Baseliner.show_topic({mid}, \'{name}\');">{name}</span></span>',
                '</tpl>' );
            Baseliner.TopicCombo.superclass.initComponent.call(this);
        }
    });
    
    Baseliner.TopicGrid = Ext.extend( Ext.grid.GridPanel, {
        height: 200,
        initComponent: function(){
            var self = this;
            self.combo_store = new Baseliner.store.Topics({});
            self.combo = new Baseliner.TopicCombo({
                store: self.combo_store, 
                width: 300,
                height: 80,
                singleMode: true, 
                fieldLabel: _('Topic'),
                name: 'topic',
                hiddenName: 'topic', 
                allowBlank: true
            }); 
            self.field = new Ext.form.Hidden({ name: self.name, value: self.value });
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
            self.tbar = [ self.field, self.combo, btn_delete ];
            self.combo.on('select', function(combo,rec,ix) {
                self.add_to_grid( rec.data );
            });
            self.store = new Ext.data.SimpleStore({
                fields: ['mid','name','title' ],
                data: []
            });
            self.viewConfig = {
                headersDisabled: true,
                enableRowBody: true,
                forceFit: true
            };
            self.sm = new Baseliner.CheckboxSelectionModel({
                checkOnly: true,
                singleSelect:false
            });
            self.on('rowclick', function(grid, rowIndex, e) {
                btn_delete.enable();
            });		
            self.columns = [
                self.sm,
                { header:_('ID'), dataIndex:'mid', hidden: true },
                { header:_('Name'), dataIndex:'name' },
                { header:_('Title'), dataIndex:'title' }
            ];
            Baseliner.TopicGrid.superclass.initComponent.call( this );
        },
        refresh_field: function(){
            var self = this;
            var mids = [];
            self.store.each(function(row){
                mids.push( row.data.mid ); 
            });
            self.field.setValue( mids.join(',') );
        },
        add_to_grid: function(rec){
            var self = this;
            var f = self.store.find( 'mid', rec.mid );
            if( f != -1 ) {
                Baseliner.warning( _('Warning'), _('Row already exists: %1', rec.name + '(' + rec.mid + ')' ) );
                return;
            }
            var r = new self.store.recordType( rec );
            self.store.add( r );
            self.store.commitChanges();
            self.refresh_field();
        }
    });
    
    var cis = new Baseliner.CIGrid({
        fieldLabel: _('CIs'),
        name: 'cis',
        anchor: '100%',
        value: params.rec.cis
    });
	
    return [
        { xtype:'textfield', fieldLabel:_('Options'), name:'regex_options', value: params.rec.regex_options || 'xmsi', anchor:'100%' },
        { xtype:'textfield', fieldLabel:_('Timeout'), name:'timeout', value: params.rec.timeout || '10', anchor:'100%' },
        combo,
        //topic_box,
        new Baseliner.TopicGrid({ fieldLabel:_('Topics'), name:'topics', value: params.rec.topics }),
        cis,
        { xtype:'textarea', fieldLabel:_('Pattern'), name:'regex', 
            height: 100,
            value: params.rec.regex, anchor:'100%', 
            style:'background-color: #000, color: #eee; font: 11px Consolas, Courier New, monotype' 
        }
    ]
})


