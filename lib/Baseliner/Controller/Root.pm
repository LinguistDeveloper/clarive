package Baseliner::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Baseliner::Utils;

use Try::Tiny;

## JSON stuff

use JSON::XS;
use constant js_true => JSON::XS::true;
use constant js_false => JSON::XS::false;
use MIME::Base64;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Baseliner.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Baseliner::Controller::Root - Root Controller for Baseliner

=head1 DESCRIPTION

All root / urls are installed here. 

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->res->headers->header( 'Cache-Control' => 'no-cache');
    $c->res->headers->header( Pragma => 'no-cache');
    $c->res->headers->header( Expires => 0 );

    if( ref $c->session->{user} ) {
        $c->languages( $c->session->{user}->languages );
    }

    Baseliner->app( $c );

    _db_setup;  # make sure LongReadLen is set after forking

    $c->forward('/theme');

    #my $logged_on = defined $c->username;
    # catch invalid user object sessions
    #try {
        #die unless $c->session->{user} || $c->stash->{auth_skip};
    ##} catch {
        #my $path = $c->request->{path} || $c->request->path;
    #};
}

sub auto : Private {
    my ( $self, $c ) = @_;
    my $notify_valid_session = delete $c->request->params->{_bali_notify_valid_session};
    return 1 if $c->stash->{auth_skip};
    return 1 if $c->req->path eq 'i18n/js';
    _debug "SESSION USER OBJ: " . $c->session->{user};
    _debug "USER_EXISTS: " . $c->user_exists;
    _debug "SESSION: " . _dump( $c->session ); 
    return 1 if try { $c->session->{user} // 0 } catch { 0 };
    my $path = $c->request->{path} || $c->request->path;
    return 1 if $path =~ /(^site\/)|(^login)|(^auth)/;
    # saml?
    if( $c->config->{saml_auth} eq 'on' ) {
        my $saml_username= $c->forward('/auth/saml_check');
	$c->change_session_expires( 1_000_000_000 );
        _debug "S-SESSION USER OBJ: " . $c->session->{user};
        _debug "S-USER_EXISTS: " . $c->user_exists;
        _debug "S-SESSION: " . _dump( $c->session ); 
        return 1 if $saml_username;
    }
    # reject request
    if( $notify_valid_session ) {
        $c->stash->{auto_stop_processing} = 1;
        $c->stash->{json} = { success=>\0, logged_out => \1, msg => _loc("Not Logged on") };
        $c->forward('View::JSON');
    } elsif( $c->request->params->{fail_on_auth} ) {
        $c->response->status( 401 );
        $c->response->body("Unauthorized");
    } else {
        $c->forward('/auth/logoff');
        $c->stash->{after_login} = '/' . $path;
        my $qp = $c->req->query_parameters // {};
        $c->stash->{after_login_query} = join '&', map { "$_=$qp->{$_}" } keys %$qp;
        $c->response->status( 401 );
        $c->forward('/auth/logon');
        #$c->detach('/end');
    }
    return 0;
}

sub serve_file : Private {
    my ( $self, $c ) = @_;
    my $filename = $c->stash->{serve_filename} or _throw 'Missing filename on stash';
    my $file= $c->stash->{serve_file};
    my $body= $c->stash->{serve_body};
    if( defined $file ) {
        $c->serve_static_file( $file );
    } 
    elsif( defined $body ) {
        $c->res->body( $body );
    }
    else {
        _throw 'Missing serve_file or serve_body on stash';
    }
    $c->res->headers->remove_header('Cache-Control');
    $c->res->header('Content-Disposition', qq[attachment; filename=$filename]);
    $c->res->headers->remove_header('Pragma');
    $c->res->content_type('application-download;charset=utf-8');
}

sub theme : Private {
    my ( $self, $c ) = @_;

    # check if theme dir is in the session already
    if( $c->session->{theme_dir} && !$c->config->{force_theme} ) {
        $c->stash->{theme_dir} = $c->session->{theme_dir}; 
        return;
    }

    # nope... so let's get the users preference
    my $prefs = {};
    if( defined $c->user && !defined $c->config->{force_theme} ) {
        my $username = $c->username;
        if( defined $username ) {
            $prefs = $c->model('ConfigStore')->get('config.user.view', ns=>"user/$username");
        }
    }
    $prefs->{theme} ||= $c->config->{force_theme} || $c->config->{default_theme}; # default
    my $theme = $prefs->{theme} ? '_' . $prefs->{theme} : '';
    my $theme_dir = $prefs->{theme} ? '/themes/' . $prefs->{theme} : '';
    $c->stash->{theme_dir} = $theme_dir;
    $c->session->{theme_dir} = $theme_dir;
}

sub whoami : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->user->username  );

}

sub controllers : Local {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre><li>' . join '<li>', sort $c->controllers );

}

sub models : Local {
    my ( $self, $c ) = @_;
    $c->res->body( '<pre><li>' . join '<li>', sort $c->models );

}

sub raw : LocalRegex( '^raw/(.*)$' ) {
    my ( $self, $c, $arg ) = @_;
    my $path = $c->req->captures->[0];
    $c->stash->{site_raw} = 1;
    push @{ $c->stash->{tab_list} }, { url=>"/$path", title=>"/$path", type=>'comp' };
    $c->forward('/index');
}

sub tab : LocalRegex( '^tab/(.*)$' ) {
    my ( $self, $c, $arg ) = @_;
    my $path = $c->req->captures->[0];
    push @{ $c->stash->{tab_list} }, { url=>"/$path", title=>"/$path", type=>'comp' };
    $c->forward('/index');
}

sub index:Private {
    my ( $self, $c ) = @_;
    my $p = $c->request->parameters;

    if( $p->{tab}  ) {
        push @{ $c->stash->{tab_list} }, { url=>$p->{tab}, title=>$p->{tab}, type=>'comp', params=>$p };
    }
    if( $p->{tab_page}  ) {
        push @{ $c->stash->{tab_list} }, { url=>$p->{tab_page}, title=>$p->{tab_page}, type=>'page', params=>$p };
    }

    # set language 
    if( $c->user ) {
        if( $c->user ) {
            my $username = $c->username;
            if( $username ) {
                my $prefs = $c->model('ConfigStore')->get('config.user.global', ns=>"user/$username");
                $c->languages( [ $prefs->{language} || $c->config->{default_lang} ] );
                if( ref $c->session->{user} ) {
                    $c->session->{user}->languages( [ $prefs->{language} || $c->config->{default_lang} ] );
                }
            }
        }
    }

    # load menus
    my @menus;
    $c->forward('/user/can_surrogate');
    if( $c->username ) {
        my @actions = $c->model('Permissions')->list( username=> $c->username, ns=>'any', bl=>'any' );
        $c->stash->{menus} = $c->model('Menus')->menus( allowed_actions=>[ @actions ]);
        $c->stash->{portlets} = [
            grep { $_->active }
            $c->model('Registry')->search_for( key=>'portlet.', allowed_actions=>[ @actions ])
        ];
        my @features_list = Baseliner->features->list;
        # header_include hooks
        $c->stash->{header_include} = [
            map { { name=>$_, content=>_slurp $_ } }
            _unique
            grep { -e $_ } map { "" . Path::Class::dir( $_->path, 'root', 'include', 'head.html') }
                    @features_list 
        ];
    }
    $c->stash->{$_} = $c->config->{header_init}->{$_} for keys %{$c->config->{header_init} || {}};

    $c->stash->{show_js_reload} = $ENV{BASELINER_DEBUG} && $c->has_action('action.admin.develop');

    $c->stash->{template} = '/site/index.html';
}

use Encode qw( decode_utf8 encode_utf8 is_utf8 );
sub detach: Local {
    my ( $self, $c ) = @_;
    my $html = $c->request->{detach_html};
    my $type = $c->request->{type};
    $html = decode_utf8 $html;
    $html = decode_utf8 $html;
    $c->stash->{detach_html} = $html;
    #$c->stash->{detach_html} = decode_utf8 decode_utf8 $c->request->{detach_html};
    $c->stash->{template} = '/site/detach.html';
}

sub show_comp : Local {
    my ( $self, $c ) = @_;
    my $url = $c->request->{url};
    $c->stash->{url} = $url;
    $c->stash->{template} = '/site/comp.html';
}

sub default:Path {
    my ( $self, $c ) = @_;
    $c->stash->{template} ||= $c->request->{path} || $c->request->path;
}

sub help_load : Path('/help/load') {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    _throw 'Missing path' unless $p->{path};
    require Text::Textile;
    my $body;
    my $path_lang;
    if( my $path = $p->{path} ) {
        $path =~ /\.\w+$/ or do {
            $path_lang=$path.'_'.$c->language.'.textile';
            $path .= '.textile';
        };
        $path_lang and $body = _textile( _mason( "". _dir( 'help', $path_lang ), c=>$c, username=>$c->username, %$p ) );
        $body and $body!~/not found by dhandler/i or $body = _textile( _mason( "". _dir( 'help', $path ), c=>$c, username=>$c->username, %$p ) );
    }
    $c->response->body( $body || _loc('Help file parsing error') );
}

=head2 to_yaml

Turns the parameters into a beautiful YAML.

=cut
sub to_yaml : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        { success=>\1, msg=>'ok', yaml=>_dump($p) };
    } catch {
        { success=>\0, msg=>"" . shift() };
    };
    $c->forward('View::JSON');
}

=head2 from_yaml

Turns YAML encoded text parameter C<yaml>
into a JSON response:

    { 
        success: true|false,
        msg: <error message>,
        json: the json object 
    }

=cut
sub from_yaml : Local {
    my ( $self, $c ) = @_;
    my $p = $c->req->params;
    $c->stash->{json} = try {
        $p->{yaml} or _fail "Missing parameter 'yaml'";
        my $data = _load $p->{yaml};
        { success=>\1, msg=>'ok', json=>$data };
    } catch {
        { success=>\0, msg=>"" . shift() };
    };
    $c->forward('View::JSON');
}


=head2 end

Renders a Mason view by default, passing it all parameters as <%args>.

=cut 

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    # check for controlled errors in DEBUG mode
    if( Baseliner->debug && _array( $c->error ) > 0 ) {
        if( $c->req->params->{_bali_client_context} eq 'json' ) {
            _debug "ERROR handled as JSON...";
            my $err = join ',', _array $c->error ;
            $c->log->error( $_ ) for _array $c->error ;
            $c->res->status( 500 );
            $c->clear_errors; # return call as normal
            $c->stash->{json} = { msg=>$err };
            $c->forward( 'View::JSON');
        }
    }
    #if( $c->res->content_type eq 'text/html' ) {
    #    _debug _dump $c->req;
    #    $c->res->content_type( 'text/css' );
    #}
    $c->stash->{$_}=$c->request->parameters->{$_} 
        foreach( keys %{ $c->req->parameters || {} });
}

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 The Authors of baseliner.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
