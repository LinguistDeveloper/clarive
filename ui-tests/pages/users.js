var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        usersTab: '.ui-tab-users',
        createBtn: '.ui-comp-users-create button',
        editWindow: '.ui-comp-scheduler-edit-window',
        editWindowSaveBtn: '.ui-comp-users-edit-window-save button',
        editWindowCloseBtn: '.ui-comp-users-edit-window-close button',
    }
};
