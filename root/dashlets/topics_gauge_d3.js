(function(params){ 
    var id = params.id_div;

    var categories = params.data.categories || [];
    var statuses = params.data.statuses || [];
    var not_in_status = params.data.not_in_status;
    var condition = params.data.condition || '';
    var days_from = params.data.days_from || 0;
    var days_until = params.data.days_until || 0;
    var date_field_start = params.data.date_field_start;
    var date_field_end = params.data.date_field_end;
    var numeric_field = params.data.numeric_field;
    var units = params.data.units;
    var input_units = params.data.input_units;
    var end_remaining = params.data.end_remaining;
    var columns = params.data.columns;

    var green = parseInt(params.data.green) || 10;
    var yellow = parseInt(params.data.yellow) || 20;

    Cla.ajax_json('/dashboard/topics_gauge', { input_units: input_units, end_remaining: end_remaining, units: units, numeric_field: numeric_field, days_from: days_from, days_until: days_until, date_field_start: date_field_start, date_field_end: date_field_end, condition: condition, not_in_status: not_in_status, categories: categories, statuses: statuses }, function(res){
        var needle_length = 0.85;
        var div = document.getElementById(id);
         if ( columns < 3 ) {
            div.style.height = "140px";
            needle_length = 0.6;
         } else if ( columns < 4 ) {
            div.style.height = "160px";
            needle_length = 0.7;
         } else if ( columns < 6 ) {
            div.style.height = "210px";
            needle_length = 0.8;
         }
        var maxValue;
        if ( res.max <= yellow ) {
            maxValue = yellow + green + ( (yellow + green) * 20 /100 );
        } else {
            maxValue = parseInt(res.max) + ( parseInt(res.max) * 20 / 100);
        }
        
       require(['d3'], function(d3){
         var gauge = function(container, configuration) {
             var that = {};
             var config = {
                 size                        : div.offsetWidth,
                 clipWidth                   : div.offsetWidth,
                 clipHeight                  : div.offsetHeight +20,
                 ringInset                   : 40,
                 ringWidth                   : 40,
                 
                 pointerWidth                : 6,
                 pointerTailLength           : 4,
                 pointerHeadLengthPercent    : needle_length,
                 
                 minValue                    : 0,
                 maxValue                    : maxValue,
                 
                 minAngle                    : -90,
                 maxAngle                    : 90,
                 
                 transitionMs                : 750,
                 
                 majorTicks                  : 3,
                 labelFormat                 : d3.format(',g'),
                 labelInset                  : 30,
                 
                 arcColorFn                  : d3.interpolateHsl(d3.rgb('#60B044'), d3.rgb('#FA5858'))
             };
             var range = undefined;
             var r = undefined;
             var pointerHeadLength = undefined;
             var value = 0;
             var innerRadius = undefined;
             var outerRadius = undefined;
             
             var svg = undefined;
             var arc = undefined;
             var scale = undefined;
             var ticks = undefined;
             var tickData = undefined;
             var pointer = undefined;

             var donut = d3.layout.pie();
             
             function deg2rad(deg) {
                 return deg * Math.PI / 180;
             }
             
             function newAngle(d) {
                 var ratio = scale(d);
                 var newAngle = config.minAngle + (ratio * range);
                 return newAngle;
             }
             
             function configure(configuration) {
                 var prop = undefined;
                 for ( prop in configuration ) {
                     config[prop] = configuration[prop];
                 }
                 
                 range = config.maxAngle - config.minAngle;
                 r = config.size / 2;
                 innerRadius = r - config.ringWidth - config.ringInset;
                 outerRadius = r - config.ringInset;
                 pointerHeadLength = Math.round(r * config.pointerHeadLengthPercent);

                 // a linear scale that maps domain values to a percent from 0..1
                 scale = d3.scale.linear()
                     .range([0,1])
                     .domain([config.minValue, config.maxValue]);
                     
                 if ( end_remaining == 'on' ) {
                     ticks = [0, yellow, green];//scale.ticks(config.majorTicks);
                     tickData = [1, green/maxValue, yellow/maxValue ];
                 } else {
                     ticks = [0,green,yellow];//scale.ticks(config.majorTicks);
                     tickData = [1, yellow/maxValue, green/maxValue];
                 }

                 // ticks = [0,green,yellow];//scale.ticks(config.majorTicks);
                 // tickData = [1, yellow/maxValue, green/maxValue];

                 var last = 0;
                 arc = d3.svg.arc()
                     .innerRadius(r - config.ringWidth - config.ringInset)
                     .outerRadius(r - config.ringInset)
                     .startAngle(function(d, i) {
                         return deg2rad(config.minAngle);
                     })
                     .endAngle(function(d, i) {
                         // console.log("Arc "+ d + " "+ i);
                         return deg2rad(config.minAngle + (d * range));
                     });
             }
             that.configure = configure;
             
             function centerTranslation() {
                 return 'translate('+r +','+ r +')';
             }
             
             function isRendered() {
                 return (svg !== undefined);
             }
             that.isRendered = isRendered;
             
             function render(newValue) {
                 svg = d3.select(container)
                     .append('svg:svg')
                         .attr('class', 'gauge')
                         .attr('width', config.clipWidth)
                         .attr('height', config.clipHeight);
                 
                 var centerTx = centerTranslation();
                 
                 var arcs = svg.append('g')
                         .attr('class', 'arc')
                         .attr('transform', centerTx);
                 
                 arcs.selectAll('path')
                         .data(tickData)
                     .enter().append('path')
                         .attr('fill', function(d, i) {
                            var colors = ['#FA5858','#F7D358','#60B044'  ];
                            if ( end_remaining == 'on') colors = colors.reverse();
                             return colors[i];
                         })
                         .attr('d', arc);

                 arcs.append("text")
                     .attr("class", 'c3-chart-arcs-gauge-unit')
                     .style("text-anchor", "middle")
                     .style("font-weight", "bold")
                     .style("font-size", "18px")
                     .style("pointer-events", "none");
                 arcs.append("text")
                     .attr("class", 'c3-chart-arcs-gauge-min')
                     .style("text-anchor", "middle")
                     .style("font-size", "10px")
                     .style("pointer-events", "none");
                 arcs.append("text")
                     .attr("class", 'c3-chart-arcs-gauge-max')
                     .style("text-anchor", "middle")
                     .style("font-size", "10px")
                     .style("pointer-events", "none");

                 arcs.select('.c3-chart-arcs-gauge-unit')
                     .attr("dy", ".75em")
                     .attr("dy", "2em")
                     .text(res.data[0][1] + ' ' + _(res.units) );
                 arcs.select('.c3-chart-arcs-gauge-min')
                     .attr("dx", -1 * (innerRadius + ((outerRadius - innerRadius) / 2)) + "px")
                     .attr("dy", "1.2em")
                     .text('0');
                 arcs.select('.c3-chart-arcs-gauge-max')
                     .attr("dx", innerRadius + ((outerRadius - innerRadius) / 2) + "px")
                     .attr("dy", "1.2em")
                     .text(res.max);

                 var lg = svg.append('g')
                         .attr('class', 'label')
                         .attr('transform', centerTx);
                 lg.selectAll('text')
                         .data(ticks)
                     .enter().append('text')
                         .attr('transform', function(d) {
                             var ratio = scale(d);
                             // alert(ratio);
                             var newAngle = config.minAngle + (ratio * range);
                             return 'rotate(' +newAngle +') translate(0,' +(config.labelInset - r) +')';
                         })
                         .text(config.labelFormat);

                 var lineData = [ [config.pointerWidth / 2, 0], 
                                 [0, -pointerHeadLength],
                                 [-(config.pointerWidth / 2), 0],
                                 [0, config.pointerTailLength],
                                 [config.pointerWidth / 2, 0] ];
                 var pointerLine = d3.svg.line().interpolate('monotone');
                 var pg = svg.append('g').data([lineData])
                         .attr('class', 'pointer')
                         .attr('transform', centerTx);
                         
                 pointer = pg.append('path')
                     .attr('d', pointerLine/*function(d) { return pointerLine(d) +'Z';}*/ )
                     .attr('transform', 'rotate(' +config.minAngle +')');
                 
                 update(newValue === undefined ? 0 : newValue);
             }
             that.render = render;
             
             function update(newValue, newConfiguration) {
                 if ( newConfiguration  !== undefined) {
                     configure(newConfiguration);
                 }
                 var ratio = scale(newValue);
                 var newAngle = config.minAngle + (ratio * range);
                 pointer.transition()
                     .duration(config.transitionMs)
                     .ease('elastic')
                     .attr('transform', 'rotate(' +newAngle +')');
             }
             that.update = update;

             configure(configuration);
             
             return that;
         };

         div.innerHTML = "";
         var powerGauge = gauge('#'+id, {
             size: div.offsetWidth,
             // clipWidth: 300,
             // clipHeight: 300,
             ringWidth: 60,
             maxValue: maxValue,
             transitionMs: 4000,
         });
         powerGauge.render();
         powerGauge.update(res.data[0][1]);
       }); 
    });
});