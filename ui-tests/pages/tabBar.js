module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    elements: {
        activeTab: '#main-panel .x-tab-strip-active',
        activeTabClose: '#main-panel .x-tab-strip-active a.x-tab-strip-close',
    }
};
