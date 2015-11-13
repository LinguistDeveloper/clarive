var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        create: '.ui-comp-rule-create button'
    }
};
