package BaselinerX::Fieldlets;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;
use utf8;

register 'fieldlet.attach_file' => {
    name        => _loc('attach files'),
    html        => '/fields/templates/html/upload_files.html',
    js          => '/fields/templates/js/upload_files.js',
    form        => '/fields/templates/config/upload_files.js',
    icon        => '/static/images/icons/file.gif',
    get_method  => 'get_files',
    type        => 'upload_files',
    relation    => 'system',
};

register 'fieldlet.progressbar' => {
    name        => _loc('progress bar'),
    html        => '/fields/templates/html/progress_bar.html',
    js          => '/fields/templates/js/progress_bar.js',
    form        => '/fields/templates/config/progress_bar.js',
    icon        => '/static/images/icons/progressbar.png'
};

register 'fieldlet.calculated_number' => {
    name        => _loc('calculated numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/calculated_numberfield.js',
    form        => '/fields/templates/config/calculated_numberfield.js',
    icon        => '/static/images/icons/number.png',
    meta_type   => 'number'
};

register 'fieldlet.datetime' => {
    name        => _loc('datefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/datetimefield.js',
    form        => '/fields/templates/config/datetimefield.js',
    icon        => '/static/images/icons/calendar.png',
    meta_type   => 'date',
    type        => 'datefield'
};

register 'fieldlet.time' => {
    name        => _loc('timefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/timefield.js',
    form        => '/fields/templates/config/timefield.js',
    icon        => '/static/images/icons/time.png',
    type        => 'timefield'
};



register 'fieldlet.ci_grid' => {
    name        => _loc('ci grid'),
    html        => '/fields/templates/html/ci_grid.html',
    js          => '/fields/templates/js/ci_grid.js',
    form        => '/fields/templates/config/ci_grid.js',
    icon        => '/static/images/icons/grid.png'
};

register 'fieldlet.combo' => {
    name        => _loc('combo'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/combo.js',
    form        => '/fields/templates/config/combo.js',
    icon        => '/static/images/icons/combo_box.png'
};

register 'fieldlet.dbi_query' => {
    name        => _loc('dbi query'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/dbi.js',
    form        => '/fields/templates/config/dbi.js',
    icon        => '/static/images/icons/sql.png',
    type        => 'combo'
};

register 'fieldlet.download_all_files' => {
    name        => _loc('download all files'),
    html        => '/fields/templates/html/download_all.html',
    form        => '/fields/templates/config/download_all.js',
    icon        => '/static/images/icons/download.png',
    type        => 'upload_files',
    relation    => 'system',
    categories  => 'all',
    files_field => 'all'
};

register 'fieldlet.grid_editor' => {
    name        => _loc('grid editor'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/grid_editor.js',
    form        => '/fields/templates/config/grid_editor.js',
    icon        => '/static/images/icons/grid.png',
    type        => 'generic'
};

register 'fieldlet.milestones' => {
    name        => _loc('milestones'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/milestones.js',
    icon        => '/static/images/icons/milestone.png',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
};

register 'fieldlet.scheduler' => {
    name        => _loc('Scheduler'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/scheduler.js',
    icon        => '/static/images/silk/clock.png',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
};

register 'fieldlet.html_editor' => {
    name        => _loc('html/editor'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/html_editor.js',
    icon        => '/static/images/icons/html.png',
    type        => 'html/editor',
    meta_type   => 'content',
    #data        => 'clob'
};

register 'fieldlet.origin_issue_chart_pie' => {
    name        => _loc('origin issue chart pie'),
    html        => '/fields/templates/html/origin_issue_pie.html',
    js          => '',
    form        => '/fields/templates/config/origin_issue_chart_pie.js',
    icon        => '/static/images/icons/chart-pie.png'
};

register 'fieldlet.pagedown' => {
    name        => _loc('pagedown editor'),
    html        => '/fields/templates/html/markdown.html',
    js          => '/fields/templates/js/pagedown.js',
    form        => '/fields/templates/config/pagedown.js',
    icon        => '/static/images/icons/html.png',
    type        => 'generic',
    meta_type   => 'content'
};

register 'fieldlet.pills' => {
    name        => _loc('pills'),
    html        => '/fields/templates/html/pills.html',
    js          => '/fields/templates/js/pills.js',
    form        => '/fields/templates/config/pills.js',
    icon        => ''
};

register 'fieldlet.status_chart_pie' => {
    name        => _loc('status chart pie'),
    html        => '/fields/templates/html/status_chart_pie.html',
    form        => '/fields/templates/config/status_chart_pie.js',
    icon        => '/static/images/icons/chart-pie.png',
    type        => 'generic'
};

register 'fieldlet.status_changes' => {
    name        => _loc('status changes'),
    html        => '/fields/templates/html/status_changes.html',
    js          => '/fields/templates/js/status_changes.js',
    form        => '/fields/templates/config/status_changes.js',
    type        => 'datefield',
    meta_type   => 'history',
    relation    => 'system'
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
    type        => 'generic'
};

register 'fieldlet.checkbox' => {
    name        => _loc('Checkbox'),
    html        => '/fields/system/html/field_checkbox.html',
    js          => '/fields/templates/js/checkbox.js',
    form        => '/fields/templates/config/checkbox.js',
    icon        => '/static/images/icons/checkbox.png',
    type        => 'checkbox'
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
    type        => 'textfield'
};

register 'fieldlet.number' => {
    name        => _loc('Numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/numberfield.js',
    form        => '/fields/templates/config/numberfield.js',
    icon        => '/static/images/icons/number.png'
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
    section     => 'body',
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
    section     => 'body',
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
    section     => 'head',
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
    name        => _loc('description'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/description.js', ############# MODIFICAR
    icon        => '/static/images/icons/lock_small.png',
    id_field    => 'description',
    bd_field    => 'description',
    origin      => 'system',
    section     => 'head',
};

########################################################################################
########################################################################################

register 'fieldlet.system.revisions' => {
    name        => _loc('revisions'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_revisions',
    set_method  => 'set_revisions',
    html        => '/fields/system/html/field_revisions.html',
    js          => '/fields/system/js/list_revisions.js',
    form        => '/fields/templates/config/revisions.js',
    meta_type   => 'revision',
    relation    => 'system',
    type        => 'listbox'
};

register 'fieldlet.system.release' => {
    name        => _loc('release'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_release',
    set_method  => 'set_release',
    html        => '/fields/system/html/field_release.html',
    js          => '/fields/system/js/list_release.js',
    form        => '/fields/templates/config/release.js',
    meta_type   => 'release',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic'
};


register 'fieldlet.system.projects' => {
    name        => _loc('projects'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_projects',
    set_method  => 'set_projects',
    html        => '/fields/system/html/field_projects.html',
    js          => '/fields/system/js/list_projects.js',
    form        => '/fields/templates/config/projects.js',
    meta_type   => 'project',
    relation    => 'system',
    include_root    => 'true',
    type        => 'listbox',
};


register 'fieldlet.system.users' => {
    name        => _loc('users'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_users',
    set_method  => 'set_users',
    html        => '/fields/system/html/field_users.html',
    js          => '/fields/system/js/list_users.js',
    form        => '/fields/templates/config/users.js',
    meta_type   => 'user',
    relation    => 'system',
    type        => 'listbox'
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
    rel_type    => 'topic_topic'
};

register 'fieldlet.system.list_topics' => {
    name        => _loc('list topics'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_topics',
    set_method  => 'set_topics',
    html        => '/fields/system/html/list_topics.html',
    js          => '/fields/system/js/list_topics.js',
    form        => '/fields/templates/config/list_topics.js',
    meta_type   => 'topic',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic'
};


register 'fieldlet.system.cis' => {
    name        => _loc('cis'),
    icon        => '/static/images/icons/listbox.png',
    get_method  => 'get_cis',
    set_method  => 'set_cis',
    html        => '/fields/system/html/field_cis.html',
    js          => '/fields/system/js/list_ci.js',
    form        => '/fields/templates/config/cis.js',
    meta_type   => 'ci',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_ci'
};


register 'fieldlet.system.tasks' => {
    name        => _loc('tasks'),
    icon        => '/static/images/icons/listbox.png',
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
    name        => _loc('category'),
    name_field  => 'Category',
    id_field    => 'category',
    bd_field    => 'id_category',
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/system/js/field_category.js',
    icon        => '/static/images/icons/lock_small.png',
    origin      => 'system',
    section     => 'body',
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
    name_field  => _loc('Modifierd On'),
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
    section     => 'details',
    editable    => 0,
    field_order => 1,
    id_field    => 'include_into',
    bd_field    => 'include_into'
};

register 'fieldlet.required.progress' => {
    name        => _loc('progress'),
    name_field  => _loc('Progress'),
    html        => '/fields/templates/html/progress_bar.html',
    js          => '/fields/templates/js/progress_bar.js',
    editable    => '0',
    hidden      => '1',
    origin      => 'system',
    section     => 'details',
    id_field    => 'progress',
    bd_field    => 'progress'
};

1;
