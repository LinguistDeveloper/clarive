(function(params){
    var data = params.data || {};
    var sl = params.data.slurp=='on' ? true : false
    var slurp = new Ext.form.Checkbox({ name: 'slurp', checked: sl , fieldLabel: _("Slurp") });
    return [
        new Baseliner.MonoTextArea({ fieldLabel: _('Path'), height: 60, name: 'path', value: params.data.path }),
        slurp,
        new Baseliner.MonoTextArea({ fieldLabel: _('Output Dir'), height: 40, name: 'output_dir', value: params.data.output_dir }),
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

