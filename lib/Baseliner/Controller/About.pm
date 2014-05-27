package Baseliner::Controller::About;
use Baseliner::PlugMouse;
use Baseliner::Utils;
use Try::Tiny;
BEGIN {  extends 'Catalyst::Controller' }

register 'action.help.server_info' => { name => 'View server info in about window'};
register 'menu.help' => { label => 'Help', index=>999 };
register 'menu.help.about' => { label => 'About...', url => '/about/show', title=>'About ' . ( Baseliner->config->{app_name} // 'Baseliner' ), index=>999 };

sub dehash {
    my $v = shift;
    my $ret ='';
    if( ref($v) eq 'HASH' ) {
        $ret.='<ul>';
        for( sort keys %{ $v || {} } ) {
           $ret .= "<li>$_: " . dehash( $v->{$_} ) . '</li>'; 
        }
        $ret.='</ul>';
    } elsif( ref($v) eq 'ARRAY' ) {
        for( sort @{ $v || [] } ) {
           $ret .= "<li>".dehash($_) . '</li>';
        }
    } else {
        $ret = $v; 
    }
    return $ret;
}

sub show : Local {
    my ( $self, $c ) = @_;
    require Sys::Hostname;
    my @about = map { { name=>$_, value=>$c->config->{About}->{$_} } } keys %{ $c->config->{About} || {} };
    push @about, { name=>'Server Version', value=>$Baseliner::VERSION };

    if ( Baseliner->model("Permissions")->user_has_action( action => 'action.help.server_info', username => $c->username ) ) {    
        push @about, { name=>'Perl Version', value=>$] };
        push @about, { name=>'Hostname', value=>Sys::Hostname::hostname() };
        push @about, { name=>'Process ID', value=>$$ };
        push @about, { name=>'Server Time', value=>_now };
        push @about, { name=>'Server Exec', value=>$0 };
        push @about, { name=>'Server Bin', value=>$FindBin::Bin };
        push @about, { name=>'Server Parent ID', value=>$ENV{BASELINER_PARENT_PID} };
        #push @about, { name=>'Path', value=>join '<li>',split /;|:/,$ENV{PATH} };
        push @about, { name=>'OS', value=>$^O };
        push @about, { name => _loc('Active users count'), value => ci->user->find({ active => '1', name => { '$ne' => 'root' }})->count };
        #push @about, { name=>'Library Path', value=>join '<li>',split /;|:/,$ENV{LIBPATH} || '-' };
        #$body = dehash( $c->config );
        $c->stash->{environment_vars} = [ 
            map {
                +{ name=>$_, value=>$ENV{$_} }
            }
            grep /BASELINER/i, keys %ENV
        ];
        $c->stash->{tlc} = $Baseliner::TLC;
    }
    $c->stash->{about} = \@about;
    $c->stash->{licenses} = [ 
        map {
           { name=>$_, text=>scalar _file( $_ )->slurp };
        }
        grep { -e }
        glob( 'LICENSE* features/*/LICENSE' )
    ];
    $c->stash->{copyright} = [ 
        map {
           { name=>$_, text=>scalar _file( $_ )->slurp };
        }
        grep { -e }
        glob( 'COPYRIGHT* features/*/COPYRIGHT' )
    ];
    $c->stash->{third_party} = try { scalar $c->path_to('THIRD-PARTY-NOTICES')->slurp };
    $c->stash->{template} = '/site/about.html';
}

sub page : Local {
    my ( $self, $c ) = @_;
    $c->stash->{name} = { aa=>11 };
    $c->stash->{template} = '/aaa.html';
}

sub version : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        { success => \1, msg => 'ok', version=>$Baseliner::VERSION };
    } catch {
        my $err = shift;
        { success => \0, msg => "$err", };
    };
    $c->forward('View::JSON');
}

1;
