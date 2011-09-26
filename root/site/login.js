Ext.onReady(function(){
	Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
	Ext.QuickTips.init();

	var after_login = "<% $c->stash->{after_login} %>";
	Ext.Ajax.timeout = 60000;

    Baseliner.doLoginForm = function(){
                                var ff = login_form.getForm();
                                ff.submit({
                                    success: function(form, action) {
                                                    var last_login = form.findField('login').getValue();
                                                    Baseliner.cookie.set( 'last_login', last_login ); 
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
            url: '/login',
			id: 'lf',
            frame: true,
            labelWidth: 60, 
			renderTo: document.body,
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

     if( last_login!=undefined && last_login.length > 0 )  {
            login_form.getForm().findField('login').setValue( last_login );
            login_form.getForm().findField('password').focus('',100);
     } else {
            login_form.getForm().findField('login').focus('',100);
     }
});

