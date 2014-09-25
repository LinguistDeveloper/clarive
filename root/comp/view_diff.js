(function(params){
    var repo_dir = params.repo_dir;
    var rev_num = params.rev_num;
    var txt = new Ext.form.TextArea({ height:'100%', width:'100%', value:'' });
    var branch = params.branch;
    Baseliner.ajax_json('/svntree/view_diff', { repo_dir: repo_dir, rev_num: rev_num, branch: branch }, function(res){
         txt.setValue(res.file_content);
    }, function(res){
         Baseliner.error( _('Error'), _(res.msg) );
    });
    return new Ext.Panel({ items: txt })
})