(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    ret.forEach(function(element) {
        // if(element.name == 'id_field'){
        //     element.value = 'status_new';
        //     element.readOnly = true;
        // }
        if(element.name == 'section'){
            element.value = 'details';
            element.readOnly = true;
        }
        if(element.name == 'hidden') { element.hide() };
        if(element.name == 'allowBlank') { element.hide() };
    });
    var checkbox_show_real_dates = new Baseliner.CBox({
        name: 'show_real_dates',
        checked: data && data[ 'show_real_dates' ]=='1'  ? true : false,
        default_value: true,
        anchor: '100%',
        width: '100%',
        // hideLabel: true,
        fieldLabel: _('Show real dates instead of "ago" format'),
        style: 'margin-bottom: 3px'
    });

    ret.push([
        checkbox_show_real_dates,
        { xtype:'hidden', name:'fieldletType', value: 'fieldlet.status_changes' } 
    ]);
    return ret;
})
