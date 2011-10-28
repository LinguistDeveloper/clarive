/** Toggles visibility for a section (after clicking on its header) */
function hideSection(header, section) {
  $(section).toggle();
  if($(section).visible()) expanded(header);
  else collapsed(header);
}

/** Hides the body of the table (after clicking on a header row) */
function hideBody(item) {
  var tbody = $(item).up(1).down('TBODY');
  if(tbody) {
    tbody.toggle();
    if(tbody.visible()) expanded(item);
    else collapsed(item);
  }
}

function expanded(header) {
  $(header).removeClassName('collapsed').addClassName('expanded');
}

function collapsed(header) {
  $(header).removeClassName('expanded').addClassName('collapsed');
}

function stopEvt(e) {
  if(e && e.stopPropagation) e.stopPropagation();
  else window.event.cancelBubble=true;
  return false;
}

/** Filters the lists by priority / rule code pattern / code file pattern */
function filter(form) {
  var priorities = [form.p1.checked, form.p2.checked, form.p3.checked, form.p4.checked, form.p5.checked, form.p6.checked];
  var rulePattern = form.rulepattern.value.strip().gsub(/\./, '_').gsub(/\*/, '.*').gsub(/\?/, '.');
  var itemPattern = form.itempattern.value.strip().gsub(/[\. \/\\]/, '_').gsub(/\*/, '.*').gsub(/\?/, '.');

  var ruleRegexp = rulePattern? new RegExp('^'+rulePattern, 'i') : null;
  var itemRegexp = itemPattern? new RegExp('^'+itemPattern, 'i') : null;

  var filterItem = function(item) {
    if(!itemRegexp) return true;
    var cname = $w(item.className)[1];
    return itemRegexp.test(cname);
  }

  var filterRule = function(item) {
    var c = $w(item.className);
    var rname = c[1];
    var priority = c[2].charAt(1) - 1;
    var rnameOk = !ruleRegexp || ruleRegexp.test(rname);
    var prioOk = priorities[priority];

    return rnameOk && prioOk;
  }

  $$('#sumcla_layer TR.R2').each(function(item) { showHide(item, filterItem) });

  $$('#anareg_layer TABLE').each(function(category) {
    var rulesShown = false;
    document.getElementsByClassName('R2', category).each( function(rule) {
      if(showHide(rule, filterRule)) rulesShown=true;
    });
    document.getElementsByClassName('suppressedViolation', category).each( function(rule) {
      if(showHide(rule, filterRule)) rulesShown=true;
    });
    if(!rulesShown) category.hide();
  });

  $$('#anacla_layer TABLE').each( function(file) {
    var isFileShown = showHide(file, filterItem);
    if(isFileShown) {
      var violsShown = false;
      document.getElementsByClassName('R2', file).each( function(viol) {
        if(showHide(viol, filterRule)) violsShown=true;
      });
      document.getElementsByClassName('suppressedViolation', file).each( function(viol) {
        if(showHide(viol, filterRule)) violsShown=true;
      });
      if(!violsShown) file.hide();
    }
  });
}

/** Resets the report to no filter */
function resetFilter(form) {
  form.p1.checked = true;
  form.p2.checked = true;
  form.p3.checked = true;
  form.p4.checked = true;
  form.p5.checked = true;
  form.rulepattern.value = '';
  form.itempattern.value = '';

  filter(form);
}

function showHide(item, filter) {
  var isShown = filter(item);
  if( isShown ) item.show();
  else item.hide();
  return isShown;
}

var POPUP_GEOM = 'toolbar=0,scrollbars=1,location=0,statusbar=0,menubar=0,width=600,height=450,resizable=1';

/**
 * Opens a popup window with the contents of the given url, centered in the screen
 *
 * @param name (s) Name of the popup window
 * @param url (s) URL
 */
function popup(name, url, geometry) {
  geometry = geometry || POPUP_GEOM;
  // center popup
  var top = (screen.height - this._getDimension(geometry, 'height')) / 2;
  var left = (screen.width - this._getDimension(geometry, 'width')) / 2;
  return window.open(url, name, geometry + ', top=' + top + ',left=' + left);
}

/**
 * Returns the width or heigth from the popup geometry
 */
function _getDimension(geometry, dimension) {
  var array = geometry.split(',');
  for (var i = 0; i < array.length; i++) {
    var aux = array[i].split('=');
    if (aux[0] == dimension) {
      return aux[1];
    }
  }
  return 0;
}