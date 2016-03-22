(function(params){
    var config = params.data;
    var fields = [ {name:'date'} ];
    Ext.each( config.bl, function(bl){
        fields.push({ name:bl });
    });
    var store = new Baseliner.JsonStore({
        root: 'data' , 
        remoteSort: true,
        totalProperty: 'totalCount', 
        baseParams: Ext.apply({ project_id: params.project_id, topic_mid: params.topic_mid },config),
        id: 'id', 
        url: '/dashboard/roadmap',
        fields: fields 
    });

    var color_index = 0;
    var all_colors = [
        '8E44AD', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399', '333333',
        '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
        'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
        'FF00FF', 'FFCC00', 'F1C40F', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
        'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'D35400', '99CCFF', 'CC99FF', '11B411',
        '1ABC9C', '16A085', '2ECC71', '27AE60', '3498DB', '2980B9', 'E74C3C', 'C0392B'
    ];
    function getRandomColor() {
        var letters = '0123456789ABCDEF'.split('');
        var color = '#';
        for (var i = 0; i < 6; i++ ) {
            color += letters[Math.floor(Math.random() * 16)];
        }
        return color;
    }
    
    var hcolor={};
    var render_topic = function(value,meta,rec,rowIndex,colIndex,store) {
        var cell_color, cell_text;
        if( !value.length ) {
            //cell_color = '#eee';
            cell_text = '';
        } else {
            var first_mid;
            cell_text = '';
            var width=value.length>0?100/value.length:0;
            for( var i=0; i<value.length; i++ ) {
                var topic = value[i].topic;
                var cal   = value[i].cal;
                var label = value[i].label;
                var acronym   = value[i].acronym;
                if( first_mid == undefined ) first_mid = topic.mid;
                if( !hcolor[topic.mid] ) hcolor[topic.mid] = '#'+all_colors[ color_index++ ];
                if( color_index >= 64 ) color_index = 0;
                var topic_name = label ? label : String.format('<b>{2}#{0}</b> {1}', topic.mid, topic.title, acronym );
                cell_text += String.format(
                        '<td width="{7}%" class="truncate roadmap-cell-div" onclick="javascript:Cla.show_topic_colored(\'{0}\',\'{5}\',\'{6}\');return false;"'
                        + 'style="cursor: pointer; padding: 4px 4px 4px 4px; font-size: .9em; color:{2}; background-color: {3}" mid="{0}">{1}</td>', 
                        topic.mid, topic_name, '#fff', hcolor[topic.mid], acronym, topic.category.name, topic.category.color, width );
            }
            cell_color = hcolor[first_mid];
        }

        /* meta.style += cell_color!=undefined 
                ? 'line-height:20px; color: #fff; background-color: '+ cell_color
                : 'line-height:20px; color: #fff';  */
        meta.style += 'line-height:20px; color: #fff'; 
        return cell_text ? '<table width="100%" border=0 style="margin-bottom: -2px; margin-top: -2px; margin-left: -2px, margin-right: -2px"><tr>'+cell_text+'</tr></table>' : ''; 
    }

    var render_date = function(value,meta,rec,rowIndex,colIndex,store) {
        meta.style += 'font-weight: bold;';
        if(rec.data.is_current) meta.style += 'background-color: yellow;';
        return moment(value).format('YYYY-MM-DD');
    }

    var cols = [
        { header: _('Week'), width: 25, dataIndex: 'date', sortable: false, menuDisabled: true, renderer: render_date }
    ];
    Ext.each( config.bl, function(bl){
        cols.push({ header: _(bl), width: 60, dataIndex: bl, sortable: false, menuDisabled: true, renderer: render_topic });
    });
    var grid = new Ext.grid.GridPanel({
        header: false,
        cls: 'roadmap-grid',
        bodyCls: 'roadmap-grid',
        autoScroll: true,
        autoWidth: true,
        stripeRows: true,
        columnLines: true,
        store: store,
        viewConfig: { scrollOffset: 2, forceFit: true },
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask  : {
                msg : '<div class="ext-el-mask-msg"><center><img src="/static/images/loading.gif" alt="loading" style="display: block;height:40px;width:40px;"></center></div>'
            },
             columns: cols 
    });

    store.load();
    return grid
})
