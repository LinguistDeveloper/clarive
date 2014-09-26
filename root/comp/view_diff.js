(function(params){
    var repo_dir = params.repo_dir;
    var rev_num = params.rev_num;
    var txt = new Ext.form.TextArea({ height:'100%', width:'100%', value:'' });
    var branch = params.branch;

    var panel = new Ext.Panel({ 
        layout:'fit',
        html:'',
        bodyStyle:{ 'background-color':'#fff', padding:' 5px 5px 5px 5px', overflow:'auto'}
    });
    
    var html = Baseliner.ajax_json('/svntree/view_diff', { repo_dir: repo_dir, rev_num: rev_num, branch: branch }, function(res){
 console.log(res);
    	var html = function(){/*
		       <div id="boot">
		           <h3>Revision number [%= rev_num %]</h3>
		           <table class="table">
		           <tbody>
		           <tr><td><b>Author</b></td><td>[%= author %]</td></tr>
		           <tr><td><b>Upload date</b></td><td>[%= date %]</td></tr>
		           <tr><td><b>Comment</b></td><td>[%= comment %]</td></tr>
		           [% for(var i=0; i < changes.length; i++) { %]
		           <tr><td><b>File</b></td><td>[%= changes[i].path %]</td></tr>
		           <tr><td><b>Previous revision</b></td><td>[%= changes[i].revision1 %]</td></tr>
		           <tr><td><b>Current revision</b></td><td>[%= changes[i].revision2 %]</td></tr>
		           <tr><td><b>Code changes</b></td><td>[%= changes[i].code.replace(/\n/g,'<br/>')  %]</td></tr>
		           [% } %]
		           </table>
		       </div>
		*/}.tmpl({ rev_num: res.commit_info.revision, author: res.commit_info.author, date: res.commit_info.date, comment: res.commit_info.comment, changes: res.changes });
    	panel.update(html);
    }, function(res){
         Baseliner.error( _('Error'), _(res.msg) );
    });
    return panel;
})













