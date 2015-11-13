function selectFromCIBox(browser, name, text)
{
    browser
      .execute(function(name, text) {
        var $select = $('input[name=' + name + ']').parents('.x-form-item');
        $select.find('.x-superboxselect-btn-expand').click();
      }, [name, text]);

    browser
      .waitForJqueryElement(".ui-ci_box-" + name + ":contains('" + text + "')", 5000)
      .jqueryClick(".ui-ci_box-" + name + ":contains('" + text + "')")
}

function createEnvironment(browser, options)
{
    var explorer = browser.page.explorer();
    var ciList = browser.page.ciList();
    var ciEditor = browser.page.ciEditor();
    var tabBar = browser.page.tabBar();

    explorer
      .expandCI()
      .waitForElementVisible('@bl', 5000)
      .click('@bl')
      ;

    ciList
      .waitForElementVisible('@createBtn', 5000)
      .click('@createBtn');

    ciEditor
      .waitForElementVisible('input[name=name]', 5000)
      .setValue('input[name=name]', options['name'])
      .setValue('input[name=bl]', options['id'])
      .click('@saveBtn')
      .click('@closeBtn');

    tabBar
      .click('@activeTabClose');
}

function createProject(browser, options)
{
    var explorer = browser.page.explorer();
    var ciList = browser.page.ciList();
    var ciEditor = browser.page.ciEditor();
    var tabBar = browser.page.tabBar();

    explorer
      .expandCI()
      .waitForElementVisible('@project', 5000)
      .click('@project')
      ;

    ciList
      .waitForElementVisible('@createBtn', 5000)
      .click('@createBtn');

    ciEditor
      .waitForElementVisible('input[name=name]', 5000)
      .setValue('input[name=name]', options['name'])
      .setValue('input[name=bls]', options['bls'])
      ;

    for (var i = 0; i < options.repositories.length; i++) {
        selectFromCIBox(browser, 'repositories', options.repositories[i]);
    }

    ciEditor
      .click('@saveBtn')
      .click('@closeBtn');

    tabBar
      .click('@activeTabClose');
}

function createGitRepository(browser, options)
{
    var explorer = browser.page.explorer();
    var ciList = browser.page.ciList();
    var ciEditor = browser.page.ciEditor();
    var tabBar = browser.page.tabBar();

    explorer
      .expandCI()
      .waitForElementVisible('@GitRepository', 5000)
      .click('@GitRepository')
      ;

    ciList
      .waitForElementVisible('@createBtn', 5000)
      .click('@createBtn');

    ciEditor
      .waitForElementVisible('input[name=name]', 5000)
      .setValue('input[name=name]', options['name'])
      .setValue('input[name=repo_dir]', options['repo_dir'])
      .click('@saveBtn')
      .click('@closeBtn');

    tabBar
      .click('@activeTabClose');
}

function createStatus(browser, options)
{
    options['type'] = (typeof options['type'] === 'undefined') ? 'G' : options['type'];

    var explorer = browser.page.explorer();
    var ciList = browser.page.ciList();
    var ciEditor = browser.page.ciEditor();
    var tabBar = browser.page.tabBar();

    explorer
      .expandCI()
      .waitForElementVisible('@status', 5000)
      .click('@status')
      ;

    ciList
      .waitForElementVisible('@createBtn', 5000)
      .click('@createBtn');

    ciEditor
      .waitForElementVisible('input[name=name]', 5000)
      .setValue('input[name=name]', options['name'])
      .click('input[value="' + options['type'] + '"]');

    for (var i = 0; i < options.bls.length; i++) {
        selectFromCIBox(browser, 'bls', options.bls[i]);
    }

    ciEditor
      .click('@saveBtn')
      .click('@closeBtn');

    tabBar
      .click('@activeTabClose');
}

function createRole(browser, options) {
    var menu = browser.page.menu();
    var roleGrid = browser.page.roleGrid();
    var roleEdit = browser.page.roleEdit();
    var tabBar = browser.page.tabBar();

    menu
      .click('@adminMenu')
      .click('@rolesMenu')
      ;

    roleGrid
      .waitForElementVisible('@createBtn', 5000)
      .click('@createBtn')
      ;

    roleEdit
      .waitForElementVisible('input[name=name]', 5000)
      .setValue('input[name=name]', options['name'])
      .click('@save');

    browser.pause(1000);

    roleEdit
      .click('@close');
      ;

    tabBar
      .click('@activeTabClose');
}

function createRule(browser, options) {
    var menu = browser.page.menu();
    var rules = browser.page.rules();
    var ruleEdit = browser.page.ruleEdit();
    var tabBar = browser.page.tabBar();

    menu
      .click('@adminMenu')
      .click('@rulesMenu')
      ;

    rules
      .waitForElementVisible('@create', 5000)
      .click('@create')
      ;

    ruleEdit
      .waitForElementVisible('input[name=rule_name]', 5000)
      .setValue('input[name=rule_name]', options['name'])
      .setValue('input[name=rule_type]', options['type'])
      .jqueryClick("button:contains('Next')")
      .jqueryClick("button:contains('Done')");

    browser.pause(1000);

    //roleEdit
      //.click('@close');
      //;

    tabBar
      .click('@activeTabClose');
}

module.exports = new (function() {
  var tests = this;

  tests['Create'] = function (browser) {
    browser.maximizeWindow();

    var login = browser.page.login();

    login.login();

    createEnvironment(browser, {
        name: 'Common',
        id: '*'
    });

    createGitRepository(browser, {
        name: 'Repository',
        repo_dir: '.git'
    });

    createProject(browser, {
        name: 'Project',
        bls: 'Common',
        repositories: ['Repository']
    });

    createStatus(browser, { name: 'New', bls: ['Common'], type: 'I' });
    createStatus(browser, { name: 'In Progress', bls: ['Common'] });
    createStatus(browser, { name: 'Closed', bls: ['Common'], type: 'F' });

    //createRule(browser, { name: 'Issue', type: 'form' });

    createRole(browser, { name: 'Developer' });

    browser.end();
  };

});
