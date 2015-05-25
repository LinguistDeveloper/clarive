(function(params){ 
    var id = params.id_div;
    var meta = params.data;
    var limit = meta.limit;
    require(['/site/swarm.js?'+Math.random()], function(res){
        var div = document.getElementById(id);
        div.innerHTML = '';
        var config = Ext.apply({ limit: limit, start_mode: 'auto', height: div.offsetHeight, width: div.offsetWidth, renderTo: id }, meta);
        var swarm = new Cla.Swarm(config);
    });
});

