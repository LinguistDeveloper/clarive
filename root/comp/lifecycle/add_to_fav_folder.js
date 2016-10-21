(function(d) {
    Baseliner.ajaxEval('/lifecycle/favorite_add_to_folder',
        {
            id_favorite: d.id_favorite,
            id_parent: d.id_folder,
            id_folder: d.id_folder
        }, function(res){
            Baseliner.message( _('Add to folder'), res.msg );
    });
})


