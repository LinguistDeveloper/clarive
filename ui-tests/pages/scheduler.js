var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        schedulerTab: '.ui-tab-scheduler',
        createBtn: '.ui-comp-scheduler-create button',
        editWindow: '.ui-comp-scheduler-edit-window',
        editWindowSaveBtn: '.ui-comp-scheduler-edit-window-save button',
        editWindowCloseBtn: '.ui-comp-scheduler-edit-window .x-tool-close',
        ruleInputInvalid: '.x-form-invalid input[name=id_rule]'
    }
};
