(function(node) {
    if( node == undefined ) node = {};

    var branch = node.data.name;
    var repository = node.data.repo_name;
    var repo_mid = node.data.repo_mid;

    Baseliner.confirm( _('Are you sure you want to close branch %1 in repository %2', branch, repository  ), function() { 
        Baseliner.ci_call( repo_mid, 'close_branch', { branch: branch }, function(res){
            Baseliner.message( _('Close branch'), _('Branch %1 closed', branch) );
        }, function(res){
            // No ci form ignore
        });
    });
})
