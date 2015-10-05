module.exports = new (function() {
  var tests = this;

  tests['Successful login'] = function (browser) {
    var login = browser.page.login();

    browser.maximizeWindow();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'local/root')
      .setValue('@loginPassword', 'admin')
      .click('@loginButton')
      .waitForElementNotVisible('@loadingMask', 5000)
      .logout();

    browser.end();
  };

  tests['No fields entered'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', '')
      .setValue('@loginPassword', '')
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

  tests['Unknown username'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'unknown')
      .setValue('@loginPassword', '')
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

  tests['Wrong password'] = function (browser) {
    var login = browser.page.login();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'local/root')
      .setValue('@loginPassword', 'wrong password')
      .click('@loginButton')
      .waitForElementVisible('@loginInputInvalid', 5000);

    browser.end();
  };

});
