(function(params){ 
    var id = params.id_div;
    var project_id = params.project_id;
    var graph;
    var mid = params.data.mid;


    var div = document.getElementById(id);
    div.style.clear = "left";
    div.innerHTML = '';
    var graph = new Baseliner.CIGraph({ mid: mid || '1736', direction:'children', 
        depth: 3, which:'st', height: $(div).height(), toolbar: false });
    graph.render( id );

});
