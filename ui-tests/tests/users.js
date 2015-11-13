module.exports = new (function() {
  var tests = this;

  tests['Create user'] = function (browser) {
    browser.maximizeWindow();

    var login = browser.page.login();
    var menu = browser.page.menu();
    var users = browser.page.users();

    login.navigate()
      .waitForElementVisible('@loginInput', 1000)
      .setValue('@loginInput', 'local/root')
      .setValue('@loginPassword', 'admin')
      .click('@loginButton')
      .waitForElementNotVisible('@loadingMask', 5000);

    menu
      .click('@adminMenu')
      .click('@usersMenu');

    users
      .waitForElementVisible('@usersTab', 5000)
      .click('@createBtn')
      //.waitForElementVisible('@editWindow', 5000)
      //.click('@editWindowSaveBtn')
      //.waitForElementVisible('@ruleInputInvalid', 5000)
      //.click('@editWindowCloseBtn')
      ;

    //scheduler
      //.waitForElementVisible('@schedulerTab', 5000)
      //.click('@createBtn')
      //.waitForElementVisible('@editWindow', 5000)
      //.setValue('input[name=time]', '')
      //.click('@editWindowSaveBtn')
      //.waitForElementVisible('.x-form-invalid input[name=time]', 5000)
      //.click('@editWindowCloseBtn')
      //;

    browser.end();
  };

});
