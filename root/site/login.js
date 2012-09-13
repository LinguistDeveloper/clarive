Ext.onReady(function(){
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    Ext.QuickTips.init();

    var after_login = "<% $c->stash->{after_login} %>";
    var after_login_query = "<% $c->stash->{after_login_query} %>";
    Ext.Ajax.timeout = 60000;

    Baseliner.doLoginForm = function(){
                                /* 
                                    Another way of getting the query:
                                    var getParams = document.URL.split("?");
                                    var tab_params = {};
                                    if( getParams!=undefined && getParams[1] !=undefined ) {
                                        tab_params = Ext.urlDecode(getParams[1]);
                                    }
                                */
                                var ff = login_form.getForm();
                                ff.submit({
                                    success: function(form, action) {
                                                    var last_login = form.findField('login').getValue();
                                                    Baseliner.cookie.set( 'last_login', last_login ); 
                                                    if( after_login_query.length > 0 ) {
                                                        after_login = after_login + '?' + after_login_query;
                                                    }
                                                    document.location.href = after_login || '/';
                                             },
                                    failure: function(form, action) {
                                                    Ext.Msg.alert('<% _loc('Login Failed') %>', action.result.msg );
	                                                login_form.getForm().findField('login').focus('',100);
                                                    //login_form.getForm().findField('password').getValue() == ''
	                                                //	? login_form.getForm().findField('login').focus('',100)
                                                    //	: login_form.getForm().findField('password').focus('',100);
                                              }
                                });
                           };

    var login_form = new Ext.FormPanel({
            id: 'lf',
            url: '/login',
            frame: true,
            bodyStyle:'padding:5px 5px 0',
            cls: 'centered',
            defaults: { width: 150 },
            buttons: [
                { text: '<% _loc('Login') %>',
                  handler: Baseliner.doLoginForm
                },
                { text: '<% _loc('Reset') %>',
                  handler: function() {
                                login_form.getForm().findField('login').focus('',100);
                                login_form.getForm().reset()
                           }
                }
            ],
            items: [
                {  xtype: 'textfield', name: 'login', width: "100%", fieldLabel: "<% _loc('Username') %>", selectOnFocus: true }, 
                {  xtype: 'textfield', name: 'password', width: "100%", inputType:'password', fieldLabel: "<% _loc('Password') %>", selectOnFocus: true} 
            ]
        });

     var map = new Ext.KeyMap(document, [{
            key : [10, 13],
            fn : Baseliner.doLoginForm
        }]); 

     var last_login = Baseliner.cookie.get( 'last_login'); 

     setTimeout(function(){
        Ext.get('bali-loading').remove();
        login_form.render( document.body );
         if( last_login!=undefined && last_login.length > 0 )  {
                login_form.getForm().findField('login').setValue( last_login );
                login_form.getForm().findField('password').focus('',100);
         } else {
                login_form.getForm().findField('login').focus('',100);
         }

        Ext.get('bali-loading-mask').fadeOut({ remove: true });
     }, 400);
     
});

