(function(params) {
    if (!params.rec) params.rec = {};

    Cla.help_push({
        title: _('Labels'),
        path: 'admin/labels'
    });

    var DEFAULT_COLOR = '#000000';

    var store = new Baseliner.Topic.StoreLabel();

    var addBtn = new Baseliner.Grid.Buttons.Add({
        handler: function() {
            addEdit(_('Create Label'), 'add', {});
        }
    });

    var editBtn = new Ext.Toolbar.Button({
        text: _('Edit'),
        disabled: true,
        icon: '/static/images/icons/edit.svg',
        cls: 'x-btn-text-icon',
        handler: function() {
            Ext.each(checkSm.getSelections(), function(row) {
                if (row.data.id) {
                    addEdit(_('Edit Label'), 'update', row.data);
                }
            });

        }
    });

    var deleteBtn = new Ext.Toolbar.Button({
        text: _('Delete'),
        icon: '/static/images/icons/delete.svg',
        cls: 'x-btn-text-icon',
        disabled: true,
        handler: function() {
            Ext.Msg.confirm(_('Confirmation'), _('Are you sure you want to delete the labels selected?'),
                function(btn) {
                    if (btn == 'yes') {
                        var labelsChecked = [];
                        checkSm.each(function(rec) {
                            labelsChecked.push(rec.get('id'));
                        });

                        Baseliner.ajaxEval('/label/delete', {
                                ids: labelsChecked
                            },
                            function(response) {
                                if (response.success) {
                                    Baseliner.message(_('Success'), response.msg);
                                    deleteBtn.disable();
                                    store.load();
                                } else {
                                    Baseliner.message(_('ERROR'), response.msg);
                                }
                            }

                        );
                    }
                });
        }
    });

    var blankImage = new Ext.BoxComponent({
        autoEl: {
            tag: 'img',
            src: Ext.BLANK_IMAGE_URL
        }
    });

    var tbar = new Ext.Toolbar({
        items: [
            blankImage,
            addBtn,
            editBtn,
            deleteBtn,
            '->'
        ]
    });

    var renderColor = function(value, meta, rec, rowIndex, colIndex, store) {
        return "<div width='15' style='border:1px solid #cccccc;background-color:" + value + "'>&nbsp;</div>";
    };

    var checkSm = new Ext.grid.CheckboxSelectionModel({
        singleSelect: false,
        sortable: false,
        checkOnly: true
    });

    checkSm.on('selectionchange', function() {
        var labelsSelected = 0;
        Ext.each(checkSm.getSelections(), function(r) {
            if (r.data.id) {
                ++labelsSelected;
            }
        });
        if (labelsSelected > 0) {
            deleteBtn.enable();
        } else {
            deleteBtn.disable();
        }
        if (labelsSelected == 1) {
            editBtn.enable();
        } else {
            editBtn.disable();
        }
    });

    var grid = new Ext.grid.GridPanel({
        renderTo: 'main-panel',
        sm: checkSm,
        height: 800,
        autoScroll: true,
        stripeRows: true,
        enableHdMenu: false,
        store: store,
        cls: 'topic_admin_grids',
        viewConfig: {
            forceFit: true,
            scrollOffset: 2
        },
        selModel: new Ext.grid.RowSelectionModel({
            singleSelect: true
        }),
        loadMask: true,
        columns: [{
                hidden: true,
                dataIndex: 'id'
            },
            checkSm, {
                header: _('Color'),
                dataIndex: 'color',
                width: 7,
                sortable: false,
                renderer: renderColor
            }, {
                header: _('Label'),
                dataIndex: 'name',
                sortable: true
            }, {
                header: _('Sequence'),
                dataIndex: 'seq',
                sortable: true
            }, {
                hidden: true,
                dataIndex: 'active'
            }
        ],
        autoSizeColumns: true,
        deferredRender: true,
        tbar: tbar
    });

    grid.on('celldblclick', function(grid, rowIndex, columnIndex, e) {
        if (columnIndex != 1) {
            var data = grid.store.data.items[rowIndex].json;

            addEdit(_('Edit Label'), 'update', data);
        }
    });

    var addEdit = function(title, action, row) {
        var selectedColor = new Ext.form.Hidden({
            name: 'color'
        });
        selectedColor.setValue(row.color ? row.color : DEFAULT_COLOR);
        var color = row.color ? row.color : DEFAULT_COLOR;

        var colorPick = new Ext.ColorPalette({
            value: color,
            colors: [
                '000000', '8E44AD', '30BED0', 'A01515', 'A83030', '003366', '000080', '333399',
                '800000', 'FF6600', '808000', '008000', '008080', '0000FF', '666699', '808080',
                'FF0000', 'FF9900', '99CC00', '339966', '33CCCC', '3366FF', '800080', '969696',
                'FF00FF', 'FFCC00', 'F1C40F', '00ACFF', '20BCFF', '00CCFF', '993366', 'C0C0C0',
                'FF99CC', 'DDAA55', 'BBBB77', '88CC88', 'D35400', '99CCFF', 'CC99FF', '11B411',
                '1ABC9C', '16A085', '2ECC71', '27AE60', '3498DB', '2980B9', 'E74C3C', 'C0392B'
            ]
        });
        var cl;
        colorPick.on('select', function(pal, color) {
            cl = '#' + color.toLowerCase();
            selectedColor.setRawValue(cl);
            colorButton.setText(colorBtnGen(cl));
        });

        var colorBtnGen = function(color) {
            return String.format('<div id="boot" style="margin-top: -3px; background: transparent"><span class="label" style="background: {0}">{1}</span></div>',
                color, color || DEFAULT_COLOR);
        };
        var colorButton = new Ext.Button({
            text: colorBtnGen(color),
            fieldLabel: _('Pick a Color'),
            height: 30,
            autoWidth: true,
            menu: {
                items: [colorPick]
            }
        });
        var nameBox = new Ext.form.TextField({
            fieldLabel: _('Name'),
            name: 'name',
            width: '120',
            value: _(row.name),
            vtype: 'labelName',
            allowBlank: false
        });
        var sequenceBox = new Ext.form.TextField({
            fieldLabel: _('Sequence'),
            name: 'seq',
            width: '120',
            value: row.seq || 0,
            allowBlank: false,
            vtype: 'labelSeq'
        });

        var win = new Baseliner.Window({
            title: title,
            name: 'edit_window',
            closeAction: 'destroy',
            resizable: false,
            maximizable: false,
            width: 340,
            layout: {
                type: 'table',
                columns: 3
            },
            items: [{
                id: 'labelForm',
                xtype: 'form',
                labelAlign: 'right',
                padding: 50,
                trackResetOnLoad: true,
                items: [{
                        xtype: 'hidden',
                        name: 'id',
                        value: row.id
                    },
                    selectedColor,
                    nameBox, {
                        xtype: 'tbspacer',
                        height: 10,
                        colspan: 3
                    },
                    colorButton, {
                        xtype: 'tbspacer',
                        height: 10,
                        colspan: 3

                    },
                    sequenceBox
                ]
            }],
            buttons: [{
                text: _('Close'),
                icon: '/static/images/icons/close.svg',
                handler: function() {
                    win.destroy();
                }
            }, {
                id: 'btn_save',
                text: _('Save'),
                icon: '/static/images/icons/action_save.svg',
                handler: function() {
                    var form = Ext.getCmp('labelForm').getForm();

                    if (action == 'add') {
                        form.url = '/label/update?action=add';
                    } else if (action == 'update') {
                        form.url = '/label/update?action=update';
                    }

                    form.submit({
                        success: function(form, action) {
                            store.reload();
                            win.close();
                        },
                        failure: function(form, action) {}
                    });
                }
            }]
        });

        win.show();
    }

    store.load();

    return grid;
});