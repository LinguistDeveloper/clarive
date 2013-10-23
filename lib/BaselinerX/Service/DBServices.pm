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
    handler => \&deploy_sql,
};

sub deploy_sql {
    my ( $self, $c, $config ) = @_;
    _fail 'Missing db connection' unless length $config->{db};
    
    my $job   = $c->stash->{job};
    my $log   = $job->logger;
    my $stash = $c->stash;
    my $job_dir = $stash->{job_dir};
    my $items = $stash->{nature_items} // $stash->{items};
    my $db = _ci( $config->{db} );
    
    $stash->{_db_transaction_count} //= 0;
    my $tran_cnt = $stash->{_db_transaction_count} + 1;
    
    if( $config->{transactional} ) {
        push @{ $stash->{_state_db_transactions} }, { id=>$tran_cnt, db=>$db };
        $db->begin_work;
    }
    
    for my $item ( _array( $items ) ) {
        my $file = _file( $job_dir, $item->path );
        my $sql = $file->slurp;
        $sql =~ s{--[^\n]*\r?\n}{\n}sg;
        my $ret = $db->dosql( sql => $sql, split => qr/;/, ignore => $config->{ignore} eq 'on' ? 1 : 0 );
        my $k=0;
        for my $st ( _array $ret->{queries} ) {
            $k++;
            if( !$st->{rc} ) {
                $log->info( _loc('SQL Query %1 executed ok', "$tran_cnt.$k"), $st->{sql} );
            } else {
                $log->error( _loc('SQL %1 Query error: %2', "$tran_cnt.$k", $st->{err} ), $st->{sql} );
            }
        }
    }
    $stash->{_db_transaction_count} += $tran_cnt;
    $tran_cnt;
}   

register 'service.db.commit_all_transactions' => {
    name    => 'Commit All Transactions', 
    icon    => '/static/images/ci/dbconn.png',
    handler => \&commit_all,
};

register 'service.db.rollback_all_transactions' => {
    name    => 'Rollback All Transactions', 
    icon    => '/static/images/ci/dbconn.png',
    handler => \&rollback_all,
};

register 'service.db.backup' => {
    name    => 'DB Backup Schema Objects',
    icon    => '/static/images/ci/dbconn.png',
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
