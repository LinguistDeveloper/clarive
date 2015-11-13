var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        createBtn: '.ui-comp-ci-create button'
    }
};
