package Baseliner::Controller::Feature;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' }
use Git::Wrapper 0.025;
use Try::Tiny;

our $INSTALL_DIR = '.install';

register 'action.admin.upgrade' => {
    name => 'Upgrade features, plugins and modules',
};

register 'menu.admin.upgrade' => {
    action => 'action.admin.upgrade',
    title => 'Upgrades',
    label => 'Upgrades',
    icon  => '/static/images/icons/upgrade.png',
    url_comp => '/comp/feature.js',
    index => 1000,
};

sub restart_server : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
    if( defined $ENV{BASELINER_PARENT_PID} ) {
        # normally, this tells a start_server process to restart children
        _log _loc "Server restart requested. Using kill HUP $ENV{BASELINER_PARENT_PID}"; 
        kill HUP => $ENV{BASELINER_PARENT_PID};
    } else {
        _log _loc "Server restart requested. Using bali-web restart";
        `bali-web restart`;  # TODO this is brute force
    }
}

sub local_delete : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my $files = _from_json( $p->{files} );
        ref $files or _fail 'Missing parameter files';
        map { unlink $_ if -e $_ } @$files;
        { success => \1, msg => 'ok', };
    } catch {
        my $err = shift;
        { success => \0, msg => "$err", };
    };
    $c->forward('View::JSON');
}

sub local_get : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
    my $file = $p->{file};
    _fail _loc('File does not exist: %1', $file) unless -e $file;
    my $f = _file( $file );
    $c->res->cookies->{ $p->{id} } = { value=>1, expires=>time()+1000 } if $p->{id};
    $c->stash->{serve_filename} = $f->basename;
    $c->stash->{serve_body} = $f->slurp; 
    $c->forward('/serve_file');
}

sub install_cpan : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    $c->stash->{json} = try {
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my $files = _from_json( $p->{files} );
        ref $files or _fail 'Missing parameter files';
        # load cpanm from its file
        require App::cpanminus;  # check if it's here
        require File::Which;  # check if it's here
        push @log, _loc('Loading cpanm.'), $/;
        my $cpanm_file = File::Which::which( 'cpanm' );
        push @log, _loc('cpanm found at %1', $cpanm_file ), $/;
        my $cpanm = _file( $cpanm_file )->slurp;
        $cpanm = eval $cpanm;
        # install one by one
        map {
            my $file = $_;
            _debug( "Installing $file with cpanm..." );
            push @log, "===========[ Installing $file ]=========", $/;
            my $ret = `cpanm -n '$file' 2>&1`;  # TODO use cpanm from a module
            
            my $app = App::cpanminus::script->new;
            # patch fix this module
            $app->parse_options( '-n', $file );
            $app->doit or do {
                _fail _loc("Install error: could not install distribution: %1", $file);
            };
            push @log, $ret;
            push @log, "===========[ $file Installed ]=========", $/;
            _fail $ret if $?;
        } @$files;
        { success => \1, msg => 'ok', log=>\@log };
    } catch {
        my $err = shift;
        { success => \0, msg => "$err", log=>\@log };
    };
    $c->forward('View::JSON');
}

sub installed_cpan : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        require ExtUtils::Installed;
        my $inst = ExtUtils::Installed->new();
        my @modules = $inst->modules();
        my @data = map {
            +{
                name => $_,
                version => '',
            }
        } @modules;
        
        { success => \1, msg => 'ok', data => \@data };
    }
    catch {
        my $err = shift;
        { success => \0, msg => "$err", };
    };
    $c->forward('View::JSON');
}

sub local_cpan : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        my @data;
        my $dir = _dir( $c->path_to( $c->config->{install_dir} // $INSTALL_DIR ) );
        $dir->mkpath unless -d $dir;
        $dir->recurse( callback => sub {
            my $f = shift;
            return if -d $f;
            push @data, {
                id      => "$f",
                name    => $f->basename,
                date    => ''.Class::Date->new( $f->stat->[9] ),
                size    => $f->stat->[7],
                file    => "$f",
            };
        });

        { success => \1, msg => 'ok', data => \@data };
    }
    catch {
        my $err = shift;
        { success => \0, msg => "$err", };
    };
    $c->forward('View::JSON');
}

sub upload_cpan : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try { 
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my $dir = _dir( $c->path_to( $c->config->{install_dir} // $INSTALL_DIR ) );
        $dir->mkpath unless -d "$dir";
        $p->{filename} ||= 'cpan-' . _md5(rand()) . 'tar.gz';
        $p->{filename} =~ s{\:\:}{-}g;
        $p->{filepath} = $dir->file( $p->{filename} );
        _debug "CPAN filepath = $p->{filepath}";
        open( my $ff, '>', "$p->{filepath}" )
            or _fail _loc 'Error opening file %1: %2', $p->{filepath}, $!; 
        binmode $ff;
        print $ff from_base64( $p->{data} );
        close $ff;
        { success=>\1, msg=>'ok', filepath=>''.$p->{filepath} };
    } catch {
        my $err = shift;
        { success=>\0, msg=>"$err", };
    };
    $c->forward('View::JSON');
}

sub upload_file_b64 : Private {
    my ( $self, $p ) = @_;
    my $data = $p->{data} or _fail 'Missing data';
    # convert data
    $data = from_base64( $data );
    # dump to file
    open( my $ff, '>', $p->{filepath} )
        or _fail _loc 'Error opening file: %1', $!; 
    binmode $ff;
    print $ff $data;
    close $ff;
}

sub pull : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    $c->stash->{json} = try {
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my $data = $p->{data} or _fail 'Missing data';
        my $id = $p->{id} // _md5( rand() ) ;
        # dump to file
        push @log, _loc "upgrade id: %1", $id;
        my $branch = $p->{branch} // _fail _loc 'Missing branch';
        my $filename = "upgrade-$id.bundle";
        my ($feature) = grep { $_->name eq $p->{feature} } $c->features->list;
        my $filepath =  $p->{feature} eq 'clarive' 
            ? $c->path_to( $filename )
            : $c->path_to( 'features', $feature->id, $filename ); 
        push @log, _loc "file: %1", $filepath;

        $self->upload_file_b64({ data=>$data, id=>$id, filepath=>$filepath });

        # cd to .git and verify file 
        my $repohome = $p->{feature} eq 'clarive' 
            ? $c->path_to( '.git' )
            : $c->path_to( 'features', $feature->id, '.git' ); 
        my $git = Git::Wrapper->new( $repohome );
        my @verify = $git->bundle('verify', "$filepath" ); 
        # add / replace remote patch
        my $remote = 'patch';
        push @log, _loc 'remote setup: remote add %1 %2', $remote, $filepath;
        try { $git->remote( 'add', $remote, "$filepath" ) } catch {
            push @log, _loc('ok, remote %1 already exists: %2', $remote, shift() );
            $git->remote( 'set-url', $remote, "$filepath" );
        };
        push @log, _loc 'remote add/set-url: %1', $remote;
        push @log, _loc('Fetching from remote %1 into branch %2', $remote, $branch);
        my @fetch;
        push @fetch, $git->fetch( $remote ); 
        push @fetch, $git->fetch( $remote, '--tags' ); 
        push @log, @fetch;
        
        # delete file
        unlink $filepath;
        
        # checkout?
        
        { success=>\1, msg=>'ok', filepath=>"$filepath", verify=>\@verify, fetch=>\@fetch, log=>\@log };
    } catch {
        my $err = shift;
        push @log, _loc 'Error: %1', $err;
        { success=>\0, msg=>"$err", log=>\@log };
    };
    $c->forward('View::JSON');
}

sub list_repositories : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my @features =  $c->features->list;
        my @repositories = map { { feature=>$_->name, dir=>$_->path . '/.git' } } @features;
        unshift @repositories, { feature=>'clarive', dir=>$c->path_to('.git') . '' };
        @repositories = grep { -d $_->{dir} } @repositories;
        
        my $remote = 'patch';
        for my $repo ( @repositories ) {
            my $git = Git::Wrapper->new( $repo->{dir} );
            _debug "REPO DIR: $repo->{dir}";
            # find refs and branches available
            my @log = $git->RUN("log",{pretty=>"format:%ad %h %d", abbrev_commit=>1, date=>"short", 1=>1});
            if( $log[0] =~ /^(\S+)\s+(\S+)\s+\((.*)\)$/ ) {
                $repo->{date} = $1;
                $repo->{commit} = $2;
                my @refs = split /,\s*/,$3;
                @refs = grep !/HEAD/, @refs;
                #$repo->{branch} = pop @refs;
                $repo->{refs} = \@refs;
            }
            # get the current branch name
            $repo->{branch} = try { ($git->symbolic_ref( 'HEAD' ))[0] } catch { '' };
            #$repo->{branch} = scalar _file( $repo->{dir}, 'HEAD' )->slurp; 
            $repo->{branch} =~ s{^.*/(.*?)$}{$1}g;
            # fetch_head - try to find out which is the latest commit from remote/patch 
            $repo->{fetch_head} = try {
                ( $git->RUN('rev-parse', "remotes/$remote/" . $repo->{branch} ) )[0]
            } catch {
                try {
                    ( $git->RUN('rev-parse', $repo->{branch} ) )[0]
                } catch {
                    ( $git->RUN('rev-parse', 'master' ) )[0]
                };
                #my $fetch_head = _file( $repo->{dir}, 'FETCH_HEAD');
                #$repo->{fetch_head} = -e $fetch_head && ((scalar$fetch_head->slurp)=~/^(\S+)/) ? $1 : '';
            };
            # current version of repo:
            $repo->{version} = ( $git->describe({ always=>1, tag=>1 }) )[0];
            # all branches
            #my @heads = map { /^.*\/(.*?)$/; $1 } $git->for_each_ref({ sort=>'-committerdate', format=>'%(refname)' }, "refs/heads" );
            my @heads = try { $git->for_each_ref({ sort=>'-committerdate', format=>'%(refname)' }, "refs/heads" ) } catch {};
            my @patches = try { $git->for_each_ref({ sort=>'-committerdate', format=>'%(refname)' }, "refs/remotes/$remote" ) } catch {};
            # list of available tags:
            $repo->{versions} = [ 'HEAD', reverse sort $git->tag(), @heads, @patches ];
        }
        @repositories = sort { 
            $a->{feature} eq 'clarive' ? -1 : $b->{feature} eq 'clarive' ? 1 : $a->{feature} cmp $b->{feature}
            } @repositories;
        { success=>\1, msg=>'ok', totalCount=>scalar@repositories, data=>\@repositories };
    } catch {
        { success=>\0, msg=>"" . shift() };
    };
    $c->forward('View::JSON');
}

sub checkout : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    my @log;
    $c->stash->{json} = try {
        _fail _loc('Unauthorized') unless $c->has_action('action.admin.upgrade');
        my $repos = _from_json( $p->{repos} );
        my %repositories = $self->repositories( $c );
        for my $repo ( _array $repos ) {
            my $dir = $repositories{ $repo->{feature} } or _fail _loc 'Feature %1 not found', $repo->{feature};
            -d $dir or _fail _loc 'Invalid feature %1 directory: %2', $repo->{feature}, $dir;
            my $git = Git::Wrapper->new( $dir );
            $repo->{branch} ||= 'master';
            push @log, "\n*** Current commit for $repo->{version}:";
            push @log, $git->RUN('rev-parse', $repo->{version} );
            push @log, "\n\n===============[ Log ]==================";
            push @log, $git->RUN('log', { 'format' => '%h %ad %aN%x09%d%x09%s', date=>'short' }, "HEAD..$repo->{version}");
            push @log, "\n\n===============[ Differences ]==================";
            push @log, $git->diff({ 'name-status'=>1 }, "HEAD..$repo->{version}");
            if( $p->{checkout} ) {
                my $rollback = '__rollback__';
                    push @log, try { $git->RUN('branch', { D=>1 }, $rollback) };
                push @log, "\n*** Creating rollback branch...";
                    push @log, $git->RUN('checkout', { f=>1, b=>$rollback });
                push @log, "\n*** Creating stash commit...";
                    push @log, try { $git->RUN('stash', 'save', $rollback ) };
                push @log, "\n*** Reassigning ref $repo->{branch} to $repo->{version}...";
                    push @log, $git->RUN('branch', { f=>1 }, $repo->{branch}, $repo->{version} );
                push @log, "\n*** Checking out $repo->{branch} ($repo->{version}) for feature $repo->{feature}...\n";
                    push @log, $git->RUN('checkout', { f=>1 }, $repo->{branch} );
                push @log, "\n*** Done checking out";
            } else {
                push @log, "\n*** No checkout has been done";
            }
        }
        { success=>\1, msg=>'ok', log=>\@log };
    } catch {
        my $err = shift;
        { success=>\0, msg=>"" . $err, log=>[@log, 'error: ' . $err ] };
    };
    $c->forward('View::JSON');
}

sub repositories {
    my ( $self, $c ) = @_;
    my @features =  $c->features->list;
    my %repositories = map { $_->name => $_->path . '' } @features;
    $repositories{clarive} = $c->path_to . '';
    return %repositories;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
# deprecated ------------

#register 'menu.admin.features' => {
#    label => 'List Features',
#    url_comp=>'/comp/grid',
#    title=>'Features', icon=>'/static/images/chromium/plugin.png' };
#register 'menu.admin.features.install' => { label => 'Install Features', url_comp=>'/feature/install', title=>'Install', icon=>'/static/images/chromium/plugin.png'};

sub details : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my $id = $p->{id};
    my @data;
    for my $f ( $c->features->list ) {
        if( $f->id eq $id ) {
            my $home = dir( $f->path );
            $home->recurse( callback=>sub{
                my $d = shift;
                push @data, $d->absolute;
            });
            last;
        }
    }
    $c->response->body( '<pre><li>' . join'<li>',@data );
}

sub list : Local {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
    my @rows;
    for my $f ( $c->features->list ) {
        next if( $query && !Util->query_grep(query=>$query, fields=>[qw(id name version)], rows=>[{id=>$f->id}, {name=>$f->name}, {version=>$f->version} ] ));
        push @rows, {
            id      => $f->id,
            name    => $f->name,
            description    => $f->name,
            path    => $f->path,
            provider       => $f->name,
            version => $f->version,
        } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
    @rows = sort { $a->{ $sort } cmp $b->{ $sort } } @rows if $sort;
    $c->stash->{json} = {
        totalCount=>scalar @rows,
        data=>\@rows
    };
    $c->forward('View::JSON');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
