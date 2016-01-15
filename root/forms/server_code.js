(function(params){
    var data = params.data || {};
    
    var lang_combo = new Baseliner.ComboDouble({ 
        fieldLabel: _('Language'), name:'lang', value: data.lang || 'js', data: [
            ['js',_('JavaScript')],
            ['perl',_('Perl')]
        ]
    });

    var code = new Baseliner.AceEditor({
        fieldLabel:_('Code'), anchor:'100%', height: 500, name:'code', value: data.code, mode: 'javascript'
    });
    
    lang_combo.on('select',function(){
        var lang = lang_combo.getValue() == 'perl' ? 'perl' : 'javascript';
        code.editor.getSession().setMode("ace/mode/" + lang);
    });
    return [
        lang_combo,
        code
    ]
})
