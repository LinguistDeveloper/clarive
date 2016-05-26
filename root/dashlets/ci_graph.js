(function(params){ 
    var data = params.data || {};
    var id = params.id_div;
    var project_id = params.project_id;
    var topic_mid = params.topic_mid;
    var graph;
    var mid = data.starting_mid;
    var context_override = data.context_override || 'context';
    if( context_override == 'context' ) {
        if( topic_mid != undefined ) mid = topic_mid
        else if( project_id != undefined ) mid = project_id;
    }

    var div = document.getElementById(id);
    div.style.clear = "left";

    if (mid == "") {
        mid = undefined;
    }

    if( mid ) {
        div.innerHTML = '';
        var graph = new Baseliner.CIGraph({
            mid: mid, 
            direction:'children', 
            depth: 3, 
            toolbar: data.toolbar_mode == 'hide' ? false : data.toolbar_mode,
            include_cl: data.include_cl,
            not_in_class: data.not_in_class,
            condition: data.condition,
            which: data.graph_type||'st', 
            height: $(div).height()
        });
        graph.render( id );
    } else {
        div.innerHTML = function(){/*
            <table style="height: 100%">
            <tr><td style="align: center">
            <div id="boot">
            <p><i>[CI Graph Error: Missing Starting Point MID]</i></p>
            </div>
            <td><tr>
            </table>
        */}.heredoc();
    }

});
