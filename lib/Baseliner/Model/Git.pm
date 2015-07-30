package Baseliner::Model::Git;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
#use Git::Repository;
use Try::Tiny;
extends 'Catalyst::Model';

use constant REPO_HOME => _dir( Baseliner->config->{gitscm}->{repo_home} ); # || die "Error: gitscm: missing config variable repo_home\n";

our %all_bls = ( DEV=>1, TEST=>1, PROD=>1, PREP=>1, QA=>1, DESA=>1, ANTE=>1 );

sub setup_new_repo {
    my ($self, %p ) = @_;
    my ( $service, $home, $repo ) = @p{ qw/service home repo/ };

    return unless $service =~ /git-receive-pack/ || $service =~ /git-upload-pack/;
    _throw 'Missing repository' unless $repo;
    # pre hook
    _log ">>>GIT: " .  "Repo: " . $repo;

    # check if repository dir exists
    my $dir = _dir $home, $repo;
    return if -e _file($dir,'info');

    # ok, create repository
    _log ">>>GIT: Creating repo $repo ($dir)...\n";
    _mkpath $dir;
    #my $out = Git::Repository->run( init => "$dir", '--bare' ) or _throw $!;
    my $git = Git::Wrapper->new( $dir );
    my $out = $git->init('--bare');
    _log ">>>GIT INIT: $out";
    #my $git = Git::Repository->new( git_dir => $dir );
    #_log join'',$cmd->stdout;
    #mkdir $dir;
    #chdir $dir;
    #log ">>>GIT: " . `git init --bare`;
    #open my $fe, '>', _dir( $dir, 'git-daemon-export-ok' ); close $fe;
    open( my $f, '>', _dir($dir, '/config') ) or _throw $!;
    print $f "[http]\n\treceivepack = true";
    close $f;
    _log ">>>GIT: " .  "Done creating repo $repo.\n";
    return 1;
}

sub repositories {
    my ($self, %args) = @_;

    my @repos = BaselinerX::Lc->new->all_repos;
}

sub repositories_from_dir {
    my ($self, %args) = @_;

    my @repos = map {
        _log "DIR $_";
        Girl::Repo->new( path => "$_" );
    } grep {
        $_->is_dir 
    } REPO_HOME->children;
}

sub message_from_tag {
    my ($self, %args) = @_;
    my ($tag,$repo) = @args{ qw/tag repo/ };
    my @s = split /\s+/, $repo->git->exec( qw/tag -l -n/, $tag );
    $s[1];
}

=head2 nice list of history for a tag

    git rev-list  --pretty=format:%d $(git rev-parse TEST)
    commit 037c96e12f13410f0a552bf5a8945df8aa71c4eb
     (TEST, GDF-0001)
    commit 7bbed8be84fc5d58f81ed5b1729076dc5ac57e1d
    commit f11bc4c7be4dbd26323da928657c4be897d35f8c
    commit 798c9faf404cb8d4590a2413156e61a9f219ea28
     (SCT-0001)
    commit 6970571d6af75f1450cdf058f8098588b5780b1d
     (JOB-TEST-0002)
    commit 207fb37eae3db1cbe34867edeca4971fd34dce0d
     (SCT-0000, DESA)

=cut

sub tags_arr {
    my ($self, %args) = @_;
    my ($bl, $repo, $repo_name, $project, $state_name ) = @args{ qw/bl repo repo_name project state_name/ };
    my $repo_path = $repo->path;
    my $git  = Git::Wrapper->new( $repo_path );
    # get the next bl in the cycle
    #   TODO could be more then one next, but it requires a loop and a separation of destinations 
    #      on the return list (whereto)
    my $lc = Baseliner->model('LCModel')->lc;
    $bl ||= $lc->bl( $state_name );
    my $show_branch = $lc->show_branch( $state_name ) if length $state_name;  # could be master instead of DEV
    my $bl_commit = $repo->git->exec( 'rev-parse', $show_branch // $bl );
    my $bl_to = $lc->bl_to( $state_name );
    my $bl_from = $lc->bl_from( $state_name );
    my $bl_range = defined $bl_to ? "$bl_to..$bl_commit" : $bl_commit;
    _log "GIT rev-list: bl=>$bl, bl_commit=>$bl_commit, bl_to=>$bl_to, bl_from=>$bl_from, range=>$bl_range, show_branch=>$show_branch, $repo_path";
    # generate the list
    my @tags = $git->rev_list( { pretty=>'%d', "simplify-by-decoration" => 1 }, $bl_range );
    # my @tags = $git->rev_list( { pretty=>'%d', "simplify-by-decoration" => 1, 'ancestry-path' => 1 }, $bl_range );
    #my @tags = $git->exec( 'rev-list', '--pretty-format:%d', $bl_commit );
    #my @tags = $git->rev_list( { pretty=>'%d', "simplify-by-decoration" => 1 }, $bl_commit );
    my %tags_to = map { $_ => 1 } $git->tag( { contains => $bl_to } ) if length $bl_to;
    my %tags_from = map { $_ => 1 } $git->tag( { contains => $bl_from } ) if length $bl_from;

    # cleanup utf8
    _utf8_on_all( @tags );
    _log "TAGS = " . _dump \@tags;
    _log "TAGS TO= " . _dump \%tags_to;
    my $parent = 0; # used to detect tags yet to be merged
    @tags = 
        grep { defined }
        map {
            my $name = $_;
            my $msg = $repo->git->exec( qw/tag -n -l/, $name );
            my $t;
            ($t, $msg) = split /\s+/, $msg;
            # identify tag status, if its promotable, etc.
            my $trunk = length $bl_to ? $tags_to{ $name } : 1;  # linear history
            $parent = 1 if !$parent && $trunk;
            my $status = $trunk ? 'trunk' : !$parent ? 'pending' : 'merged';
            my $promotable = length $bl_to ? $trunk : 0;
            my $demotable = length $bl_from ? $trunk : 0;
            +{ name => $name, msg => "$msg", 
                    bl_to => $bl_to,
                    bl_from => $bl_from,
                    promotable => $promotable, demotable => $demotable, status => $status }
        }
        grep { length > 5 } # 5 letter minimum
        map {
            my $x = $_;
            $x =~ s{\(|\)}{}g;
            my @t = split /,/, $x; 
            @t = map { s/^\s+//g; $_ } @t;
            @t;
        }
        grep !/^commit/, @tags;
    # remove the BL names from tags
    @tags = grep { ! exists $all_bls{ $_->{name} } } @tags;
    @tags;
}

sub tags_for_bl {
    my ($self, %args) = @_;
    my ($bl, $repo, $repo_name, $project ) = @args{ qw/bl repo repo_name project/ };
    my @tags = $self->tags_arr( %args );
    map {
        $_->{msg} = unac( $_->{msg} );
        BaselinerX::GitTag->new(
            {   head        => $_,
                repo_dir    => $repo->path,
                name        => $_->{name},
                bl_to       => $_->{bl_to},
                bl_from     => $_->{bl_from},
                promotable => $_->{promotable},
                demotable  => $_->{demotable},
                status      => $_->{status},
                description => $_->{msg},
                repo_name   => $repo_name,
                project     => $project
            }
        );
    } @tags;
}

=pod

sub old_tags_for_bl {
    my ($self, %args) = @_;
    my ($bl, $repo, $repo_name, $project ) = @args{ qw/bl repo repo_name project/ };
    my $bl_commit = $repo->git->exec( 'rev-parse', $bl );
    _log "GIT getting tags that --contains $bl_commit (rev-parse of $bl)";
    my @tags = $repo->git->exec( qw/tag -l -n --contains/, $bl_commit );
    @tags = 
        grep { $_->{name} !~ /^(DESA|TEST|PREP|PROD|PREP|DEV|QA)/ }
        map {
            my ($name, $msg ) = m/^(\S+)\s+(.+)$/;
            { name=> $name, msg => $msg }
        } @tags;
    @tags = grep { ! exists $all_bls{ $_->{name} } } @tags;
    map {
        BaselinerX::GitTag->new({ head=>$_, repo_dir=>$repo->path, name=>$_->{name},
            description=>$_->{msg}, repo_name=>$repo_name, project=>$project });
    } @tags;
}

=cut

sub unac {
    my $str = shift;
    #utf8::upgrade( $str );
    #$str = Baseliner::Utils::unac_string( $str );
    $str =~ s{\W}{}g;
    $str;
}
sub tags_not_in_bl {
    my ($self, %args) = @_;
    my ($repo, $repo_name, $project ) = @args{ qw/repo repo_name project/ };
    _throw 'Missing parameter project' unless $project;
    _throw 'Missing parameter repo_name' unless $repo_name;
    my $repo_dir = $repo->path;

    my @bl_tags;
    for my $bl ( qw/TEST PREP PROD/ ) {
        try {
           push @bl_tags, map { $_->{name} } $self->tags_arr( %args, bl=>$bl );  
        } catch {};
    }
    #@bl_tags = _unique @bl_tags;
    my %other;
    $other{ $_ } = 1 for @bl_tags ;

    my %bls; @bls{ qw/DESA DEV QA TEST PREP PRUE PREP PROD/ }=(); # TODO needs to check what bl (or bl tags are needed

    # list all tags
    my @all =
        grep { defined }
        map {
            my ($sha,$tag) = split / /, $_;
            $tag =~ s{^.*\/(.*)$}{$1}g;
            my $msg = $self->message_from_tag( tag=>$tag, repo=>$repo );
            $msg = unac( $msg );
            exists $other{ $tag }
                ? undef
                : BaselinerX::GitTag->new(
                        {   head        => $_,
                            repo_dir    => $repo_dir,
                            name        => $tag,
                            commit      => $sha,
                            description => $msg,
                            project     => $project,
                            repo_name   => $repo_name
                        }
                    );
        } $repo->git->exec( qw/show-ref --tags/ );
    grep { ! exists $bls{ $_->name } } @all;
}

sub hist {
    my ($self, %p ) = @_;
    my $g = Girl::Repo->new( path=>$p{repo_path} );
    my @log = $g->git->exec( 'log', '--decorate', $p{ref}, '--', $p{path} );
    my @hist;
    my $commit = {};
    for( @log ) {
        chomp;
        if( /^commit (\S+).*\((.+)\)/ ) {
            push @hist, $commit if keys %$commit;
            # reset:
            $commit = {};
            $commit->{commit} = $1;
            my $revs = $2;
            my @revs = $revs =~ /\w+: (\w+)/g;
            $commit->{revs} = \@revs;
        }
        elsif( /^Author: (.+)/ ) {
            $commit->{author} = $1;
        }
        elsif( /^Date: (.+)/ ) {
            $commit->{date} = $1;
        }
        else {
            $commit->{msg} .= $_;
        }
    }
    push @hist, $commit if keys %$commit;
    _utf8_on_all( @hist );
    return wantarray ? @hist : \@hist;
}

sub source {
    my ($self, %p ) = @_;
    my $g = Girl::Repo->new( path=>$p{repo_path} );
    my @source = $g->git->exec( 'cat-file', '-p', $p{sha} );
    _utf8_on_all( @source );
    @source = map { utf8::encode( $_ ); $_ } @source;
    return wantarray ? @source : \@source;
}

sub diff {
    my ( $self, %p ) = @_;
    my $ref_from = $p{ref_from} || $p{ref};
    my $ref_to   = $p{ref_to}   || $ref_from . '~1';
    my $g = Girl::Repo->new( path => $p{repo_path} );
    my @diff = $g->git->exec( 'diff', $ref_from, "$ref_to~1", '--', $p{path} );
    _utf8_on_all( @diff );
    return wantarray ? @diff : \@diff;
}

=pod 

sub old_tags_not_in_bl {
    my ($self, %args) = @_;
    my ($repo, $repo_name, $project ) = @args{ qw/repo repo_name project/ };
    _throw 'Missing parameter project' unless $project;
    _throw 'Missing parameter repo_name' unless $repo_name;
    my $repo_dir = $repo->path;
    my @bl_tags;
    my %bls; @bls{ qw/DESA DEV QA TEST PREP PRUE PREP PROD/ }=(); # TODO needs to check what bl (or bl tags are needed
    for my $bl ( keys %bls ) {
        push @bl_tags, map { $_->name }
            $self->tags_for_bl(  repo=>$repo, repo_dir=>$repo_dir, bl=>$bl, repo_name=>$repo_name, project=>$project );
    }
    @bl_tags = grep { not exists $bls{ $_ } } _unique @bl_tags;
    my %h; @h{ @bl_tags } = 1;
    # list all tags
    my @all = map {
        my ($sha,$tag) = split / /, $_;
        $tag =~ s{^.*\/(.*)$}{$1}g;
        ##+{ tag=>$tag, commit=>$sha }
        my $msg = $self->message_from_tag( tag=>$tag, repo=>$repo );
        BaselinerX::GitTag->new({ head=>$_, repo_dir=>$repo_dir, name=>$tag, description=>$msg, project=>$project, repo_name=>$repo_name });
    } $repo->git->exec( qw/show-ref --tags/ );
    grep {
        not exists $h{ $_->{tag} } ;
    } @all;
}

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
