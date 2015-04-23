(function(params){ 
    var id = params.id_div;  // id of the target div

    var gd = function(year, month, day) {
        return new Date(year, month, day).getTime();
    }

     var lineFit = function(points){
        sI = slopeAndIntercept(points);
        if (sI){
          // we have slope/intercept, get points on fit line
          var N = points.length;
          var rV = [];
          rV.push([points[0][0], sI.slope * points[0][0] + sI.intercept]);
          rV.push([points[N-1][0], sI.slope * points[N-1][0] + sI.intercept]);
          return rV;
        }
        return [];
      }

      // simple linear regression
      var slopeAndIntercept = function(points){
        var rV = {},
            N = points.length,
            sumX = 0, 
            sumY = 0,
            sumXx = 0,
            sumYy = 0,
            sumXy = 0;

        // can't fit with 0 or 1 point
        if (N < 2){
          return rV;
        }    

        for (var i = 0; i < N; i++){
          var x = points[i][0],
              y = points[i][1];
          sumX += x;
          sumY += y;
          sumXx += (x*x);
          sumYy += (y*y);
          sumXy += (x*y);
        }

        // calc slope and intercept
        rV['slope'] = ((N * sumXy) - (sumX * sumY)) / (N * sumXx - (sumX*sumX));
        rV['intercept'] = (sumY - rV['slope'] * sumX) / N;
        rV['rSquared'] = Math.abs((rV['slope'] * (sumXy - (sumX * sumY) / N)) / (sumYy - ((sumY * sumY) / N)));

        return rV;
      }


    var data0 = [];
    var data1 = [];
    var ticks = [];
    Cla.ajax_json('/job/burndown', params.data, function(res){
        for( var k in res.data0 ) {
            // if( k==0 || k==23 )   // FIXME fake trendline
                data0.push([ k,res.data0[k] ]);
        };
        for( var k in res.data1 ) {
            data1.push([k,res.data1[k] ]);
        };
        var trend = data0 ; // not working, 23h point is superlow lineFit( data0 );
        for( var i=0; i<24; i++ ) {
            //var hr = ( i>11 ? (i-12)+'pm' : i+'am' );
            ticks.push([i,i+'h']); 
        }
         
        $.plot( $('#'+id), [
                {
                    data: trend,
                    label: _('Jobs last %1', params.data.days_avg),
                    lines: { show: true}
                },
                {
                    data: data1,
                    label: _('Jobs last %1', params.data.days_last),
                    lines: { show: true}
                }
            ],
            {
                legend: { show: true },
                xaxis: { 
                    ticks: ticks,
                    axisLabelUseCanvas: true,
                    labelAngle: -90
                }
            }
        );
         

    });
});

