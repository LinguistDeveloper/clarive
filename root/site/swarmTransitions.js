Cla.SwarmTransitions = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;
console.log('initComponent');
        Cla.SwarmTransitions.superclass.initComponent.call(this);
        
        self.on('afterrender', function(){
            self.init();
        });
    },
    init : function(){
        var self = this;
console.log('init');
        //var color = d3.scale.category10();
        
        var id = self.body.id; 
        var selector = '#' + id; 
 
        var image;
        var texto;

        self.array =  [
            { t:'1000', ev:'add', who:'pedro', node: '#43', parent:'Changeset' },
            { t:'2000', ev:'del', who:'pedro', node: '#43', parent:'Changeset' },
            { t:'3000', ev:'add', who:'tot', node: '#45', parent:'Changeset' },
            { t:'4000', ev:'del', who:'tot', node: '#45', parent:'Changeset' },
            { t:'5000', ev:'add', who:'carlos', node: '#46', parent:'Changeset' },
            { t:'6000', ev:'add', who:'diego', node: '#47', parent:'Changeset' },
            { t:'7000', ev:'add', who:'marco', node: '#48', parent:'Changeset' },
            { t:'8000', ev:'del', who:'marco', node: '#48', parent:'Changeset' },
            { t:'9000', ev:'add', who:'alex', node: '#49', parent:'Changeset' },
            { t:'10000', ev:'del', who:'alex', node: '#49', parent:'Changeset' },
            { t:'11000', ev:'add', who:'fran', node: '#50', parent:'Changeset' },
            { t:'12000', ev:'add', who:'pedro', node: '#51', parent:'Changeset' },
            { t:'13000', ev:'add', who:'ana', node: '#52', parent:'Changeset' }
        ];

        
       self.svg = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').call(d3.behavior.zoom().scaleExtent([1, 8])
        .on("zoom", function(){ self.zoom() }));
     ;
       
       for (i=0; i<13; i++){

        var randomValuex = Math.random()*100;
        var randomValuey = Math.random()*100;
        //alert (randomValuex);
        self.image = self.svg.append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20).attr("x", randomValuex).attr("y",randomValuey);
        self.texto = self.svg.append("text").attr("x", randomValuex).attr("y",randomValuey).text(self.array[i].who);
        self.image.transition().duration(1500).attr("x",randomValuex+150).attr("y",randomValuey+150);
        self.texto.transition().duration(1500).attr("x",randomValuex+150).attr("y",randomValuey+150);

        }
       
    },
    
    zoom : function() {
        
     alert("entra en rescale");
  var self = this;
  
  self.vis.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");
    }

});
