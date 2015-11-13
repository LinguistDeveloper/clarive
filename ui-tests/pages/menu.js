var commands = {
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        logo: 'img[src*="logo.png"]',
        userMenu: '.ui-user-menu button',
        userMenuLogout: 'a.ui-user-menu-logout',
        adminMenu: '.ui-menu-admin button',
        schedulerMenu: '.ui-menu-scheduler span',
        usersMenu: '.ui-menu-users span',
        rolesMenu: '.ui-menu-role span',
        rulesMenu: '.ui-menu-rule span',
    }
};
