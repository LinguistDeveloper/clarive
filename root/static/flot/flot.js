/**
 * @class Ext.FlotPanel
 */

Ext.namespace("Ext.FlotPanel"); 

Ext.FlotPanel = Ext.extend(Ext.Panel, {

	initComponent : function(){
		Ext.FlotPanel.superclass.initComponent.apply(this, arguments);
		this.addEvents(
			"plotclick",
			"plotselected",
			"plothover"
		);
		this.cmpId = 'placeholder'+this.id;
		
		// adjust height
		this.on('render', function(panel){
			// getInnerHeight() doesn't work in onRender method. (It returns 1)
			var height = panel.getInnerHeight()-panel.getFrameHeight();			
			$("#"+this.cmpId).height(height);

			if(this.data){
				this.plot(this.data, this.options);
			}
		});
	},
	
	onRender : function(){
		Ext.FlotPanel.superclass.onRender.apply(this, arguments);
		
		this.body.createChild({
			id: this.cmpId,
			style: 'width:'+this.width+'px; height:'+this.height+'px;'
		});
		
		// binding flot events to this class 
		
	    var fe = this.fireEvent.createDelegate(this);
	    
	    $("#"+this.cmpId).unbind();
	    
		$("#"+this.cmpId).bind("plotclick", function (event, pos, item) {
			fe("plotclick", event, pos, item);
		});

		$("#"+this.cmpId).bind("plotselected", function (event, ranges) {			
			fe("plotselected", event, ranges);
		});
		
		$("#"+this.cmpId).bind("plothover", function (event, pos, item) {			
			fe("plothover", event, pos, item);
		});
	},

	// wrapping float API
	
	plot: function(data, options){
		this.plotObj = $.plot($("#"+this.cmpId), data, options);
	},
	
	clearSelection: function(){
		this.plotObj.clearSelection();	
	},
	
	setSelection: function(ranges, preventEvent){
		this.plotObj.setSelection(ranges, preventEvent);
	},
	
	highlight: function(series, datapoint){
		this.plotObj.highlight(series, datapoint);
	},

	unhighlight: function(series, datapoint){
		this.plotObj.unhighlight(series, datapoint);
	},
	
	setData: function(data){
		this.plotObj.setData(data);	
	},
	
	setupGrid: function(){
		this.plotObj.setupGrid();
	},
	
	draw: function(){
		this.plotObj.draw();
	},
	
	getData: function(){
		this.plotObj.setData();
	},
	
	getAxes: function(){
		this.plotObj.getAxes();
	},
	
	getCanvas: function(){
		this.plotObj.getCanvas();
	},
	
	getPlotOffset: function(){
		this.plotObj.getPlotOffset();
	}
		
});

Ext.reg("flotpanel", Ext.FlotPanel);
