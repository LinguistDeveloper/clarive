package BaselinerX::Fieldlets;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Baseliner::Sugar;
use Path::Class;
use Try::Tiny;

register 'fieldlet.include_into' => {
    name        => _locl('Included Into'),
    html        => '/fields/system/html/field_include_into.html',
    form        => '/fields/system/config/include_into.js',
    origin      => 'default',
    editable    => 0,
    section_default => 'details',
    section_allowed => ['details'],
};

register 'fieldlet.attach_file' => {
    name            => _locl('Attach Files'),
    html            => '/fields/templates/html/upload_files.html',
    js              => '/fields/templates/js/upload_files.js',
    form            => '/fields/templates/config/upload_files.js',
    icon            => '/static/images/icons/file.svg',
    get_method      => 'get_files',
    type            => 'upload_files',
    relation        => 'system',
    section_default => 'head',
    section_allowed => [ 'head', 'details', 'between' ]
};

register 'fieldlet.progressbar' => {
    name        => _locl('Progress Bar'),
    html        => '/fields/templates/html/progress_bar.html',
    js          => '/fields/templates/js/progress_bar.js',
    form        => '/fields/templates/config/progress_bar.js',
    icon        => '/static/images/icons/progressbar.svg',
    meta_type   => 'number',
    section_default => 'details',
    section_allowed => ['details','between']
};

register 'fieldlet.calculated_number' => {
    name        => _locl('Calculated Numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/calculated_numberfield.js',
    form        => '/fields/templates/config/calculated_numberfield.js',
    icon        => '/static/images/icons/number.svg',
    meta_type   => 'number',
    section_default => 'body',
    section_allowed => ['body'],
    limit_height   => 1
};

register 'fieldlet.datetime' => {
    name        => _locl('Datefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/datetimefield.js',
    form        => '/fields/templates/config/datetimefield.js',
    icon        => '/static/images/icons/calendar.svg',
    meta_type   => 'date',
    type        => 'datefield',
    section_default => 'body',
    section_allowed => ['body'],
    limit_height   => 1
};

register 'fieldlet.time' => {
    name        => _locl('Timefield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/timefield.js',
    form        => '/fields/templates/config/timefield.js',
    icon        => '/static/images/icons/slot.svg',
    type        => 'timefield',
    section_default => 'body',
    section_allowed => ['body']
};

register 'fieldlet.ci_list' => {
    name        => _locl('CI List'),
    html        => '/fields/templates/html/ci_grid.html',
    js          => '/fields/system/js/list_ci.js',
    form        => '/fields/templates/config/ci_list.js',
    icon        => '/static/images/icons/grid.svg',
    section_default => 'head',
    section_allowed => ['head','more'],
    limit_height =>  1
};

register 'fieldlet.ci_grid' => {
    name        => _locl('CI Grid'),
    html        => '/fields/templates/html/ci_grid.html',
    js          => '/fields/templates/js/ci_grid.js',
    form        => '/fields/templates/config/ci_grid.js',
    icon        => '/static/images/icons/grid.svg',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.combo' => {
    name        => _locl('Combo'),
    html        => '/fields/templates/html/combo_box.html',
    js          => '/fields/templates/js/combo.js',
    form        => '/fields/templates/config/combo.js',
    icon        => '/static/images/icons/combo_box.svg',
    section_default => 'body',
    section_allowed => ['body','head'],
    limit_height   => 1
};

register 'fieldlet.dbi_query' => {
    name        => _locl('DB Query'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/dbi.js',
    form        => '/fields/templates/config/dbi.js',
    icon        => '/static/images/icons/sql.svg',
    type        => 'combo',
    show_in_palette => 0,
    section_default => 'head',
    section_allowed => ['head'],
};

register 'fieldlet.download_all_files' => {
    name        => _locl('Download All Files'),
    html        => '/fields/templates/html/download_all.html',
    form        => '/fields/templates/config/download_all.js',
    icon        => '/static/images/icons/download.svg',
    type        => 'upload_files',
    relation    => 'system',
    categories  => 'all',
    files_field => 'all',
    section_default => 'details',
    section_allowed => ['details']
};

register 'fieldlet.grid_editor' => {
    name        => _locl('Grid Editor'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/grid_editor.js',
    form        => '/fields/templates/config/grid_editor.js',
    icon        => '/static/images/icons/grid.svg',
    type        => 'generic',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.milestones' => {
    name        => _locl('Milestones'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/milestones.js',
    icon        => '/static/images/icons/milestone.svg',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.env_planner' => {
    name        => _locl('Environment Planner'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/env_planner.js',
    form        => '/fields/templates/config/env_planner.js',
    icon        => '/static/images/icons/milestone.svg',
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
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.scheduler' => {
    name        => _locl('Scheduler'),
    html        => '/fields/templates/html/grid_editor.html',
    js          => '/fields/templates/js/milestones.js',
    form        => '/fields/templates/config/scheduler.js',
    icon        => '/static/images/icons/clock.svg',
    relation    => 'system',
    get_method  => 'get_cal',
    set_method  => 'set_cal',
    type        => 'generic',
    meta_type   => 'calendar',
    data_gen    => sub{
        +{
            columns=>sprintf(
                '%s[slotname],textfield,100;%s[plan_end_date],datefield,80;%s[end_date],datefield,80',
                _loc('Milestone'), _loc('Planned End Date'), _loc('Real End Date') )
        }
    },
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.html_editor' => {
    name        => _locl('HTML Editor'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/html_editor.js',
    icon        => '/static/images/icons/html.svg',
    type        => 'html/editor',
    meta_type   => 'content',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.pagedown' => {
    name        => _locl('Pagedown Editor'),
    html        => '/fields/templates/html/markdown.html',
    js          => '/fields/templates/js/pagedown.js',
    form        => '/fields/templates/config/pagedown.js',
    icon        => '/static/images/icons/html.svg',
    type        => 'generic',
    meta_type   => 'content',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.pills' => {
    name        => _locl('Pills'),
    html        => '/fields/templates/html/pills.html',
    js          => '/fields/templates/js/pills.js',
    form        => '/fields/templates/config/pills.js',
    icon        => '/static/images/icons/pills.svg',
    section_default => 'body',
    section_allowed => ['body']
};

register 'fieldlet.status_chart_pie' => {
    name        => _locl('Status Pie Chart'),
    html        => '/fields/templates/html/status_chart_pie.html',
    form        => '/fields/templates/config/status_chart_pie.js',
    icon        => '/static/images/icons/chart_pie.svg',
    type        => 'generic',
    section_default => 'details',
    section_allowed => ['details']
};

register 'fieldlet.status_changes' => {
    name        => _locl('Status Changes'),
    html        => '/fields/templates/html/status_changes.html',
    js          => '/fields/templates/js/status_changes.js',
    form        => '/fields/templates/config/status_changes.js',
    icon        => '/static/images/icons/chart_pie.svg',
    type        => 'datefield',
    meta_type   => 'history',
    relation    => 'system',
    section_default => 'details',
    section_allowed => ['details']
};

register 'fieldlet.topic_grid' => {
    name            => _locl('Topic Grid'),
    html            => '/fields/templates/html/topic_grid.html',
    js              => '/fields/templates/js/topic_grid.js',
    form            => '/fields/templates/config/topic_grid.js',
    icon            => '/static/images/icons/grid.svg',
    get_method      => 'get_topics',
    meta_type       => 'topic',
    relation        => 'system',
    set_method      => 'set_topics',
    type            => 'generic',
    show_in_palette => 0,
    section_default => 'head',
    section_allowed => [ 'head', 'more' ]
};

register 'fieldlet.checkbox' => {
    name        => _locl('Checkbox'),
    html        => '/fields/system/html/field_checkbox.html',
    js          => '/fields/templates/js/checkbox.js',
    form        => '/fields/templates/config/checkbox.js',
    icon        => '/static/images/icons/admin_request.svg',
    type        => 'checkbox',
    section_default => 'details',
    section_allowed => ['details','more','between', 'body'],
};

register 'fieldlet.separator' => {
    name        => _locl('Separator'),
    html        => '',
    js          => '/fields/templates/js/separator.js',
    form        => '/fields/templates/config/separator.js',
    icon        => '/static/images/icons/separator.svg',
    holds_children => 1,
    isTarget => 1
};

register 'fieldlet.text' => {
    name        => _locl('Textfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/textfield.js',
    icon        => '/static/images/icons/field.svg',
    type        => 'textfield',
    section_default => 'head',
    section_allowed => ['head','more','body'],
    limit_height   => 1
};

register 'fieldlet.text_plain' => {
    name        => _locl('Preformatted Text'),
    html        => '/fields/templates/html/preformattedtext.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/preformattedtext.js',
    icon        => '/static/images/icons/field.svg',
    type        => 'textarea',
    section_default => 'head',
    section_allowed => ['head','more']
};

register 'fieldlet.number' => {
    name        => _locl('Numberfield'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/numberfield.js',
    form        => '/fields/templates/config/numberfield.js',
    icon        => '/static/images/icons/number.svg',
    meta_type   => 'number',
    section_default => 'body',
    section_allowed => ['body'],
    limit_height   => 1
};

########################
#                      #
#     OBLIGATORIES     #
#                      #
########################

register 'fieldlet.system.status_new' => {
    name        => _locl('Status'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/system/js/field_status.js',
    form        => '/fields/templates/config/status_new.js',
    icon        => '/static/images/icons/action.svg',
    display_field => 'name_status',
    bd_field    => 'id_category_status',
    id_field    => 'status_new',
    framed      => 1,
    origin      => 'system',
    relation    => 'status',
    meta_type   => 'status',
    section     => 'body',
    section_allowed => ['body'],
    limit_height => 1

};

register 'fieldlet.system.moniker' => {
    name        => _locl('Moniker'),
    name_field  => _locl('Moniker'),
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/moniker.js',
    icon        => '/static/images/icons/action.svg',
    html        => '/fields/templates/html/row_body.html',
    origin      => 'system',
    type        => 'textfield',
    bd_field    => 'moniker',
    id_field    => 'moniker',
    section_default => 'details',
    limit_height   => 1
};

register 'fieldlet.system.title' => {
    name        => _locl('Title'),
    id_field    => 'title',
    bd_field    => 'title',
    html        => '/fields/system/html/field_title.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/title.js',
    icon        => '/static/images/icons/action.svg',
    type        => 'textfield',
    origin      => 'system',
    section     => 'title',
    section_allowed => ['title'],
    limit_height   => 1
};

register 'fieldlet.system.labels' => {
    name_field  => _locl('Labels'),
    origin      => 'default',
    bd_field    => 'labels',
    id_field    => 'labels',
    show_in_palette => 0,
    get_method  => 'get_labels',
    relation    => 'system'
};

register 'fieldlet.system.description' => {
    name        => _locl('Description'),
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/templates/js/html_editor.js',
    form        => '/fields/templates/config/description.js', ############# MODIFICAR
    icon        => '/static/images/icons/textfield.svg',
    id_field    => 'description',
    bd_field    => 'description',
    origin      => 'system',
    section_default => 'head',
    section_allowed => ['head','more']

};

########################################################################################
########################################################################################

register 'fieldlet.system.revisions' => {
    name        => _locl('Revision Box'),
    icon        => '/static/images/icons/combo_box.svg',
    get_method  => 'get_revisions',
    set_method  => 'set_revisions',
    html        => '/fields/system/html/field_revisions.html',
    js          => '/fields/system/js/list_revisions.js',
    form        => '/fields/templates/config/revisions.js',
    meta_type   => 'revision',
    relation    => 'system',
    type        => 'listbox',
    section_default => 'head',
    section_allowed => ['head', 'details']
};

register 'fieldlet.system.release' => {
    name        => _locl('Release Combo'),
    icon        => '/static/images/icons/combo_box.svg',
    get_method  => 'get_release',
    set_method  => 'set_release',
    html        => '/fields/system/html/field_release.html',
    js          => '/fields/system/js/list_release.js',
    form        => '/fields/templates/config/release.js',
    meta_type   => 'release',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_topic',
    section_default => 'body',
    section_allowed => ['body','head','more'],
    limit_height => 1
};

register 'fieldlet.system.release_version' => {
    name        => _locl('Release Version'),
    html        => '/fields/templates/html/row_body.html',
    js          => '/fields/templates/js/textfield.js',
    form        => '/fields/templates/config/textfield.js',
    icon        => '/static/images/icons/field.svg',
    type        => 'textfield',
    section_default => 'head',
    section_allowed => ['head','more','body'],
    limit_height   => 1
};

register 'fieldlet.system.projects' => {
    name        => _locl('Project Combo'),
    icon        => '/static/images/icons/combo_box.svg',
    get_method  => 'get_projects',
    set_method  => 'set_projects',
    html        => '/fields/system/html/field_projects.html',
    js          => '/fields/system/js/list_projects.js',
    form        => '/fields/templates/config/projects.js',
    meta_type   => 'project',
    relation    => 'system',
    include_root    => 'true',
    type        => 'listbox',
    section_default => 'details',
    section_allowed => ['details'],
    limit_height => 1
};


register 'fieldlet.system.users' => {
    name        => _locl('User Combo'),
     icon        => '/static/images/icons/combo_box.svg',
    get_method  => 'get_users',
    set_method  => 'set_users',
    html        => '/fields/system/html/field_users.html',
    js          => '/fields/system/js/list_users.js',
    form        => '/fields/templates/config/users.js',
    meta_type   => 'user',
    relation    => 'system',
    type        => 'listbox',
    section_default => 'details',
    section_allowed => ['details'],
    limit_height => 1
};


register 'fieldlet.system.topics' => {
    name        => _locl('Topics'),
    icon        => '/static/images/icons/listbox.svg',
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
    section_default => 'head',
    section_allowed => ['head','more','details']
};

register 'fieldlet.system.list_topics' => {
    name        => _locl('Topic Selector'),
    icon        => '/static/images/icons/combo_box.svg',
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
    section_default => 'head',
    section_allowed => ['head','more','details'],
    limit_height   => 1
};


register 'fieldlet.system.cis' => {
    name        => _locl('CI Combo'),
    icon        => '/static/images/icons/combo_box.svg',
    get_method  => 'get_cis',
    set_method  => 'set_cis',
    html        => '/fields/system/html/field_cis.html',
    js          => '/fields/system/js/list_ci.js',
    form        => '/fields/templates/config/cis.js',
    meta_type   => 'ci',
    relation    => 'system',
    type        => 'listbox',
    rel_type    => 'topic_ci',
    section_default => 'body',
    section_allowed => ['body','details'],
    limit_height   => 1
};


register 'fieldlet.system.tasks' => {
    name        => _locl('Task Grid'),
    icon        => '/static/images/icons/grid.svg',
    get_method  => '',
    set_method  => '',
    html        => '',
    js          => '',
    meta_type   => 'task',
    type        => 'listbox',
    show_in_palette => 0,
    relation    => '',
    form        => '/fields/templates/config/tasks.js',
};

###########################
#                         #
#     REQUIRED FIELDS     #
#                         #
###########################

register 'fieldlet.required.category' => {
    name        => _locl('Topic Category'),
    name_field  => _locl('Category'),
    id_field    => 'category',
    bd_field    => 'id_category',
    html        => '/fields/templates/html/dbl_row_body.html',
    js          => '/fields/system/js/field_category.js',
    icon        => '/static/images/icons/action.svg',
    origin      => 'system',
    relation    => 'categories',
    hidden      => '1',
    system_force => 'true',
};

register 'fieldlet.required.created_by' => {
    name_field  => _locl('Created By'),
    origin      => 'default',
    id_field    => 'created_by',
    bd_field    => 'created_by',
    editable    => 0,
    field_order => 1,
    origin      => 'default',
    meta_type   => 'user',
};

register 'fieldlet.required.created_on' => {
    name_field  => _locl('Created On'),
    origin      => 'default',
    id_field    => 'created_on',
    bd_field    => 'created_on',
    editable    => 0,
    field_order => 1,
    meta_type   => 'date',
};

register 'fieldlet.required.modified_by' => {
    name_field  => _locl('Modified By'),
    origin      => 'default',
    editable    => 0,
    field_order => 1,
    id_field    => 'modified_by',
    bd_field    => 'modified_by',
    meta_type   => 'user',
};

register 'fieldlet.required.modified_on' => {
    name_field  => _locl('Modified On'),
    origin      => 'default',
    id_field    => 'modified_on',
    bd_field    => 'modified_on',
    editable    => 0,
    field_order => 1,
    meta_type   => 'date',
};

# register 'fieldlet.required.progress' => {
#     name        => _locl('Progress'),
#     name_field  => _locl('Progress'),
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
