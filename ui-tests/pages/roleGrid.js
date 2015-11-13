var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        createBtn: '.ui-comp-role-create button'
    }
};
