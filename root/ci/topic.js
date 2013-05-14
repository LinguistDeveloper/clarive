(function(params){
    return [
       { xtype:'button', fieldLabel: _('View'), text:_('View'), fieldWidth: 40, width: 40,
           handler:function(){
               Baseliner.add_tabcomp(
                   '/topic/view?topic_mid=' + params.mid + '&swEdit=0', params.title ,
                   { topic_mid: params.mid, title: params.title } );
           }
       },
       { xtype:'textfield', fieldLabel: _('Title'), name:'title', inputType:'title' }
    ]
})



