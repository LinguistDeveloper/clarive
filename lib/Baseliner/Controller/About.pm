package Baseliner::Controller::About;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Baseliner::Plug;
use Baseliner::Utils;

register 'menu.admin.about' => { label => 'About...', url => '/about/show', title=>'About ' . Baseliner->config->{app_name} // 'Baseliner', index=>999 };

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

use Sys::Hostname;
sub show : Local {
    my ( $self, $c ) = @_;
    my @about = map { { name=>$_, value=>$c->config->{About}->{$_} } } keys %{ $c->config->{About} || {} };
    push @about, { name=>'Server Version', value=>$Baseliner::VERSION };
    push @about, { name=>'Perl Version', value=>$] };
    push @about, { name=>'Hostname', value=>hostname };
    push @about, { name=>'Process ID', value=>$$ };
    push @about, { name=>'Server Time', value=>_now };
    push @about, { name=>'Server Exec', value=>$0 };
    push @about, { name=>'Server Bin', value=>$FindBin::Bin };
    push @about, { name=>'Server Parent ID', value=>$ENV{BASELINER_PARENT_PID} };
    #push @about, { name=>'Path', value=>join '<li>',split /;|:/,$ENV{PATH} };
    push @about, { name=>'OS', value=>$^O };
    #push @about, { name=>'Library Path', value=>join '<li>',split /;|:/,$ENV{LIBPATH} || '-' };
    #$body = dehash( $c->config );
    $c->stash->{about} = [ @about ];
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
