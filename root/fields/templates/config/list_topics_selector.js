(function(params){
    var data = params.data || {};
    var ret = Baseliner.generic_fields(data);
    var value_type = Baseliner.generic_list_fields(data);
    var ccategory = new Baseliner.CategoryBox({ name: 'categories', fieldLabel: _('Select topics in categories'), value: data.categories || ''  });
    Cla.help_push({ title:_('Topic Selector'), path:'rules/palette/fieldlets/topic-selector' });
    var cstatus = new Baseliner.StatusBox({ name: 'statuses', fieldLabel: _('Select topics in statuses'), value: data.statuses || ''});

    ret.push([
        ccategory,
        cstatus,
        { xtype : "checkbox", name : "not_in_status", checked: data.not_in_status=='on' ? true : false, boxLabel : _('Exclude selected statuses?') },
        value_type
    ]);

    var combo_datatable = new Baseliner.ComboDouble({
        name: 'datatable',
        editable: false,
        fieldLabel: _('Table format?'),
        emptyText: _('Select one'),
        data:[ 
            [ 'always', _('Always') ],
            [ 'paging', _('Only if paging') ],
            [ 'never', _('Never') ],
        ],
        value: /paging|always|never/.test(data.datatable) ? data.datatable : 'paging'
    });

    var filter_field_box = new Ext.form.TextField({
        name: 'filter_field',
        xtype: "textfield",
        fieldLabel: _('Filter field'),
        value: data.filter_field,
        allowBlank : true,
        listeners: {
            'change': function(obj){
                if(this.getValue().length == 0 && filter_data_box.getValue().length == 0){
                    filter_data_box.allowBlank = true;
                    this.allowBlank = true;
                }else{
                    filter_data_box.allowBlank = false;
                    this.allowBlank = false;
                }
            }
        }

    });

    var filter_data_box = new Ext.form.TextField({
        name: 'filter_data',
        xtype: "textfield",
        fieldLabel: _('Filter data'),
        value: data.filter_data,
        allowBlank : true,
        listeners: {
            'change': function(obj){
                if(this.getValue().length == 0 && filter_field_box.getValue().length == 0){
                    filter_field_box.allowBlank = true;
                    this.allowBlank = true;
                }else{
                    filter_field_box.allowBlank = false;
                    this.allowBlank = false;
                }
            }
        }
    });

    var combo_paging = new Baseliner.ComboSingle({
        name: 'paging_datatable',
        fieldLabel: _('Grid Page Size'),
        data:[10,20,25,50,100] ,
        value: data.paging_datatable || 10
    });

    ret.push([ 
        { xtype:'textfield', fieldLabel: _('List of columns to show in grid'), name: 'columns', value: data.columns },
        { xtype:'numberfield', fieldLabel: _('Height of grid in edit mode'), name: 'height', fieldClass: "x-fieldlet-type-height", minValue:'1', value: data.height || 250 },
        { xtype:'numberfield', name:'page_size', fieldLabel: _('Page size'), value: data.page_size || 20},
        { xtype:'textfield', name:'parent_field', fieldLabel: _('Parent field'), value: data.parent_field },
        filter_field_box,
        filter_data_box,
        combo_paging,
        combo_datatable,
        { xtype:'textfield', fieldLabel: _('Sort By'), name: 'sort', value:data.sort},
        new Baseliner.ComboSingle({ forceSelection: true, allowBlank: false, fieldLabel: _('Sort Order'), editable: false, name: 'dir', value: data.dir || '', data: [
                    [_('DESC')],
                    [_('ASC')]
                  ] 
        })
    ]);
    return ret;
})
