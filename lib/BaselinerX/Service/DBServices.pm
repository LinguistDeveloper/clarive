package BaselinerX::Service::DBServices;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;

#with 'Baseliner::Role::Namespace::Create';
with 'Baseliner::Role::Service';


register 'service.db.deploy_sql' => {
    name    => 'Deploy SQL from Nature Items',
    icon    => '/static/images/ci/dbconn.png',
    form    => '/forms/db_deploy_sql.js',
    job_service  => 1,
    handler => \&deploy_sql,
};

sub deploy_sql {
    my ( $self, $c, $config ) = @_;
    _fail 'Missing db connection' unless length $config->{db};
    
    my $job          = $c->stash->{job};
    my $log          = $job->logger;
    my $stash        = $c->stash;
    my $job_dir      = $stash->{job_dir};
    my $items        = $stash->{nature_items} // $stash->{items};
    my $split        = $config->{split} // ';';
    my $split_mode   = $config->{split_mode} // 'auto';
    my $comment      = $config->{comment} // 'strip';
    my $mode         = $config->{mode} // 'direct';
    my $exists_action = $config->{exists_action} // 'drop';
    my $error_mode   = $config->{error_mode} // 'fail';
    my ($include_path,$exclude_path,$include_content,$exclude_content) = 
        @{ $config }{qw(include_path exclude_path include_content exclude_content)};
    
    my $tran_cnt = $stash->{_db_transaction_count} // 0;
    
    # get db CI
    for my $db ( Util->_array_or_commas( $config->{db} ) ) {
        $db = ci->new( $db ) unless ci->is_ci($db);
            
        $tran_cnt += 1;
    
        if( $config->{transactional} ) {
            push @{ $stash->{_state_db_transactions} }, { id=>$tran_cnt, db=>$db };
            try { $db->begin_work } catch { _debug "BEGIN WORK WARNING: " . shift() };
        }
        
        ITEM: for my $item ( _array( $items ) ) {
            
            # path checks
            my $path = $item->path;
            my $file = _file( $job_dir, $path );
            my $flag;
            IN: for my $in ( _array( $include_path ) ) {
                $flag //= 0;
                if( $path =~ _regex($in) ) {
                    $flag =$in;
                    last IN;
                }
            }
            if( defined $flag && !$flag ) {
                _debug "SQL not included path `$path` due to rule `$flag`";
                next ITEM;
            }
            for my $ex ( _array( $exclude_path ) ) {
                if( $path =~ _regex($ex) ) {
                    _debug "SQL excluded path `$path` due to rule `$ex`";
                    next ITEM;
                }
            }
            
            _debug "Checking content for sql item path: " . $path;
            
            # content check
            my $sql = $file->slurp;
            $flag = undef;
            for my $in ( _array( $include_content ) ) {
                $flag //= 0;
                if( $sql =~ _regex($in) ) {
                    $flag = $in;
                }
            }
            if( defined $flag && !$flag ) {
                _debug "SQL not included content due to rule `$flag`";
                next ITEM;
            }
            for my $ex ( _array( $exclude_content ) ) {
                if( $sql =~ _regex($ex) ) {
                    _debug "SQL excluded content due to rule `$ex`";
                    next ITEM;
                }
            }
            
            _log "Calling do for item path: " . $path;
            
            # call connection do
            my $ret = $db->dosql(
                sql          => $sql,
                mode         => $mode,
                split_mode   => $split_mode,
                comment      => $comment,
                exists_action => $exists_action,
                split        => _regex($split),
                error_mode   => $error_mode,
            );
            my $k=0;
            for my $st ( _array $ret->{queries} ) {
                $k++;
                my $msg = <<LOG;
=========| SQL |=======
$st->{sql}

=========| DROPS |=======
$st->{drops}

=========| SKIPS |=======
$st->{skips}

========| ERR |=========
$st->{err}

==========| RETURN |========
$st->{ret}
LOG
                if( !$st->{rc} ) {
                    $log->info( _loc('SQL Query %1 executed ok (mode %2)', "$tran_cnt.$k", $st->{mode}), $msg );
                } else {
                    my @errmsg = ( _loc('SQL %1 Query error (mode %3): %2',"$tran_cnt.$k",substr($st->{err},0,30),$st->{mode}), $msg );
                    if( $error_mode eq 'fail' ) {
                        $log->error( @errmsg ); 
                        _fail( _loc('Error processing SQL') );
                    } elsif( $error_mode eq 'warn' ) {
                        $log->warn( @errmsg ); 
                    } elsif( $error_mode eq 'ignore' ) {
                        # ignore...
                        $log->error( @errmsg ); 
                    } else {
                        # silent
                        # _debug( @errlog );  # not needed, should be enough with dbi_connection _log
                    }
                }
            }
        }
    }
    $stash->{_db_transaction_count} = $tran_cnt;
    $tran_cnt;
}   

register 'service.db.commit_all_transactions' => {
    name    => 'Commit All Transactions', 
    icon    => '/static/images/ci/dbconn.png',
    job_service  => 1,
    handler => \&commit_all,
};

register 'service.db.rollback_all_transactions' => {
    name    => 'Rollback All Transactions', 
    icon    => '/static/images/ci/dbconn.png',
    job_service  => 1,
    handler => \&rollback_all,
};

register 'service.db.backup' => {
    name    => 'DB Backup Schema Objects',
    icon    => '/static/images/ci/dbconn.png',
    job_service  => 1,
    handler => \&backup_schema,
};

sub backup_schema {
    my ( $self, $c, $config ) = @_;
    
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    
    $log->info( _loc('Schema backup ok') );
}

sub commit_all {
    my ( $self, $c, $config ) = @_;
    
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    for my $tran ( _array $stash->{_state_db_transactions} ) {
        $log->info( _loc( 'DB COMMIT transaction %1', $tran->{id} ) );
        $tran->{db}->commit;
    }
    delete $stash->{_state_db_transactions};  # cant' be seraialized
    return;
}   

sub rollback_all {
    my ( $self, $c, $config ) = @_;
    
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    for my $tran ( _array $stash->{_state_db_transactions} ) {
        $log->warn( _loc( 'DB ROLLBACK transaction %1', $tran->{id} ) );
        $tran->{db}->rollback;
    }
    delete $stash->{_state_db_transactions};  # cant' be seraialized
    return;
}   

1;
