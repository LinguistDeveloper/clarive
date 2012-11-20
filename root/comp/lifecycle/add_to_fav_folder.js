(function(d) {
    var n1 = d.node1;
    var n2 = d.node2;
    Baseliner.ajaxEval('/lifecycle/favorite_add_to_folder',
        {
            id_favorite: n1.attributes.id_favorite,
            favorite_folder: n1.attributes.favorite_folder,
            id_folder: n2.attributes.id_folder
        }, function(res){
            Baseliner.message( _('Add to folder'), res.msg );
            var is = n2.isExpanded();
            Baseliner.lifecycle.getLoader().load( n2 );
            if( is ) n2.expand();
            n1.parentNode.removeChild( n1 );
    });
})

