(function(params){
	var repo_dir = params.repo_dir;
	var branch = params.branch;
	var repo_mid = params.repo_mid;
	var ps = 50;
	var controller = params.click.controller;
	var store_history = new Baseliner.JsonStore({
	    root: 'commits', 
	    remoteSort: true, 
	    autoLoad: true,
	    totalProperty:"totalCount", 
	    baseParams: { repo_dir: repo_dir, branch: branch, start: 0, limit: ps },  
	    url: '/'+controller+'/get_commits_history', 
	    fields: ['ago','author','revision','comment'] 
	});

	var render_diff_btn = function(value,metadata,rec,rowIndex,colIndex,store){       
		var comment_length = 25;
        var str_title = branch + ": [" + rec.data.revision + "] " + repo_dir;
        if (str_title.length > comment_length && controller != 'plastictree'){ 
            var i = str_title.lastIndexOf('/');
            var actual = str_title.indexOf('/');
            var c = -1;
            var temp;
            while (actual < comment_length && c != actual){
                temp = str_title.indexOf('/', actual+1);
                c = actual;
                actual = temp > comment_length ? actual : temp;
            }
            str_title = str_title.substr(0, actual+1) + '...' + str_title.substr(i);
        }
        str_title = escape(str_title);

        var params = { 
        	repo_dir:  repo_dir,
        	repo_mid: repo_mid,
        	branch: branch,
        	rev_num: rec.data.revision,
        	controller: controller
        };

        str_params = Ext.util.JSON.encode( params );
        return "<div style='color: blue;cursor: pointer;' onclick=Baseliner.add_tabcomp('/comp/view_diff.js','" + str_title + "'," + str_params + ");>"+_('DIFF')+"</div>";
    };

	var grid = new Ext.grid.GridPanel({
	        store: store_history,
	        columns: [
	            {id:'company',header: _("Ago"), width: 75, dataIndex: 'ago'},
	            {header: _("Author"), width: 70, sortable: true, dataIndex: 'author'},
	            {header: _("Revision"), width: 50, sortable: true, dataIndex: 'revision'},
	            {header: _("Comment"), width: 450, dataIndex: 'comment'},
	            {header: _('DIFF'), width: 50, dataIndex: 'diff_btn', renderer: render_diff_btn }
	        ],
	        stripeRows: true,
	        autoExpandColumn: 'company',
	        height:320,
	        width:600,
	        frame:true,
	        title:_('Commits history of branch'),
            viewConfig: {
                forceFit: true
            },
	        plugins: new Ext.ux.PanelResizer({
	            minHeight: 100
	        }),

	        bbar: new Ext.PagingToolbar({
	            pageSize: ps,
	            store: store_history,
	            displayInfo: true,
	            plugins: new Ext.ux.ProgressBarPager()
	        })
	});

	var panel = new Ext.Panel({ 
	    layout:'fit',
	    items: grid
	});
    return panel;
})
