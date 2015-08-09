(function(params){ 
    var id = params.id_div;
    var project_id = params.project_id;
    var meta = params.data;

    require(['/site/swarm.js?'+Math.random()], function(res){
        var div = document.getElementById(id);
        div.innerHTML = '';
        var config = Ext.apply({ project_id: project_id, start_mode: 'auto', height: div.offsetHeight, width: div.offsetWidth, renderTo: id }, meta);
        var swarm = new Cla.Swarm(config);
    });
});

