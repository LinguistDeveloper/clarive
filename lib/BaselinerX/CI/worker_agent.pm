package BaselinerX::CI::worker_agent;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging _file _dir);
use v5.10;

has workerid   => qw(is rw isa Str lazy 1), default => sub { 
    my ($self)=@_;
    my $wid = $self->_whos_capable( $self->cap );
    $wid or Util->_throw( Util->_loc( 'Could not find a worker capable of %1', $self->cap ) );
    return $wid;
};
has cap        => qw(is rw isa Str default '');

has db => qw(is ro lazy 1), default => sub { 
    require Redis;
    Redis->new;
};

has queue => qw(is ro lazy 1), default => sub { 
    require Redis;
    Redis->new;
};

has_array 'destroy_list';

has chunk_size => qw(is ro lazy 1), default => sub{ 64 * 1024 }; # 64K
has timeout_file => qw(is ro default 10);  # if we don't get blpop stuff in x seconds, the file is done - careful with large chunk_sizes, may take more
has wait_frequency => qw(is rw default 5);
has cap_wait => qw(is rw default 2);   # how long to wait for worker responses

with 'Baseliner::Role::CI::Agent';

=head2 put_file

Sends file or data over.

    $wa->put_file({ local=>'/tmp/local.tar', remote=>'/tmp/remote.tar' });
    $wa->put_file({ data=>("A" x 10000), remote=>'/tmp/xx' });

=cut
method put_file( :$local=undef, :$remote, :$group='', :$user=$self->user, :$data=undef  ) {
    defined $local or defined $data or Util->_throw( 'Missing parameter local or data' );
    $remote or Util->_throw( 'Missing parameter remote' );
    
    my $chunk_size = $self->chunk_size(); 
    my $file_size;
    if( defined $local ) {
        my $f = Util->_file( $local ); 
        Util->_fail( Util->_loc( 'Local file `%1` not found', $f) ) unless -e $f;
        $file_size = $f->stat->size;
    } else {
        $file_size = length( $data );
    }
    
    $self->_worker_do( 
        put_file => { filepath=>$remote, filesize=>$file_size },
        start    => sub {
            my ($msg_id) = @_;
            
            if( defined $local ) {
                # send file
                open my $ff, '<:raw', $local or Util->_throw( "ERROR opening file: $!" );
                my $chunk;
                my $k=1;
                while( sysread $ff, $chunk, $chunk_size ) {
                    #my $enc = unpack 'H*', $chunk;
                    #my $list_len = $self->db->rpush( "queue:$msg_id:file", $enc ); 
                    my $list_len = $self->db->rpush( "queue:$msg_id:file", MIME::Base64::encode_base64( $chunk ) );
                }
                close $ff;
            } else {
                # send data
                for( my $pos=0; $pos<$file_size; $pos+=$chunk_size ) {
                    my $list_len = $self->db->rpush( "queue:$msg_id:file", 
                        MIME::Base64::encode_base64( substr($data,$pos,$chunk_size) ) );
                }
            }
        }
    );
}

=head2 

Tars a directory and ships it remotely.

    $wa->put_dir({ local=>'/tmp/xxx', remote=>'/tmp/ddd', owner=>'myuser:mygroup', replace=>1 });

=cut
sub put_dir {
    my ($self,$p) = @_;
    my $local = $p->{local} or Util->_throw( 'Missing parameter local' );
    my $remote = $p->{remote} or Util->_throw( 'Missing parameter remote' );
    my $owner = [ split /:/, $p->{owner} ] if defined $p->{owner};
    my $replace = $p->{replace};  # replace destination dir?
    
    require Archive::Tar; 
    my $fn = sprintf "%s-%s", $self->workerid, Util->_nowstamp; 
    $fn = Util->_name_to_id( $fn );
    $fn = $fn . '.tar';
    # build local tar
    my $local_tar = Util->_file( Util->_tmp_dir, $fn );
    my $tar = Archive::Tar->new or _throw $!;
    my $dir = Util->_dir( $local );
    $dir->recurse( callback=>sub{
        my $f = shift;
        #return if $f->is_dir;
        my $rel = $f->relative( $dir );
        say "ADDING $rel";
        my $stat = $f->stat;
        if( $f->is_dir ) {
            # directory with empty data
            my $tf = Archive::Tar::File->new(
                data => "$rel", '', {
                    type  => 5,             # type 5=DIR, type 0=FILE
                    mtime => $stat->mtime,
                    ( defined $owner ? ( uname =>$owner->[0], gname=>$owner->[1] ) : () )
                });
            $tar->add_files($tf);
        } else {
            # file
            my $tf = Archive::Tar::File->new( 
                data=>"$rel", scalar($f->slurp), 
                {   type=>0, 
                    mtime=>$stat->mtime,
                    mode =>$stat->mode,
                    ( defined $owner ? ( uname =>$owner->[0], gname=>$owner->[1] ) : () )
                });
            $tar->add_files( $tf );
        }
    });
    say "WRITING $local_tar";
    $tar->write( $local_tar );
    # send to remote tar
    my $remote_tar = $self->remote_eval('File::Spec->catfile( File::Spec->tmpdir, $stash )', "remote-$fn" );
    $self->put_file({ local=>$local_tar, remote=>$remote_tar });
    # mkpath, untar, delete
    $self->remote_eval(q{
        if( $stash->{replace} ) {
            rmtree( $stash->{remote} ) if length $stash->{remote} > 4; 
        }
        if( ! -e $stash->{remote} ) {
            mkpath( $stash->{remote} );
        }
        chdir $stash->{remote};
        system 'tar', 'xvf', $stash->{tar_file};
        unlink $stash->{tar_file};
        1;
    },{ remote=>$remote, tar_file=>$remote_tar, replace=>$replace });
    unlink $local_tar;
    1;
}

method get_file( :$local, :$remote, :$group='', :$user=$self->user  ) {
    $self->_worker_do( get_file => { filepath=>$remote },
        start => sub {
            my ($msg_id) = @_;
            my $key = "queue:$msg_id:file";
            open my $ff, '>:raw', $local or Util->_throw( "ERROR opening file '$local': $!" );
            my $k = 1;
            while( my $chunk = $self->db->blpop( $key, $self->timeout_file ) ) {
                # chunk 0: key, 1: data
                print $ff MIME::Base64::decode_base64( $chunk->[1] );
            }
            close $ff;
        }
    );
}

method file_exists( $file_or_dir ) {
    $self->execute( 'test', '-r', $file_or_dir ); # check it exists
    return !$self->rc; 
}

=head2

Execute a command remotely with system. Returns 
the merged stdin + stderr.

    say "LS =" . $wa->execute('ls',-la);
    say "OUT=" . $wa->output;
    say "RC =" . $wa->rc;
    say "RET=" . $wa->ret;

=cut
sub execute {
    my $self = shift;
    my $tmout = $self->timeout;
    alarm $tmout if $tmout; 
    local $SIG{ALRM} = sub { _fail _loc 'worker agent error: timeout during execute (tmout=%1 sec)', $tmout } if $tmout;
    my %p = %{ shift() } if ref $_[0] eq 'HASH';
    my @cmd = @_;
    my $res = $self->remote_eval( q{ 
        my $merged = Capture::Tiny::tee_merged(sub{ 
            my $olddir = Cwd::cwd;
            my $cr = chdir $stash->{chdir};
            die $! if !$cr; 
            print "Changed dir to " . $stash->{chdir}, "\n";
            system @{ $stash->{cmd} };
            my $rc = $?;
            print "Changed dir back to " . $olddir, "\n";
            chdir $olddir;
            die $! if $rc;
        });
    }, { cmd=>\@cmd, chdir=>$p{chdir} } );
    alarm 0;
    return $self->ret;
}

sub chmod {
    my ($self,$mode,@files)=@_;
    $self->remote_eval( q(
        my $mode = oct($stash->{mode}) || return "Invalid mode: $stash->{mode}\n";
        my $ret = chmod( $mode, @{$stash->{files}} );
        return $ret == 0 ? $! : 0;
    ), 
    { mode=>$mode, files=>\@files });
    $self->rc( 1 ) if $self->ret && !ref $self->ret;
    $self->output( $self->ret ) if $self->ret && !ref $self->ret;

    return $self->tuple;
}

sub chown {
    my ($self,$perm,@files)=@_;
    $self->execute( 'chown', $perm, @files );
    return $self->tuple;
}

sub error {}
sub get_dir {}
sub mkpath {}
sub rmpath {}

sub _msgid {
    Data::UUID->new->create_from_name_b64( 'clarive', 'worker-agent');
}

sub remote_eval {
    my ($self, $code, $stash ) = @_;
    
    $self->_worker_do( 
        eval => { code=>$code//'print "pong"', stash=>$stash }, 
        done => sub {
           my ($msg_id, $res ) = @_;
           #say "DONE!!!!=". $out->{output};
        }
    );
    return $self->ret;
}

sub cleanup_queue {
    my ($self) = @_;
    if( my @patterns = $self->destroy_list_elements ) {
       Util->_debug( "DESTROY queue items: @patterns" );
       for my $pattern ( @patterns  ) {
           next unless ref $self->db;
           if( my @keys = $self->db->keys( $pattern ) ) {
               Util->_debug( "DELETING keys: @keys" );
               $self->db->del( @keys );
           }
       }
    }
}

#sub DEMOLISH {
#   my ($self) = @_;
#   $self->cleanup_queue;
#}

sub _worker_do {
    my ($self, $cmd, $cmd_data, %p ) = ( @_ ); 
    my $r = $self->db;
    my $q = $self->queue;

    #my %ws = $self->db->hgetall( 'queue:workers' );
    require MIME::Base64;
    require Data::UUID;
    
    # XXX ping - determine if we have the agent online 
    
    my $msg_id = $self->_msgid;
    $self->destroy_list_push( "queue:$msg_id:*" );
    my $id = $self->workerid or Util->_throw( 'Missing workerid' );
    
    # let me know someone got this
    $self->queue->subscribe( "queue:$msg_id:start", sub {
        my ($msg,$topic)=@_;
        $p{start}->($msg_id, @_) if ref $p{start};
    });

    # let me know if you are done
    $self->queue->subscribe( "queue:$msg_id:done", sub {
        my ($msg,$topic)=@_;
        my $res_key = "queue:$msg_id:result" ;
        my $result = $self->db->get( $res_key );
        $self->db->del( $res_key );
        if( length $result ) {
            $result = $self->parse_message( $result );
        }
        # load standard receivers
        $self->output( $result->{output} );
        $self->rc( $result->{rc} );
        $self->ret( $result->{ret} );
        # notify
        $p{done}->($msg_id, $result, @_) if ref $p{done} eq 'CODE';
        goto FINISH;
    });

    # my callbacks are setup, tell agent to fetch file
    $r->publish( "queue:$id:$cmd:$msg_id", 
       ref $cmd_data ? Util->_to_json( Util->_damn($cmd_data) ) : $cmd_data
    );

    # wait for done
    while(1) {
        $q->wait_for_messages( $p{loop_frequency} // $self->wait_frequency );
        $p{loop}->(@_) if ref $p{loop} eq 'CODE';
    }
    FINISH:
    return;   # do not return anything here, use the done callback
}

sub parse_message { 
    my($self,$msg) = @_; 
    my $msgtype = substr($msg,0,5);
    return $msgtype eq 'stor:' 
        ? Storable::thaw(substr($msg,5)) 
        : $msgtype eq 'yaml:' 
            ? Util->_load( substr($msg,5) )
            : Util->_from_json( $msg );
}

sub _whos_capable {
   my ($self,@caps) = @_;
   my $reqid = $self->_msgid;
   my $cap64 = MIME::Base64::encode_base64( join ',', @caps );
   $self->db->publish( "queue:capability:$reqid", $cap64 );
   if( my $who = $self->db->blpop( "queue:capable:$reqid", $self->cap_wait ) ) {
       my $workerid = $who->[1];
       say "$workerid can!";
       $self->db->del( "queue:capable:$reqid" );
       return $workerid;
   }
}

1;
