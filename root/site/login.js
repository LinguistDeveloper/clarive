Ext.onReady(function() {
    Ext.BLANK_IMAGE_URL = '/static/ext/resources/images/default/s.gif';
    Ext.QuickTips.init();

    var after_login = Base64.decode("<% Util->to_base64( $c->stash->{after_login}, '' ) %>");
    var after_login_query = Base64.decode("<% Util->to_base64( $c->stash->{after_login_query}, '' ) %>");

    var login_txt = '<% _loc("Login") %>';

    Baseliner.doLoginForm = function() {
        /*
            Another way of getting the query:
            var getParams = document.URL.split("?");
            var tab_params = {};
            if( getParams!=undefined && getParams[1] !=undefined ) {
                tab_params = Ext.urlDecode(getParams[1]);
            }
        */
        login_button.setText('<img src="/static/images/loading-fast.gif" />');
        login_button.disable();
        var ff = login_form.getForm();
        ff.submit({
            success: function(form, action) {
                var last_login = form.findField('login').getValue();
                Baseliner.cookie.set('last_login', last_login);
                if (after_login_query.length > 0) {
                    after_login = after_login + '?' + after_login_query;
                }
                document.location.href = after_login || '/';
            },
            failure: function(form, action) {
                login_button.setText(login_txt);
                login_button.enable();

                if (action.failureType == 'client') {
                    // This is a client error, do nothing, ExtJS will highlight errors with no problem
                } else if (action.result == undefined) {
                    var errorMask = Ext.fly(document.body).mask(_('Server communication failure. Check your connection.'));
                    errorMask.show();
                    setTimeout(function() {
                        Ext.fly(document.body).unmask();
                    }, 4000);
                } else if (action.result.attempts_duration && action.result.block_datetime != 0) {
                    var interval = action.result.attempts_duration * 100
                    Ext.Msg.show({
                        title: '<% _loc("Login Failed") %>',
                        msg: '<% _loc("Attempts exhausted, please wait") %>',
                        width: 300,
                        wait: true,
                        waitConfig: {
                            interval: interval
                        }
                    });
                    setTimeout(function() {
                        Ext.Msg.hide();
                    }, action.result.attempts_duration * 1000);
                } else {
                    login_form.getForm().findField('login').focus('', 100);
                }
            }
        });
    };

    var login_button = new Ext.Button({
        text: login_txt,
        handler: Baseliner.doLoginForm,
        cls: 'ui-button-login'
    });
    var login_form = new Ext.FormPanel({
        id: 'lf',
        url: '/login',
        frame: false,
        style: 'background: #d8d0e1',
        bodyStyle: 'padding:5px 5px 0; background: transparent',
        cls: 'centered',
        labelAlign: 'right',
        timeout: 120, // this is in seconds, give it 2 minutes in case there's a slow rule checking identity or something
        defaults: {
            msgTarget: 'under'
        },
        buttons: [
            login_button, {
                text: '<% _loc("Reset") %>',
                handler: function() {
                    login_form.getForm().findField('login').focus('', 100);
                    login_form.getForm().reset()
                }
            }
        ],
        items: [{
            xtype: 'textfield',
            name: 'login',
            width: "95%",
            fieldLabel: "<% _loc('Username') %>",
            selectOnFocus: true,
            allowBlank: false
        }, {
            xtype: 'textfield',
            name: 'password',
            width: "95%",
            inputType: 'password',
            fieldLabel: "<% _loc('Password') %>",
            selectOnFocus: true
        }]
    });

    var map = new Ext.KeyMap(document, [{
        key: [10, 13],
        fn: Baseliner.doLoginForm
    }]);

    var last_login = Baseliner.cookie.get('last_login');

    setTimeout(function() {
        Ext.get('bali-loading').remove();
        login_form.render(document.body);
        if (last_login != undefined && last_login.length > 0) {
            login_form.getForm().findField('login').setValue(last_login);
            login_form.getForm().findField('password').focus('', 100);
        } else {
            login_form.getForm().findField('login').focus('', 100);
        }

        Ext.get('bali-loading-mask').fadeOut({
            remove: true
        });
    }, 400);

});
