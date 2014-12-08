(function(params){
    var foo = function(){
        Cla.ajax_json('/topic/topic_drop', params, function(res){
            if( res.targets ) {
                var win = new Cla.Window({
                    width: 800, height: 300, layout: 'form', 
                    bodyStyle: { 'background-color':'#fff', padding: '20px 20px 20px 20px', frame: false, border: false },
                    defaults: { anchor:'100%', padding: '5px 0 0 0' },
                    items:[ 
                       { border:false, html: String.format('<div id="boot" style="border:0"><h3>{0}</h3><hr /></div>', _('More than one field detected. Select target field from list:')) },
                       {
                            xtype: 'checkboxgroup',
                            fieldLabel: _('Available Fields'),
                            itemCls: 'x-check-group-alt',
                            columns: 1,
                            items: res.targets.map(function(f){ return { 
                                xtype:'radio', 
                                listeners:{ 'check':function(){ 
                                    win.close();
                                    params.selected_id_field = f.id_field;
                                    params.selected_mid = f.mid;
                                    foo();
                                } },
                                name: f.id_field + ',' + f.mid,
                                boxLabel: String.format('{0} (#{1} : {2})', f.name_field, f.mid, f.id_field) } 
                            })
                        }
                    ],
                    tbar: ['->', {text:_('Cancel'), icon: IC('cancel'), handler:function(){ win.close() } }]
                });
                win.show();
            } else {
                Cla.message(_('Drop'), res.msg);
            }
        });
    }
    foo();
})
