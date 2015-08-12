/*

   Baseliner.Calendar - fullcalendar Panel wrapper

   var cal = new Baseliner.Calendar({
        width: 999, height: 999, ...            // panel config
        fullCalendarConfig: {  ... }            // fullcalendar object config
   });

   cal.fullCalendar('renderEvent', { ... } );
  
   Docs: http://arshaw.com/fullcalendar/docs/usage/

*/ 
Baseliner.Calendar = Ext.extend( Ext.Panel, {
    layout: 'fit',
    bar_where: 'top',
    show_jobs: 1,
    query_type: 'start_end',
    default_view: 'month',
    initComponent: function(){
        var self = this;
        var cal_div = new Ext.Container({
           style: { padding: '10px' },
           autoScroll: true
        });
        var cal;
        var tbarr = [
              { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/arrow_left.gif', handler:function(){ 
                  cal.fullCalendar("prev"); 
                  load_cal_events();
              }},
              { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/arrow_right.gif', handler:function(){ 
                  cal.fullCalendar("next"); 
                  load_cal_events();
              }},
              '-',
              { xtype:'button', text:_('Today'), icon: IC('calendar'),
                  handler:function(){ cal.fullCalendar("today"); load_cal_events() } },
              '-',
              { xtype:'button', text:_('Day1'), allowDepress: false, pressed:self.default_view=='basicDay', toggleGroup:'cal-view',
                      handler:function(){ cal.fullCalendar("changeView", "basicDay") } } ,
              { xtype:'button', text:_('Day2'), allowDepress: false, pressed:self.default_view=='agendaDay', toggleGroup:'cal-view',
                      handler:function(){ cal.fullCalendar("changeView", "agendaDay") } } ,
              { xtype:'button', text:_('Week1'), allowDepress: false, pressed:self.default_view=='basicWeek', toggleGroup:'cal-view',
                      handler:function(){ cal.fullCalendar("changeView", "basicWeek") } } ,
              { xtype:'button', text:_('Week2'), allowDepress: false, pressed:self.default_view=='agendaWeek', toggleGroup:'cal-view',
                      handler:function(){ cal.fullCalendar("changeView", "agendaWeek") } } ,
              { xtype:'button', text:_('Month'), allowDepress: false, pressed:self.default_view=='month', toggleGroup:'cal-view', 
                      handler:function(){ cal.fullCalendar("changeView", "month") } } ,
              '-',
              { xtype:'button', iconCls:'x-btn-icon', icon:'/static/images/icons/refresh.png', handler:function(){ 
                    // cal.fullCalendar("refetchEvents") 
                    // refresh: delete everything and start over
                    load_cal_events();
               } }
        ];

        if( this.tbar_end ) tbarr.push( this.tbar_end );
        if( self.bar_where=='top' ) this.tbar = tbarr; 
        else this.bbar=tbarr;
        this.items = [cal_div];

        Baseliner.Calendar.superclass.initComponent.call(this);

        self.on('show', function(){
            load_cal_events();
        });

        var load_cal_events = function(){
            if( !cal ) return;
            cal.fullCalendar("removeEvents") ;
            var view = cal.fullCalendar('getView');
            Cla.ajax_json( '/calendar/events', { 
                    start: moment(view.start).format(), end: moment(view.end).format(), 
                    id_project: self.id_project, topic_mid: self.topic_mid, 
                    label_mask: self.label_mask, query_type: self.query_type,
                    categories: self.categories, show_jobs: self.show_jobs, id_fieldlet: self.id_fieldlet }, 
              function(res){
                Ext.each( res.events, function(ev){
                    cal.fullCalendar('renderEvent',
                        {
                            title: ev.title,
                            mid  : ev.mid,
                            topic_color : ev.topic_color,
                            acronym     : ev.acronym,
                            color: ev.color,
                            start: ev.start,
                            end: ev.end,
                            allDay: ev.allDay
                        }, true 
                    );
                });
                Ext.each( res.warnings,function(warn){
                    Baseliner.warning( _('Calendar'), warn );
                });

            });
        };
        
        cal_div.on('afterrender', function(){
            var date = new Date();
            var d = date.getDate();
            var m = date.getMonth();
            var y = date.getFullYear();
            var el = cal_div.getEl() ;
            var id = el.id ;
            var dt = new Baseliner.DropTarget(el, {
                comp: cal_div,
                ddGroup: 'explorer_dd',
                copy: true,
                notifyEnter: function(ddSource, ev, data) {
                    var el = ddSource.getProxy().getGhost();

                    $(el.dom).data('eventObject', data );
                    var id = el.id;
                    //$( el.dom ).css( 'background-color', 'green' );
                    $( el.dom ).draggable({
                        addClasses: true,
                        zIndex: 999
                        //revert: true,      // will cause the event to go back to its
                        //revertDuration: 0  //  original position after the drag
                    });
                    self.calendar.getView().dragStart(el.dom, ev.browserEvent, null);
                    return true;              
                },
                notifyDrop: function(ddSource, ev, data) {
                    var el = ddSource.getProxy().getGhost();
                    // get drag object data (node or row grid are supported for now)
                    var calev; 
                    if( data.grid != undefined ) {
                        var row = data.grid.getStore().getAt( data.rowIndex );
                        calev = row.data.calevent != undefined ? row.data.calevent : row.data;
                    }
                    else if( data.node!=undefined && data.node.attributes!=undefined ) {
                        calev = data.node.attributes.calevent != undefined 
                            ? data.node.attributes.calevent : data.node.attributes;
                    }
                    else {
                        Baseliner.message( _('Calendar'), _('Calendar object type not allowed') );
                        return false;
                    } 
                    ev.browserEvent.data = calev;   // store the row data in the event hack
                    self.calendar.getView().dragStop(el.dom, ev.browserEvent, null);  // call the original end of drag event
                    return true;
                }
            });

            var event_new_url = this.url_new || '/calendar/event/add';  // this should be the controller that creates events
            var event_new = function( data ) {
                Baseliner.ajaxEval( event_new_url, data, function(res) { 
                    if( res && res.success ) {
                        //var allday = res.allday!=undefined ? res.allday : true;
                        var title = data.text;
                        // create the event
                        var tn = data.topic_name || {};
                        cal.fullCalendar('renderEvent',
                            Ext.apply({
                                title: _('%1 #%2', tn.category_name, tn.mid),
                                mid: tn.mid,
                                color: tn.category_color
                                //start: date,
                                //end: date,
                                //allDay: allday
                            }, Ext.apply(data, res.data ) ),
                            true 
                        );
                    } else {
                        Baseliner.error( _('Error'), _(res.msg) );
                    }
                });
            };

            cal = $( el.dom );
            cal.fullCalendar( Ext.apply({
                header: false,
                timeFormat: 'H(:mm)',
                dayNames: [_('Sunday'), _('Monday'), _('Tuesday'), _('Wednesday'), _('Thursday'), _('Friday'), _('Saturday')],
                dayNamesShort: [_('Sun'), _('Mon'), _('Tue'), _('Wed'), _('Thu'), _('Fri'), _('Sat')],
                selectable: true,
                selectHelper: true,
                drop: function( date, allday, jsEvent, ui  ) {
                     var opts = jsEvent.data;
                     opts.date = date;
                     opts.allday = allday;
                     event_new( opts );
                },
                eventResizeStop: function( ev, jsEvent, ui, view ) { 
                    //Baseliner.ajaxEval( '/calendar/event/modify', ev, function(res) { });
                },
                eventClick: function(calEvent, jsEvent, view) {
                    Cla.show_topic_colored( calEvent.mid, calEvent.acronym, calEvent.topic_color );
                },
                select: function(start, end, allday) {
                    if( self.onSelect ) {
                        self.onSelect( cal, start, end, allday );
                    }
                    cal.fullCalendar('unselect');
                },
                editable: true,
                events: []
            }, self.fullCalendarConfig ));
            self.calendar = cal.data('fullCalendar'); // new Calendar() in fullcalendar
            load_cal_events();
            cal.fullCalendar("changeView", self.default_view);
        });
        self.on('resize', function(w,w1,h1,w2,h2) { 
          if( cal == undefined ) return;
          cal.fullCalendar('option', 'height', h1 - 80);
          cal.fullCalendar('option', 'width', w1);
          cal.fullCalendar("render");
        });
    },
    fullCalendar : function( p ) {
        return cal.fullCalendar( p );
    }
});

Baseliner.calendar_events = function( start, end, cb ) {
   /* Baseliner.ajaxEval('/events.js', { start: start, end: end }, function(res){
        cb( res.data ); 
   }); */
};


