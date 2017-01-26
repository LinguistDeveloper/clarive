define(function() {
    function build() {
        var rolesSelectionModel = new Ext.grid.CheckboxSelectionModel({
            singleSelect: false,
            sortable: false,
            checkOnly: true
        });

        var rolesStore = new Baseliner.JsonStore({
            root: 'data',
            remoteSort: true,
            totalProperty: "totalCount",
            autoLoad: true,
            id: 'id',
            url: '/role/json',
            fields: [{
                name: 'id'
            }, {
                name: 'role'
            }, {
                name: 'actions'
            }, {
                name: 'description'
            }, {
                name: 'mailbox'
            }]
        });

        var rolesGrid = new Ext.grid.GridPanel({
            title: _('Available Roles'),
            sm: rolesSelectionModel,
            store: rolesStore,
            stripeRows: true,
            autoScroll: true,
            autoWidth: true,
            autoSizeColumns: true,
            viewConfig: {
                forceFit: true
            },
            loadMask: true,
            columns: [
                rolesSelectionModel, {
                    hidden: true,
                    dataIndex: 'id'
                }, {
                    header: _('All'),
                    width: 250,
                    dataIndex: 'role',
                    sortable: true
                }
            ],
            getCheckedRoles: function() {
                var rolesChecked = [];

                rolesSelectionModel.each(function(record) {
                    rolesChecked.push(record.get('id'));
                });

                return rolesChecked;
            }
        });

        rolesGrid.on('rowclick', function(grid, rowIndex, columnIndex, e) {
            toggleButtons();
        });

        var treeRoot = new Ext.tree.AsyncTreeNode({
            text: _('All'),
            draggable: false,
            checked: false,
            id: 'All',
            iconCls: 'default_folders',
            data: {
                project: '',
                id_project: 'todos',
                parent_checked: ''
            }
        });

        var projectsTree = new Ext.tree.TreePanel({
            title: _('Available Projects'),
            dataUrl: "user/projects_list",
            split: true,
            colapsible: true,
            useArrows: true,
            ddGroup: 'secondGridDDGroup',
            animate: true,
            enableDrag: true,
            containerScroll: true,
            autoScroll: true,
            rootVisible: true,
            preloadChildren: true,
            root: treeRoot,
            getCheckedProjects: function() {
                var projectsChecked = [];

                Ext.each(projectsTree.getChecked(), function(node) {
                    if (node.attributes.leaf) {
                        projectsChecked.push(node.attributes.data.id_project);
                    } else {
                        if (node.childNodes.length > 0 || node.attributes.data.id_project == 'todos') {
                            projectsChecked.push(node.attributes.data.id_project);
                        }
                    }
                });

                return projectsChecked;
            }
        });

        projectsTree.getLoader().on("beforeload", function(treeLoader, node) {
            var loader = projectsTree.getLoader();
            loader.baseParams = node.attributes.data;
            loader.dataUrl = window.location.origin + "/" + projectsTree.dataUrl;
            node.attributes.data.parent_checked = (node.attributes.checked) ? 1 : 0;
        });

        projectsTree.on('checkchange', function(node, checked) {
            if (node != treeRoot) {
                if (node.attributes.checked == false) {
                    treeRoot.attributes.checked = false;
                    treeRoot.getUI().checkbox.checked = false;
                }
            }
            node.eachChild(function(n) {
                n.getUI().toggleCheck(checked);
            });

            toggleButtons();
        });

        function toggleRolesAndProjects(action, rolesChecked, projectsChecked) {
            rolesAndProjectsContainer.fireEvent('togglerolesprojects', action, rolesChecked, projectsChecked);
        }

        var assignRolesAndProjectsButton = new Ext.Toolbar.Button({
            text: _('Assign roles/projects'),
            icon: IC('key-add'),
            cls: 'x-btn-text-icon ui-comp-users-edit-window-assign-roles',
            disabled: true,
            handler: function() {
                var rolesChecked = rolesGrid.getCheckedRoles();
                var projectsChecked = projectsTree.getCheckedProjects();

                toggleRolesAndProjects('assign', rolesChecked, projectsChecked);
            }
        });

        var unassignRolesAndProjectsButton = new Ext.Toolbar.Button({
            text: _('Unassign roles/projects'),
            icon: IC('key-delete'),
            cls: 'x-btn-text-icon ui-comp-users-unassign-roles',
            disabled: true,
            handler: function() {
                var rolesChecked = rolesGrid.getCheckedRoles();
                var projectsChecked = projectsTree.getCheckedProjects();

                toggleRolesAndProjects('unassign', rolesChecked, projectsChecked);
            }
        });

        function toggleButtons() {
            var rolesSelected = rolesSelectionModel.getCount();
            var projectsSelected = projectsTree.getChecked().length;

            if (rolesSelected && projectsSelected) {
                unassignRolesAndProjectsButton.enable()
                assignRolesAndProjectsButton.enable();
            } else {
                unassignRolesAndProjectsButton.disable();
                assignRolesAndProjectsButton.disable();
            }
        }

        var rolesAndProjectsContainer = new Ext.Container({
            height: 180,
            split: true,
            region: 'north',
            layout: 'fit',
            items: [{
                layout: 'hbox',
                layoutConfig: {
                    align: 'stretch'
                },
                items: [{
                    layout: 'fit',
                    flex: 1,
                    items: rolesGrid
                }, {
                    layout: 'fit',
                    flex: 1,
                    items: projectsTree
                }],
                bbar: [
                    assignRolesAndProjectsButton,
                    unassignRolesAndProjectsButton
                ]
            }],
            enableAll: function() {
                rolesAndProjectsContainer.enable();
                rolesGrid.cascade(function(el) {
                    el.setDisabled(false);
                });
                projectsTree.cascade(function(el) {
                    el.setDisabled(false);
                });
            }
        });

        rolesAndProjectsContainer.disable();
        rolesGrid.cascade(function(el) {
            el.setDisabled(true);
        });
        projectsTree.cascade(function(el) {
            el.setDisabled(true);
        });

        return rolesAndProjectsContainer;
    }

    return {
        build: build
    }
});
