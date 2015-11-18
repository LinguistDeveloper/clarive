module.exports = new (function() {
  var tests = this;

  tests['before'] = function(browser) {
    browser.resizeWindow(1024, 768);
    browser.maximizeWindow();
  };

  tests['Successful login'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'local/root')
      .setValue('@loginPassword', 'admin');

    browser.pause(500);

    login
      .click('@loginButton')
      .waitForElementVisible('@userMenu', 5000)
      .logout();

    browser.end();
  };

  tests['No fields entered'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', '')
      .setValue('@loginPassword', '');

    browser.pause(500);

    login
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

  tests['Unknown username'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'unknown')
      .setValue('@loginPassword', '');

    browser.pause(500);

    login
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

  tests['Wrong password'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'local/root')
      .setValue('@loginPassword', 'wrong password');

    browser.pause(500);

    login
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

});
