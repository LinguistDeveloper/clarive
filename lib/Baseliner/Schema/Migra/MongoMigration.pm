package Baseliner::Schema::Migra::MongoMigration;
use Baseliner::Mouse;
use Baseliner::Utils;
use v5.10;
use strict;
use Try::Tiny;

sub drop_all {
    say "Dropping Grid data for this DB...";
    mdb->grid->drop;
    say "Dropping DB...";
    mdb->db->drop;
}

sub cleanup {
    my ($self,%p) = @_;
    # bad inserts probably
    mdb->master->remove({ mid=>undef }); 
}

sub current {
    my ($self,%p) = @_;
    $self->run( tables=>[qw(bali_master)], no_assets=>1 );
    Baseliner->model('Topic')->migrate_docs();
}

sub run {
    my ($self,%p) = @_;
    $p{drop} //= 0;  # indicate if we should drop before inserting
    $self->drop_all if $p{drop_all};
    require Tie::IxHash;
    tie( my %ff, 'Tie::IxHash',
        bali_master       => 'master',
        bali_master_cal   => 'master_cal',
        # bali_master_kv    => 'master_kv',  # needed?
        bali_master_prefs => 'master_prefs',
        bali_master_rel   => 'master_rel',

        bali_topic_status              => 'status',
        bali_topic_categories          => 'category',
        bali_topic_categories_status   => 'category_status',
        bali_topic_categories_admin    => 'category_workflow',
        bali_topic_categories_priority => 'category_priority',
        bali_topic_fields_category     => 'category_fields',
        bali_topic_priority            => 'priority',
        bali_topic_view                => 'view',

        bali_calendar        => 'calendar',
        bali_calendar_window => 'calendar_window',
        bali_config          => 'config',
        bali_daemon          => 'daemon',
        bali_dashboard       => 'dashboard',
        bali_dashboard_role  => 'dashboard_role',
        bali_event           => { coll=>'event', seq=>1 },
        bali_event_rules     => { coll=>'event_log', seq=>1, capped=>1, size=>(1024*1024*50), max=>1000 },
        bali_job             => 'job',
        bali_log             => 'job_log',
        # bali_job_items       => 'job_items',
        bali_label           => 'label',
        bali_label_project   => 'label_project',

        bali_message                   => 'message',
        bali_message_queue             => { coll=>'message_queue', capped=>1, size=>(1024*1024*50), max=>( 1024*1024 ) },
        bali_notification              => 'notification',
        bali_post                      => 'post',
        bali_project                   => 'project',
        bali_project_directories       => 'project_directories',
        bali_project_directories_files => 'project_directories_files',

        bali_request        => 'request',
        bali_role           => 'role',
        bali_roleaction     => 'role_action',
        bali_roleuser       => 'role_user',
        bali_rule           => 'rule',
        #  bali_rule_statement => 'rule_statement', deprecated
        bali_scheduler      => 'scheduler',
        bali_sem            => 'sem',
        bali_sem_queue      => 'sem_queue',
        bali_sysoutdds      => 'sysoutdds',
        bali_user           => 'user',
        
        #  bali_topic_image               => 'image',              # convert to asset
        # bali_file_version    => 'file_version',                  # asset
        # bali_job_stash       => 'job_stash',                     # asset
        # bali_log             => 'log',                           # asset
        # bali_log_data        => 'log_data',                      # asset
        # bali_repo           => 'repo',                           # not migrated
        # bali_topic_fields_custom       => 'custom_fields',       # not needed, incorporated into topic
        # bali_repokeys       => 'repokeys',                       # what?
    );
    my ($ok,$nok)=(0,0);
    say "Database name: " . mdb->db->name;
    # migrate tables
    my $db = Util->_dbis;
    my %tables = map { $_=>1 } _array($p{tables}) ;
    my @tables_processed;
    for my $table ( grep { $p{tables} ? exists $tables{$_} : 1 } keys %ff ) {
       my $collname = $ff{$table};
       if( ref $collname ) {
           my $coll = $collname->{coll};
           mdb->collection( $coll )->drop if $p{drop};  # drop before creating capped collection
           mdb->db->run_command([ create=> $collname, capped=>boolean::true, size=>$collname->{size}, max=>$collname->{max} ])
                if( $collname->{capped} );
           # seq initialize to table or to mdb if exists. In drop mode, use DB top value
           if( $collname->{seq} ) {
               my $db_curr = $db->query(sprintf q{select max(id) from %s}, $table)->array->[0] + 1;
               my $mdb_curr = mdb->seq( $coll );
               my $seq_value = ($db_curr > $mdb_curr) || $p{drop} ? $db_curr : $mdb_curr;
               mdb->seq( $coll, "$seq_value" );
               say "SEQ $coll created with value=$seq_value";
           }
           $collname = $coll;
       } else {
           mdb->collection($collname)->drop;
       }
       push @tables_processed, $table;
       print sprintf "Dumping table %32s --> %-27s", $table,$collname;
       my $coll = mdb->collection( $collname );
       my $sch_ok = $ok;
       my $sch_nok = $nok;
       $self->each( $table, sub{
           my $r = shift;
           try { $coll->insert( $r ); $ok++ }
           catch { warn "\nERROR: $table: ".shift(); $nok++ }
       });
       say sprintf 'OK: %6s, NOK: %6s' , ( $ok - $sch_ok ) , ( $nok - $sch_nok );
    }
    say "OK=$ok - NOK=$nok";
    $self->assets( %tables ) unless $p{no_assets};
    $self->convert_schemas( %tables ) unless $p{no_convert};  
    mdb->index_all;
}

sub convert_schemas {
    my ($self,%tables) = @_;
    
    say "Converting schemas for tables: " . join keys %tables;

    if( !%tables || exists $tables{bali_user} ) {
        say "Converting schema user...";
        my %users = map { $_->{mid}=>$_ } mdb->user->find->all;
    }

    # label
    if( !%tables || exists $tables{bali_label} ) {
        say "Converting schema label...";
        # mdb->label->find->each(sub{
        #     my $lab = $_;
        #     my $uid = delete $lab->{mid_user};
        #     $lab->{
    }
    
    # master_rel dups
    my $rs = mdb->master_rel->find;
    my %rel_index;
    my $dup=0;
    print "Removing duplicates from master_rel...";
    while( my $r = $rs->next ) {
        my $key = join'|', @{$r}{qw(from_mid to_mid rel_field rel_type)};
        if( exists $rel_index{ $key } ) {
            say "Removing duplicate master_rel: " . $key;
            mdb->master_rel->remove( $r );
            $dup++;
        }
        $rel_index{ $key } = 1;
    }
    say "duplicates found: $dup";
    
    # master_doc
    if( !%tables || exists $tables{bali_master} ) {
        say "Converting master yaml to docs in master_doc...";
        mdb->master_doc->drop;
        $self->each('bali_master', sub{
            my $r = shift;
            #my $doc = Util->_load( delete $r->{yaml} ) // {};
            my $doc = try { ci->new( $r->{mid} ) } catch { undef };
            return unless $doc;
            $doc = { %$doc, %$r }; # merge yaml with master row, so that doc has all attributes for searching
            Util->_unbless( $doc );
            delete $doc->{yaml};
            $doc->{mid} = "$r->{mid}";
            mdb->clean_doc( $doc );
            mdb->master_doc->insert( $doc );
        });
    }
    
    # sequences
    if( !%tables || exists $tables{bali_master_seq} ) {
        mdb->master_seq->drop; 
        my $db = Util->_dbis;
        my $max_mid = $db->query('select max(mid) from bali_master')->array->[0];
        require List::Util;
        my $max_mid_mdb = List::Util::max(map { $_->{mid} } mdb->master_doc->find->fields({ mid=>1 })->all );
        mdb->seq('mid', ($max_mid_mdb > $max_mid ? $max_mid_mdb : $max_mid)+1 );
    }
    
    # topic
    if( !%tables || exists $tables{bali_topic} ) {
        print "Migrating bali_topic...";
        my $k = 0;
        mdb->topic->drop;
        my $coll = mdb->topic;
        $self->each('bali_topic', sub{
           my $r = shift;
           $self->topic( coll=>$coll, row=>$r );
           $k++;
        });
        say "$k rows migrated.";
    }
    
    # repository 
    #   migrate Repository saved.repl into mdb->repl
    #   migrate mvs.queue? no, not needed
    if( !%tables || exists $tables{bali_repo} ) {
        mdb->repl->drop;
        $self->each('bali_repo', sub{
           my $r = shift;
           return unless $r->{ns} =~ /repl/;
           my $t = $r->{ns};
           $t =~ s{^.*/(.*)$}{$1}g;
           #say $t;
           #say _dump $r;
           my $d = Util->_load($r->{data});
           #say _dump $d;
           my $doc = { %$d, text=>$t };
           mdb->repl->insert( $doc );
        });
        mdb->repo->drop; # in case it exists
    }
    
    say 'Done converting.';
}

sub assets {
    my ($self,%tables) = @_;
    
    say "Migrating assets for tables " . join ',', keys %tables;

    # log
    if( !%tables || exists $tables{bali_log} ) {
        my $k=0;
        print "Migrating log assets..."; 
        mdb->log->drop;
        mdb->grid->remove({ parent_collection=>'log' });
        my %not_found;
        $self->each('bali_log', sub{
            my $r = shift;
            my $d = delete $r->{data};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                $not_found{ $r->{id_job} } ++;
                #warn "ERROR: job $r->{id_job} not found for log id $r->{id}. Row ignored.";
                return;
            }
            my $mid = $job->{mid};
            my $ass = mdb->asset( $d, filename=>$r->{data_name}//'', parent_collection=>'log', parent_mid=>$mid );
            $ass->insert;
            $r->{data} = $ass->id;
            mdb->job_log->insert( $r );
            $k++;
            print "$k..." if ! $k % 1000;
        });
        say "$k rows migrated.";
        say "id_job not found: " . join ', ', map { "$_ (" . $not_found{$_} . ")" } keys %not_found if %not_found;
    }
    
    # log_data
    if( !%tables || exists $tables{bali_log_data} ) {
        my $k=0;
        print "Migrating log_data assets..."; 
        mdb->log_data->drop;
        mdb->grid->remove({ parent_collection=>'log_data' });
        $self->each('bali_log_data', sub{
            my $r = shift;
            my $d = delete $r->{data};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                warn "ERROR: job $r->{id_job} not found for log_data id $r->{id}. Row ignored.";
                return;
            }
            my $mid = $job->{mid};
            my $ass = mdb->asset( $d, filename=>$r->{name}//'', parent_collection=>'log_data', parent_mid=>$mid );
            $ass->insert;
            $r->{data} = $ass->id;
            mdb->log_data->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # job_stash
    if( !%tables || exists $tables{bali_job_stash} ) {
        my $k = 0;
        print "Migrating job_stash assets..."; 
        mdb->job_stash->drop;
        mdb->grid->remove({ parent_collection=>'job' });
        $self->each('bali_job_stash', sub{
            my $r = shift;
            my $d = delete $r->{stash};
            my $job = mdb->job->find_one({ id=>$r->{id_job} });
            if( !$job ) {
                warn "ERROR: job $r->{id_job} not found for stash id $r->{id}. Row ignored.";
                return;
            }
            my $ass = mdb->asset( $d, parent_collection=>'job', parent_mid=>$job->{mid}  );
            $ass->insert;
            $job->{stash} = $ass->id;
            mdb->job->save( $job );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # file_version 
    if( !%tables || exists $tables{bali_file_version} ) {
        my $k=0;
        print "Migrating file_version assets...";
        mdb->file_version->drop;
        mdb->grid->remove({ parent_collection=>'file_version' });
        $self->each('bali_file_version', sub{
            my $r = shift;
            my $d = delete $r->{filedata};
            my $ass = mdb->asset( $d, filename=>$r->{filename}, parent_collection=>'file_version', parent_mid=>$r->{mid} );
            $ass->insert;
            $r->{filedata} = $ass->id;
            mdb->file_version->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    # topic_image
    if( !%tables || exists $tables{bali_topic_image} ) {
        my $k=0;
        print "Migrating topic_image assets...";
        mdb->topic_image->drop;
        $self->each('bali_topic_image', sub{
            my $r = shift;
            my $d = delete $r->{img_data};
            $r->{mid} //= $r->{topic_mid};
            my $ass = mdb->asset( $d, parent_collection=>'topic_image', parent_mid=>$r->{topic_mid} );
            $ass->insert;
            $r->{img_data} = $ass->id;
            mdb->topic_image->insert( $r );
            $k++;
        });
        say "$k rows migrated.";
    }
    
    say 'Done migrating assets.';
}

sub each {
    my ($self, $table, $code) = @_;
    my $db = Util->_dbis;
    my $rs = $db->query( sprintf 'SELECT * FROM %s', $table );
    while( my $row = $rs->hash ) {
        $code->( $row ); 
    }
}

sub topic_security {
    my ( $self, %p ) = @_;
    for my $doc ( mdb->topic->find->all ) {
        my $meta = Baseliner->model('Topic')->get_meta( $doc->{mid} );
        die "Meta not found for $doc->{mid}" unless $meta;
        warn "Updating topic security for $doc->{mid}\n";
        my $sec = Baseliner->model('Topic')->update_project_security($meta,$doc,$doc);
        warn _dump($sec);
        mdb->topic->save( $doc );
    }
}

sub topic_labels {
    my ( $self, %p ) = @_;
    for my $doc ( mdb->topic->find->all ) {
        warn "Updating labels for topic #$doc->{mid}\n";
        $doc->{id_label} = [ 
            map  { $_->{id_label} } 
            DB->BaliTopicLabel->search({ id_topic=>"$doc->{mid}" },{ select=>'id_label' })->hashref->all ];
        mdb->topic->save( $doc );
    }
}

sub topic_status {
    my ( $self, %p ) = @_;
    for my $row ( DB->BaliTopic->search->hashref->all ) {
        warn "Updating status for topic #" . $row->{mid} . "\n";
        Baseliner->model('Topic')->update_category( $row->{mid}, $row->{id_category} ); 
        Baseliner->model('Topic')->update_category_status( $row->{mid}, $row->{id_category_status} );
    }
}

sub job_status_fix {
    # fix CIs that do not have its job_status correct due to old changes directed to BaliJob, now everything goes through CI
    DB->BaliJob->search->each(sub{
       my $r = shift;
       my $ci = ci->new( ns=>'job/' . $r->id );
       if( $ci ) {
           $ci->status( $r->status );
           $ci->step( $r->step );
           $ci->save;
       }
    });
}
    
sub topic_numify {
    my ( $self, %p ) = @_;
    for my $doc ( mdb->topic->find->all ) {
    }
}
    
sub master_and_rel {
    my ( $self, %p ) = @_;
    my $db = Util->_dbis();
    my @master = $db->query('select * from bali_master')->hashes;
    for my $r ( @master ) {
        mdb->master->update({ mid=>''.$r->{mid} }, $r, { upsert=>1 });
    }
    my @master_rel = $db->query('select * from bali_master_rel')->hashes;
    mdb->master_rel->drop;  # cleaner just to insert
    mdb->index_all('master_rel');  # so we have the master_rel uniques
    for my $r ( @master_rel ) {
        next if mdb->master_rel->find_one($r); # bali_master_rel may have tons of junk
        mdb->master_rel->insert( $r );
    }
    
}
    
sub topic {
    my ( $self, %p ) = @_;
    
    my $db = Util->_dbis;
    my $coll = $p{coll} // mdb->topic;
    my $r = $p{row} // $db->query('select * from bali_topic where mid=?', $p{mid} )->hash;
    my $mid = ''. ( $p{mid} // $r->{mid} );
    if( $mid && $p{replace} ) {
        $coll->remove({ mid=>$mid });
    }

    my $rs = $db->query( $self->topic_view, $r->{mid} );
    my $row = $rs->hash;
    return if !$row;
    my $doc = { %$row, %$r };
    $doc->{category} = mdb->category->find_one( { id => $r->{id_category} } );
    $doc->{category_status} = mdb->status->find_one( { id => $r->{id_category_status} } );
    $doc->{calevent} = '';

    #$doc->{created_on} = Class::Date->new( $doc->{created_on_epoch} ).""; # not needed, dates are correct comming out of oraclej
    #$doc->{modified_on} = Class::Date->new( $doc->{modified_on_epoch} )."";
    delete $doc->{$_} for grep /\./, keys $doc;
    my @fields = $db->query( 'select * from bali_topic_fields_custom where topic_mid=?', $r->{mid} )->hashes;
    my @rels = $db->query(
        'select r.rel_field, m.collection, m.name from bali_master_rel r,bali_master m where (m.mid=r.to_mid) and r.from_mid=?',
        $r->{mid}
    )->hashes;
    my @rels2 = $db->query(
        'select r.rel_field, m.collection, m.name from bali_master_rel r,bali_master m where (m.mid=r.from_mid) and r.to_mid=?',
        $r->{mid}
    )->hashes;
    my %cals = map {
        my $slot = Util->_name_to_id( $_->{slotname} );
        $_->{rel_field} => {
            $slot => {
                start_date      => $_->{start_date},
                end_date        => $_->{end_date},
                plan_start_date => $_->{plan_start_date},
                plan_end_date   => $_->{plan_end_date}
            }
            }
    } $db->query( 'select * from bali_master_cal c where c.mid=?', $r->{mid} )->hashes;

    #_debug \@rels;
    say "found custom fields for $r->{mid}: " . join ',', map { $_->{name} } @fields if @fields;

    my %fieldlets = map( {
            my $v = $_->{value_clob} || $_->{value};
                $v = try { _load($v) } catch { $v } if $v;
                ( $_->{name} => $v )
    } @fields );
    my %relations = map( {
            my $v = $_->{name};
                ( $_->{rel_field} => $v )
        } @rels,
        @rels2 );
    $doc = { %$doc, %cals, %fieldlets, %relations };
    delete $doc->{$_} for qw(sw_edit last_seen label_color label_name label_id);
    $coll->insert($doc);
}

sub clean_master_topic {
   for ( _dbis->query(q{select name,mid from bali_master m where m.collection='topic' and not exists 
    (select 1 from bali_topic t where t.mid=m.mid)})->hashes ){
        warn "Deleting master mid $_->{mid} not found in topic...";
        my $x = DB->BaliMaster->find($_->{mid});
        next unless $x;
        $x->delete
    } 
}

sub topic_view {
    qq{
    SELECT  T.MID TOPIC_MID,
            T.MID,
            T.TITLE,
            T.CREATED_ON,
            T.CREATED_BY,
            T.MODIFIED_ON,
            T.MODIFIED_BY,
            T.DESCRIPTION,
            T.STATUS, 
            NUMCOMMENT,
            C.ID CATEGORY_ID,
            C.NAME CATEGORY_NAME,
            T.PROGRESS,
            T.ID_CATEGORY_STATUS CATEGORY_STATUS_ID,
            S.NAME CATEGORY_STATUS_NAME,
            S.SEQ CATEGORY_STATUS_SEQ,
            S.TYPE CATEGORY_STATUS_TYPE,
            T.ID_PRIORITY AS PRIORITY_ID,
            TP.NAME PRIORITY_NAME,
            TP.RESPONSE_TIME_MIN,
            TP.EXPR_RESPONSE_TIME,
            TP.DEADLINE_MIN,
            TP.EXPR_DEADLINE,
            C.COLOR CATEGORY_COLOR,
            C.IS_CHANGESET,
            C.IS_RELEASE,
            L.ID LABEL_ID,
            L.NAME LABEL_NAME,
            L.COLOR LABEL_COLOR,
            P.MID AS PROJECT_ID,
            P.NAME AS PROJECT_NAME,
            MP.COLLECTION AS COLLECTION,
            F.FILENAME AS FILE_NAME,
            PS.TEXT AS TEXT,
            NUM_FILE,
            U.USERNAME ASSIGNEE,
            MA.MONIKER,
            cis_out.NAME CIS_OUT,
            cis_in.NAME CIS_IN,
            topics_in.TITLE REFERENCED_IN,
            topics_out.TITLE REFERENCES_OUT,
            DS.NAME directory
            FROM  BALI_TOPIC T
                    JOIN BALI_MASTER MA ON T.MID = MA.MID
                    LEFT JOIN BALI_TOPIC_CATEGORIES C ON T.ID_CATEGORY = C.ID
                    LEFT JOIN BALI_TOPIC_LABEL TL ON TL.ID_TOPIC = T.MID
                    LEFT JOIN BALI_LABEL L ON L.ID = TL.ID_LABEL
                    LEFT JOIN BALI_TOPIC_PRIORITY TP ON T.ID_PRIORITY = TP.ID
                    LEFT JOIN (SELECT COUNT(*) AS NUMCOMMENT, A.MID 
                                        FROM BALI_TOPIC A, BALI_MASTER_REL REL, BALI_POST B
                                        WHERE A.MID = REL.FROM_MID
                                        AND REL.TO_MID = B.MID
                                        AND REL.REL_TYPE = 'topic_post'
                                        GROUP BY A.MID) D ON T.MID = D.MID
                    LEFT JOIN (SELECT COUNT(*) AS NUM_FILE, E.MID 
                                        FROM BALI_TOPIC E, BALI_MASTER_REL REL1, BALI_FILE_VERSION G
                                        WHERE E.MID = REL1.FROM_MID
                                        AND REL1.TO_MID = G.MID
                                        AND REL1.REL_TYPE = 'topic_file_version'
                                        GROUP BY E.MID) H ON T.MID = H.MID                                         
                    LEFT JOIN BALI_TOPIC_STATUS S ON T.ID_CATEGORY_STATUS = S.ID
                    LEFT JOIN BALI_MASTER_REL REL_PR ON REL_PR.FROM_MID = T.MID AND REL_PR.REL_TYPE = 'topic_project'
                    LEFT JOIN BALI_PROJECT P ON P.MID = REL_PR.TO_MID
                    LEFT JOIN BALI_MASTER MP ON REL_PR.TO_MID = MP.MID AND MP.COLLECTION = 'project'
                    LEFT JOIN BALI_MASTER_REL REL_F ON REL_F.FROM_MID = T.MID AND REL_F.REL_TYPE = 'topic_file_version'
                    LEFT JOIN BALI_FILE_VERSION F ON F.MID = REL_F.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_PS ON REL_PS.FROM_MID = T.MID AND REL_PS.REL_TYPE = 'topic_post'
                    LEFT JOIN BALI_POST PS ON PS.MID = REL_PS.TO_MID
                    LEFT JOIN BALI_MASTER_REL REL_USER ON REL_USER.FROM_MID = T.MID AND REL_USER.REL_TYPE = 'topic_users'
                    LEFT JOIN BALI_USER U ON U.MID = REL_USER.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_topics_out ON rel_topics_out.FROM_MID = T.MID AND rel_topics_out.REL_TYPE = 'topic_topic'
                    LEFT JOIN BALI_TOPIC topics_out ON topics_out.MID = rel_topics_out.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_topics_in ON rel_topics_in.TO_MID = T.MID AND rel_topics_in.REL_TYPE = 'topic_topic'
                    LEFT JOIN BALI_TOPIC topics_in ON topics_in.MID = rel_topics_in.FROM_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_cis_out ON rel_cis_out.FROM_MID = T.MID AND rel_cis_out.REL_TYPE NOT IN( 
                        'topic_post','topic_file_version','topic_project','topic_users','topic_topic' )
                    LEFT JOIN BALI_MASTER cis_out ON cis_out.MID = rel_cis_out.TO_MID
                    
                    LEFT JOIN BALI_MASTER_REL rel_cis_in ON rel_cis_in.TO_MID = T.MID AND rel_cis_in.REL_TYPE NOT IN( 
                        'topic_post','topic_file_version','topic_project','topic_users','topic_topic' )
                    LEFT JOIN BALI_MASTER cis_in ON cis_in.MID = rel_cis_in.FROM_MID
                    
                    LEFT JOIN BALI_PROJECT_DIRECTORIES_FILES DF ON DF.ID_FILE = T.MID
                    LEFT JOIN BALI_PROJECT_DIRECTORIES DS ON DF.ID_DIRECTORY = DS.ID
            WHERE T.ACTIVE = 1
            AND T.MID = ?
    };
}
1;

__END__


---
- BaliProjectTree
- TopicView
- bali_calendar
- bali_calendar_window
- bali_config
- bali_daemon
- bali_dashboard
- bali_dashboard_role
- bali_event
- bali_event_rules
- bali_file_version
- bali_job
- bali_job_items
- bali_job_stash
- bali_label
- bali_label_project
- bali_log
- bali_log_data
- bali_master
- bali_master_cal
- bali_master_kv
- bali_master_prefs
- bali_master_rel
- bali_message
- bali_message_queue
- bali_notification
- bali_post
- bali_project
- bali_project_directories
- bali_project_directories_files
- bali_repo
- bali_repokeys
- bali_request
- bali_role
- bali_roleaction
- bali_roleuser
- bali_rule
- bali_rule_statement
- bali_scheduler
- bali_sem
- bali_sem_queue
- bali_sysoutdds
- bali_topic
- bali_topic_categories
- bali_topic_categories_admin
- bali_topic_categories_priority
- bali_topic_categories_status
- bali_topic_fields_category
- bali_topic_fields_custom
- bali_topic_image
- bali_topic_label
- bali_topic_priority
- bali_topic_status
- bali_topic_view
- bali_user

