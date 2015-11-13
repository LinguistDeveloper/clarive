var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        save: '.ui-comp-role-edit-save button',
        close: '.ui-comp-role-edit-close button'
    }
};
