(function(params){ 
    var id = params.id_div;

    var url = params.data.url || '';
    var height = parseInt(params.data.rows)*350;

    var div = document.getElementById(id);
    var html = "<iframe iframe_zoom='0.5' style='width:100%;height:"+height+"px;' src='"+url+"'/>";
    div.innerHTML = html;
});
