(function() {
  var active, ajax, button_activate, button_clear, button_disable, button_restore, button_save, code, dsl, form_dsl, id, is_active, modify_active, show_activate, show_disable, store_name, temp, textarea_code, toolbar_dsl;
  dsl = <% $dsl %>;
  code = <% $code %>;
  id = <% $id %>;
  active = <% $active %>;
  temp = code;
  ajax = new Ext.data.Connection();
  is_active = function() {
    if (active === 0) {
      return show_activate();
    } else {
      return show_disable();
    }
  };
  show_activate = function() {
    button_activate.show();
    button_disable.hide();
    return modify_active(0);
  };
  show_disable = function() {
    button_activate.hide();
    button_disable.show();
    return modify_active(1);
  };
  modify_active = function(value) {
    return ajax.request({
      url: '/chain/modify_active',
      method: 'POST',
      params: {
        value: value,
        id: id
      }
    });
  };
  button_clear = new Ext.Button({
    text: 'Clear',
    icon: '/static/images/icons/application.png',
    handler: function() {
      textarea_code.setValue('');
      return button_save.show();
    }
  });
  button_save = new Ext.Button({
    text: 'Save',
    icon: '/static/images/icons/application_edit.png',
    handler: function() {
      ajax.request({
        url: '/chain/save_dsl',
        method: 'POST',
        params: {
          dsl_code: textarea_code.getValue(),
          id: id
        }
      });
      this.hide();
      return temp = textarea_code.getValue();
    }
  });
  button_restore = new Ext.Button({
    text: 'Restore',
    icon: '/static/images/icons/arrow_undo.png',
    handler: function() {
      textarea_code.setValue(code);
      button_restore.hide();
      if (code === temp) {
        return button_save.hide();
      } else {
        button_save.show();
        return temp = code;
      }
    }
  });
  button_activate = new Ext.Button({
    text: 'Activate',
    icon: '/static/images/yes.png',
    handler: function() {
      return show_disable();
    }
  });
  button_disable = new Ext.Button({
    text: 'Disable',
    icon: '/static/images/no.png',
    handler: function() {
      return show_activate();
    }
  });
  toolbar_dsl = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_clear, button_save, button_restore, button_activate, button_disable]
  });
  textarea_code = new Ext.form.TextArea({
    hideLabel: true,
    style: "font-family:\"Courier New\"",
    width: 684,
    height: 314,
    value: code,
    enableKeyEvents: true,
    listeners: {
      keyup: function() {
        if (this.getValue() !== temp) {
          button_save.show();
        } else {
          button_save.hide();
        }
        if (this.getValue() === code) {
          return button_restore.hide();
        } else {
          return button_restore.show();
        }
      }
    }
  });
  form_dsl = new Ext.form.FormPanel({
    title: "DSL: " + dsl,
    items: [toolbar_dsl, textarea_code]
  });
  store_name = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    fields: [
      {
        name: 'dsl'
      }, {
        name: 'code'
      }
    ]
  });
  button_save.hide();
  button_restore.hide();
  is_active();
  return form_dsl;
  <%args>
  $dsl    => $ARGS{dsl}
  $code   => $ARGS{code}
  $id     => $ARGS{id}
  $active => $ARGS{active}
</%args> ;
}).call(this);
