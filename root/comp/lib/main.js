Baseliner.Grid = {};


Baseliner.Grid.Buttons = {};

Baseliner.Grid.Buttons.Add = Ext.extend( Ext.Toolbar.Button, {
	constructor: function(config) {
		config = Ext.apply({
			text: _('New'),
			icon:'/static/images/icons/add.gif',
			cls: 'x-btn-text-icon'
		}, config);
		Baseliner.Grid.Buttons.Add.superclass.constructor.call(this, config);
	}
});

Baseliner.Grid.Buttons.Edit = Ext.extend( Ext.Toolbar.Button, {
	constructor: function(config) {
		config = Ext.apply({
			text: _('Edit'),
			icon: '/static/images/icons/edit.gif',
			cls: 'x-btn-text-icon',
			disabled: true
		}, config);
		Baseliner.Grid.Buttons.Edit.superclass.constructor.call(this, config);
	}
});

Baseliner.Grid.Buttons.Delete = Ext.extend( Ext.Toolbar.Button, {
	constructor: function(config) {
		config = Ext.apply({
			text: _('Delete'),
			icon:'/static/images/icons/delete.gif',
			cls: 'x-btn-text-icon',
			disabled: true
		}, config);
		Baseliner.Grid.Buttons.Delete.superclass.constructor.call(this, config);
	}
});




