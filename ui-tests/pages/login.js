var commands = {
    logout: function() {
        this
          .waitForElementVisible('@userMenu', 5000)
          .click('@userMenu')
          .click('@userMenuLogout')
          .waitForElementVisible('@loginInput', 5000);
    }
};

module.exports = {
    url: function () { return this.api.launchUrl + '/' },
    commands: [commands],
    elements: {
        loginButton: '.ui-button-login button',
        loginInput: 'input[name=login]',
        loginInputInvalid: 'input[name=login].x-form-invalid',
        loginPassword: 'input[name=password]',
        loadingMask: '#bali-loading-img',
        logo: 'img[src*="logo.png"]',
        userMenu: '.ui-user-menu button',
        userMenuLogout: 'a.ui-user-menu-logout',
        alertBox: '.x-window',
        alertBoxButton: '.x-window-dlg .x-window-bc button'
    }
};
