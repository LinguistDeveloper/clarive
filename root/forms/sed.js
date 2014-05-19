(function(params){
    var data = params.data || {};
    var sl = params.data.slurp=='on' ? true : false;
    var ta = Baseliner.cols_templates['textarea'];
    var slurp = new Ext.form.Checkbox({ name: 'slurp', checked: sl , fieldLabel: _("Slurp") });
    var item_mode = new Baseliner.ComboDouble({ 
        fieldLabel: _('Items Mode'), name:'items_mode', value: data.items_mode || 'all_files', 
        data: [ ['all_files',_('All files')], ['only_job_items',_('Job Items')] ]
    });

    return [
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 60, name: 'path', value: params.data.path }),
        slurp,
        item_mode,
        new Baseliner.MonoTextArea({ fieldLabel: _('Output Dir'), height: 40, name: 'output_dir', value: params.data.output_dir }),
        { xtype:'textfield', name:'suffix', value: data.suffix || '', fieldLabel: _('Suffix') },
        new Baseliner.GridEditor({
            fieldLabel: _('Tablas'),
            height: 300,
            name: 'tablas',
            records: data.tablas,
            preventMark: false,
            columns: [
                Ext.apply({ dataIndex:'maq', header: 'M&aacute;quina' }, ta() ),
                Ext.apply({ dataIndex:'port', header: 'Puerto (default: 1521)' }, ta() )
            ],
            viewConfig: { forceFit: true }
        }),

        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Patterns'), 
            name: 'patterns', 
            value: params.data.patterns,
            description:_('Patterns Regex'), 
            default_value:'s{}{}g' 
        }), 
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Includes'), 
            name: 'includes', 
            value: params.data.includes,
            description:_('Include Regex'), 
            default_value:'.*' 
        }), 
        new Baseliner.ArrayGrid({ 
            fieldLabel:_('Excludes'), 
            name: 'excludes', 
            value: params.data.excludes,
            description:_('Exclude Regex'), 
            default_value:'.*' 
        })
    ]
})

