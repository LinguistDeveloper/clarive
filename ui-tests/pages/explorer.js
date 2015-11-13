var commands = {
    expandCI: function() {
        return this
          .click('@ciBtn')
          .waitForElementVisible('@CI', 5000)
          .click('@CI')
          ;
    }
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        ciBtn: '.ui-explorer-ci button',
        CI: '.ui-explorer-ci-CI img.x-tree-elbow-plus',
        bl: '.ui-explorer-ci-bl',
        project: '.ui-explorer-ci-project',
        GitRepository: '.ui-explorer-ci-GitRepository',
        status: '.ui-explorer-ci-status',
    }
};
