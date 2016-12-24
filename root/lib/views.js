Ext.ns('Cla.ui');

/**
 * @private
 * @class Cla.ui.Field
 */ 
/**
 * @cfg {String} name The field's HTML name attribute (defaults to '').
 * <b>Note</b>: this property must be set if this field is to be automatically included with
 * {@link Ext.form.BasicForm#submit form submit()}.
 */
 /**
 * @cfg {Boolean} allowBlank Specify <tt>false</tt> to validate that the value's length is > 0 (defaults to
 * <tt>true</tt>)
 */
/**
 * @cfg {Boolean} readOnly <tt>true</tt> to mark the field as readOnly in HTML
 * (defaults to <tt>false</tt>).
 * <br><p><b>Note</b>: this only sets the element's readOnly DOM attribute.
 * Setting <code>readOnly=true</code>, for example, will not disable triggering a
 * ComboBox or DateField; it gives you the option of forcing the user to choose
 * via the trigger without typing in the text box. To hide the trigger use
 * <code>{@link Ext.form.TriggerField#hideTrigger hideTrigger}</code>.</p>
 */
/**
 * @cfg {Boolean} hidden
 * Render this component hidden (default is false). If <tt>true</tt>, the
 * {@link #hide} method will be called internally.
 */
/**
 * True if this component is hidden. Read-only.
 * @type Boolean
 * @property hidden
 */
/**
 * @method hide
 * Hide this component.  Listen to the '{@link #beforehide}' event and return
 * <tt>false</tt> to cancel hiding the component.  Fires the '{@link #hide}'
 * event after hiding the component. Note this method is called internally if
 * the component is configured to be <code>{@link #hidden}</code>.
 * @return {Ext.Component} this
 */    



/**
 * @class Cla.ui.textField
 * @extend Cla.ui.Field
 * Basic text field. Can be used as a direct replacement for traditional text inputs
 * <pre><code>
var textfield = Cla.ui.textField({
    name: 'hostname',
    fieldLabel: 'Hostname or IP',
    allowBlank: false
});
 * </code></pre>
 */ 
Cla.ui.textField = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'hidden', 'allowBlank', 'anchor', 'height', 'maxLength', 'style'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.textField(validAPI);
};

/**
 * @class Cla.ui.numberField
 * @extend Cla.ui.Field
 * Numeric text field that provides automatic keystroke filtering and numeric validation.
 * <pre><code>
var numberfield = Cla.ui.numberField({
    name: 'port',
    fieldLabel: 'Port',
    allowBlank: false,
    maxValue: '99999',
    type: 'int',
    vtype:  'port'
});
 * </code></pre>
 */  
Cla.ui.numberField = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'hidden', 'allowBlank', 'anchor', 'height', 'maxValue', 'style'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.numberField(validAPI);
};

/**
 * @class Cla.ui.datetimeField
 * @extend Cla.ui.Field
 * Provides a date input field with a {@link Ext.DatePicker} dropdown and automatic date validation.
 * <pre><code>
var datetime = Cla.ui.datetimeField({
    name: 'date',
    fieldLabel: 'Birthdate',
    allowBlank: false
});
 * </code></pre>
 */
Cla.ui.datetimeField = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'hidden', 'allowBlank', 'format'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.datetimeField(validAPI);  
};

/**
 * @class Cla.ui.timeField
 * @extend Cla.ui.Field
 * Provides a time input field with a time dropdown and automatic time validation.  Example usage:
 * <pre><code>
var timefield = Cla.ui.TimeField({
    minValue: '9:00 AM',
    maxValue: '6:00 PM',
    increment: 30
});
</code></pre>
 */
Cla.ui.timeField = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'hidden', 'allowBlank', 'format'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.timeField(validAPI);  
};

/**
 * @class Cla.ui.textArea
 * @extend Cla.ui.Field
 */
Cla.ui.textArea = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'hidden', 'allowBlank', 'anchor', 'height', 'maxLength', 'style'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.textArea(validAPI);
};

/**
 * @class Cla.ui.comboBox
 * @extend Cla.ui.Field
 */
Cla.ui.comboBox = function (options){
    var API = ['name', 'fieldLabel', 'data', 'value', 'disabled', 'hidden', 'allowBlank', 'anchor', 'singleMode'];

    for (var typeEvent in Cla.model.events.combo) {
            API.push('event.' + typeEvent);
    }

    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.comboBox(validAPI);
};

/**
 * @class Cla.ui.ciCombo
 * @extend Cla.ui.Field
 */
Cla.ui.ciCombo = function (options){

    //private options
    options.mode = 'remote';
    options.force_set_value = true;

    return Baseliner.ci_box(options);
    //return new Cla.ui.form.ciCombo();
};

/**
 * @class Cla.ui.topicCombo
 * @extend Cla.ui.Field
 */
Cla.ui.topicCombo = function (options){
    var API = ['name', 'fieldLabel', 'value', 'disabled', 'hidden', 'allowBlank', 'anchor', 'singleMode', 'categories', 'statuses', 'exlcudeStatus', 'filter'];
    var validAPI = Cla.$validateAPI(API, options);

    //private options
    validAPI.pageSize       = options.pageSize;
    validAPI.displayField   = options.displayField;
    validAPI.tplCfg         = options.tplCfg;
    validAPI.sortField      = options.sortField;
    validAPI.sortDir        = options.sortDir;
    validAPI.mid            = options.mid;

    return Cla.ui.form.topicCombo(validAPI);
    //return new Cla.ui.form.comboTopic();
};

/**
 * @class Cla.ui.projectCombo
 * @extend Cla.ui.Field
 */
Cla.ui.projectCombo = function (options){
    //var API = ['name', 'fieldLabel', 'value', 'disabled', 'hidden', 'allowBlank', 'anchor', 'singleMode', 'categories', 'statuses', 'exlcudeStatus', 'filter'];
    //var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.projectCombo(options);
};

/**
 * @class Cla.ui.userCombo
 * @extend Cla.ui.Field
 */
Cla.ui.userCombo = function (options){
    //var API = ['name', 'fieldLabel', 'value', 'disabled', 'hidden', 'allowBlank', 'anchor', 'singleMode', 'categories', 'statuses', 'exlcudeStatus', 'filter'];
    //var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.userCombo(options);   
};

/**
 * @class Cla.ui.codeEditor
 * @extend Cla.ui.Field
 */
Cla.ui.codeEditor = function (options){
    var API = ['fieldLabel', 'name', 'height', 'value', 'mode', 'cls', 'hidden', 'anchor'];
    var validAPI = Cla.$validateAPI(API, options);

    return new Cla.ui.form.codeEditor(validAPI);
};

/**
 * @class Cla.ui.htmlEditor
 * @extend Cla.ui.Field
 * Provides a lightweight HTML Editor component. Some toolbar features are not supported by Safari and will be
 * automatically hidden when needed.  These are noted in the config options where appropriate.
  * <pre><code>
var editor = Cla.ui.htmlEditor({
    name: 'description',
    fieldLabel: 'Description',
    height: 300
});
</code></pre>
 */
Cla.ui.htmlEditor = function (options){
    var API = ['fieldLabel', 'name', 'height', 'value', 'hidden', 'anchor', 'readOnly', 'allowBlank'];
    var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.htmlEditor(validAPI);
    //return 	new Cla.ui.form.htmlEditor(validAPI);
};

/**
 * @class Cla.ui.markdownEditor
 * @extend Cla.ui.Field
  * <pre><code>
var editor = Cla.ui.markdownEditor({
    name: 'comment',
    fieldLabel: 'Comment',
    height: 300
});
</code></pre> 
 */
Cla.ui.markdownEditor = function (options){
    var API = ['fieldLabel', 'name', 'height', 'value', 'hidden', 'anchor', 'readOnly', 'allowBlank','font'];
    var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.markdownEditor(validAPI);
};

/**
 * @class Cla.ui.checkBox
 * @extend Cla.ui.Field 
 * Single checkbox field.  Can be used as a direct replacement for traditional checkbox fields. 
 * <pre><code>
var combo = Cla.ui.comboBox({
    name: 'active',
    fieldLabel: 'Active',
    checked: 'true'
});
</code></pre>
 */
Cla.ui.checkBox = function (options){
    var API = ['fieldLabel', 'name', 'checked', 'disabled', 'hidden'];
    var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.checkBox(validAPI);
    //return 	new Cla.ui.form.checkBox(validAPI);
};

/**
 * @class Cla.ui.progressBar
 * @extend Cla.ui.Field
 * An updateable progress bar component.
 * <pre><code>
var progress = Cla.ui.progressBar({
        fieldLabel: 'Progress',
        name: 'progress',
        value: 50
});
</code></pre>
 */
Cla.ui.progressBar = function (options){
    var API = ['name', 'fieldLabel', 'value', 'disabled', 'hidden'];
    var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.progressBar(validAPI);
    //return    new Cla.ui.form.checkBox(validAPI);
};

/**
 * @class Cla.ui.pill
 * @extend Cla.ui.Field
 */
Cla.ui.pill = function (options){
    var API = ['name', 'fieldLabel', 'value', 'readOnly', 'options', 'anchor'];
    var validAPI = Cla.$validateAPI(API, options);

    return Cla.ui.form.pill(validAPI);    
};


Ext.ns('Cla.ui.form');

Cla.ui.form.textField = Ext.extend(Ext.form.TextField, {
    preventMark: true,
    msgTarget: 'under',

    listeners: {
        'afterrender': function() {
            this.preventMark = false;
        }
    },

    initComponent: function() {
        var self = this;

        if (!self.height) self.height = 30;
        if (!self.maxLength) self.maxLength = 255;
        if (!self.anchor) self.anchor = '100%';

        Cla.ui.form.textField.superclass.initComponent.call(self);
    }
});

Cla.ui.form.numberField = function (validAPI){
    return  {
        xtype:'numberfield',
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        value: validAPI.value,
        style: validAPI.style,
        anchor: validAPI.anchor || '100%',
        height: validAPI.height || 30,
        allowBlank: validAPI.allowBlank,
        readOnly: validAPI.readOnly,
        preventMark: true,
        listeners: {
            'afterrender': function() {
                this.preventMark = false;
            }
        },
        hidden: validAPI.hidden,
        maxValue: validAPI.maxValue,
        msgTarget: 'under'
    }
};

Cla.ui.form.datetimeField = function (validAPI){
    return  {
        xtype:'xdatefield',
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        value: validAPI.value,
        format:  validAPI.format,
        width: 165,
        allowBlank: validAPI.allowBlank,
        readOnly: validAPI.readOnly,
        hidden: validAPI.hidden
    }
};

Cla.ui.form.timeField = function (validAPI){
    return  {
        xtype:'timefield',
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        format: validAPI.format || 'H:i',
        value: validAPI.value,
        readOnly: validAPI.readOnly,
        allowBlank: validAPI.allowBlank,
        hidden: validAPI.hidden,
        width: 165
    }
};

Cla.ui.form.textArea = Ext.extend(Ext.form.TextArea, {
    preventMark: true,
    msgTarget: 'under',

    listeners: {
        'afterrender': function() {
            this.preventMark = false;
        }
    },

    initComponent: function() {
        var self = this;

        if (!self.height) self.height = 400;
        if (!self.maxLength) self.maxLength = 524288;
        if (!self.anchor) self.anchor = '100%';

        Cla.ui.form.textArea.superclass.initComponent.call(self);
    }
});


Cla.ui.form.$comboBox = Ext.extend(Ext.ux.form.SuperBoxSelect, {
    initComponent: function() {
        var self = this;

        for (var typeEvent in Cla.model.events.combo) {
            if (self['event.' + typeEvent]){
                var methodEvent = String.format('self.on("{0}", function({1}){{2}});', typeEvent, Cla.model.events.combo[typeEvent], self['event.' + typeEvent]);
                eval(methodEvent);            
            }
        }

        Cla.ui.form.$comboBox.superclass.initComponent.call(self);
    },

});

Cla.ui.form.comboBox = Ext.extend(Cla.ui.form.$comboBox, {
    mode: 'local',
    editable: false,

    initComponent: function() {
        var self = this;
        var store = new Ext.data.ArrayStore({
            fields: [self.name],
            data: self.data
        });

        if (!'singleMode' in self) {
            self.singleMode = false;
        }

        self.valueField = self.name;
        self.displayField = self.name;
        self.store = store;

        Cla.ui.form.comboBox.superclass.initComponent.call(self);
    }
});

Cla.ui.form.ciCombo = Ext.extend(Cla.ui.form.$comboBox, {
    initComponent: function() {
        var self = this;

        Cla.ui.form.ciCombo.superclass.initComponent.call(self);
    }
});

Cla.ui.form.topicCombo = function (validAPI){
    var topicStore = new Baseliner.store.Topics({
        baseParams: {
            limit: validAPI.pageSize,
            topic_child_data: true,
            mid: validAPI.mid,
            show_release: 0,
            filter: validAPI.filter,
            sort_field: validAPI.sortField,
            dir: validAPI.sortDir,
            categories: validAPI.categories ? validAPI.categories : [],
            statuses: validAPI.statuses ? validAPI.statuses : [],
            not_in_status: validAPI.excludeStatus
        },
        display_field: validAPI.displayField,
        tpl_cfg: validAPI.tplCfg
    });

    var topicCombo = new Baseliner.TopicBox({
        fieldLabel: validAPI.fieldLabel,
        pageSize: validAPI.pageSize,
        name: validAPI.name,
        hiddenName: validAPI.name,
        //emptyText: _( meta.emptyText ),
        allowBlank: validAPI.allowBlank,
        store: topicStore,
        disabled: !validAPI.readOnly || validAPI.readOnly === undefined ? false : validAPI.readOnly,
        value: validAPI.value,
        singleMode: validAPI.singleMode,
        hidden: !validAPI.hidden || validAPI.hidden === undefined ? false : validAPI.hidden,
        display_field: validAPI.displayField,
        tpl_cfg: validAPI.tplCfg
    });

    return topicCombo;
};

Cla.ui.form.projectCombo = function (validAPI){
    var project_box_store_user;
    var projects = validAPI.value;
    var firstload = true;

    if (validAPI.collection == 'project') {
        project_box_store_user = new Baseliner.store.UserProjects({
            id: 'id',
            baseParams: {
                tree_level: validAPI.levelTree || '',
                limit: validAPI.pageSize,
                include_root: true,
                level: validAPI.level,
                collection: validAPI.collection,
                autoLoad: false,
                roles: validAPI.roles
            }
        });

        project_box_store = new Baseliner.store.AllProjects({
            id: 'id',
            baseParams: {
                tree_level: validAPI.levelTree || '',
                limit: validAPI.pageSize,
                include_root: true,
                level: validAPI.level,
                collection: validAPI.collection,
                autoLoad: false,
                roles: validAPI.roles
            }
        });
    } else {
        project_box_store = new Baseliner.store.UserProjects({
            id: 'id',
            baseParams: {
                tree_level: validAPI.levelTree || '',
                limit: validAPI.pageSize,
                include_root: true,
                level: validAPI.level,
                collection: validAPI.collection,
                autoLoad: false,
                roles: validAPI.roles
            }
        });
    }

    var no_items = _('No items found');
    var tpl;
    if (validAPI.displayField == 'description') {
        tpl = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">'
          + '<span id="boot" style="background: transparent"><div class="project-item-list"><img src="{icon}" width="16" /></div><strong>{name} </strong></span>'
          + '<tpl if="description.length &gt; 0"><span class="x-combo-name-list-description">{description} </span></tpl>'
          + '</div></tpl>'
        );
    } else if (validAPI.displayField == 'baseline') {
        tpl = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">'
          + '<span id="boot" style="background: transparent"><div class="project-item-list"><img src="{icon}" width="16" /></div><strong>{name}</strong> <span class="x-combo-name-list-description">{values.bl} </span></span>'
          + '</div></tpl>'
        );
    } else if (validAPI.displayField == 'moniker') {
        tpl = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">'
          + '<span id="boot" style="background: transparent"><div class="project-item-list"><img src="{icon}" width="16" /></div><strong>{name}</strong> <span class="x-combo-name-list-description">{values.moniker} </span></span>'
          + '</div></tpl>'
        );
    } else {
        tpl = new Ext.XTemplate(
            '<tpl for="."><div class="x-combo-list-item">'
          + '<span id="boot" style="background: transparent"><div class="project-item-list"><img src="{icon}" width="16" /></div><strong>{name} </strong></span>'
          + '</div></tpl>'
        );
    }
    var project_box = new Baseliner.PagingProjects({
        origin: 'custom',
        fieldLabel: validAPI.fieldLabel,
        pageSize: '',
        tpl: tpl,
        name: validAPI.name,
        hiddenName: validAPI.name,
        listEmptyText: no_items,
        emptyText: validAPI.emptyText,
        field_ready: false,
        allowBlank: validAPI.allowBlank,
        disabled: validAPI.disabled,
        store: project_box_store,
        singleMode: validAPI.singleMode
    });

    project_box.field_ready = false;

    project_box_store.on('load', function() {
        project_box.field_ready = true;
        if (projects && firstload) {
            firstload = false;
            project_box.setValue(projects);
            if (validAPI.collection == 'project') {
                project_box.store = project_box_store_user;
                project_box_store_user.on('load', function() {
                    var removed_elems = {};
                    project_box_store_user.each(function(elem) {
                        var user_elem = elem;
                        project_box.items.items.forEach(function(elem) {
                            if (user_elem.json.mid == elem.value) {
                                removed_elems[elem.value] = 1;
                                project_box_store_user.remove(user_elem);
                            }
                        });
                    });
                    project_box.items.items.forEach(function(elem) {
                        if (!removed_elems[elem.value]) {
                            if (project_box.buttonClear.isDisplayed()) {
                                project_box.buttonClear.hide();
                            }
                            elem.disableAllListeners();
                        }
                    });
                });
                project_box_store_user.load();
            }
        }
    });

    project_box_store.load();

    if (validAPI.parentField) {
        var form = params.form.getForm();
        var parent_field = form.findField(validAPI.parentField);
        if (parent_field) {
            var parent_last = parent_field.value;
            project_box_store.baseParams['root_mid'] = parent_last;
            var parent_foo = function() {
                if (!project_box.field_ready || !parent_field.field_ready) return;
                //Baseliner.message( 'nada', String.format('parent changed = {0}, {1} = {2}', parent_last, parent_field.getValue(), parent_last != parent_field.getValue() ) );
                var cvalue = project_box.getValue();
                if (parent_last != parent_field.getValue()) {
                    if (cvalue != undefined && cvalue != '') {
                        Baseliner.warning(_('Warning'), _('Field %1 reset due to change in %2', _(validAPI.fieldLabel), _(parent_field.fieldLabel)));
                        project_box.setValue(null);
                        project_box.removeAllItems();
                        project_box.killItems();
                        // FIXME - should reset store everytime, so a new dataview is shown
                    }
                    parent_last = parent_field.getValue();
                    if (parent_last == undefined || parent_last == '') { // parent is unselected, make an impossible query with -1
                        project_box_store.baseParams['root_mid'] = -1;
                        project_box.listEmptyText = _('Select field %1 first or reload', _(parent_field.fieldLabel));
                    } else {
                        project_box_store.baseParams['root_mid'] = parent_last;
                        project_box_store.removeAll();
                        project_box.listEmptyText = no_items;
                    }
                }
            };
            parent_field.on('additem', function() {
                return parent_foo.call(this, arguments)
            });
            parent_field.on('removeitem', function() {
                return parent_foo.call(this, arguments)
            });
        }
    }

    var pb_panel = new Ext.Panel({
        layout: 'form',
        enableDragDrop: true,
        anchor: validAPI.anchor || '100%',
        border: false,
        items: [project_box]
    });

    pb_panel.on('afterrender', function() {
        var el = pb_panel.el.dom; //.childNodes[0].childNodes[1];
        var project_box_dt = new Baseliner.DropTarget(el, {
            comp: pb_panel,
            ddGroup: 'explorer_dd',
            copy: true,
            notifyDrop: function(dd, e, id) {
                var n = dd.dragData.node;
                //var s = project_box.store;
                var add_node = function(node) {
                    var data = node.attributes.data;
                    var swOk = true;
                    projects = (project_box.getValue()).split(",");
                    for (var i = 0; i < projects.length; i++) {
                        if (projects[i] == data.id_project) {
                            swOk = false;
                            break;
                        }
                    }
                    if (swOk) {
                        projects.push(data.id_project);
                        project_box.setValue(projects);
                    } else {
                        Baseliner.message(_('Warning'), _('Project %1 is already assigned', data.project));
                    }
                };
                var attr = n.attributes;
                if (typeof attr.data.id_project == 'undefined') { // is a project?
                    Baseliner.message(_('Error'), _('Node is not a project'));
                } else {
                    add_node(n);
                }
                // multiple? Ext.each(dd.dragData.selections, add_node );
                return (true);
            }
        });
    });

    return pb_panel;
};

Cla.ui.form.userCombo = function (validAPI){
    var users = validAPI.value;
    var user_box_store = new Baseliner.Topic.StoreUsers({
        autoLoad: true,
        baseParams: {projects:[],
                     roles: validAPI.roles,
                     topic_mid: validAPI.topicMid,
                     limit: validAPI.pageSize || 9999999,
                    }
    });
    
    var user_box = new Baseliner.model.Users({
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        hiddenName: validAPI.name,      
        store: user_box_store,
        disabled: validAPI.disabled,
        singleMode: validAPI.singleMode,
        allowBlank: validAPI.allowBlank
    });
    
    user_box_store.on('load',function(){
        user_box.setValue( users ) ;
    });

    return user_box;
};

Cla.ui.form.pill = function (validAPI){
    var pill = new Baseliner.Pills({
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        anchor: validAPI.anchor || '100%',
        readOnly: validAPI.readOnly,
        options: validAPI.options,
        value: validAPI.value,
        listeners: {
            change: function() {
                this.fireEvent('filter', this, this.getValue());
            }
        }
    });

    return pill;
};

Cla.ui.$aceEditor = Ext.extend(Ext.Panel, {
    gutter: true,
    mode: 'perl',
    theme: 'xcode',
    border: false,
    initComponent: function() {
        var self = this;
        var btnUndo = new Ext.Button({
            icon: IC('undo.svg'),
            handler: function() {
                self.$undo()
            }
        });
        var btnRedo = new Ext.Button({
            icon: IC('redo.svg'),
            handler: function() {
                self.$redo()
            }
        });
        if (self.tbar !== undefined) self.tbar = [
            btnUndo, btnRedo
        ];
        self.addEvents('aftereditor', 'docchange');
        self.on('afterrender', function() {
            self.$createEditor();
            self.fireEvent('aftereditor');
        });
        self.on('resize', function() {
            if (self.editor && self.editor.resize) {
                self.editor.resize();
            }
        });
        Cla.ui.$aceEditor.superclass.initComponent.call(this);
    },
    $createEditor: function() {
        var self = this;
        self.body.dom.innerHTML = "";
        self.editor = ace.edit(self.body.id);
        self.editor.setTheme("ace/theme/" + self.getTheme());

        var session = self.editor.session;
        session.setMode("ace/mode/" + self.mode);
        self.editor.setHighlightActiveLine(false);
        self.editor.renderer.setShowGutter(self.gutter);
        self.editor.setOptions({
            enableBasicAutocompletion: true,
            enableLiveAutocompletion: true
        });
        if (self.font) {
            self.el.setStyle({
                'font': self.font
            });
        }
        if (self.value) {
            self.setValue(self.value);
        } else if (self.data) {
            self.setValue(self.data);
        } else if (self.file) {
            self.load_file(self.file);
        } else {
            self.setValue('');
        }
    },
    getTheme: function() {
        switch (this.theme) {
            case 'dark':
                return 'idle_fingers';
            case 'light':
                return 'github';
            default:
                return this.theme;
        }
    },
    getValue: function() {
        return this.editor.getValue();
    },
    get_save_data: function() {
        return this.editor.getValue();
    },
    setValue: function(value) {
        var self = this;
        self.editor.setValue(value);
        self.editor.getSession().selection.clearSelection();
    },
    setReadOnly: function(v) {
        var self = this;
        return self.editor.setReadOnly(v);
    },

    setOptions: function(options) {
        var self = this;
        return self.editor.setOptions(options);
    },

    goTop: function() {
        var self = this;
        return self.editor.moveCursorToPosition({
            row: 0,
            column: 0
        });
    },

    setMode: function(v) {
        this.editor.session.setMode('ace/mode/' + v);
    },
    setTheme: function(v) {
        this.editor.setTheme('ace/theme/' + v);
    },
    focus: function() {
        Cla.ui.$aceEditor.superclass.focus.apply(this, arguments);
        if (this.editor)
            this.editor.focus();
    },
    $undo: function() {
        var self = this;
        self.editor.undo();
        self.editor.focus();
        self.editor.getSession().selection.clearSelection();
    },
    $redo: function() {
        var self = this;
        self.editor.redo();
        self.editor.focus();
        self.editor.getSession().selection.clearSelection();
    }
});

Cla.ui.form.codeEditor = Ext.extend(Cla.ui.$aceEditor, {
    initComponent: function() {
        var self = this;

        Cla.ui.form.codeEditor.superclass.initComponent.call(self);
    }
});

Cla.ui.form.htmlEditor = function(validAPI) {

    var editor = new Baseliner.CLEditor({
        value: validAPI.value,
        height: validAPI.height ? parseInt(validAPI.height) : 397,
        submitValue: false,
        readOnly: !validAPI.readOnly || validAPI.readOnly === undefined ? false : validAPI.readOnly,
    });

    function strip_html(html) {
        var tmp = document.createElement("DIV");
        tmp.innerHTML = html;
        return tmp.textContent || tmp.innerText || "";
    }

    return {
        xtype: 'panel',
        border: false,
        name: validAPI.name,
        margin: 0,
        padding: 0,
        fieldLabel: validAPI.fieldLabel,
        allowBlank: validAPI.allowBlank,
        hidden: !validAPI.hidden || validAPI.hidden === undefined ? false : validAPI.hidden,
        readOnly: !validAPI.readOnly || validAPI.readOnly === undefined ? false : validAPI.readOnly,
        anchor: validAPI.anchor || '100%',
        items: editor,
        get_save_data: function() {
            return editor.getValue();
        },
        is_valid: function() {
            var text = strip_html(editor.getValue());
            text = text.replace(/\s+/g, '');
            var is_valid = text != '' ? true : false;
            if (is_valid && this.on_change_lab) {
                this.getEl().applyStyles('border: none; margin_bottom: 0px');
                this.on_change_lab.style.display = 'none';
            }

            return is_valid;
        }
    }
};

Cla.ui.form.markdownEditor = function (validAPI){
    var editor = new Baseliner.Pagedown({
        font: validAPI.font,
        anchor: validAPI.anchor || '100%',
        height: validAPI.height || 300,
        value: validAPI.value || ''
    });
    
    return [
        new Ext.Panel({
            layout:'fit',
            name: validAPI.name,
            fieldLabel: validAPI.fieldLabel,
            allowBlank: validAPI.allowBlank,
            readOnly: validAPI.readOnly,
            hidden: validAPI.hidden,
            anchor: validAPI.anchor || '100%',
            border: false,
            items: editor,
            get_save_data : function(){
                return editor.getValue();
            },
            is_valid : function(){
                var is_valid = editor.getValue() != '' ? true : false;
                if (is_valid && this.on_change_lab){
                    this.getEl().applyStyles('border: none; margin_bottom: 0px');
                    this.on_change_lab.style.display = 'none';
                }
                return is_valid;
            }             
        })
    ]
};

Cla.ui.form.checkBox = function (validAPI) {
    return new Baseliner.CBox({
        name: validAPI.name,
        checked: !validAPI.checked || validAPI.checked === undefined ? false : validAPI.checked,
        disabled: !validAPI.readOnly || validAPI.readOnly === undefined ? false : validAPI.readOnly,
        hidden: !validAPI.hidden || validAPI.hidden === undefined ? false : validAPI.hidden,
        hideLabel: true,
        boxLabel: validAPI.fieldLabel
    });
};

Cla.ui.form.progressBar = function (validAPI) {
    return  { 
        xtype:'sliderfield', 
        fieldLabel: validAPI.fieldLabel,
        name: validAPI.name,
        value: validAPI.value || 0,
        anchor: '100%', 
        tipText: function(thumb){
            return String(thumb.value) + '%';
        },
        disabled: !validAPI.readOnly || validAPI.readOnly === undefined ? false : validAPI.readOnly,
        hidden: false//!validAPI.hidden || validAPI.hidden === undefined ? false : validAPI.hidden
    }
};

Cla.$validateAPI = function (API, attributes) {
    var validAtributes;

    if (attributes) {
        validAtributes = {};

        Ext.each(API, function(apiAttribute) {
            if (attributes[apiAttribute] || attributes[apiAttribute] === false) {
                validAtributes[apiAttribute] = attributes[apiAttribute];
            }
        });
    }
    return validAtributes;
};