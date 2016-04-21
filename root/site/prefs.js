Baseliner.Prefs = Ext.extend(Ext.util.Observable, {
    js_date_format: _('js_date_format'),
    js_dt_format: _('js_dt_format'),
    js_dtd_format: _('js_dtd_format'),
    is_logged_in: true,
    toolbar_height: 28,
    constructor: function(config) {
        if (!config) {
            config = {};
        }

        config.site = Ext.apply({
            show_menu: true,
            show_dashboard: true,
            show_lifecycle: true,
            show_tabs: true,
            show_search: true
        }, config.site);

        if (config.df == 'js_date_format') {
            config.df = 'Y-M-d';
        }

        if (config.site_raw) {
            Ext.apply(config.site, {
                show_tabs: false,
                show_portal: false,
                show_menu: false,
                show_main: false
            });
        }
        Ext.apply(this,
            Ext.apply({}, config)
        );

        Baseliner.Prefs.superclass.constructor.call(this, config);
    },
    load: function() {
        var self = this;
        Baseliner.ci_call('user', 'prefs_load', {
            _res_key: 'data'
        }, function(res) {
            Ext.apply(self, res.data);
        });
    },
    save: function() {
        var self = this;
        var prefs = {
            site: self.site,
            stash: self.stash,
            js_date_format: self.js_date_format
        };
        Baseliner.ci_call('user', 'prefs_save', {
            prefs: prefs
        }, function(res) {
            Baseliner.message(_('Preferences'), _('Saved ok'));
        });
    },
    open_editor: function(opts) {
        if (!opts) {
            opts = {};
        }
        var upload = new Ext.Container();
        var username = opts.username;
        var avatar_username = username || Prefs.username;
        var img_id = Ext.id();
        var reload_avatar_img = function() {

            var el = Ext.get(img_id);
            var rnd = Math.floor(Math.random() * 80000);
            el.dom.src = '/user/avatar/' + avatar_username + '/image.png?' + rnd;
        };
        upload.on('afterrender', function() {
            var uploader = uploader_avatar(upload, avatar_username, img_id, opts);
        });
        var gen_avatar = function() {
            Baseliner.ajaxEval('/user/avatar_refresh/' + avatar_username, {}, function(res) {
                Baseliner.message(_('Avatar'), res.msg);
                reload_avatar_img();
                if (opts.on_save) {
                    opts.on_save({});
                }
            });
        };
        var rnd = Math.floor(Math.random() * 80000);
        Baseliner.ajaxEval('/user/user_data', {
            username: username
        }, function(res) {
            if (!res.success) {
                Baseliner.error(_('User data'), res.msg);
                return;
            }
            var img = String.format('<img width="32" id="{0}" style="border: 2px solid #bbb" src="/user/avatar/' + avatar_username + '/image.png?{1}" />', img_id, rnd);
            var api_key = res.data.api_key;
            var default_dashboard = res.data.dashboard;
            var gen_apikey = function() {
                Baseliner.ci_call('user', 'save_api_key', {
                    for_username: username
                }, function(res) {
                    Baseliner.message(_('API Key'), res.msg);
                    if (res.success) {
                        api_key_field.setValue(res.api_key);
                    }
                });
            };
            var save_apikey = function() {
                Baseliner.ci_call('user', 'save_api_key', {
                    api_key_param: api_key_field.getValue()
                }, function(res) {
                    Baseliner.message(_('API Key'), res.msg);
                });
            };
            var api_key_field = new Ext.form.TextArea({
                fieldLabel: _('API Key'),
                value: api_key,
            });

            var data_language = language_prefs(res, Prefs);
            var language = data_language.language;
            var language_pref = data_language.language_pref;

            var date_format = date_prefs(res, Prefs);
            var time_format = time_prefs(res, Prefs);


            Baseliner.ajaxEval('/user/timezone_list', {}, function(timezone_list) {

                var timezone = timezone_prefs(res, Prefs, timezone_list);

                var dashboard = new Baseliner.DashboardBox({
                    fieldLabel: _('Default Dashboard'),
                    name: 'dashboard',
                    singleMode: true,
                    allowBlank: true,
                    baseParams: {
                        username: true
                    },
                    value: default_dashboard
                });

                Baseliner.ajaxEval('/user/country_info', {}, function(countries_list) {
                    var data_country = country_prefs(res, Prefs, countries_list);
                    var country = data_country.country;
                    var currency = data_country.currency;
                    var decimal = data_country.decimal;

                    var change_dashboard_form = prefs_form(language, timezone, country, currency, decimal, date_format, time_format, dashboard, username, Prefs, language_pref, opts);


                    var preftabs = tabs_prefs(change_dashboard_form, img, gen_avatar, upload, api_key_field, gen_apikey);
                    var win = window_prefs(username, preftabs);
                    win.show();
                });
            });
        });
    }
});


function uploader_avatar(upload, avatar_username, img_id, opts) {
    var uploader = new qq.FileUploader({
        element: upload.el.dom,
        action: '/user/avatar_upload/' + avatar_username,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
        template: '<div class="qq-uploader">' +
            '<div class="qq-upload-drop-area"><span>' + _('Drop files here to upload') + '</span></div>' +
            '<div class="qq-upload-button">' + _('Upload File') + '</div>' +
            '<ul class="qq-upload-list"></ul>' +
            '</div>',
        onComplete: function(fu, filename, res) {


            Baseliner.message(_('Upload File'), _(res.msg, filename));

            var el = Ext.get(img_id);
            var rnd = Math.floor(Math.random() * 80000);
            el.dom.src = '/user/avatar/' + avatar_username + '/image.png?' + rnd;
            if (opts.on_save) {
                opts.on_save({});
            }
        },
        onSubmit: function(id, filename) {

        },
        onProgress: function(id, filename, loaded, total) {},
        onCancel: function(id, filename) {},
        classes: {

            button: 'qq-upload-button',
            drop: 'qq-upload-drop-area',
            dropActive: 'qq-upload-drop-area-active',
            list: 'qq-upload-list',

            file: 'qq-upload-file',
            spinner: 'qq-upload-spinner',
            size: 'qq-upload-size',
            cancel: 'qq-upload-cancel',


            success: 'qq-upload-success',
            fail: 'qq-upload-fail'
        }
    });
    return uploader;
}

function language_prefs(res, Prefs) {
    var language_pref = res.data.language_pref;
    var data_language = {};
    var installed_languages = res.languages;
    var lang_arr = [];

    for (var ln in installed_languages) {
        var lang_name = installed_languages[ln];
        lang_arr.push([ln, _(lang_name) || _(ln)]);
    }
    lang_arr = lang_arr.sort(function(a, b) {
        return a[1].toUpperCase() > b[1].toUpperCase() ? 1 : b[1].toUpperCase() > a[1].toUpperCase() ? -1 : 0;
    });

    var language = new Baseliner.ComboDouble({
        fieldLabel: _('Interface Language'),
        name: 'language_pref',
        value: language_pref || Prefs.language || 'en',
        data: lang_arr.length ? lang_arr : [
            ['en', _('English')],
            ['es', _('Spanish')]
        ]
    });
    data_language["language"] = language;
    data_language["language_pref"] = language_pref;
    return data_language;

}

function date_prefs(res, Prefs) {
    var date_formats = [
        ['format_from_local', _('Default Format for Current Language')],
        ['DD-MM-YY'],
        ['DD-MM-YYYY'],
        ['YY-MM-DD'],
        ['YYYY-MM-DD'],
        ['MM/DD/YY'],
        ['MM/DD/YYYY'],
        ['DD/MM/YY'],
        ['DD/MM/YYYY'],
        ['l'],
        ['L'],
        ['ll'],
        ['LL'],
        ['lll'],
        ['LLL'],
        ['LLLL'],
        ['llll']
    ].map(function(row) {
        row[1] = row[0] == 'format_from_local' ?
            moment().format(_('momentjs_date_format')) + ' (' + row[1] + ')' :
            moment().format(row[0]) + ' (' + row[0] + ')';
        return row;
    });

    var date_format = new Baseliner.ComboDouble({
        fieldLabel: _('Date Format'),
        name: 'date_format_pref',
        value: res.data.date_format_pref || Prefs.date_format || 'format_from_local',
        data: date_formats
    });
    return date_format;
}

function time_prefs(res, Prefs) {
    var time_formats = [
        ['format_from_local', _('Default Format for Current Language')],
        ['H:mm'],
        ['HH:mm'],
        ['h:mma'],
        ['hh:mma']
    ].map(function(row) {
        row[1] = row[0] == 'format_from_local' ?
            moment().format(_('momentjs_time_format')) + ' (' + row[1] + ')' :
            moment().format(row[0]) + ' (' + row[0] + ')';
        return row;
    });
    var time_format = new Baseliner.ComboDouble({
        fieldLabel: _('Time Format'),
        name: 'time_format_pref',
        value: res.data.time_format_pref || Prefs.time_format || 'format_from_local',
        data: time_formats
    });
    return time_format;
}

function timezone_prefs(res, Prefs, timezone_list) {
    var timezone = new Baseliner.ComboDouble({
        fieldLabel: _('Timezone'),
        name: 'timezone_pref',
        value: res.data.timezone_pref || Prefs.timezone || 'server_timezone',
        data: [
            ['server_timezone', _('Server Timezone (%1)', Prefs.server_timezone)],
            ['browser_timezone', _('My Browser Timezone (now is %1)', moment(Date().now).format('h:mma'))]
        ].concat(timezone_list.data.map(function(tz) {
            tz[1] = String.format(_("{0} (now is {1})"), tz[0], moment(Date().now).tz(tz[0]).format('h:mma'));
            return tz;
        }))
    });
    return timezone;
}

function country_prefs(res, Prefs, countries_list) {
    var data_country = {};
    var country = new Baseliner.ComboDouble({
        fieldLabel: _('Country'),
        name: 'country',
        value: res.data.country || Prefs.country || 'es',
        data: (countries_list.data.map(function(c) {
            return c;
        }))
    });

    country.on('select', function(cb, rec, index) {
        currency.setValue(rec.json[2]);
        decimal.setValue(rec.json[3]);
    });
    var currency = new Ext.form.Hidden({
        name: 'currency',
        value: ''
    });
    var decimal = new Ext.form.Hidden({
        name: 'decimal',
        value: ''
    });
    data_country["currency"] = currency;
    data_country["decimal"] = decimal;
    data_country["country"] = country;
    return data_country;

}

function prefs_form(language, timezone, country, currency, decimal, date_format, time_format, dashboard, username, Prefs, language_pref, opts) {
    var change_dashboard_form = new Cla.FormPanel({
        frame: false,
        border: false,
        labelWidth: 150,
        timeout: 120,
        items: [
            language,
            timezone,
            country,
            currency,
            decimal, {
                xtype: 'panel',
                layout: 'form',
                border: false,
                bodyStyle: 'margin-top: 5px',
                fieldLabel: _('Current Browser Timezone'),
                html: _('<b>%1</b>', Cla.timezone_str())
            }, {
                xtype: 'panel',
                layout: 'form',
                border: false,
                bodyStyle: 'margin-top: 5px;margin-bottom: 6px',
                fieldLabel: _('Current Server Timezone'),
                html: _('<b>%1</b>', Prefs.server_timezone)
            },
            date_format,
            time_format,
            dashboard
        ],
        buttons: [{
            text: username ? _('Save %1', username) : _('Save'),
            handler: function() {
                var form = change_dashboard_form.getForm();
                if (form.isValid()) {
                    var form_data = change_dashboard_form.getValues() || {};
                    Prefs.date_format = date_format.get_save_data();
                    Prefs.time_format = time_format.get_save_data();
                    Prefs.timezone = timezone.get_save_data();
                    Prefs.country = country.get_save_data();
                    Prefs.currency = currency.getValue();
                    Prefs.decimal = decimal.getValue();
                    Baseliner.ci_call('user', 'general_prefs_save', {
                        data: form_data,
                        for_username: username
                    }, function(res) {
                        Cla.message(_('Save'), _('General Preferences Saved'));
                        if (!username && language.getValue() != language_pref) {
                            Cla.confirm(_('To reflect language changes you need to reload the page. Do you want to do that now?'),
                                function() {
                                    window.location.href = window.location.href;
                                });
                        }
                        if (opts.on_save) {
                            opts.on_save(res);
                        }
                    }, function(res) {
                        Cla.error(_('Error'), _('Could not save general preferences: %1', res.msg));
                    });
                }
            }
        }]
    });
    return change_dashboard_form;
}

function tabs_prefs(change_dashboard_form, img, gen_avatar, upload, api_key_field, gen_apikey, save_apikey) {
    var preftabs = new Ext.TabPanel({
        activeTab: 0,
        plugins: [new Ext.ux.panel.DraggableTabs()],
        items: [{
            xtype: 'panel',
            layout: 'form',
            frame: false,
            border: false,
            title: _('General'),
            bodyStyle: {
                'background-color': '#fff',
                padding: '10px 10px 10px 10px'
            },
            items: [
                change_dashboard_form
            ]
        }, {
            xtype: 'panel',
            layout: 'form',
            frame: false,
            border: false,
            title: _('Avatar'),
            cls: 'avatar_tab',
            bodyStyle: {
                'background-color': '#fff',
                padding: '15px 10px 10px 10px'
            },
            items: [{
                xtype: 'container',
                fieldLabel: _('Current avatar'),
                html: img
            }, {
                xtype: 'button',
                width: 80,
                fieldLabel: _('Change avatar'),
                scale: 'large',
                text: _('Change Avatar'),
                handler: gen_avatar
            }, {
                xtype: 'container',
                cls:'upload_avatar',
                fieldLabel: _('Upload avatar'),
                items: [upload]
            }]
        }, {
            title: _('API'),
            cls: 'api_tab',
            layout: 'form',
            frame: false,
            border: false,
            bodyStyle: {
                'background-color': '#fff',
                padding: '7px 10px 10px 10px'
            },
            items: [
                api_key_field, {
                    xtype: 'button',
                    fieldLabel: _('Generate API Key'),
                    width: 150,
                    scale: 'large',
                    text: _('Generate API Key'),
                    handler: gen_apikey
                }, {
                    xtype: 'button',
                    fieldLabel: _('Save API Key'),
                    width: 150,
                    scale: 'large',
                    text: _('Save Current API Key'),
                    handler: save_apikey
                }
            ]
        }]
    });
    return preftabs;
}

function window_prefs(username, preftabs) {
    var win = new Baseliner.Window({
        title: username ? _('Preferences for %1', username) : _('Preferences'),
        layout: 'fit',
        width: 650,
        height: 380,
        cls: 'prefs_window',
        items: [preftabs]
    });
    return win;
}
