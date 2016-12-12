package Baseliner::Schema::Migrations::0125_update_rule_report_icons;
use Baseliner::Schema::Migrations::0119_modify_structure_favorite_tree;
use Baseliner::Utils qw(_decode_json _array _encode_json _dump);
use Moose;

my $DEFAULT_RULE_ICON   = '/static/images/icons/report-default.svg';
my $DEFAULT_REPORT_ICON = '/static/images/icons/report-default.svg';

sub upgrade {
    my $self = shift;

    $self->update_rule_icons;
    $self->update_reports_icons;
}

sub update_rule_icons {
    my ( $self, %p ) = @_;

    my $all_rules = mdb->rule->find();

    while ( my $rule = $all_rules->next ) {
        next unless $rule->{rule_tree};

        my $rule_tree = _decode_json( $rule->{rule_tree} );
        foreach my $rule_tree_attribute ( _array $rule_tree) {
            $self->_update_rule_child_icon($rule_tree_attribute);
        }
        my $rule_tree_updated = _encode_json($rule_tree);

        mdb->rule->update( { id => $rule->{id} }, { '$set' => { rule_tree => $rule_tree_updated } } );
    }
}

sub _update_rule_child_icon {
    my ( $self, $rule_tree_json ) = @_;

    my $attr = $rule_tree_json->{attributes};

    $attr->{icon}           = $self->_update_rule_icon($attr);
    $rule_tree_json->{icon} = $self->_update_rule_icon($rule_tree_json);

    if ( $attr->{children} ) {
        foreach my $child ( _array $attr->{children} ) {
            $self->_update_rule_child_icon($child);
        }
    }

    foreach my $child ( _array $rule_tree_json->{children} ) {
        $self->_update_rule_child_icon($child);
    }
    return $rule_tree_json;
}

sub _update_rule_icon {
    my $self = shift;
    my ($rule_element) = @_;
    if ( $rule_element->{key} ) {
        my $icon = $self->get_icon_from_register_key( $rule_element->{key} );
        return $icon if $icon && $self->_exists_icon($icon);
    }
    my $icon = $rule_element->{icon};

    return $DEFAULT_RULE_ICON unless $icon;

    my $new_icon = Baseliner::Schema::Migrations::0119_modify_structure_favorite_tree->get_icon($icon);
    return $DEFAULT_RULE_ICON unless $new_icon || $icon =~ m/\.svg$/;

    $new_icon = $icon if !$new_icon;
    return $self->_exists_icon($new_icon) ? $new_icon : $DEFAULT_RULE_ICON;
}

sub _exists_icon {
    my ( $self, $icon ) = @_;

    return 0 unless $icon;

    if ( $icon =~ m{^/static} ) {
        return -e "root/$icon";
    }
    my ($feature_path) = $icon =~ m{^(.*)/};

    return -e "$ENV{CLARIVE_BASE}/features/$feature_path/root/$icon";
}

sub _update_report_children {
    my ( $self, $json ) = @_;

    $json->{icon} = $self->get_icon_for_reports( $json->{icon} ) if $json->{icon};
    foreach my $child ( _array $json->{children} ) {
        $child->{children} = $self->_update_report_children($child) || [];
    }
}

sub _update_report_icons {
    my ( $self, $report ) = @_;
    foreach my $select ( _array $report->{selected} ) {
        $self->_update_report_children($select);
    }
    mdb->master_doc->update( { mid => $report->{mid} }, { '$set' => { selected => $report->{selected} } } );
}

sub update_reports_icons {
    my ( $self, %p ) = @_;

    my $reports = mdb->master_doc->find( { collection => 'report' } );
    while ( my $report = $reports->next ) {
        $self->_update_report_icons($report);
        my $yaml = _dump( mdb->master_doc->find_one( { mid => $report->{mid} } ) );
        if ($yaml) {
            $yaml =~ s{expanded: '0'}{expanded: !!perl/scalar:JSON::PP::Boolean 0}g;
            $yaml =~ s{expanded: '1'}{expanded: !!perl/scalar:JSON::PP::Boolean 1}g;
            $yaml =~ s{leaf: '0'}{leaf: !!perl/scalar:JSON::PP::Boolean 0}g;
            $yaml =~ s{leaf: '1'}{leaf: !!perl/scalar:JSON::PP::Boolean 1}g;
            mdb->master_doc->update( { mid => $report->{mid} }, { '$set' => { yaml => $yaml } } )
              if ( $report->{yaml} );
            mdb->master->update( { mid => $report->{mid} }, { '$set' => { yaml => $yaml } } );
        }
    }
}

sub downgrade {

}

sub get_icon_for_reports {
    my $self = shift;
    my ($icon) = @_;
    return $DEFAULT_REPORT_ICON unless $icon;

    my %report_icon = (
        '/static/images/icons/field.png'           => '/static/images/icons/ci-report-selected-field.svg',
        '/static/images/icons/field.svg'           => '/static/images/icons/ci-report-selected-field.svg',
        '/static/images/icons/where.svg'           => '/static/images/icons/ci-report-filter-field.svg',
        '/static/images/icons/where.png'           => '/static/images/icons/ci-report-filter-field.svg',
        '/static/images/icons/topic.svg'           => '/static/images/icons/ci-report-selected-category.svg',
        '/static/images/icons/topic_one.png'       => '/static/images/icons/ci-report-selected-category.svg',
        '/static/images/icons/topic.png'           => '/static/images/icons/ci-report-selected-category.svg',
        '/static/images/icons/folder_database.png' => '/static/images/icons/ci-report-category.svg',
        '/static/images/icons/folder_database.svg' => '/static/images/icons/ci-report-category.svg',
        '/static/images/icons/folder-database.svg' => '/static/images/icons/ci-report-category.svg',
        '/static/images/icons/folder_explore.png'  => '/static/images/icons/ci-report-field.svg',
        '/static/images/icons/folder_explore.svg'  => '/static/images/icons/ci-report-field.svg',
        '/static/images/icons/folder_magnify.png'  => '/static/images/icons/ci-report-field.svg',
        '/static/images/icons/folder-explore.svg'  => '/static/images/icons/ci-report-field.svg',
        '/static/images/icons/folder_find.png'     => '/static/images/icons/ci-report-filter.svg',
        '/static/images/icons/folder_find.svg'     => '/static/images/icons/ci-report-filter.svg',
        '/static/images/icons/folder-find.svg'     => '/static/images/icons/ci-report-filter.svg',
        '/static/images/icons/folder_go.svg'       => '/static/images/icons/ci-report-sort.svg',
        '/static/images/icons/folder_go.png'       => '/static/images/icons/ci-report-sort.svg',
        '/static/images/icons/folder-go.svg'       => '/static/images/icons/ci-report-sort.svg',
        '/static/images/icons/arrow_down.gif'      => '/static/images/icons/ci-report-sort-desc.svg',
        '/static/images/icons/arrow-down.gif'      => '/static/images/icons/ci-report-sort-desc.svg',
        '/static/images/icons/arrow-down.svg'      => '/static/images/icons/ci-report-sort-desc.svg',
        '/static/images/icons/arrow_down.svg'      => '/static/images/icons/ci-report-sort-desc.svg',
        '/static/images/icons/arrow_up.gif'        => '/static/images/icons/ci-report-sort-asc.svg',
        '/static/images/icons/arrow-up.gif'        => '/static/images/icons/ci-report-sort-asc.svg',
        '/static/images/icons/arrow-up.svg'        => '/static/images/icons/ci-report-sort-asc.svg',
        '/static/images/icons/arrow_up.svg'        => '/static/images/icons/ci-report-sort-asc.svg',

    );

    return $report_icon{$icon} || $DEFAULT_REPORT_ICON;
}

sub get_icon_from_register_key {
    my $self = shift;
    my ($icon) = @_;

    return undef unless $icon;

    my %registed_icon = (
        'fieldlet.include_into'                   => '/static/images/icons/fieldlet-included-into.svg',
        'fieldlet.attach_file'                    => '/static/images/icons/fieldlet-attach-file.svg',
        'fieldlet.progressbar'                    => '/static/images/icons/fieldlet-progressbar.svg',
        'fieldlet.calculated_number'              => '/static/images/icons/fieldlet-calculated-number.svg',
        'fieldlet.datetime'                       => '/static/images/icons/fieldlet-datetime.svg',
        'fieldlet.time'                           => '/static/images/icons/fieldlet-time.svg',
        'fieldlet.ci_list'                        => '/static/images/icons/fieldlet-ci-list.svg',
        'fieldlet.ci_grid'                        => '/static/images/icons/fieldlet-ci-grid.svg',
        'fieldlet.combo'                          => '/static/images/icons/fieldlet-combo.svg',
        'fieldlet.dbi_query'                      => '/static/images/icons/fieldlet-dbi-query.svg',
        'fieldlet.download_all_files'             => '/static/images/icons/fieldlet-download-all.svg',
        'fieldlet.grid_editor'                    => '/static/images/icons/fieldlet-grid-editor.svg',
        'fieldlet.milestones'                     => '/static/images/icons/fieldlet-milestones.svg',
        'fieldlet.env_planner'                    => '/static/images/icons/fieldlet-env-planner.svg',
        'fieldlet.scheduler'                      => '/static/images/icons/fieldlet-scheduler.svg',
        'fieldlet.html_editor'                    => '/static/images/icons/fieldlet-html-editor.svg',
        'fieldlet.pagedown'                       => '/static/images/icons/fieldlet-pagedown.svg',
        'fieldlet.pills'                          => '/static/images/icons/fieldlet-pills.svg',
        'fieldlet.status_chart_pie'               => '/static/images/icons/fieldlet-status-chart-pie.svg',
        'fieldlet.status_changes'                 => '/static/images/icons/fieldlet-status-changes.svg',
        'fieldlet.topic_grid'                     => '/static/images/icons/fieldlet-topic-grid.svg',
        'fieldlet.checkbox'                       => '/static/images/icons/fieldlet-checkbox.svg',
        'fieldlet.separator'                      => '/static/images/icons/fieldlet-separator.svg',
        'fieldlet.text'                           => '/static/images/icons/fieldlet-text.svg',
        'fieldlet.text_plain'                     => '/static/images/icons/fieldlet-text-plain.svg',
        'fieldlet.number'                         => '/static/images/icons/fieldlet-number.svg',
        'fieldlet.system.status_new'              => '/static/images/icons/fieldlet-system-status.svg',
        'fieldlet.system.moniker'                 => '/static/images/icons/fieldlet-system-moniker.svg',
        'fieldlet.system.title'                   => '/static/images/icons/fieldlet-system-title.svg',
        'fieldlet.system.description'             => '/static/images/icons/fieldlet-system-description.svg',
        'fieldlet.system.revisions'               => '/static/images/icons/fieldlet-system-revisions.svg',
        'fieldlet.system.release'                 => '/static/images/icons/fieldlet-system-release.svg',
        'fieldlet.system.release_version'         => '/static/images/icons/fieldlet-system-release-version.svg',
        'fieldlet.system.projects'                => '/static/images/icons/fieldlet-system-projects.svg',
        'fieldlet.system.users'                   => '/static/images/icons/fieldlet-system-users.svg',
        'fieldlet.system.topics'                  => '/static/images/icons/fieldlet-system-topics.svg',
        'fieldlet.system.list_topics'             => '/static/images/icons/fieldlet-system-list-topics.svg',
        'fieldlet.system.cis'                     => '/static/images/icons/fieldlet-system-cis.svg',
        'fieldlet.system.tasks'                   => '/static/images/icons/fieldlet-system-tasks.svg',
        'fieldlet.required.category'              => '/static/images/icons/fieldlet-required-category.svg',
        'dashlet.job.last_jobs'                   => '/static/images/icons/dashlet-job-last.svg',
        'dashlet.job.list_jobs'                   => '/static/images/icons/dashlet-job-list.svg',
        'dashlet.job.list_baseline'               => '/static/images/icons/dashlet-job-bl.svg',
        'dashlet.job.chart'                       => '/static/images/icons/dashlet-job-chart.svg',
        'dashlet.job.day_distribution'            => '/static/images/icons/dashlet-job-day.svg',
        'dashlet.ci.graph'                        => '/static/images/icons/dashlet-ci-graph.svg',
        'dashlet.topic.number_of_topics'          => '/static/images/icons/dashlet-topic-chart.svg',
        'dashlet.topic.list_topics'               => '/static/images/icons/dashlet-topic-list.svg',
        'dashlet.topic.topics_by_date_line'       => '/static/images/icons/dashlet-topic-dateline.svg',
        'dashlet.topic.topics_burndown'           => '/static/images/icons/dashlet-topic-burndown.svg',
        'dashlet.topic.topics_period_burndown'    => '/static/images/icons/dashlet-topic-period.svg',
        'dashlet.topic.topics_burndown_ng'        => '/static/images/icons/dashlet-topic-ng.svg',
        'dashlet.topic.gauge'                     => '/static/images/icons/dashlet-topic-gauge.svg',
        'dashlet.topic.topic_roadmap'             => '/static/images/icons/dashlet-topic-roadmap.svg',
        'dashlet.topic.calendar'                  => '/static/images/icons/dashlet-topic-calendar.svg',
        'dashlet.iframe'                          => '/static/images/icons/dashlet-iframe.svg',
        'dashlet.email'                           => '/static/images/icons/dashlet-email.svg',
        'dashlet.html'                            => '/static/images/icons/dashlet-html.svg',
        'dashlet.swarm'                           => '/static/images/icons/dashlet-swarm.svg',
        'service.workflow.transition'             => '/static/images/icons/service-workflow-transition.svg',
        'service.workflow.transition_match'       => '/static/images/icons/service-workflow-match.svg',
        'service.topic.upload'                    => '/static/images/icons/service-topic-upload.svg',
        'service.auth.ok'                         => '/static/images/icons/service-auth-ok.svg',
        'service.config'                          => '/static/images/icons/service-config.svg',
        'service.git.create_branch'               => '/static/images/icons/service-git-branch.svg',
        'service.git.newjob'                      => '/static/images/icons/service-git-newjob.svg',
        'service.git.create_tag'                  => '/static/images/icons/service-git-tag.svg',
        'service.ci.create'                       => '/static/images/icons/service-ci-create.svg',
        'service.git.delete_reference'            => '/static/images/icons/service-git-delete.svg',
        'service.auth.deny'                       => '/static/images/icons/service-auth-deny.svg',
        'service.dispatcher'                      => '/static/images/icons/service-dispatcher.svg',
        'service.daemon.email'                    => '/static/images/icons/service-daemon-email.svg',
        'service.email.flush'                     => '/static/images/icons/service-email-flush.svg',
        'service.catalog.form'                    => '/static/images/icons/service-catalog-form.svg',
        'service.get_date'                        => '/static/images/icons/service-get-date.svg',
        'service.topic.get_with_condition'        => '/static/images/icons/service-topic-condition.svg',
        'service.project.import_template'         => '/static/images/icons/service-project-template.svg',
        'service.ci.load'                         => '/static/images/icons/service-ci-load.svg',
        'service.ci.load_related'                 => '/static/images/icons/service-ci-related.svg',
        'service.user.load'                       => '/static/images/icons/service-user-load.svg',
        'service.topic.load'                      => '/static/images/icons/service-topic-load.svg',
        'service.topic.related'                   => '/static/images/icons/service-topic-related.svg',
        'service.auth.message'                    => '/static/images/icons/service-auth-message.svg',
        'service.git.merge'                       => '/static/images/icons/service-git-merge.svg',
        'service.purge.daemon'                    => '/static/images/icons/service-purge-daemon.svg',
        'service.git.rebase'                      => '/static/images/icons/service-git-rebase.svg',
        'service.topic.remove'                    => '/static/images/icons/service-topic-remove.svg',
        'service.restart_server'                  => '/static/images/icons/service-restart-server.svg',
        'service.script.run_script'               => '/static/images/icons/service-script-run.svg',
        'service.ldap.search'                     => '/static/images/icons/service-ldap-search.svg',
        'service.catalog.service'                 => '/static/images/icons/service-catalog-service.svg',
        'service.catalog.task'                    => '/static/images/icons/service-catalog-task.svg',
        'service.catalog.task_group'              => '/static/images/icons/service-catalog-group.svg',
        'service.ci.update'                       => '/static/images/icons/service-ci-update.svg',
        'service.event.daemon'                    => '/static/images/icons/service-event-daemon.svg',
        'service.scheduler'                       => '/static/images/icons/service-scheduler.svg',
        'service.scheduler.run_once'              => '/static/images/icons/service-scheduler-run.svg',
        'service.scheduler.run_once'              => '/static/images/icons/service-scheduler-test.svg',
        'service.validate.stash_variables'        => '/static/images/icons/service-validate-stash.svg',
        'service.job.daemon'                      => '/static/images/icons/service-job-daemon.svg',
        'service.topic.inactivity_daemon'         => '/static/images/icons/service-topic-inactivity.svg',
        'statement.call'                          => '/static/images/icons/statement-call.svg',
        'statement.catalog.if.var'                => '/static/images/icons/statement-catalog-if.svg',
        'statement.catalog.step'                  => '/static/images/icons/statement-catalog-step.svg',
        'statement.perl.code'                     => '/static/images/icons/statement-perl-code.svg',
        'statement.perl.do'                       => '/static/images/icons/statement-perl-do.svg',
        'statement.if.else'                       => '/static/images/icons/statement-if-else.svg',
        'statement.if.elsif'                      => '/static/images/icons/statement-if-elsif.svg',
        'statement.fail'                          => '/static/images/icons/statement-fail.svg',
        'statement.perl.for'                      => '/static/images/icons/statement-perl-for.svg',
        'statement.perl.group'                    => '/static/images/icons/statement-perl-group.svg',
        'statement.step'                          => '/static/images/icons/statement-step.svg',
        'statement.log'                           => '/static/images/icons/statement-log.svg',
        'statement.perl.eval'                     => '/static/images/icons/statement-perl-eval.svg',
        'statement.code.server'                   => '/static/images/icons/statement-code-server.svg',
        'statement.step'                          => '/static/images/icons/statement-step.svg',
        'statement.sub'                           => '/static/images/icons/statement-sub.svg',
        'statement.shortcut'                      => '/static/images/icons/statement-shortcut.svg',
        'statement.parallel.wait'                 => '/static/images/icons/statement-parallel-wait.svg',
        'service.topic.change_status'             => '/static/images/icons/service-topic-status.svg',
        'service.topic.status'                    => '/static/images/icons/service-topic-change-status.svg',
        'service.git.checkout'                    => '/static/images/icons/service-git-checkout.svg',
        'service.changeset.checkout.bl'           => '/static/images/icons/service-changeset-bl.svg',
        'service.changeset.checkout.bl_all_repos' => '/static/images/icons/service-changeset-bl-all.svg',
        'service.changeset.checkout'              => '/static/images/icons/service-changeset-checkout.svg',
        'service.db.commit_all_transactions'      => '/static/images/icons/service-db-commit.svg',
        'service.topic.create'                    => '/static/images/icons/service-topic-create.svg',
        'service.db.backup'                       => '/static/images/icons/service-db-backup.svg',
        'service.db.deploy_sql'                   => '/static/images/icons/service-db-deploy.svg',
        'service.git.job_elements'                => '/static/images/icons/service-git-job.svg',
        'service.ci.invoke'                       => '/static/images/icons/service-ci-invoke.svg',
        'service.git.link_revision_to_topic'      => '/static/images/icons/service-git-link.svg',
        'service.fileman.parse_config'            => '/static/images/icons/service-fileman-parse.svg',
        'service.changeset.items'                 => '/static/images/icons/service-changeset-items.svg',
        'service.changeset.natures'               => '/static/images/icons/service-changeset-natures.svg',
        'service.job.pause'                       => '/static/images/icons/service-job-pause.svg',
        'service.job.rename_items'                => '/static/images/icons/service-job-rename.svg',
        'service.sed'                             => '/static/images/icons/service-sed.svg',
        'service.approval.request'                => '/static/images/icons/service-approval-request.svg',
        'service.web.rest'                        => '/static/images/icons/service-web-rest.svg',
        'service.db.rollback_all_transactions'    => '/static/images/icons/service-db-rollback.svg',
        'service.job.sleep'                       => '/static/images/icons/service-job-sleep.svg',
        'service.changeset.sync_baselines'        => '/static/images/icons/service-changeset-sync.svg',
        'service.job.system_messages'             => '/static/images/icons/service-job-sms.svg',
        'service.changeset.update_baselines'      => '/static/images/icons/service-changeset-baselines.svg',
        'service.changeset.update'                => '/static/images/icons/service-changeset-update.svg',
        'service.changeset.update_bls'            => '/static/images/icons/service-changeset-update-bls.svg',
        'service.topic.update'                    => '/static/images/icons/service-topic-update.svg',
        'service.changeset.verify_revisions'      => '/static/images/icons/service-changeset-verify.svg',
        'service.web.request'                     => '/static/images/icons/service-web-request.svg',
        'service.scripting.windows_service'       => '/static/images/icons/service-scripting-windows.svg',
        'service.fileman.foreach'                 => '/static/images/icons/service-fileman-foreach.svg',
        'service.fileman.tar'                     => '/static/images/icons/service-fileman-tar.svg',
        'service.fileman.zip'                     => '/static/images/icons/service-fileman-zip.svg',
        'service.fileman.tar_nature'              => '/static/images/icons/service-fileman-tar-nature.svg',
        'service.fileman.zip_nature'              => '/static/images/icons/service-fileman-zip-nature.svg',
        'service.fileman.ship'                    => '/static/images/icons/service-fileman-ship.svg',
        'service.fileman.retrieve'                => '/static/images/icons/service-fileman-retrieve.svg',
        'service.fileman.sync_remote'             => '/static/images/icons/service-fileman-sync.svg',
        'service.fileman.mkpath_remote'           => '/static/images/icons/service-fileman-mkpath.svg',
        'service.fileman.store'                   => '/static/images/icons/service-fileman-store.svg',
        'service.fileman.write'                   => '/static/images/icons/service-fileman-write.svg',
        'service.fileman.rm'                      => '/static/images/icons/service-fileman-rm.svg',
        'service.fileman.rmtree'                  => '/static/images/icons/service-fileman-rmtree.svg',
        'service.fileman.write_config'            => '/static/images/icons/service-fileman-config.svg',
        'service.parsing.parse_files'             => '/static/images/icons/service-parse-files.svg',
        'service.scripting.local'                 => '/static/images/icons/service-scripting-local.svg',
        'service.scripting.remote'                => '/static/images/icons/service-scripting-remote.svg',
        'service.scripting.remote_eval'           => '/static/images/icons/service-scripting-eval.svg',
        'service.templating.transform'            => '/static/images/icons/service-templating-transform.svg',
        'service.event.run_once'                  => '/static/images/icons/service-event-run-once.svg',
        'service.notify.create'                   => '/static/images/icons/service-send-notification.svg',
        'service.echo'                            => '/static/images/icons/service-echo.svg',
        'service.fail'                            => '/static/images/icons/service-fail.svg',
        'service.job.new'                         => '/static/images/icons/service-job-new.svg',
        'service.job.create'                      => '/static/images/icons/service-job-create.svg',
        'service.job.dummy'                       => '/static/images/icons/service-job-dummy.svg',
        'service.job.init'                        => '/static/images/icons/service-job-init.svg',
        'service.job.footprint'                   => '/static/images/icons/service-job-footprint.svg',
        'statement.include'                       => '/static/images/icons/service-job-footprint.svg',
        'service.artifacts.publish'               => '/artifacts/service-publish-artifacts.svg',
        'service.artifactlocal.index_catalog'     => '/artifacts/git.svg',
        'service.sfrepository.create_tags'        => '/force.com/service-create-tags.svg',
        'service.forcecom.execute_task'           => '/force.com/service-execute-task.svg',
        'service.forcecom.generate_package_xml'   => '/force.com/service-generate-package-xml.svg',
        'fieldlet.system.ucm_files'               => '/ucm/logo-ucm.svg',
        'service.dbmaestro.deploy'                => '/dbmaestro/service-dbmaestro-deploy.svg',
    );

    return $registed_icon{$icon} || undef;
}

1;
