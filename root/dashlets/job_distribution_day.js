(function(params){ 
    var id = params.id_div;

    var graph_jobs_burndown_day;
    var graph_type = params.data.type || 'area';
    var joined = params.data.joined || '0';
    var stacked = false;
    if ( graph_type.startsWith('stack-') ) {
        graph_type = graph_type.replace('stack-','');
        stacked = true;
    }
    var period = params.data.period || '1Y';
    var bls = params.data.bls;

    Cla.ajax_json('/job/burndown_new', { joined: joined, bls: bls, period: period }, function(res){
        var groups = new Array();
        console.dir(res);
        if ( stacked ) {
            groups = [res.group];
        }else{
            groups= []
        }
        require(['d3','c3'], function(d3,c3){
           graph_jobs_burndown_day = c3.generate({
                bindto: '#'+id,
                data: {
                    x: 'x',
                    columns: res.data,
                    type: graph_type,
                    groups: groups
                },
                bar: {
                    width: {
                        ratio: 0.4 // this makes bar width 50% of length between ticks
                    }
                    // or
                    //width: 100 // this makes bar width 100px
                },
                grid: {
                    x: {
                        show: true
                    },
                    y: {
                        show: true
                    }
                },
                axis: {
                    x: {
                        type: 'category',
                        tick: {
                            multiline: false
                        }
                    },
                    y: {
                      label: {
                        text: '# jobs ',
                        position: 'outer-middle'
                      }
                    }
                },
                tooltip: {
                   grouped: false // Default true
                },
                regions: [
                    {axis: 'x', start: 8, end: 18, class: 'workhours'}
                ],
                point: {
                    show: false
                }
           });
        });
    });
});