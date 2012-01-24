<%perl>
    use Baseliner::Utils;
    my $iid = "div-" . _nowstamp;
</%perl>

<style type="text/css">
    .calloutUp  
    {  
    height: 0;  
    width: 0;  
    border-bottom: 12px solid #ffffff;  
    border-left: 12px dotted transparent;  
    border-right: 12px dotted transparent;  
    left: 0px;  
    top: 0px;  
    margin-left: 20px;  
    z-index: 10;  
    }  
    .calloutUp2  
    {  
    position: relative;  
    left: -10px;  
    top: 2px;  
    height: 0;  
    width: 0;  
    border-bottom: 10px solid #ccc;  
    border-left: 10px dotted transparent;  
    border-right: 10px dotted transparent;  
    z-index: 11;  
    }  
    .divContainerUp  
    {  
    background-color: #ccc;  
    border: solid 1px #ffffff;  
    position: relative;  
    top: -1px;  
    z-index: 9;  
    width: 500px;  
    padding: 4px;  
    }  
    .divContainerMain  
    {  
    background-color: #e6e6e6;
    padding: 8px;
    overflow: auto;
    height: 100%;
    }  
</style>

<script>
    var store_issue_comments = new Ext.data.JsonStore({
    root: 'data' , 
    remoteSort: true,
    totalProperty:"totalCount", 
    url: '/issue/viewdetail',
    fields: [
        {name: 'created_by'},
        {name: 'text' },
        ]
    });

var init_buttons = function(action) {
        var obj_btn = Ext.getCmp('btn_add');
        obj_btn.disable();
        obj_btn = Ext.getCmp('btn_edit');
        obj_btn.disable();
        obj_btn = Ext.getCmp('btn_delete');
        obj_btn.disable();
        obj_btn = Ext.getCmp('btn_close');
        obj_btn.disable();
}

var id_rel = '<% $c->stash->{id_rel} %>' ;
store_issue_comments.load({ params: {id_rel: id_rel} });

Ext.onReady(function(){
    init_buttons();
   
    //var data = {
    //    name: 'Jack Slocum',
    //    company: 'Ext JS, LLC',
    //    address: '4 Red Bulls Drive',
    //    city: 'Cleveland',
    //    state: 'Ohio',
    //    zip: '44102',
    //    kids: [{
    //        name: 'Sara Grace',
    //        age:3
    //    },{
    //        name: 'Zachary',
    //        age:2
    //    },{
    //        name: 'John James',
    //        age:0
    //    }]
    //};


    //var tpl = new Ext.Template(
    //    '<p>Name: {created_by}</p>',
    //    '<p>Company: {text}</p>'        
    //);

        //'<div class="thumb-wrap">{created_by}</div>',

var tpl = new Ext.XTemplate(
    '<tpl for=".">',
        '<div style="margin-left: 40px;">',
        '<div>',
        '<br />',
        '{created_by} commented:',
        '</div>', 
        '<div class="calloutUp">',  
        '<div class="calloutUp2"></div>',  
        '</div>', 
        '<div class="divContainerUp">',  
        '{text}',
        '<br />',  
        '<br />',
        '</div>',
        '</div>',        
    '</tpl>',
    '<div class="x-clear"></div>'
);   

var panel = new Ext.Panel({
    id:'images-view',
    frame:true,
    layout:'fit',

    items: new Ext.DataView({
    store: store_issue_comments,
    tpl: tpl
    }),
});

panel.render('prueba<% $iid %>');

    //var p = new Ext.Panel({
    //    title: 'Basic Template',
    //    width: 300,
    //    html: '<p><i>Apply the template to see results here</i></p>',
    //    tbar: [{
    //        text: 'Apply Template',
    //        handler: function(){
    //
    //
    //
    //            tpl.overwrite(p.body, store_issue_comments);
    //            p.body.highlight('#c3daf9', {block:true});
    //        }
    //    }],
    //
    //    renderTo: 'prueba<% $iid %>'
    //});
});
</script>  

<div class="divContainerMain" id='prueba<% $iid %>'></div>
