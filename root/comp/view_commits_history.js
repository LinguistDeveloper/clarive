(function(params){
	var repo_dir = params.repo_dir;
	var branch = params.branch;
	var repo_mid = params.repo_mid;
	var ps = 50;
	var controller;
    if(!params.controller){
        controller = params.click.controller;
    }else{
        controller = params.controller;
    }
	var store_history = new Baseliner.JsonStore({
	    root: 'commits',
	    autoLoad: true,
	    totalProperty:"totalCount", 
	    baseParams: { repo_dir: repo_dir, branch: branch, start: 0, limit: ps, repo_mid: repo_mid, tag: params.tag, commit: params.commit },  
	    url: '/'+controller+'/get_commits_history', 
	    fields: ['ago','author','revision','comment', 'date'],
	});

	var render_diff_btn = function(value,metadata,rec,rowIndex,colIndex,store){       
		var comment_length = 25;
        var str_title = branch + ": [" + rec.data.revision + "] " + repo_dir;
        if (str_title.length > comment_length && controller != 'plastictree'){ 
            var center = str_title.length/2;
            var surplus_str = str_title.length - comment_length;
            str_title = str_title.substr(0, center-surplus_str/2) + '...' + str_title.substr(center+surplus_str/2);
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

    var search_form = new Ext.form.TextField({ enableKeyEvents : true });
    search_form.on('keypress', function(obj,e){ 
		if(e.which == 13 || e.keyCode == 13){
			if(this.getValue() == ''){
				Baseliner.ajax_json('/'+controller+'/get_commits_history', { repo_dir: repo_dir, branch: branch, start: 0, limit: ps, repo_mid: repo_mid }, 
					function(res){
						store_history.loadData(res);
					}
				);
			} else {
				Baseliner.ajax_json('/'+controller+'/get_commits_search', { repo_dir: repo_dir, branch: branch, query: this.getValue(), repo_mid: repo_mid }, 
					function(res){
						pagingBar.pageSize = res.commits.length;
						store_history.loadData(res);
					}
				);
			}
		}
    });

	var pagingBar = new Ext.PagingToolbar({
        pageSize: ps,
        store: store_history,
        displayInfo: true,
        plugins: new Ext.ux.ProgressBarPager()
    });

	var render_ago = function(value,metadata,rec,rowIndex,colIndex,store){
		return store.getAt(rowIndex).data.ago;
	};

	var grid = new Ext.grid.GridPanel({
		tbar : [ _('Search'),search_form ],
        store: store_history,
        columns: [
            {header: _("Ago"), width: 75, dataIndex: 'date', sortable: true, dataIndex: 'date', renderer: render_ago },
            {header: _("Author"), width: 70, sortable: true, dataIndex: 'author', sortable: true},
            {header: _("Revision"), width: 50, sortable: true, dataIndex: 'revision', sortable: true},
            {header: _("Comment"), width: 450, dataIndex: 'comment', sortable: true},
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

        bbar: pagingBar
	});

	var panel = new Ext.Panel({ 
	    layout:'fit',
	    items: grid
	});
    return panel;
})
