package Baseliner;
use Moose;
$SIG{__WARN__} = sub { die @_ } if $ENV{CLARIVE_DIE_ON_WARN};

use Catalyst::Runtime 5.80;
our @modules;
BEGIN {

    use CatalystX::Features 0.24;
    
    # TODO ConfigLoader used by some features with .conf, but not core -- migrate to features/*/config/.yml

    if( $ENV{BALI_PLUGINS} ) {
        @modules = split /,/, $ENV{BALI_PLUGINS};
    }
    elsif( $ENV{BALI_CMD} || $ENV{BALI_FAST} ) {
        @modules = qw/
            Singleton           
            +Baseliner::Plugin::ConfigExternal
            +CatalystX::Features
            +CatalystX::Features::Lib
            +CatalystX::Features::Plugin::ConfigLoader
            +CatalystX::Features::Plugin::I18N/;
    } else {
        @modules = qw/
            StackTrace
            +Baseliner::Plugin::ConfigExternal
            +CatalystX::Features
            +CatalystX::Features::Lib
            +CatalystX::Features::Plugin::ConfigLoader
            Authentication
            Session     
            +Baseliner::MongoSession
            Session::State::Cookie
            Singleton           
            +CatalystX::Features::Plugin::I18N
            +CatalystX::Features::Plugin::Static::Simple/;
        push @modules, 'Log::Colorful' if eval "require Catalyst::Plugin::Log::Colorful";
    }
    #unshift @modules, '-Debug' if $ENV{BASELINER_DEBUG};
}

use Catalyst (@modules);
use Time::HiRes qw(gettimeofday tv_interval);
use Baseliner::CI;
use Try::Tiny;
my $t0 = [ gettimeofday ];
extends 'Catalyst';
$DB::deep = 500; # makes the Perl Debugger Happier

our $VERSION = Clarive->version;

# find my parent to enable restarts
$ENV{BASELINER_PARENT_PID} //= getppid();

__PACKAGE__->config( name => 'Baseliner', default_view => 'Mason' );
__PACKAGE__->config( setup_components => { search_extra => [ 'BaselinerX' ] } );
__PACKAGE__->config( xmlrpc => { xml_encoding => 'utf-8' } );

__PACKAGE__->config->{'Plugin::Static::Simple'}->{dirs} = [
        'static',
        qr/images/,
    ];
__PACKAGE__->config->{'Plugin::Static::Simple'}->{ignore_extensions} = [ qw/mas html js json css less/ ];    

__PACKAGE__->config( encoding => 'UTF-8' ); # used by Catalyst::Plugin::Unicode::Encoding

__PACKAGE__->config( {
        'View::JSON' => {
            decode_utf8  => 0,
            json_driver  => 'JSON::XS',
            expose_stash => 'json',
            encoding     => 'utf-8',
        },
    });

# __decrypt( ... )__  conf definition
__PACKAGE__->config->{ 'Plugin::ConfigLoader' }->{ substitutions } = {
    decrypt => sub {
        my $c = shift;
        $c->decrypt( @_ );
    }
};

if( $ENV{BALI_CMD} ) {
    # only load the root controller, for capturing $c
    __PACKAGE__->config->{ setup_components }->{except} = qr/Controller(?!\:\:Root)|View/;
    require Baseliner::Standalone;
}

__PACKAGE__->config->{'Plugin::Session'}{cookie_name} //= 'clarive-session';
    
use FindBin '$Bin';
#$c->languages( ['es'] );
__PACKAGE__->config(
    'Plugin::I18N' => {
        maketext_options => {
            Style => 'gettext',
            Path => $Bin.'/../lib/Baseliner/I18N',
            Decode => 0,
        }
    }
);

## Authentication
    __PACKAGE__->config(
        'authentication' => {
            realms => {
                ldap => {
                    store => {
                        class               => "LDAP",
                        user_class          => "Baseliner::Core::User::LDAP",
                        entry_class         => "Baseliner::LDAP::Entry",
                        user_results_filter => sub { return shift->pop_entry },
                    },
                },
            },
        },
    );
    __PACKAGE__->config(
        'authentication' => {
            realms => {
                ldap_no_pw =>
                  \%{ __PACKAGE__->config->{authentication}->{realms}->{ldap} },
            },
        },
    );

# Start the application
if( $ENV{BALI_CMD} ) {
    # no controllers on command line mode
    around 'locate_components' => sub {
        my $orig = shift;
        my @comps = $orig->( @_ );
        # save original
        Baseliner->config->{ all_components } = [ @comps ];
        @comps = grep !/Controller/, @comps;
        return @comps;
    };
}
if( $ENV{BALI_FAST} ) {
    around 'locate_components' => sub {
        my $orig = shift;
        my @comps = $orig->( @_ );
        # save original
        Baseliner->config->{ all_components } = [ @comps ];
        # filter
        if( $ENV{BALI_FAST} ) {
            @comps = grep /Model/, @comps;
        } else {
            @comps = grep /(Controller|View|Model)/, @comps;
        }

        return @comps;
    };
}

after 'setup_finalize' => sub {
    my $app = shift;

    my $precompile = $app->config->{precompiled_rules};

    # Precompile rules?
    if ($precompile) {
        $app->model('Rules')->compile_rules;
    }
};

#############################
__PACKAGE__->setup();
#############################

# Capture Signals
$SIG{INT} = \&signal_interrupt;
$SIG{KILL} = \&signal_interrupt;

# setup the DB package

around 'debug' => sub {
    my $orig = shift;
    my $c = shift;

    $c->$orig( @_ ) unless $Baseliner::DebugForceOff;
};

    
    # Inversion of Control
    if( $ENV{BALI_FAST} ) {
        for my $component ( grep !/(Controller|Model|View)/, @{ Baseliner->config->{ all_components } } ) {
            print "all: $component\n";
            Catalyst::Utils::ensure_class_loaded( $component, { ignore_loaded => 1 } );
        }
    }
    require Baseliner::Core::Registry;
    $ENV{BALI_FAST} or Baseliner::Core::Registry->setup;
    $ENV{BALI_FAST} or Baseliner::Core::Registry->print_table;
    $ENV{BALI_WRITE_REGISTRY} and Baseliner::Core::Registry->write_registry_file;

    if( ! Clarive->debug ) {
        # make immutable for speed
        my %cl=Class::MOP::get_all_metaclasses;

        # generic classes
        for my $package (
            grep !/(Baseliner|Baseliner::Cmd|Baseliner::Moose|Baseliner::Role::.*|Baseliner::View::.*|BaselinerX::CI::.*)$/, 
            grep /^Baseliner/, 
            keys %cl )
        {
            my $meta = $cl{ $package };
            next if ref $meta eq 'Moose::Meta::Role';
            unless( $meta->is_immutable ) {
                $meta->make_immutable ;   # slow loadup... ~1s
            }
        }

        #my %pkgs;
        #for( keys %{ Baseliner::Core::Registry->registrar } ) {
        #   my $node = Baseliner::Core::Registry->registrar->{$_};
        #   $pkgs{ $node->instance->module } =undef;
        #   #  say _dump $node;
        #}
        #$_->meta->make_immutable for keys %pkgs;
    }

    # cache legacy, for unmigrated features
    sub cache_get { shift; cache->get( @_ ) }
    sub cache_set { shift; cache->set( @_ ) }
    sub cache_remove { shift; cache->remove( @_ ) }
    sub cache_remove_like { shift; cache->remove_like( @_ ) }
    sub cache_keys { shift; cache->keys( @_ ) }
    sub cache_keys_like { shift; cache->keys_like( @_ ) }
    sub cache_clear { shift; cache->clear( @_ ) }
    
    # cache setup
    cache->remove( qr/registry:/ );

    # Beep
    my $bali_env = $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} // $ENV{BASELINER_CONFIG_LOCAL_SUFFIX};
    print STDERR ( Baseliner->config->{name} // 'Baseliner' ) 
        . " $Baseliner::VERSION. Startup time: " . tv_interval($t0) . "s.\n";
    $ENV{CATALYST_DEBUG} || $ENV{BASELINER_DEBUG} and do { 
        my $mdbv = mdb->eval('db.version()');
        print STDERR "Environment: $bali_env. MongoDB: $mdbv / $MongoDB::VERSION. Catalyst: $Catalyst::VERSION. Perl: $^V. OS: $^O\n";
        print STDERR "\7";
    };
    # Make registry easily available to contexts
    sub registry {
        my $c = shift;
        return 'Baseliner::Core::Registry';
    }

    # this is deprecated
    sub c {
        use Carp;
        Catalyst->log->warn( Carp::longmess 'Use of Baseliner->c() is deprecated' );
        __PACKAGE__->commandline;
    }

    # elegant shutdown
    sub signal_interrupt {
        print STDERR "Baseliner server interrupt requested.\n";
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm 5;
            exit 0;
        };
        kill 9,$$;
        #exit 0;
    }
    
    our $_logger;
    our $_thrower;
    
    sub launch {
        my $c = shift;
        ref $c or $c = Baseliner->app($c);
        # Baseliner->app($c);
        return $c->model('Services')->launch(@_, c=>$c);
    }

    our $global_app;
    sub app {
        # TODO use this only: 
        #         return bless {} => __PACKAGE__;  # so it won't break $c->{...} calls
        Baseliner->instance and return __PACKAGE__->instance;  # depends on Catalyst Plugin "Singleton"
        my ($class, $c ) = @_;
        return $global_app = $c if ref $c;
        return $global_app if ref $global_app;
        return bless {} => 'Baseliner';  # so it won't break $c->{...} calls
    }

    #TODO move this to a model
    sub inf {
        my $c = shift;
        my %p = @_;
        $p{ns} ||= '/';
        $p{bl} ||= '*';
        if( $p{domain} ) {
            $p{domain} =~ s{\.$}{}g;
            # $p{key}={ -like => "$p{domain}.%" };
            $p{key}= qr/^$p{domain}\./ ;
        }
        print "KEY==$p{domain}\n";
        my %data;
        my $rs = mdb->config->find({ ns=>$p{ns}, bl=>$p{bl}, key=>$p{key} });
        while( my $r = $rs->next  ) {
            (my $var = $r->key) =~ s{^(.*)\.(.*?)$}{$2}g;
            $c->stash->{$var} = $r->value;
            $data{$var} = $r->value;
        }
        return \%data;
    }

sub decrypt {
    my $c = shift;
    require Crypt::Blowfish::Mod;
    my $key = $c->config->{decrypt_key} // $c->config->{dec_key};
    die "Error: missing 'decrypt_key' config parameter" unless length $key;

    my $b = Crypt::Blowfish::Mod->new( $key );
    $b->decrypt( @_ );
}

# user shortcut
sub username {
    require Baseliner::Utils;
    my $c = shift;
    my $user;
    $user = try { return $c->session->{username} } and return $user;
    Baseliner::Utils::_debug "No session user";
    $user = try { return $c->user->username } and return $c->session->{username} = $user;
    Baseliner::Utils::_debug "No user user";
    $user = try { return $c->user->id
    } catch {
        Baseliner::Utils::_debug "No user id.";
        return undef;   
    } and return $user;
}
sub user_ci {
    my ($c,$username) = @_;
    ci->user->search_ci( name=>( $username // $c->username ) );
}

sub has_action {
    my ($c,$action) = @_;
    # memoization for the same request
    my $v = $c->stash->{ $c->username }->{ $action };
    return $v if defined $v;
    $v = $c->model('Permissions')->user_has_action( action=>$action, username=>$c->username );
    return $c->stash->{ $c->username }->{ $action } = $v;
}

sub is_root {
    my ($c,$username) = @_;
    Baseliner->model('Permissions')->is_root( $username || $c->username );
}

sub loghome {
    my $c = shift;
    my $loghome = $ENV{BASELINER_LOGHOME} // Baseliner->path_to( 'logs' );
    _mkpath $loghome unless -d $loghome;
    if( @_ ) {
        return ''. Baseliner::Utils::_file( $loghome, @_ );
    } else {
        return "$loghome";
    }
}

=head2 full_logout

logout is not enough, needs to delete session

=cut
sub full_logout {
    my $c = shift;
    $c->delete_session;
    $c->logout;
}

# Utils
sub uri_for_static {
    my ( $self, $asset ) = @_;
    return ( $self->config->{static_path} || '/static/' ) . $asset;
}

# mokeypatching for 5.8
sub _comp_names_search_prefixes {
    my ( $c, $name, @prefixes ) = @_;
    my $appclass = ref $c || $c;
    my $filter   = "^\\w+(::\\w+)*::(" . join( '|', @prefixes ) . ')::';
    $filter = qr/$filter/; # Compile regex now rather than once per loop

    # map the original component name to the sub part that we will search against
    my %eligible = map { my $n = $_; $n =~ s{^.+::Model::}{}; $_ => $n; }
        grep { /$filter/ } keys %{ $c->components };

    # undef for a name will return all
    return keys %eligible if !defined $name;

    my $query  = ref $name ? $name : qr/^$name$/i;
    my @result = grep { $eligible{$_} =~ m{$query} } keys %eligible;

    return @result if @result;

    # if we were given a regexp to search against, we're done.
    return if ref $name;

    # regexp fallback
    $query  = qr/$name/i;
    @result = grep { $eligible{ $_ } =~ m{$query} } keys %eligible;

    # no results? try against full names
    if( !@result ) {
        @result = grep { m{$query} } keys %eligible;
    }

    # don't warn if we didn't find any results, it just might not exist
    if( @result ) {
        # Disgusting hack to work out correct method name
        my $warn_for = lc $prefixes[0];
        my $msg = "Used regexp fallback for \$c->${warn_for}('${name}'), which found '" .
           (join '", "', @result) . "'. Relying on regexp fallback behavior for " .
           "component resolution is unreliable and unsafe.";
        my $short = $result[0];
        $short =~ s/.*?Model:://;
        my $shortmess = Carp::shortmess('');
        if ($shortmess =~ m#Catalyst/Plugin#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "plugin's config";
        } elsif ($shortmess =~ m#Catalyst/lib/(View|Controller)#) {
           $msg .= " You probably need to set '$short' instead of '${name}' in this " .
              "component's config";
        } else {
           $msg .= " You probably meant \$c->${warn_for}('$short') instead of \$c->${warn_for}({'${name}'}), " .
              "but if you really wanted to search, pass in a regexp as the argument " .
              "like so: \$c->${warn_for}(qr/${name}/)";
        }
        $c->log->warn( "${msg}$shortmess" );
    }

    return @result;
}

=head2 dump_these

Replace the C<password> field in the debug log with asterisks.

=cut
if( Clarive->debug ) {
    around dump_these => sub {
        my $orig = shift;
        my $c = shift;

        my @vars = $c->$orig( @_ );
        my @ret;
        for my $d ( @vars ) {
            my ($type,$obj)=@$d;
            if( $type eq 'Request' ){
                if( defined $obj->{_log}{_body} && $obj->{_log}{_body} =~ m{(password\s+\|\s+)(.+?)(\s+)}s ) {
                   my $p = $2;
                   my $np = '*' x length($p) ;
                   $obj->{_log}{_body} =~ s{\Q$p}{$np}gsm;
                }
                push @ret, $d;
            } else {
                push @ret, $d;
            }
        }
        return @ret;
    };
}

# monkey patch this
sub Class::Date::TO_JSON { $_[0]->string };

# now check for migrations: --migrate
if( $ENV{CLARIVE_MIGRATE_NOW} ) {
    require Baseliner::Schema::Migrator;
    Baseliner::Schema::Migrator->check( $ENV{CLARIVE_MIGRATE_NOW} );
}

# clear cache on restart
if( Clarive->debug ) {
    cache->clear;  
    mdb->grid->remove({ id_rule=>{ '$exists'=>1 } });
    Util->_debug( "Cache cleared" );
}
    
# disconnect from mongo global just in case somebody connected during initializacion (like cache_remove)
# otherwise mongo hell breaks loose
mdb->disconnect;

=head1 NAME

Baseliner - A Catalyst-based Release Management Automation framework

=head1 SYNOPSIS

    script/baseliner_server.pl

=head1 DESCRIPTION

This is the main Baseliner app object.

=head1 SEE ALSO

L<Baseliner::Controller::Root>, L<Catalyst>

=cut

1;
