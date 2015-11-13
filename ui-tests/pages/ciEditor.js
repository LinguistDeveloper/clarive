var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        saveBtn: '.ui-comp-ci-editor-save button',
        closeBtn: '.ui-comp-ci-editor-close button'
    }
};
