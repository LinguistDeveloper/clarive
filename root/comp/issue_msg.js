<%perl>
    use Baseliner::Utils;
    my $iid = "div-" . _nowstamp;
</%perl>

<style type="text/css">
    #tabla2{
    border: 1px solid #165480;
    width: 100%;
    background-color: #e6e6e6;
    }
    #cabtab2{
    background-color: #5fa6d7;
    font-weight: bold;
    font-size: 8pt;
    padding: 2 2 2 2px;
    }
    #cuerpotab2{
    font-size: 8pt;
    padding: 4 4 4 4px;
    background-color: #ffffcc;
    }
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

    //var init_buttons = function(action) {
    //        var obj_btn = Ext.getCmp('btn_add');
    //        obj_btn.disable();
    //        obj_btn = Ext.getCmp('btn_edit');
    //        obj_btn.disable();
    //        obj_btn = Ext.getCmp('btn_delete');
    //        obj_btn.disable();
    //        obj_btn = Ext.getCmp('btn_close');
    //        obj_btn.disable();
    //}

    var id_rel = '<% $c->stash->{id_rel} %>' ;
    store_issue_comments.load({ params: {id_rel: id_rel} });

    Ext.onReady(function(){
        //init_buttons();

        //var data = {
        //        title: '<% $c->stash->{title} %>',
        //        description: '<% $c->stash->{description} %>'
        //};
        //
        //var tpl1 = new Ext.XTemplate(
        //    '<div id=tabla2>',
        //    '<div id=cabtab2>',
        //    '{title}',
        //    '</div>',
        //    '<div id=cuerpotab2>', 
        //    '{description}',  
        //    '</div>',  
        //    '</div>' 
        //);
        //tpl1.overwrite('zz<% $iid %>', data);

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
            frame:true,
            layout:'fit',
            items: new Ext.DataView({
                store: store_issue_comments,
                tpl: tpl
            })
        });

        //var panel1 = new Ext.Panel({
        //    frame:true,
        //    layout:'fit',
        //    data: data,
        //    tpl: tpl1
        //});
        
        panel.render('prueba<% $iid %>');
        //panel1.render('zz<% $iid %>');

    });
</script>  

<div id=tabla2>
<div id=cabtab2>
<% $c->stash->{title} %>
</div>
<div id=cuerpotab2>
<% $c->stash->{description} %>
</div>
</div>

<div class="divContainerMain" id='prueba<% $iid %>'></div>
