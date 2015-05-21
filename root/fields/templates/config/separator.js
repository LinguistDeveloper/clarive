(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    


    var selected_color = new Ext.form.Hidden({ name:'color' });
    selected_color.setValue(data.color ? data.color : '#999');
    var color = data.color ? data.color : '';

    var color_pick = new Ext.ColorPalette({ 
        value: color, 
        colors: [
            '8E44AD', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399', '333333',
            '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
            'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
            'FF00FF', 'FFCC00', 'F1C40F', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
            'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'D35400', '99CCFF', 'CC99FF', '11B411',
            '1ABC9C', '16A085', '2ECC71', '27AE60', '3498DB', '2980B9', 'E74C3C', 'C0392B'
        ]
    });
    var cl;
    color_pick.on('select', function(pal,color){
        cl = '#' + color.toLowerCase();
        selected_color.setRawValue( cl ); 
        color_button.setText( color_btn_gen(cl) );
    });
    
    var color_btn_gen = function(color){
        return String.format('<div id="boot" style="margin-top: -3px; background: transparent"><span class="label" style="background: {0}">{1}</span></div>', 
            color, cl || '#999' );
    };
    var color_button = new Ext.Button({ 
        text: color_btn_gen( color ), 
        fieldLabel: _('Pick a Color'),
        height: 30,
        menu: { items: [color_pick] }
    });
    




    ret.push([ 
    	{ xtype:'hidden', name:'fieldletType', value: 'fieldlet.separator' },
    	color_button,
    	selected_color 
    ]);
    return ret;
})
