(function(params){
    if( !params.rec ) params.rec = {};

    var contents = new Baseliner.CIGrid({ 
        fieldLabel:_('Contents'), ci: { 'class': 'project' },
        anchor:'100%',
        height: 500,
        value: params.rec.contents, name: 'contents' });
    
    return [
        { xtype:'cbox', name: 'parallel', fieldLabel:_('Parallel?'), checked: params.rec.parallel == '1' ? true : false },
        contents
    ]
})


