(function(params){
    var data = params.data || {};
    var common = params.common_options || Cla.dashlet_common(params);

    Cla.HTMLSnippets = {
        base : function(){/*
        */},
        table1 : function(){/*
           <table class="table table-striped">
              <thead>
                <tr>
                  <th>#</th>
                  <th>First Name</th>
                  <th>Last Name</th>
                  <th>Username</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>1</td>
                  <td>Mark</td>
                  <td>Otto</td>
                  <td>@mdo</td>
                </tr>
                <tr>
                  <td>2</td>
                  <td>Jacob</td>
                  <td>Thornton</td>
                  <td>@fat</td>
                </tr>
                <tr>
                  <td>3</td>
                  <td>Larry</td>
                  <td>the Bird</td>
                  <td>@twitter</td>
                </tr>
              </tbody>
            </table>
        */},
        dyn_table : function(){/*
           <table class="table table-striped">
              <thead>
                <tr>
                  <th>#</th>
                  <th>First Name</th>
                  <th>Last Name</th>
                  <th>Username</th>
                </tr>
              </thead>
              <tbody>
[% for( var i=0; i<5; i++ ) { %]
                <tr>
                  <td>1</td>
                  <td>[%= ws_params.username %]</td>
                  <td>Otto</td>
                  <td>@mdo</td>
                </tr>
[% } %]
                <tr>
                  <td>2</td>
                  <td>Jacob</td>
                  <td>Thornton</td>
                  <td>@fat</td>
                </tr>
                <tr>
                  <td>3</td>
                  <td>Larry</td>
                  <td>the Bird</td>
                  <td>@twitter</td>
                </tr>
              </tbody>
            </table>
        */},
        form_inline : function(){/*
            <form class="form-inline">
              <input type="text" class="input-small" placeholder="Email">
              <input type="password" class="input-small" placeholder="Password">
              <label class="checkbox">
                <input type="checkbox"> Remember me
              </label>
              <button type="submit" class="btn">Sign in</button>
            </form>
        */},
        form_horiz : function(){/*
             <form class="form-horizontal">
              <div class="control-group">
                <label class="control-label" for="inputEmail">Email</label>
                <div class="controls">
                  <input type="text" id="inputEmail" placeholder="Email">
                </div>
              </div>
              <div class="control-group">
                <label class="control-label" for="inputPassword">Password</label>
                <div class="controls">
                  <input type="password" id="inputPassword" placeholder="Password">
                </div>
              </div>
              <div class="control-group">
                <div class="controls">
                  <label class="checkbox">
                    <input type="checkbox"> Remember me
                  </label>
                  <button type="submit" class="btn">Sign in</button>
                </div>
              </div>
            </form>
        */},
        checkboxes : function(){/*
             <label class="checkbox">
              <input type="checkbox" value="">
              Option one is this and that—be sure to include why it's great
            </label>
             
            <label class="radio">
              <input type="radio" name="optionsRadios" id="optionsRadios1" value="option1" checked>
              Option one is this and that—be sure to include why it's great
            </label>
            <label class="radio">
              <input type="radio" name="optionsRadios" id="optionsRadios2" value="option2">
              Option two can be something else and selecting it will deselect option one
            </label>
        */},
        checkboxes_inline : function(){/*
            <label class="checkbox inline">
              <input type="checkbox" id="inlineCheckbox1" value="option1"> 1
            </label>
            <label class="checkbox inline">
              <input type="checkbox" id="inlineCheckbox2" value="option2"> 2
            </label>
            <label class="checkbox inline">
              <input type="checkbox" id="inlineCheckbox3" value="option3"> 3
            </label>
        */},
        select1 : function(){/*
            <select>
              <option>1</option>
              <option>2</option>
              <option>3</option>
              <option>4</option>
              <option>5</option>
            </select>
             
            <select multiple="multiple">
              <option>1</option>
              <option>2</option>
              <option>3</option>
              <option>4</option>
              <option>5</option>
            </select>
        */},
        action_selection : function(){/*
              <div class="input-append">
              <input class="span2" id="appendedDropdownButton" type="text">
              <div class="btn-group">
                <button class="btn dropdown-toggle" data-toggle="dropdown">Action <span class="caret"></span></button>
                <ul class="dropdown-menu">
                  <li><a href="#">Action</a></li>
                  <li><a href="#">Another action</a></li>
                  <li><a href="#">Something else here</a></li>
                  <li class="divider"></li>
                  <li><a href="#">Separated link</a></li>
                </ul>
              </div>
            </div>
        */},
        form1 : [function(){/*
             <form>
              <fieldset>
                <legend>Legend</legend>
                <label>Label name</label>
                <input type="text" placeholder="Type something...">
                <span class="help-block">Example block-level help text here.</span>
                <label class="checkbox">
                  <input type="checkbox"> Check me out
                </label>
                <button class="btn dash-sample-button">Submit</button>
              </fieldset>
            </form>
        */},
            function(){/*
              $('.dash-sample-button').click(function(){
                  alert("you clicked: " + this.innerHTML);
                  return false;
              });
            */}
        ],
        extjs1 : [ null, function(){/*
                var panel = new Ext.FormPanel({ 
                    tbar:['Save'], 
                    items:[
                        {xtype:'textfield',fieldLabel:'Fill'}
                    ], 
                    height: 300 
                });
                return panel;
        */}]
    };

    var snippets = new Cla.ComboDouble({ 
        fieldLabel:_('Sample Snippets'),
        data:[
            [ 'add', _('[select a sample snippet to add/replace in the code]') ],
            [ 'base', _('Base HTML') ],
            [ 'table1', _('Striped Table') ],
            [ 'dyn_table', _('Dynamic Table') ],
            [ 'form1', _('Basic Form with JS event click') ], 
            [ 'form_inline', _('Inline Form') ],
            [ 'select1', _('Select') ],
            [ 'action_selection', _('Input and Select Action') ],
            [ 'checkboxes', _('Checkboxes') ],
            [ 'checkboxes_inline', _('Inline Checkboxes') ],
            [ 'extjs1', _('ExtJS Panel') ] 
    ]});
    snippets.on('select',function(ev,sel){
        var curr = sel.data.item; 
        if( curr == 'add' ) return;
        var snip = Cla.HTMLSnippets[ curr ], snip_js;
        if( Ext.isArray(snip) ) {
            snip_js = snip[1].heredoc();
            snip = snip[0] ? snip[0].heredoc() : null;
        } else {
            snip = snip.heredoc();
            snip_js = '';
        }
        snip = snip==null ? ' ' : String.format('<div id="boot" style="text-align:left;float:left;width:100%">\n{0}\n</div>', snip);
        if( html_code.getValue().length > 0 ) {
            Cla.confirm( _('Do you want to overwrite the current HTML and JS? ("No" will append code to the end)'), function(res){
                html_code.setValue(snip);
                js_code.setValue(snip_js);
            },function(){
                html_code.setValue( html_code.getValue() + "\n" + snip );    
                js_code.setValue( js_code.getValue() + "\n" + snip_js );    
            });
        } else {
            html_code.setValue(snip);
            js_code.setValue(snip_js);
        }
    });
    
    var html_code = new Baseliner.AceEditor({
        title: _('HTML Code'), mode:'html', fieldLabel:_('HTML Code'), anchor:'100%', height: 400, name:'html_code', value: params.data.html_code
    });
    var js_code = new Baseliner.AceEditor({
        title: _('JS Code'), mode:'javascript', fieldLabel:_('JS Code'), anchor:'100%', height: 400, name:'js_code', value: params.data.js_code
    });

    var tabs = new Ext.TabPanel({ height: 400, deferredRender: false, activeTab: 0, items:[ html_code, js_code ] });
    tabs.on('afterrender',function(){
        //if( !params.data.html_code && params.data.js_code ) tabs.setActiveTab(1);
    });
    var data_url = new Ext.form.TextField({ name:'data_url', fieldLabel: _('Data Url (optional)'), value: params.data.data_url });
    return common.concat([ snippets, data_url, tabs ]);
})


