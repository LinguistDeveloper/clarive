package BaselinerX::Fieldlets;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;

register 'fieldlet.attach_file' => {
    name        => _loc('Attach Files'),
    html        => '/fields/templates/html/upload_files.html',
    js          => '/fields/templates/js/upload_files.js',
    form        => '/fields/templates/config/upload_files.js',
    icon        => '/static/images/icons/file.gif',
    get_method  => 'get_files',
    type        => 'upload_files',
    relation    => 'system',
    section_allowed => ['details','between']
};

register 'fieldlet.progressbar' => {
    name        => _loc('Progress Bar'),
    html        => '/fields/templates/html/progress_bar.html',
    js          => '/fields/templates/js/progress_bar.js',
    form        => '/fields/templates/config/progress_bar.js',
    icon        => '/static/images/icons/progressbar.png',
    section_allowed => ['details','between']
};

register 'fieldlet.calculated_number' => {
    name        => _loc('Calculated Numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/calculated_numberfield.js',
    form        => '/fields/templates/config/calculated_numberfield.js',
    icon        => '/static/images/icons/number.png',
    meta_type   => 'number',
    section_allowed => ['body']
};

register 'fieldlet.datetime' => {
    name        => _loc('Datefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/datetimefield.js',
    form        => '/fields/templates/config/datetimefield.js',
    icon        => '/static/images/icons/calendar.png',
    meta_type   => 'date',
    type        => 'datefield',
    section_allowed => ['body']
};

register 'fieldlet.time' => {
    name        => _loc('Timefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/timefield.js',
    form        => '/fields/templates/config/timefield.js',
    icon        => '/static/images/icons/time.png',
    type        => 'timefield',
    section_allowed => ['body']
};



register 'fieldlet.ci_grid' => {
    name        => _loc('CI Grid'),
    html        => '/fields/templates/html/ci_grid.html',
    js          => '/fields/templates/js/ci_grid.js',
    form        => '/fields/templates/config/ci_grid.js',
    icon        => '/static/images/icons/grid.png',
    section_allowed => ['more','head']
};

register 'fieldlet.combo' => {
    name        => _loc('Combo'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/combo.js',
    form        => '/fields/templates/config/combo.js',
    icon        => '/static/images/icons/combo_box.png',
    section_allowed => ['body']
};

register 'fieldlet.dbi_query' => {
    name        => _loc('DB Query'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/dbi.js',
    form        => '/fields/templates/config/dbi.js',
    icon        => '/static/images/icons/sql.png',
    show_in_palette => 0, 
    type        => 'combo'
};

register 'fieldlet.download_all_files' => {
    name        => _loc('Download All Files'),
    html        => '/fields/templates/html/download_all.html',
    form        => '/fields/templates/config/download_all.js',
    icon        => '/static/images/icons/download.png',
    type        => 'upload_files',
    relation    => 'system',
    categories  => 'all',
    files_field => 'all',
    section_allowed => ['details']
};

register 'fieldlet.grid_editor' => {
    name        => _loc('Grid Editor'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/grid_editor.js',
    form        => '/fields/templates/config/grid_editor.js',
    icon        => '/static/images/icons/grid.png',
    type        => 'generic',
    section_allowed => ['head','more']
};

register 'fieldlet.milestones' => {
    name        => _loc('Milestones'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/milestones.js',
    icon        => '/static/images/icons/milestone.png',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
    section_allowed => ['head','more']
};

register 'fieldlet.env_planner' => {
    name        => _loc('Environment Planner'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/env_planner.js',
    form        => '/fields/templates/config/env_planner.js',
    icon        => '/static/images/icons/milestone.png',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
    data_gen    => sub{
        +{
            columns=>sprintf(
                '%s[slotname],bl_combo,100;%s[plan_start_date],datefield,80;%s[plan_end_date],datefield,80', 
                _loc('Environment'), _loc('Planned Start'), _loc('Planned End') )
        }
    },
    section_allowed => ['head','more']
};

register 'fieldlet.scheduler' => {
    name        => _loc('Scheduler'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/scheduler.js',
    icon        => '/static/images/icons/clock.png',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
    section_allowed => ['head','more']
};

register 'fieldlet.html_editor' => {
    name        => _loc('HTML Editor'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/html_editor.js',
    icon        => '/static/images/icons/html.png',
    type        => 'html/editor',
    meta_type   => 'content',
    section_allowed => ['head','more']
};

register 'fieldlet.pagedown' => {
    name        => _loc('pagedown editor'),
    html        => '/fields/templates/html/markdown.html',
    js          => '/fields/templates/js/pagedown.js',
    form        => '/fields/templates/config/pagedown.js',
    icon        => '/static/images/icons/html.png',
    type        => 'generic',
    meta_type   => 'content',
    section_allowed => ['head','more']
};

register 'fieldlet.pills' => {
    name        => _loc('pills'),
    html        => '/fields/templates/html/pills.html',
    js          => '/fields/templates/js/pills.js',
    form        => '/fields/templates/config/pills.js',
    icon        => '/static/images/icons/pills.png',
    section_allowed => ['body']
};

register 'fieldlet.status_chart_pie' => {
    name        => _loc('status chart pie'),
    html        => '/fields/templates/html/status_chart_pie.html',
    form        => '/fields/templates/config/status_chart_pie.js',
    icon        => '/static/images/icons/chart_pie.png',
    type        => 'generic',
    section_allowed => ['details']
};

register 'fieldlet.status_changes' => {
    name        => _loc('status changes'),
    html        => '/fields/templates/html/status_changes.html',
    js          => '/fields/templates/js/status_changes.js',
    form        => '/fields/templates/config/status_changes.js',
    icon        => '/static/images/icons/chart_pie.png',
    type        => 'datefield',
    meta_type   => 'history',
    relation    => 'system',
    section_allowed => ['details']
};

register 'fieldlet.topic_grid' => {
    name        => _loc('topic grid'),
    html        => '/fields/templates/html/topic_grid.html',
    js          => '/fields/templates/js/topic_grid.js',
    form        => '/fields/templates/config/topic_grid.js',
    icon        => '/static/images/icons/grid.png',
    get_method  => 'get_topics',
    meta_type   => 'topic',
    relation    => 'system',
    set_method  => 'set_topics',
    type        => 'generic',
    section_allowed => ['head','more']
};

register 'fieldlet.checkbox' => {
    name        => _loc('Checkbox'),
    html        => '/fields/system/html/field_checkbox.html',
    js          => '/fields/templates/js/checkbox.js',
    form        => '/fields/templates/config/checkbox.js',
    icon        => '/static/images/icons/admin_request.png',
    #icon        => '/static/images/icons/checkbox.png',
    type        => 'checkbox',
    section_allowed => ['details','more','between'],
    section_allowed => ['body']
};

register 'fieldlet.separator' => {
    name        => _loc('Separator'),
    html        => '',
    js          => '/fields/templates/js/separator.js',
    form        => '/fields/templates/config/separator.js',
    icon        => '/static/images/icons/separator.png',
    holds_children => 1,
    isTarget => 1
};

register 'fieldlet.text' => {
    name        => _loc('Textfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/textfield.js',
    icon        => '/static/images/icons/field.png',
    type        => 'textfield',
    section_allowed => ['head','more','body']
};

register 'fieldlet.number' => {
    name        => _loc('Numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/numberfield.js',
    form        => '/fields/templates/config/numberfield.js',
    icon        => '/static/images/icons/number.png',
    section_allowed => ['body']
};

########################
#                      #
#     OBLIGATORIES     #
#                      #
########################

register 'fieldlet.system.status_new' => {
    name        => _loc('State'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/system/js/field_status.js',
    form        => '/fields/templates/config/status_new.js',
    icon        => '/static/images/icons/lock_small.png',
    display_field => 'name_status',
    bd_field    => 'id_category_status',
    id_field    => 'status_new',
    framed      => 1,
    origin      => 'system',
    relation    => 'status',
    meta_type   => 'status'
};

register 'fieldlet.system.moniker' => {
    name        => _loc('Moniker'),
    name_field  => _loc('moniker'),
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/moniker.js',
    icon        => '/static/images/icons/lock_small.png',
    html        => '/fields/templates/html/row_body.html',
    origin      => 'system',
    bd_field    => 'moniker',
    id_field    => 'moniker'
};

register 'fieldlet.system.title' => {
    name        => _loc('title'),
    name_field  => _loc('Title'),
    id_field    => 'title',
    bd_field    => 'title',
    html        => '/fields/system/html/field_title.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/title.js',
    icon        => '/static/images/icons/lock_small.png',
    origin      => 'system'
};

register 'fieldlet.system.labels' => {
    name_field  => _loc('Labels'),
    origin      => 'default',
    bd_field    => 'labels',
    id_field    => 'labels',
    get_method  => 'get_labels',
    relation    => 'system'
};

register 'fieldlet.system.description' => {
    name        => _loc('Description'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/description.js', ############# MODIFICAR
    icon        => '/static/images/icons/textfield.png',
    id_field    => 'description',
    bd_field    => 'description',
    origin      => 'system',
};

########################################################################################
########################################################################################

register 'fieldlet.system.revisions' => {
    name        => _loc('Revision Box'),
    #icon        => '/static/images/icons/report_default.png',
    icon        => '/static/images/icons/combo_box.png',
    get_method  => 'get_revisions',
    set_method  => 'set_revisions',
    html        => '/fields/system/html/field_revisions.html',
    js          => '/fields/system/js/list_revisions.js',
    form        => '/fields/templates/config/revisions.js',
    meta_type   => 'revision',
    relation    => 'system',
    type        => 'listbox',
    section_allowed => ['details']
};

register 'fieldlet.system.release' => {
    name        => _loc('Release Combo'),
    icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_release',
    set_method  => 'set_release',
    html        => '/fields/system/html/field_release.html',
    js          => '/fields/system/js/list_release.js',
    form        => '/fields/templates/config/release.js',
    meta_type   => 'release',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic',
    section_allowed => ['body','head','more']
};


register 'fieldlet.system.projects' => {
    name        => _loc('Project Combo'),
    icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_projects',
    set_method  => 'set_projects',
    html        => '/fields/system/html/field_projects.html',
    js          => '/fields/system/js/list_projects.js',
    form        => '/fields/templates/config/projects.js',
    meta_type   => 'project',
    relation    => 'system',
    include_root    => 'true',
    type        => 'listbox',
    section_allowed => ['details']
};


register 'fieldlet.system.users' => {
    name        => _loc('User Combo'),
     icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_users',
    set_method  => 'set_users',
    html        => '/fields/system/html/field_users.html',
    js          => '/fields/system/js/list_users.js',
    form        => '/fields/templates/config/users.js',
    meta_type   => 'user',
    relation    => 'system',
    type        => 'listbox',
    section_allowed => ['details']
};


register 'fieldlet.system.topics' => {
    name        => _loc('topics'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_topics',
    set_method  => 'set_topics',
    html        => '/fields/system/html/field_topics.html',
    js          => '/fields/system/js/list_topics.js',
    form        => '/fields/templates/config/topics.js',
    meta_type   => 'topic',
    relation    => 'system',
    type        => 'listbox',
    show_in_palette => 0,
    rel_type    => 'topic_topic',
    section_allowed => ['head','more','details']
};

register 'fieldlet.system.list_topics' => {
    name        => _loc('Topic Selector'),
    icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_topics',
    set_method  => 'set_topics',
    section_allowed => ['head','more'],
    html        => '/fields/system/html/list_topics.html',
    js          => '/fields/system/js/list_topics.js',
    form        => '/fields/templates/config/list_topics.js',
    meta_type   => 'topic',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic',
    section_allowed => ['head','more','details']
};

register 'fieldlet.system.list_topics_selector' => {
    name        => _loc('Topic Selector with filter'),
    icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_topics',
    set_method  => 'set_topics',
    section_allowed => ['head','more'],
    html        => '/fields/system/html/list_topics.html',
    js          => '/fields/system/js/list_topics_selector.js',
    form        => '/fields/templates/config/list_topics_selector.js',
    meta_type   => 'topic',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic',
    section_allowed => ['head','more','details']
};


register 'fieldlet.system.cis' => {
    name        => _loc('CI Combo'),
    icon        => '/static/images/icons/combo_box.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_cis',
    set_method  => 'set_cis',
    html        => '/fields/system/html/field_cis.html',
    js          => '/fields/system/js/list_ci.js',
    form        => '/fields/templates/config/cis.js',
    meta_type   => 'ci',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_ci',
    section_allowed => ['body','head','more']
};


register 'fieldlet.system.tasks' => {
    name        => _loc('Task Grid'),
    icon        => '/static/images/icons/grid.png',
    #icon        => '/static/images/icons/listbox.png',
    get_method  => '',
    set_method  => '',
    html        => '',
    js          => '',
    meta_type   => 'task',
    type        => 'listbox',
    relation    => '',
    form        => '/fields/templates/config/tasks.js',
};

###########################
#                         #
#     REQUIRED FIELDS     #
#                         #
###########################

register 'fieldlet.required.category' => {
    name        => _loc('Topic Category'),
    name_field  => 'Category',
    id_field    => 'category',
    bd_field    => 'id_category',
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/system/js/field_category.js',
    icon        => '/static/images/icons/lock_small.png',
    origin      => 'system',
    relation    => 'categories',
    hidden      => '1',
    system_force => 'true',
};

register 'fieldlet.required.created_by' => {
    name_field  => _loc('Created By'),
    origin      => 'default',
    id_field    => 'created_by',
    bd_field    => 'created_by',
    editable    => 0,
    field_order => 1,
    origin      => 'default'
};

register 'fieldlet.required.created_on' => {
    name_field  => _loc('Created On'),
    origin      => 'default',
    id_field    => 'created_on',
    bd_field    => 'created_on',
    editable    => 0,
    field_order => 1,
    meta_type   => 'date',
};

register 'fieldlet.required.modified_by' => {
    name_field  => _loc('Modified By'),
    origin      => 'default',
    editable    => 0,
    field_order => 1,
    id_field    => 'modified_by',
    bd_field    => 'modified_by'
};

register 'fieldlet.required.modified_on' => {
    name_field  => _loc('Modified On'),
    origin      => 'default',
    id_field    => 'modified_on',
    bd_field    => 'modified_on',
    editable    => 0,
    field_order => 1,
    meta_type   => 'date',
};

register 'fieldlet.required.include_into' => {
    name_field  => _loc('Include into'),
    html        => '/fields/system/html/field_include_into.html',
    origin      => 'default',
    editable    => 0,
    field_order => 1,
    id_field    => 'include_into',
    bd_field    => 'include_into'
};

# register 'fieldlet.required.progress' => {
#     name        => _loc('progress'),
#     name_field  => _loc('Progress'),
#     html        => '/fields/templates/html/progress_bar.html',
#     js          => '/fields/templates/js/progress_bar.js',
#     editable    => '0',
#     hidden      => '1',
#     origin      => 'system',
#     id_field    => 'progress',
#     bd_field    => 'progress'
# };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
