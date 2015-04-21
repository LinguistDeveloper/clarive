(function(){
	// Sequences to modify
	var modified_records={};


	var store = new Baseliner.JsonStore({
        autoLoad: false,
        totalProperty:"totalCount",
    	url: '/repl/sequence_store',
    	fields: [ 
                {  name: '_id' },
                {  name: 'seq' }
        ]
	});

	var btn_submit = new Ext.Button({ text:_('Submit'), icon:'/static/images/icons/save.png', handler: function(){
		Baseliner.ajaxEval( '/repl/sequences_update',{modified_records: Ext.util.JSON.encode(modified_records)},
                            function(response) {
                                if ( response.success ) {
                                	modified_records={};
                                    Baseliner.message( _('Success'), response.msg );
                                } else {
                                    Baseliner.error( _('ERROR'), response.msg );
                                }
                            }
    	);	    	
	}});

	var btn_refresh = new Ext.Button({ text:_('Refresh'), icon:'/static/images/icons/refresh.png', handler: function(){
		var hash={};
		store.load();
   		Ext.each(store.reader.jsonData.data,function(row){
   			hash[row._id ] = row.seq;
   		});
   		grid_seq.setSource(hash);
	}});

	var grid_seq = new Ext.grid.PropertyGrid({
	    title: _('Properties Grid'),
	    tbar: [ '->',btn_submit, '->',btn_refresh ],
	    region: 'center',
	    source: {}
	});

	store.on('load', function(obj){
   		var hash={};
   		Ext.each(obj.reader.jsonData.data,function(row){
   			hash[row._id ] = row.seq;
   		});
   		grid_seq.setSource(hash);
	});

	var handler_afterEdit_event = (function afterEdit(e) {
		modified_records[ e.record.data.name ] = [e.value, e.originalValue];
	});
	grid_seq.on('afteredit', handler_afterEdit_event, this);

	store.load();

	return grid_seq;
}
);
