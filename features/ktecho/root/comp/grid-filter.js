(function() {
  var active, ajax, button_delete, button_refresh, button_show_active, button_show_all, button_view, column_active, column_description, column_step, column_todo, filter_id, form_filter, grid_filter, hide_show_active, hide_show_all, load_grid_store, render_active, show_all, store_grid_filter, toolbar_filter, view_dsl;
  show_all = 1;
  filter_id = '';
  active = '';
  ajax = new Ext.data.Connection();
  render_active = function(value, metadata, rec, rowIndex, colIndex, store) {
    var img;
    img = value === '1' ? 'yes.png' : 'no.png';
    return "<img alt='" + value + "' border=0 src='/static/images/" + img + "' />";
  };
  load_grid_store = function() {
    return store_grid_filter.load({
      params: {
        show_all: show_all,
        chain_id: <% $chain_id %>
      }
    });
  };
  view_dsl = function() {
    var comp_url, params, ptitle;
    comp_url = 'chain/view_dsl';
    ptitle = 'hello world';
    params = {
      id: filter_id,
      active: active
    };
    return Baseliner.addNewWindowComp(comp_url, ptitle, params);
  };
  hide_show_active = function() {
    button_show_active.hide();
    return button_show_all.show();
  };
  hide_show_all = function() {
    button_show_active.show();
    return button_show_all.hide();
  };
  button_show_active = new Ext.Button({
    text: 'Show active',
    icon: '/static/images/icons/arrow_redo.png',
    handler: function() {
      show_all = 0;
      load_grid_store();
      return hide_show_active();
    }
  });
  button_show_all = new Ext.Button({
    text: 'Show all',
    icon: '/static/images/icons/arrow_redo.png',
    handler: function() {
      show_all = 1;
      load_grid_store();
      return hide_show_all();
    }
  });
  button_delete = new Ext.Button({
    text: 'Delete',
    icon: '/static/images/icons/delete.png',
    handler: function() {
      return ajax.request({
        url: '/chain/delete_row',
        method: 'POST',
        params: {
          id: filter_id
        }
      });
    }
  });
  button_view = new Ext.Button({
    text: 'View',
    icon: '/static/images/values.png',
    handler: view_dsl
  });
  button_refresh = new Ext.Button({
    text: 'Refresh',
    icon: '/static/images/icons/arrow_refresh.png',
    handler: load_grid_store
  });
  toolbar_filter = new Ext.Toolbar({
    autoHeight: true,
    autoWidth: true,
    items: [button_show_active, button_show_all, button_delete, button_view, button_refresh]
  });
  column_todo = new Ext.grid.Column({
    header: 'Name',
    width: 120,
    sortable: true,
    dataIndex: 'name'
  });
  column_description = new Ext.grid.Column({
    header: 'Description',
    width: 120,
    sortable: true,
    dataIndex: 'description'
  });
  column_step = new Ext.grid.Column({
    header: 'Step',
    width: 120,
    sortable: true,
    dataIndex: 'step'
  });
  column_active = new Ext.grid.Column({
    header: 'Active?',
    width: 120,
    sortable: true,
    dataIndex: 'active',
    renderer: render_active
  });
  store_grid_filter = new Ext.data.JsonStore({
    root: 'data',
    remoteSort: true,
    totalProperty: 'totalCount',
    url: '/chain/data_grid_filter',
    fields: [
      {
        name: 'name'
      }, {
        name: 'description'
      }, {
        name: 'step'
      }, {
        name: 'active'
      }, {
        name: 'id'
      }
    ]
  });
  grid_filter = new Ext.grid.GridPanel({
    autoWidth: true,
    autoHeight: true,
    store: store_grid_filter,
    border: false,
    viewConfig: {
      forceFit: true
    },
    cm: new Ext.grid.ColumnModel([new Ext.grid.RowNumberer, column_todo, column_description, column_step, column_active])
  });
  grid_filter.on('rowclick', function(grid, rowIndex, e) {
    var row;
    row = grid.getStore().getAt(rowIndex);
    filter_id = row.get('id');
    return active = row.get('active');
  });
  grid_filter.on('dblclick', function() {
    return view_dsl();
  });
  form_filter = new Ext.form.FormPanel({
    title: 'Filter',
    items: [toolbar_filter, grid_filter]
  });
  load_grid_store();
  hide_show_all();
  return form_filter;
  <%args>
    $chain_id => $ARGS{id_chain}
</%args> ;
}).call(this);
