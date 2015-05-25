package Baseliner::Utils;

=head1 NAME

Baseliner::Utils 

=head1 DESCRIPTION

Some utilities shared by different Baseliner modules and plugins.

=head1 METHODS

=cut 

use Exporter::Tidy default => [
    qw(
    _loc
    _log
    _info
    _debug
    _warn
    _error
    _utf8
    _tz
    _ts
    _loc_unaccented
    _unique
    _throw
    _dt
    _now
    _nowstamp
    parse_date
    parse_dt
    _logts
    _logt0
    _unac
    _name_to_id
    _whereami
    _throw_stack
    _parse_template
    _get_options
    _decode_json
    _encode_json
    _check_parameters
    _bool
    _mkpath
    _rmpath
    _mktmp
    _tmp_dir
    _tmp_file
    _damn
    _parameters
    _strip_html
    is_number
    _dump
    _load
    _trim
    _array
    to_pages
    to_base64
    from_base64
    packages_that_do
    query_array
    _file
    _dir
    _fail
    _mason
    _textile
    _pathxs
    _uacc
    _markup
    zip_files
    zip_tree
    hash_flatten
    parse_vars
    _to_json
    _from_json
    _repl
    _md5
    _html_escape
    _fixascii_sql
    _fixCharacters_mail
    _join_quoted
    case
    _utf8_on_all
    _to_utf8
    _dbis
    _hook
    _ci
    _any
    _ixhash
    _package_is_loaded
    _regex
    _get_dotted_keys
)],
other => [qw(
    _load_yaml_from_comment
    job_icon
    _markdown
    hash_shallow
    ago
)],
logging => [qw(
    _debug _fail _log _info _fixascii_sql _throw _loc _error _whereami _warn
)],
basic => [qw(
    _array _file _dir _now _ci _load :logging 
)],
common => [qw(
    _decode_json _encode_json _to_utf8 _from_json _to_json :basic
)],
;

# setup I18n
our $i18n_path;
our $patterns;

BEGIN {
    use FindBin '$Bin';
    my $path = "/lib/Baseliner/I18N";
    $Bin = "$Bin/script" if $Bin eq $ENV{BASELINER_HOME};
    $i18n_path = File::Spec->catfile($Bin,'..',$path);
    $i18n_path = File::Spec->catfile($ENV{BASELINER_HOME},$path) unless -d $i18n_path;
    #$pattern = File::Spec->catfile($path, '*.[pm]o');
    eval {
        my @patterns;
        for my $dir ( glob "./features/*/lib/Baseliner/I18N" ) {
            next unless -d "$dir";
            $pattern = File::Spec->catfile($dir, '*.[pm]o');
            push @patterns, "Gettext => '$pattern'";
        } 
        $patterns = join',', @patterns;
    };  # may fail when Baseliner is not "use" - ignore then
    warn $@ if $@;
}

use Locale::Maketext::Simple (
            Style => 'gettext',
            Path => $i18n_path,
            Decode => 1,
        );

use strict;
use utf8;
use v5.10;
use Carp::Tidy $ENV{BASELINER_DEBUG} < 2 ? ( -clan=>['Clarive','Baseliner'] ) : (); 
use Class::Date;
use YAML::XS;
use List::MoreUtils qw(:all);
use Try::Tiny;
use Path::Class;
use Term::ANSIColor;
use Scalar::Util qw(looks_like_number);
use Encode qw( decode_utf8 encode_utf8 is_utf8 );

BEGIN {
    # enable a TO_JSON converter
    sub DateTime::TO_JSON  {  $_[0] . '' };
    # include all features I18N files
eval <<"";
    package Baseliner::Utils::I18N;
    Locale::Maketext::Lexicon->import({ '*' => [ $patterns ] });

    loc_lang($Baseliner::locale || 'es' );
}

# split a namespace resource into domain and item
our $ns_regex = qr/^(.*?)\/(.*)$/;
sub ns_split {
    my ( $ns ) = @_;

    if( $ns =~ m{$ns_regex} ) {
        return ($1, $2 );       # package/packagename
    }
    elsif( $ns =~ m{^/(.*)$} ) {
        return ( '', $1 );   # /packagename
    }
    elsif( $ns =~ m{^(.*)/$} ) {
        return ( $1, '' );  # application/ 
    }
    else {
        return ( '', $ns );  
    }
}

sub _unique {
    return () unless @_ > 0;
    my %dup;    
    grep { $dup{$_} // (($dup{$_}=0)+1) } @_;
}

# detect regex auto, use this instead of qr//
sub _regex {
    my ($s) = @_;
    if( $s =~ m{^!!(.*)!!(\w*)$} ) {
        my ($re,$opt)=($1,$2);
        return eval "qr{$re}$opt";
    } else {
        return qr/$s/;
    }
}

# used by job_stash serializer, safer than YAML
sub _stash_dump {
    my ($data) = @_;
    require Storable;
    # local $Storable::Deparse = 1;
    local $Storable::forgive_me = 1;   # warns on CODE, etc., but no fail
    Storable::freeze( $data )
}
sub _stash_load {
    my ($str) = @_;
    require Storable;
    #local $Storable::Eval = sub{ sub{} };
    local $Storable::forgive_me = 1;
    Storable::thaw( $str );
}

sub _load {
    my @args = @_;
    return try {
        my $str = $args[0]; 
        if ( $str ) {
            utf8::encode( $str ) if utf8::valid( $str );  # TODO consider using _to_utf8 - a decode may be needed before
            $str =~ s{!!perl/code }{}g;
            my $obj = YAML::XS::Load( $str );
            return $obj;
        } 
    } catch { 
        my $err = shift;
        local $Baseliner::Utils::caller_level = 2;
        _log( "_load error: " . $err );
        _fail( $err ) if $Baseliner::Utils::YAML_LOAD_FAIL; 
        require YAML::Syck;
        YAML::Syck::Load( @args );
    };
}

sub _dump {
    my @args = @_;
    return try { 
        my $str = YAML::XS::Dump( @args );
        Encode::_utf8_on( $str );
        $str;
    } catch { 
        _error( "_dump error: " . shift() );
        require YAML::Syck;
        YAML::Syck::Dump( @args );
    };
}

sub _loc {
    return unless $_[0];
    #return loc( @_ );
    my @args = @_;
    my $c = try { Baseliner->app };
    if( $ENV{BALI_CMD} || !ref($c) ) {
        my $default_lang = try { Baseliner->config->{default_lang} } catch { 'en' } ;
        loc_lang( $default_lang );
        return loc( @args );
    } else {
        return $c->localize( @args );
    }
}

sub _loc_raw { return loc( @_ ) }
sub _loc_decoded { return _utf8( _loc(@_) ) }
sub _loc_ansi { return _utf8_to_ansi( _loc(@_) ) }
sub _loc_unaccented { 
    require Text::Unaccent::PurePerl;
    Text::Unaccent::PurePerl::unac_string( _loc_ansi(@_) ) 
}

sub _utf8 {
    my $msg = shift;
    is_utf8($msg) ? $msg : decode_utf8($msg);
}

sub _unac { 
    require Text::Unaccent::PurePerl;
    my $s = "$_[0]"; $s = Text::Unaccent::PurePerl::unac_string( $s ); 
    return $s;
}

sub _guess_utf8 { 
    require Encode::Guess;
    Encode::Guess->import('utf8');
    ref guess_encoding( $_[0] ) 
}

sub _utf8_to_ansi {
    return $_[0] unless _guess_utf8( $_[0] );
    my $ret = "$_[0]";
    Encode::from_to( $ret, 'utf8', 'iso8859-1' );	
    return $ret;
}

# Logging

# used by Job::Log.pm (why?)
sub _log_lev {
    my $lev = shift;
    my $calllev = shift;
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller($calllev);
    $cl =~ s{^Baseliner}{B};
    my $pid = sprintf('%s', $$);
    print STDERR ( '('.uc(substr($lev,0,1)//'?').') '. _now()."[$pid] [$cl:$li] ", @_, "\n" );
}

sub isatty { no autodie; return open(my $tty, '+<', '/dev/tty'); }

# internal log engine used by _log and _debug
sub _log_me {
    my ($lev, $cl,$fi,$li, @msgs ) = @_;
    my $logger = $Baseliner::logger // ( Baseliner->can('app') && Baseliner->app ? Baseliner->app->{_logger} : '' );
    my $log_out;
    if( ref $logger eq 'CODE' ) { # logger override
        $log_out = $logger->($lev, $cl,$fi,$li, @msgs );  # logger return if we should continue logging
    } else {
        $log_out = 1;
    }
    
    if( $log_out ) {
        my $first = shift @msgs;
        if( my $rf = ref $first ) {
            $first = sprintf '[DUMP ref=%s]%s', $rf , "\n" . _dump( $first );
        }
        $cl =~ s{^Baseliner}{B};
        my $pid = sprintf('%s', $$);
        my $msg = join '', '('.uc(substr($lev,0,1)).')', _now_log(), "[$pid] [$cl:$li] ", $first, @msgs ;
        #if( !$ENV{BALI_CMD} && ( my $cat_log = Baseliner->log ) ) {
            #$cat_log->$lev( $msg );
        if( ( ( $^O ne 'Win32' && -t STDOUT ) || $ENV{BASELINER_LOGCOLOR} ) && !$Baseliner::no_log_color) { 
            if( $lev eq 'error' ) {
                print STDERR color('red') , $msg , color('reset'), "\n"; 
            } elsif( $lev eq 'debug' ) {
                print STDERR color('cyan') , $msg , color('reset'), "\n"; 
            } elsif( $lev eq 'warn' ) {
                print STDERR color('yellow') , $msg , color('reset'), "\n"; 
            } elsif( $lev eq 'info' ) {
                print STDERR color('green') , $msg , color('reset'), "\n"; 
            } else {
                print STDERR $msg , "\n"; 
            }
        } else {
            print STDERR $msg , "\n"; 
        }
    }
}

sub _log {
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller( ($Baseliner::Utils::caller_level // 0) );
    _log_me( 'info', $cl, $fi, $li, @_ );
}

sub job_icon {
    my ($status, $rollback) = @_;

    given( $status ) {
        when( 'RUNNING' ) { 'gears.gif'; }
        when( 'READY' ) { 'waiting.png'; }
        when( 'APPROVAL' ) { 'user_delete.gif'; }
        when( 'FINISHED' ) { if (!$rollback) { 'log_i.gif' } else { 'close.png' } }
        when( 'IN-EDIT' ) { 'log_w.gif'; }
        when( 'WAITING' ) { 'waiting.png'; }
        when( 'PAUSED' ) { 'paused.png'; }
        when( 'TRAPPED_PAUSED' ) { 'paused.png'; }
        when( 'CANCELLED' ) { 'close.png'; }
        default { 'log_e.gif' }
    }
}

sub _info {    # info is the same as _log, but in a job, reports as info instead as debug
    return unless any { $_ } @_;
    local $Baseliner::log_info_is_info = 1;
    my ($cl,$fi,$li) = caller( ($Baseliner::Utils::caller_level // 0) );
    _log_me( 'info', $cl, $fi, $li, @_ );
}

sub _error {
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller( ($Baseliner::Utils::caller_level // 0) );
    _log_me( 'error', $cl, $fi, $li, @_ );
}

sub _warn {
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller(($Baseliner::Utils::caller_level // 0));
    _log_me( 'warn', $cl, $fi, $li, @_ );
}

sub _debug {
    my $cal = looks_like_number($_[0]) && $_[0] < 0 ? -(shift()) : ($Baseliner::Utils::caller_level // 0);
    my ($cl,$fi,$li) = caller( $cal );
    return unless Clarive->debug;
    _log_me( 'debug', $cl,$fi,$li,@_);
}

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep stat );
my $t0 = [gettimeofday];

sub _logt0 {
    $t0 = [gettimeofday]; 
}

sub _logts {
    return unless any { $_ } @_;
    my $inter = sprintf( "%.04f", tv_interval( $t0 ) );
    $t0 = [gettimeofday]; 
    my ($cl,$fi,$li) = caller(0);
    my $logger = $Baseliner::_logger;
    if( ref $logger eq 'CODE' ) { # logger override
        $logger->($cl,$fi,$li, @_);
    } else {
        $cl =~ s{^Baseliner}{B};
        my $pid = sprintf('%s', $$);
        print STDERR ( _now()." $inter [$pid] [$cl:$li] ", @_, "\n" );
    }
}

sub _decode_json {
    my $json = shift;
    require JSON::XS;
    $json = encode_utf8($json) if is_utf8($json);
    return JSON::XS::decode_json($json); 
}

sub _encode_json {
    my $data = shift;
    require JSON::XS;
    #$data = encode_utf8($data) if is_utf8($data);
    return decode_utf8( JSON::XS::encode_json($data) ); 
}

sub _throw {
    #Carp::confess(@_);
    #die join('', @_ , "\n");
    #Catalyst::Exception->throw( @_ );
    #Carp::Clan::croak @_;
    ##Baseliner->{last_err} = { err=>$_[0], stack=>_whereami };
    #   Carp::croak @_, Carp::longmess();

    my $thower = try { Baseliner->app->{_thrower} } catch { '' };
    if( ref $thower eq 'CODE' ) { # throw override
        $thower->(@_);
    } else {
        print STDERR Carp::longmess @_;
        die @_,"\n";
    }
}

sub _throw_stack {
    Carp::confess(@_);
}

sub _whereami {
    Carp::longmess(@_);
}

sub _say {
    print @_,"\n" if( $Baseliner::DEBUG );
} 

sub _tz {
    my $tz = try { Baseliner->config->{time_zone} } catch {''};
    $tz || 'CET';
}

sub _dt { 
    require DateTime;
    DateTime->now(time_zone=>_tz);  }

# same as _now, but with hi res in debug mode
sub _now_log {
    if( Clarive->debug ) {
        my @t=split /\./, Time::HiRes::time(); 
        return sprintf "%s.%03d", Class::Date::date( $t[0]), substr $t[1], 0, 3;
    } else {
        return _now();
    }
}

sub _ts {
    Class::Date->now()->to_tz(_tz())
}

sub _now {
    return _ts().''
}

sub _nowstamp {
    (my $t = _now )=~ s{-|\:|\/|\\|\s}{}g;
    return $t;
}

sub _cut {
    my ($index, $separator, $str ) = @_;
    my @s = split /$separator/, $str;
    my $max = $#s;
    my $top = $index > 0 ? $index : $max + $index;
    return join $separator, @s[ 0..$top ];
}

# date natural parsing 
use DateTime::Format::Natural;
sub parse_date {
    my ( $format, $date ) = @_;
    my $parser = DateTime::Format::Natural->new( format=>$format );
    return $parser->parse_datetime(string => $date);
}

# alternative parsing with strpdate
sub parse_dt {
    my ( $format, $date ) = @_;
    require DateTime::Format::Strptime;
    my $parser = DateTime::Format::Strptime->new( pattern => $format, on_error=>'croak', time_zone=>_tz() );
    my $dt = try { 
        $parser->parse_datetime( "$date" );
    } catch {
        _fail( _loc( "Could not parse date %1 with format %2", $date, $format ) );
    };
}

sub query_array {
    my $query = shift;
    {
        no warnings;  # may be empty strings, unitialized
        my $txt = join ',', @_;    ##TODO check for "and", "or", etc. with text::query
        return $txt =~ m/$query/i;
    }
}

sub packages_that_do {
    my @roles = @_;
    my @packages;
    require Class::MOP;
    my %cl=Class::MOP::get_all_metaclasses();
    for my $package ( grep !/::Role/, grep /^Baseliner/, keys %cl ) {
        #my $meta = Class::MOP::get_metaclass_by_name($package);
        my $meta = Class::MOP::Class->initialize($package);
        eval {
            foreach my $role ( @roles ) {
                next unless $meta->can('does_role');
                push @packages, $package if $meta->does_role($role);
            }
        };
    }
    return @packages;
}

sub _parameters {
    my $p = {};
    if( ref $_[0] ) {
        $p = $_[0];
    } else {
        $p = { @_ };
    }
    return $p;
}

# creates an array from whatever arrays
# rgo: fix the hash to hash-items problem, use Util->_array_all for legacy
sub _array {
    my @array;
    for my $item ( @_ ) {
        if( ref $item eq 'ARRAY' ) {
            push @array, @{ $item };
        } elsif( ref $item eq 'HASH' ) {
            push @array, $item;
        } else {
            push @array, $item if length $item;
        }
    }
    return @array;
}

sub _array_all {
    my @array;
    for my $item ( @_ ) {
        if( ref $item eq 'ARRAY' ) {
            push @array, @{ $item };
        } elsif( ref $item eq 'HASH' ) {
            push @array, %{ $item };
        } else {
            push @array, $item if $item;
        }
    }
    return @array;
}

sub _array_or_commas {
    my (@arr) = @_;
    my @ret = map { ref($_) ? ( map { ref $_ ? $_ : split(/,/,$_) } _array($_) ) : split( /,/, $_) } @arr;
    return @ret==1 && ref $ret[0] eq 'ARRAY' ? _array($ret[0]) : @ret; 
}

sub is_number {
    #return $_[0] =~ /^(?=[-+.]*\d)[-+]?\d*\.?\d*(?:e[-+ ]?\d+)?$/i;
    my $val = $_[0];
    return 0 unless length $val;
    return looks_like_number($val);
}

sub is_int {
    return 0 unless length $_[0];
    return $_[0] =~ /^\d+$/;
}

sub _trim {
    my $str = shift;
    return '' unless length $str;
    $str =~ s{^\s*}{}g;
    $str =~ s{\s*$}{}g;
    return $str;
}

sub _parse_template {
    my ( $template, %vars ) = @_;
    my $type = $vars{text_template_type} || 'FILE'; # could use STRING
    require Text::Template;
    my $tt = Text::Template->new( 
                    TYPE => $type,
                    SOURCE => $template ) or _throw _loc("Could not open template file %1", $template);
    my $body = $tt->fill_in( 
        HASH=> \%vars,
        BROKEN => sub { 
            my %p=@_; 
            _throw _loc("Error loading template '%1': '%2'",$p{template},$p{text} ); 
        },
        DELIMITERS => [ '<%','%>' ] 
    );
    return $body;
}

sub _parse_template_mason {
    my ( $template, %vars ) = @_;

    my $body;
    require HTML::Mason::Interp;
    my $comp_root = "". Baseliner->config->{root};
    my $data_dir = File::Spec->catdir( _tmp_dir(), 'mason', sprintf('Baseliner_%d_mason_data_dir', $<));
    my $m = HTML::Mason::Interp->new(
        comp_root  => $comp_root,
        data_dir   => $data_dir,
        out_method => \$body,
    );
    $m->exec( "/$template", %vars );
    return $body;
}

sub my_hostname {
   require Sys::Hostname;
   return Clarive->config->{hostname} || Baseliner->config->{hostname} || lc( Sys::Hostname::hostname() ); 
}

sub _notify_address {
    my $host = Baseliner->config->{web_host} || my_hostname(); 
    my $port = Baseliner->config->{web_port} || $ENV{BASELINER_PORT} || $ENV{CATALYST_PORT} || 3000;
    return "http://$host:$port";
}

# usage: my %opts = get_options @ARGV
sub _get_options {
    my ( $last_opt, %hash );
    for my $opt (@_) {
        if ( $opt =~ m/^-+(.*)/ ) {
            $last_opt = $1;
            $hash{$last_opt} = [] unless ref $hash{$last_opt};
        }
        else {
            $opt = Encode::encode_utf8($opt) if Encode::is_utf8($opt);
            push @{ $hash{$last_opt} }, $opt; 
        }
    }
    # convert single option => scalar
    for( keys %hash ) {
        if( @{ $hash{$_} } == 1 ) {
            $hash{$_} = $hash{$_}->[0];
        }
    }
    return %hash;
}

# change < and > for &gt; etc
sub _replace_tags {
    my $str = shift;
    $str =~ s{<}{&lt;}g;
    $str =~ s{>}{&gt;}g;
    return $str;
}

sub _strip_html {
    my $d = shift;
    return $d unless length $d;
    require HTML::Strip;
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($d);
    utf8::decode( $clean_text );
    $clean_text;
}

sub _check_parameters {
    my $p = shift;
    for my $param ( @_ ) {
        exists($p->{$param}) or _throw _loc('Missing parameter %1', $param);
    }
}

sub _bool {
    my ($v,$default)=@_;
    $default //= 0; 
    return !defined $v ? $default
        : ref $v eq 'SCALAR' ? !!$$v
        : "$v" eq 'true' ? 1
        : "$v" eq 'on' ? 1
        : "$v" eq 'off' ? 0
        : "$v" eq 'false' ? 0
        : "$v" eq '' ? $default
        : !!$v;
}
sub _mkpath {
    my $dir = File::Spec->catfile( @_ );
    return if( -e $dir );
    require File::Path;
    File::Path::make_path( $dir ) or _throw "Error creating directory $dir: $!";
}

sub _rmpath {
    my $dir = _dir( @_ );
    return unless -e $dir;
    $dir->rmtree;
}

sub _name_to_id {
    my $name = _unac( lc shift );
    $name =~ s{\s+}{_}g;
    $name =~ s{\W}{_}g;
    $name =~ s{_+}{_}g;
    $name =~ s{_$}{}g;
    $name =~ s{^_}{}g;
    $name =~ s/[^[:ascii:]]+//g;
    return $name;
}

# returns the official tmp dir
sub _tmp_dir {
    my $tmp_dir = try { Baseliner->config->{tempdir} } catch {};
    $tmp_dir || $ENV{BASELINER_TEMP} || $ENV{BASELINER_TMPHOME} || File::Spec->tmpdir || $ENV{TEMP};
}

=head2 _mktmp( suffix=>$str )

Creates a random tempdir inside the official temp dir.

=cut
sub _mktmp {
   my %p = @_;
   my $suffix = [ _array($p{suffix}) ] || [];
   my $prefix = [ _array($p{prefix}) ] || [];
   return _dir( _tmp_dir(), @$prefix, join( '_', _nowstamp, $$, int( rand( 100000 ) ), @$suffix ) );
}

=head2 _tmp_file( prefix=>'myprefix', extension=>'zip' )

Returns a temp file name, creating the temp directory if needed. 

=cut
sub _tmp_file {
    my $p = _parameters(@_);
    # dir selection
    my $tempdir = $p->{tempdir} || _tmp_dir();
    my $dir  = File::Spec->catdir($tempdir, ($p->{dir}//'') );
    unless( -d $dir ) {
        warn "Creating temp dir $dir";
        _mkpath( $dir );
    }
    # file selection
    my $file = $p->{filename} 
        ? File::Spec->catfile($dir,$p->{filename}) 
        : do {
            $p->{prefix} ||= [ caller(0) ]->[2];  # get the subname
            $p->{prefix} =~ s/\W/_/g;
            $p->{extension} ||='log';
            File::Spec->catfile($dir, $p->{prefix} . "_" . _nowstamp() . "_$$." . $p->{extension} ); 
        };
    ( $ENV{BASELINER_DEBUG} || $ENV{CATALYST_DEBUG} ) and warn "Created tempfile $file\n";
    return $file;
}

sub _blessed {
    require Scalar::Util;
    Scalar::Util::blessed( shift() );
}

sub _unbless {
    require Data::Structure::Util;
    Data::Structure::Util::unbless( @_ );
}

sub _clone {
    my ($obj) = @_;
    return Storable::thaw(Storable::freeze($obj));
}

sub _damn {
    my $blessed = shift;
    my $damned;
    my $clone = _load( _dump( $blessed ) );
    return _unbless( $clone );
    ## deprecated:
    try {
        # recurse
        if( ref($blessed) eq 'HASH' ) {
            $damned = {};
            for my $k ( keys %$blessed ) { 
                $damned->{$k} = _damn( $blessed->{$k} );
            }
        }
        elsif( ref($blessed) eq 'SCALAR' ) {
            $damned = "$$blessed";
        }
        elsif( ref($blessed) eq 'ARRAY' ) {
            $damned = [ map { _damn($_) } @$blessed ];
        }
        elsif( ref $blessed ne 'CODE' ) {
            $damned = _damn( { %$blessed } );
        }
        else {
            $damned = $blessed;
        }
    } catch {
        my $err = shift;
        $damned = $blessed;
        #_debug( 'DAMN1=' . $err );
    };
    return $damned;
}

sub to_pages {
    my %p = @_;
    return 1 unless $p{start} && $p{limit};
    return int( $p{start} / $p{limit} ) + 1;
}

sub to_base64 {
    require MIME::Base64;
    return MIME::Base64::encode_base64( shift );
}

sub from_base64 {
    require MIME::Base64;
    return  MIME::Base64::decode_base64( shift() );
}

=head2 _fail

Die without line number info.

=cut
sub _fail {
    my ($cl,$fi,$li) = caller();
    if( $Baseliner::logger ) {
        _debug( "FAIL: $cl;$li: @_" ); # if we are in a job, be a little more discrete
    } else {
        _error( "FAIL: $cl;$li: @_" ) 
    }
    _throw( @_ ) if $ENV{BASELINER_THROW} || $ENV{BASELINER_DEBUG} > 1;
    die join(' ',@_) . "\n";
}

=head2 query_sql_build

Returns a SQL::Abstract where statement given
a query string and a list of fields.

    $query and $where = query_sql_build( query=>$query, fields=>{
        name     =>'me.name',
        id       =>'to_char(me.id)',
        user     =>'me.username',
        comments =>'me.comments',
        status   =>'me.status',
        start    =>"me.starttime",
        sched    =>"me.schedtime",
        end      =>"me.endtime",
        items    =>"foreign.item",
    });

You can use an ARRAY for shorthand too:


    $where = query_sql_build( query=>$query,
        fields=>[
            qw/id bl name requested_on requested_by finished_on finished_by/,
            [ 'age', 'foreign.age' ]     # handles pairs also
        ]);

=cut
sub query_sql_build {
    my %p = @_;
    return {} unless $p{query};
    _throw 'Fields parameter should be HASH or ARRAY'
        unless ref( $p{fields} ) =~ m/HASH|ARRAY/i;
    my @terms;
    my $where = {};
    my $fields = $p{fields};
    ref $fields eq 'ARRAY' and do {
        $fields = { map {
            my $val = $_;
            my $col = $_;
            if( $val eq 'ARRAY' ) {
                $val = $val->[0]; 
                $col = $val->[1];
            }
            $val => $col;
        } @$fields };
    };
    # build columns   -----    TODO use field:lala
    my $col = join '||', values %{ $fields };
    $p{query} =~ s{\*}{%}g;
    $p{query} =~ s{\?}{_}g;
    @terms = grep { defined($_) && length($_) } split /\s+/, lc($p{query});  # TODO handle quotes "
    $col = "lower($col)" unless grep /[A-Z]/, @terms; # case sensitive search
    my @terms_normal = grep(!/^\+|^\-/,@terms);
    my @terms_plus = grep(/^\+/,@terms);
    my @terms_minus = grep(/^\-/,@terms);
    my @ors = map { \[ "trim($col) LIKE '%'||?||'%' ", [ value => $_ ] ] } @terms_normal;
    #push @ors, { 1=>1 } if ! @terms_normal;
    $where->{'-and'} = [
        ( @ors ? [ -or => \@ors ] : () ),
        ( map { \[ "trim($col) LIKE '%'||?||'%' ", [ value => substr($_,1) ] ] } @terms_plus ),
        ( map { \[ "trim($col) NOT LIKE '%'||?||'%' ", [ value => substr($_,1) ] ] } @terms_minus )
    ];
    return $where;
}

sub build_master_search {
    my (%p) = @_;
    return {} unless $p{query};
    my $query = $p{query};
    my $where = {};
    $query =~ s{\*}{%}g;
    $query =~ s{\?}{_}g;
    # take care of keeping quoted terms together
    my $no_spaces = sub{ (my$r=$_[0])=~ s/\s+//g; $r };  # quote terms cannot have spaces, so that they don't get splited on term split
    $query =~ s/"(.*?)"/$no_spaces->($1)/eg;   
    my @terms = grep { defined($_) && length($_) } map { Util->_unac($_) } split /\s+/, lc $query; # split terms and all lowercase 
    my $clean_terms = sub { s/[^\w|:|,|-]//g for @_; @_  };  # terms can only have a few special chars
    my @terms_normal = $clean_terms->(  grep(!/^\+|^\-/,@terms) ); # ORed
    my @terms_plus = $clean_terms->( grep(/^\+/,@terms) ); # ANDed
    my @terms_minus = $clean_terms->(  grep(/^\-/,@terms) ); # NOTed
    my @ors = map { \[ " EXISTS (select 1 from bali_master_search ss where ss.mid=me.mid and ss.search_data LIKE ? ) ", '%'.$_.'%' ] } @terms_normal;
    $where->{'-and'} = [
        ( @ors ? [ -or => \@ors ] : () ),
        ( map { \[ " EXISTS (select 1 from bali_master_search ss where ss.mid=me.mid and ss.search_data LIKE ? ) ", '%'.$_.'%' ] } @terms_plus ),
        ( map { \[ " NOT EXISTS (select 1 from bali_master_search ss where ss.mid=me.mid and ss.search_data LIKE ? ) ", '%'.$_.'%' ] } @terms_minus ),
    ];
    return $where;
}

sub _file { goto &Path::Class::file }
sub _dir { goto &Path::Class::dir }
sub _slurp {
    my $file = shift;
    return unless -e $file;
    open my $f, '<', $file or _throw _loc("Could not open file %1: %2", $file, $!);
    return join'',<$f>;
}

our @mason_features;
sub _mason {
    my ( $template, %p ) = @_; 
    my $body;
    @mason_features or @mason_features = map {
        [ $_->id => _dir( $_->root )->stringify ]
    } Baseliner->features->list;
    require File::Spec;
    require HTML::Mason::Interp;
    my $comp_root = $p{comp_root} ? [[root=>"$p{comp_root}"]] : [ @mason_features, [ root=>"". Baseliner->config->{root} ] ];
    my $data_dir = File::Spec->catdir( _tmp_dir(), 'mason', sprintf('Baseliner_%d_mason_data_dir', $<));
    my $m = HTML::Mason::Interp->new(
        ( $p{utf8} ? (preamble => "use utf8;") : () ),
        comp_root  => $comp_root,
        data_dir   => $data_dir,
        out_method => \$body,
    );
    $m->exec( "/$template", %p );
    return $body;
}

sub _textile {
    require Text::Textile;
    Text::Textile::textile( shift );
}

sub _pathxs {
    my ($dir, $i) = @_;
    $dir =~ s/\\/\//g;         # Make this work in Win.
    my @lat = split('/', $dir);
    return $lat[$i] if $i;     # Return n position.
    return @lat if wantarray;  # Return a list.
    sub { shift @lat || q{} }  # Build up an iterator.
}

sub _markdown {
    require Text::Markdown;
    my ($txt,$mdopts, %p) = @_;
    #$txt = _markdown_escape($txt);
    $txt =~ s{##:([^:]+):}{/topic/download_file/$p{mid}/$1};
    $txt = Text::Markdown::markdown( $txt, $mdopts );
    $txt =~ s{^\<p\>}{};
    $txt =~ s{\</p\>\n?$}{};
    $txt ;
}

sub _uacc {
    my @l = @_;
    sub { 
        my $a = shift;
        if ($a) {
            return push @l, $a unless $a ~~ @l;
        }
        return @l;
    }
}

sub _markdown_escape {
    my $text = shift;
    my @chars = split("", $text);
    my @escaped_symbols = ('\\','*','_','[',']','(',')','#','-','+','.','!','{','}', '`');
    my $i = 0;
    foreach my $char (@chars){
        if(grep { $_ eq $char } @escaped_symbols){
            $chars[$i] = "\\$char";
        }
        $i++;
    }
    return join '', @chars;
}

sub _markup_escape {
    my $txt = shift;
    $txt =~ s/\\\*/\&\#42\;/g;
    $txt =~ s/\\\`/\&\#96\;/g;
    $txt =~ s/\\\\/\&\#92\;/g;
    $txt =~ s/\\\_/\&\#95\;/g;
    $txt =~ s/\\\[/\&\#91\;/g;
    $txt =~ s/\\\]/\&\#93\;/g;
    $txt =~ s/\\\(/\&\#40\;/g;
    $txt =~ s/\\\)/\&\#41\;/g;
    $txt =~ s/\\\#/\&\#35\;/g;
    $txt =~ s/\\\-/\&\#45\;/g;
    $txt =~ s/\\\+/\&\#43\;/g;
    $txt =~ s/\\\./\&\#46\;/g;
    $txt =~ s/\\\!/\&\#33\;/g;
    $txt =~ s/\\\{/\&\#123\;/g;
    $txt =~ s/\\\}/\&\#124\;/g;
    $txt;
}

sub _markup_unescape {
    my $txt = shift;
    $txt =~ s/\&\#42\;/\*/g;
    $txt =~ s/\&\#96\;/\`/g;
    $txt =~ s/\&\#92\;/\\/g;
    $txt =~ s/\&\#95\;/\_/g;
    $txt =~ s/\&\#91\;/\[/g;
    $txt =~ s/\&\#93\;/\]/g;
    $txt =~ s/\&\#40\;/\(/g;
    $txt =~ s/\&\#41\;/\)/g;
    $txt =~ s/\&\#35\;/\#/g;
    $txt =~ s/\&\#45\;/\-/g;
    $txt =~ s/\&\#43\;/\+/g;
    $txt =~ s/\&\#46\;/\./g;
    $txt =~ s/\&\#33\;/\!/g;
    $txt =~ s/\&\#123\;/\{/g;
    $txt =~ s/\&\#124\;/\}/g;
    $txt;
}

=head2 _markup

Baseliner flavored markup.

=cut
sub _markup {
    my $txt = shift;
    #$txt = _markup_escape($txt);
    $txt =~ s{\*\*(.*?)\*\*}{<span><b>$1</b></span>}g;
    $txt =~ s{\*(.*?)\*}{<b>$1</b>}g;
    $txt =~ s{\`(.*?)\`}{<code>$1</code>}g;
    #$txt = _markup_unescape($txt); ## se podría quitar si se muestra como html
    $txt ;
}

sub _to_json {
    goto &JSON::XS::encode_json;
}

sub _from_json {
    goto &JSON::XS::decode_json;   
}

=head2 zip_files( files=>['file.txt', ... ] [, to=>'file.zip' ] )

Write a zip file.

    prefix     => zipfile name prefix
    base       => basepath to be subtracted from each file 
    pathprefix => basepath to be appended to each file, in case they are
                already relative

=cut
sub zip_files {
    my %p = @_;
    require Archive::Zip;
    $p{to} ||= _tmp_file( extension=>'zip', prefix=>$p{prefix} || 'zipfiles' );
    my $zip = Archive::Zip->new();
    for my $file ( _array $p{files} ) {
        my $filepath;
        $p{base} and $filepath = _file($file)->relative( $p{base} ); 
        $p{pathprefix} and do {
            $filepath = $file;
            $file = File::Spec->catfile( $p{pathprefix}, $file );
        };
        _log "ZIP ADD $file, $filepath";
 if(grep /compressed/, qx{file $file}) #evitar fallo en caso de fichero comprimido
                {
                        $zip->addFile( $file, $filepath )->desiredCompressionLevel(0);
                }
                else
                {
                        $zip->addFileOrDirectory( $file, $filepath );


       # $zip->addFile( $file, $filepath );
    }
    $zip->writeToFileNamed($p{to}) == $Archive::Zip::AZ_OK
        or _throw "Error writing zip file $p{to}: $!";
    return $p{to};
	}
}
sub zip_tree {
my (%p) =@_;
    my $source = $p{source} // _fail _loc 'Missing parameter source'; 
    my $zipfile = $p{to} // _fail _loc 'Missing parameter zipfile';
my $base = $p{base} // $source;
    my $verbose = $p{verbose};

    # open and close to reset file and attempt write
         open my $ff, '>', $zipfile 
         or _fail _loc 'Could not create zip file `%1`: %2', $zipfile, $!;
        close $ff;
require Archive::Zip;
    _fail _loc 'Could not find dir `%1` to zip', $source 
        unless -e $source;
 # build local zip
my $zip = Archive::Zip->new() or _throw $!;
    _debug "Adding $source";
    if (-d $source) {
        $zip->addTree ($source, $base) == $Archive::Zip::AZ_OK
        or _throw "Error adding directory $source: $!";

    } else {
        if (grep /compressed/, qx{file $source}) {
            $zip->addFile ($source)->desiredCompressionLevel(0)
        } else {
           $zip->addFileOrDirectory($source); 
        }
    }
$zip->writeToFileNamed($p{to}) == $Archive::Zip::AZ_OK
 or _throw "Error writing zip file $p{to}: $!";
    return $p{to};
}


=head2 hash_flatten ( \%stash, $prefix )

Deeply flatten the keys in a HASH. Turns arrays into comma-separated lists.
Ignores objects.

    $h->{foo}->{bar} = 10;
    $h->{arr} = [ 1,2,3 ];

    $h = hash_flatten $h;

    $h->{foo.bar} == 10;
    $h->{arr} eq '1,2,3';

=cut
our $hf_scope;
sub merge_pushing {
    my ($h1, $h2 ) = @_;
    my %merged;
    for my $k2 ( keys %$h2 ) {
        my $v2 = $h2->{$k2};
        $merged{ $k2 } = $v2;  
    }
    for my $k1 ( keys %$h1 ) {
        my $v1 = $h1->{$k1};    
        if( exists $merged{$k1} ) {
            my $v2 = delete $merged{$k1};
            if( !defined $v2 ) {
                $merged{$k1}=$v1;
            }
            elsif( !defined $v1 ) {
                $merged{$k1}=$v2;
            }
            elsif( $v1 eq $v2 ) {
                $merged{$k1} = $v2;
            }
            else {
                push @{$merged{$k1}}, $v2 eq $v1 ? $v2 : ( $v2, $v1 );  
            }
        }
        else {
            $merged{ $k1 } = $v1;  
        }
    }
    %merged;
}
sub hash_flatten {
    my ( $stash, $prefix ) = @_;
    no warnings;
    $prefix ||= '';
    my %flat;
    $hf_scope or local $hf_scope = {};
    my $refstash = ref $stash;
    if( $refstash ) {
        my $refaddr = Scalar::Util::refaddr( $stash );
        return () if exists $hf_scope->{$refaddr};
        $hf_scope->{$refaddr}=() if $refstash;
    }
    if( $refstash eq 'HASH' ) {
        for my $k ( keys %$stash ) {
            my $v = $stash->{$k};
            %flat = merge_pushing( \%flat, scalar hash_flatten($v, $prefix ? "$prefix.$k" : $k ) );
        }
    } 
    elsif( $refstash eq 'ARRAY' ) {
        my $cnt=0;
        for my $v ( @$stash ) {
            %flat = merge_pushing( \%flat, scalar hash_flatten($v, "$prefix" ) );
        }
    }
    elsif( $refstash && $refstash !~ /CODE|GLOB|SCALAR/ ) {
        #my $clone = _damn( $stash );
        #%flat = merge_pushing( \%flat, scalar hash_flatten ( $clone, "$prefix" ) );
        #%flat = ( "$prefix"=>$stash, %flat );  # so that we have key: { ... }, key.subkey1: 1, key.subkey2: 2, ...
        $stash = _damn( $stash );
        %flat = merge_pushing( \%flat, scalar hash_flatten ( $stash, "$prefix" ) );
    }
    else {
        $flat{ "$prefix" } = "$stash";
    }
    if( !$prefix ) {
        for my $k ( keys %flat ) {
            my $v = $flat{$k};
            if( ref $v eq 'ARRAY' ) {
                $flat{$k}=join ',', @$v; 
            }
        }
    }
    return wantarray ? %flat : \%flat;
}

=head2 hash_shallow

Turns a deeply nested hash into a very flat one:

    my $h = {};
    hash_shallow( { ss=>{ aa=>[11,{ bb=>22 }] }, dd=>{ rr=>{ xx=>[99], ff=>98 } }, rr=>13 }, $h );
    _dump( $h );

Turns into:

    aa:
    - 11
    bb: 22
    ff: 98
    rr: 13
    xx:
    - 99

=cut
sub hash_shallow {
    my ($h, $ret ) = @_;
    $ret //= {};
    my $r = ref $h;
    if( $r eq 'HASH' ) {
        for my $k ( keys %$h ) {
            my $v = $h->{$k};
            my $vv = hash_shallow( $v, $ret );
            next unless defined $vv;
            if( exists $ret->{$k} ) {
                $ret->{$k} = [ $ret->{$k} ] unless ref $ret->{$k} eq 'ARRAY';
                push( @{ $ret->{$k} }, $vv );
            } else {
                $ret->{$k} = $vv;
            }
        }
        return undef;
    }
    elsif( $r eq 'ARRAY' ) {
        my @res;
        for( @$h ) {
            push @res => hash_shallow( $_, $ret );        
        }
        return [ grep { defined } @res ];
    }
    elsif( defined $h ){
        return $h ;
    }
    return undef;
}


=head2 parse_vars

Parse vars in a string. Replace them if we can. Return
the replaced string.

Options:

    throw    => die on missing variables
    cleanup  => remove unresolved variables

Default action for unresolved variables is to leave them in.

Timeout:

Only 5 seconds (default) are allowed for this operation
to complete, otherwise it will die.

Set C<$Baseliner::Utils::parse_vars_timeout> to change 
the timeout secs (or zero to disable);

=cut
sub parse_vars {
    my ( $data, $vars, %args ) = @_;
    return $data unless ref $vars;
    my $ret;
    {
          local $SIG{ALRM} = sub { alarm 0; die "parse_vars timeout - data structure too large?\n" };
          alarm( $ENV{BASELINER_PARSE_TIMEOUT} // $Baseliner::Utils::parse_vars_timeout // 30 );

          $ret = parse_vars_raw( data=>$data, vars=>$vars, throw=>$args{throw} );
          alarm 0;
    }
    return $ret;
}

our $parse_vars_raw_scope;
sub parse_vars_raw {
    my %args = @_;
    my ( $data, $vars, $throw, $cleanup ) = @args{ qw/data vars throw cleanup/ };
    my $ref = ref $data;
    # block recursion
    $parse_vars_raw_scope or local $parse_vars_raw_scope={};
    return () if $ref && exists $parse_vars_raw_scope->{"$data"};
    $parse_vars_raw_scope->{"$data"}=() if $ref;
    my $stack = $args{stack};
    
    if( $ref eq 'HASH' ) {
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw, stack=>$stack );
        }
        return \%ret;
    } elsif( $ref =~ /Baseliner/ ) {
        my $class = $ref;
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw, stack=>$stack );
        }
        return bless \%ret => $class;
    } elsif( $ref eq 'ARRAY' ) {
        my @tmp;
        for my $i ( @$data ) {
            push @tmp, parse_vars_raw( data=>$i, vars=>$vars, throw=>$throw, stack=>$stack );
        }
        return \@tmp;
    } elsif( $ref eq 'SCALAR' ) {
        return parse_vars_raw( data=>$$data, vars=>$vars, throw=>$throw,stack=>$stack );
    } elsif( $ref eq 'MongoDB::OID') {
        return parse_vars_raw( data=>$$data{value}, vars=>$vars, throw=>$throw,stack=>$stack );
    } elsif($ref) {
        return parse_vars_raw( data=>_damn( $data ), vars=>$vars, throw=>$throw,stack=>$stack );
    } else {
        # string
        return $data unless $data && $data =~ m/\$\{[^\}]+\}/;
        my $str = "$data";
        while(1) {
            # ref replaces
            if( $str =~ /^\$\{([^\}]+)\}$/ ) {
                # just the var: "${my_server}"

                # control recursion and create a path for a clearer error message
                my $k = $1;
                _fail _loc 'Deep recursion in parse_vars for variable `%1`, path %2', $k, '${'.join('}/${',_array($stack->{path})).'}' 
                    if exists $stack->{unresolved}{$k};
                $stack->{unresolved}{$k}=1;
                $stack->{path} or local $stack->{path} = []; 
                push @{ $stack->{path} }, $k;

                # just a var
                if( exists $vars->{$k} ) {
                    $str = parse_vars_raw(data=>$vars->{$k},vars=>$vars,throw=>$throw,stack=>$stack); 
                    delete $stack->{unresolved}{$k};
                    last;
                }
                # dot?
                my @keys = split( /\./, $k) if $k =~ /[\.\w]+/;
                if( @keys > 1 ) {
                    my $k2 = join('}{', @keys );
                    if( eval('exists $vars->{'.$k2.'}') ) {
                        $str = parse_vars_raw( data=>eval('$vars->{'.$k2.'}'), vars=>$vars, throw=>$throw,stack=>$stack);
                        delete $stack->{unresolved}{$k};
                        last;
                    }
                }
                if( $k =~ /^(uc|lc)\(([^\)]+)\)/ ) {
                    my $v = parse_vars_raw( data=>'${'.$2.'}', vars=>$vars, throw=>$throw,stack=>$stack );
                    $str = $1 eq 'uc' ? uc($v) : lc($v);
                    last;
                }
                if( $k =~ /^to_id\(([^\)]+)\)/ ) {
                    $str = _name_to_id(parse_vars_raw( data=>$1, vars=>$vars, throw=>$throw,stack=>$stack ));
                    last;
                }
                if( $k =~ /^nvl\(([^\)]+),(.+)\)/ ) {
                    $str = $vars->{$1} // $2;
                    last;
                }
                if( $k =~ /^ci\(([^\)]+)\)\.(.+)/ ) {
                    my $ci = ci->new( $vars->{$1} );
                    $str = $ci->can($2) ? $ci->$2 : $ci->{$2};
                    last;
                }
                if( $k =~ /^ci\(([^\)]+)\)/ ) {
                    $str = ci->new( $vars->{$1} );   # better than ci->find, this way it fails when mid not found
                    last;
                }
            }
            else {
                # a string with more text, ex: "sudo ${my_user} ; ls ${my_path}"
                $str =~ s/(\$\{[^\}]+\})/parse_vars_raw(data=>$1,vars=>$vars,throw=>$throw,stack=>$stack)/eg;
            }
            last;
        }
        # cleanup or throw unresolved vars
        if( $throw ) { 
            if( my @unresolved = $str =~ m/\$\{(.*?)\}/gs ) {
                _throw _loc( "Unresolved vars: '%1' in %2", join( "', '", @unresolved ), $str );
            }
        } elsif( $cleanup ) {
            $str =~ s/\$\{.*?\}//g; 
        }
        return $str;
    }
}

=head2 _repl

Stops execution and opens a REPL.

    ^D  - resumes execution
    ^C  - kills baseliner

=cut
sub _repl {
    require Carp::REPL;
    goto &Carp::REPL::repl;
}

=head2 _md5

Returns a md5 hash for a given string, Path::Class::File,
glob or IO::File.

    my $f = _file('/dir/file.txt');
    say 'HASH=' . _md5( $f );
    say 'HASH=' . _md5( 'hello world' );
    open my $ff,'<', '/dir/file.txt';
    say 'HASH=' . _md5( $ff );

=cut
sub _md5 {
    my ($in) = @_;
    require Digest::MD5;
    $in = $in->open('r') if ref($in) eq 'Path::Class::File';
    if( ref($in) =~ /GLOB|IO::File/ ) {
        my $md5 = Digest::MD5->new;
        $md5->addfile( $in );
        return $md5->hexdigest;
    } else {
        my $str = @_ ? join( '#',@_ ) : _now . rand() . $$ ;
        return Digest::MD5::md5_hex( $str );
    }
}

sub _html_escape {
    my $data = shift;
    $data =~ s/\&/&amp;/gs;
    $data =~ s/</&lt;/gs;
    $data =~ s/>/&gt;/gs;

    $data
}

sub _fixascii_sql {
    my $data = shift;
    #convert ASCII characters form SQL
    $data =~ s/\\xE1/á/g;
    $data =~ s/\\xE9/é/g;
    $data =~ s/\\xED/í/g;
    $data =~ s/\\xF3/ó/g;
    $data =~ s/\\xFA/ú/g;
    $data =~ s/\\Ã/í/g;
    $data =~ s/\\Ã³/ó/g;

    $data
}


sub _fix_utf8_to_xml_entities {
    my $data = shift;
    $data =~ s/á/&#225;/g;
    $data =~ s/Á/&#193;/g;
    $data =~ s/é/&#233;/g;
    $data =~ s/É/&#201;/g;
    $data =~ s/í/&#237;/g;
    $data =~ s/Í/&#205;/g;
    $data =~ s/ó/&#243;/g;
    $data =~ s/Ó/&#211;/g;
    $data =~ s/ú/&#250;/g;
    $data =~ s/Ú/&#218;/g;
    $data =~ s/ñ/&#241;/g;
    $data =~ s/Ñ/&#209;/g;
    $data;
}


sub _fixCharacters_mail {
    my $d = shift;
    return $d unless length $d;
    require HTML::Strip;
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($d);
    utf8::decode( $clean_text );
    #Ñ
    $clean_text =~ s{Ã\?}{&Ntilde;}g;
    $clean_text =~ s{Ã±}{&ntilde;}g;
    #minus
    $clean_text =~ s{Ã¡}{&aacute;}g;
    $clean_text =~ s{Ã©}{&eacute;}g;
    $clean_text =~ s{Ã³}{&oacute;}g;
    $clean_text =~ s{Ãº}{&uacute;}g;
    $clean_text =~ s{Ã­}{&iacute;}g;
    #answer
    $clean_text =~ s{Â¿}{&iquest;}g;
    $clean_text =~ s{Â¡}{&iexcl;}g;
    $clean_text =~ s{Â°}{&deg;}g;
    #minus
    # $clean_text =~ s{ÃÁ}{&Eacute;}g;
    $clean_text;
}

sub _join_quoted {
    return '' unless @_;
    return '"' . join( '" "', @_ ) . '"';
}


sub _utf8_on_all {
    return map { Encode::_utf8_on( $_ ) if utf8::valid( $_); $_ } @_;
}

# decode sequences of octets in utf8 into Perl's internal form,
# which is utf-8 with utf8 flag set if needed.  
sub _to_utf8 {
    my $str = shift;
    return undef unless defined $str;
    my $fallback_encoding = 'latin1';
    if ( utf8::valid($str) ) {
        utf8::decode($str);
        return $str;
    } else {
        return Encode::decode( $fallback_encoding, $str, Encode::FB_DEFAULT );
    }
}


sub _size_unit {
    my $size = shift;
    use constant MB => (1024*1024);
    use constant GB => (1024* MB);
    my $units = $size >= GB ? 'GB' : $size >= MB ? 'MB' :  $size > 1024 ? 'KB' : 'bytes';
    my $divisor = { GB=>(1024*1024*1024), MB=>(1024*1024), KB=>1024, bytes=>1 }->{ $units };
    my $size = $size / $divisor;
    $size = ($units =~ /bytes|KB/i) ? int( $size) : sprintf( "%.02f", $size );
    return ( $size, $units );
}

sub _dbis {
    my( $dbh ) = @_;
    $dbh ||= Clarive->config->{rdbms}{connect_info} // Clarive->config->{baseliner}{'Model::Baseliner'}{connect_info};
    _fail( 'Missing RDBMS database configuration' ) unless length $dbh;
    $ENV{NLS_LANG} = 'AMERICAN_AMERICA.AL32UTF8';  # needed when called from a Clarive Cmd
    require DBIx::Simple;
    my $conn = DBIx::Simple->connect( ref $dbh eq 'ARRAY' ? @$dbh : $dbh );
    $conn->dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
    return $conn;
}

=head2 _hook

Hook around Moose methods. Supports around, before and after.

    _hook around => 'BaselinerX::Job::Controller::Job' => job_submit_cancel => sub {
        ...
    };

=cut
sub _hook {
    my $type = shift;
    my $class_name = shift;
    my $code = pop @_;
    my $meth = "add_${type}_method_modifier";
    eval qq{require $class_name};
    if( $@ ) {
        _throw $@;
    } else {
        $class_name->meta->$meth( $_, $code ) for @_;
    }
}

sub _read_password {
    my $prompt = shift || 'PASSWORD: ';
    require Term::ReadKey;
    print $prompt;
    Term::ReadKey::ReadMode('noecho');
    my $pass = Term::ReadKey::ReadLine(0);
    Term::ReadKey::ReadMode(0); # reset
    chomp $pass;
    say '';
    $pass;
}

sub _ci {
    local $Baseliner::CI::_no_record = 0;
    return Baseliner::CI->new( @_ );
}

sub to_base_class {
    my($cn)=@_;
    $cn = ref $cn if ref $cn;
    if( $cn =~ /^.+::(.+?)$/ ) {
        return $1;
    } else {
        return $cn;
    }
}

sub to_role_class {
    my($cn)=@_;
    return $cn if $cn =~ /::/;
    return 'Baseliner::Role::CI::'.$cn;
}

sub to_ci_class {
    my($cn)=@_;
    return $cn if $cn =~ /::/;
    return 'BaselinerX::CI::'.$cn;
}

sub is_ci_or_fail {
    my ($obj,$name)=@_;
    my $msg = _loc('Invalid or missing CI: %1', $name);
    _fail($msg) unless _blessed($obj) && $obj->does('Baseliner::Role::CI'); 
    return 1;
}

sub _strip_last {
    my ($pattern, $str)=@_;
    my ($ret) = reverse ( split /$pattern/, $str );
    return $ret;
}

*_any = \&List::MoreUtils::any;

sub _ixhash {
    require Tie::IxHash;
    my @arr = ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_;
    Tie::IxHash->new( @arr );
}

sub _package_is_loaded {
    my $cl = shift;
    $cl =~ s/::/\//g;
    $cl = $cl . '.pm';
    exists $INC{ $cl };
}

sub _reload_file {
    my ($file) = @_;
    $file = Baseliner->path_to($file) if !-e "$file";
    local $SIG{__WARN__} = sub{};
    do "$file";
    if( $@ ) {
        _fail( _loc('Error while reloading %1: %2', $file, $@ ) );
    }
}

sub _reload_dir {
    my ($dir, $pattern) = @_;
    my $d = _dir( Baseliner->path_to( $dir ) );
    _fail( _loc('%1 is not a dir', $d) ) unless $d->is_dir && -e $d;
    my $re = $pattern ? qr/$pattern/i : qr/\.pl|\.pm$/i;
    my @reloaded;
    $d->recurse( callback=>sub{
        my $f = shift;
        return if $f->is_dir || $f !~ $re;
        _reload_file( $f );
        push @reloaded, "$f";
        do "$f";
        if( $@ ) {
            _fail( _loc('Error while reloading %1: %2', $f, $@ ) );
        }
    });
    return @reloaded; 
}

sub _load_yaml_from_comment {
    my ($y,$rest) = $_[0] =~ m{^(?:<!--+|/\*)(.*?)(?:---|-->+|\*/)}gs;
    return $y;
}

our $__day = 3600 * 24;
our $__week = 3600 * 24 * 7;
our $__month = 3600 * 24 * 4.33;
our $__year = 2_629_744*12;

sub ago {
    my ($date, $now) = @_;
    $now //= Class::Date->now();
    # if( ref $date eq 'DateTime' ) {
    #     $date = Class::Date->new( $date->epoch );
    # } elsif( ref $date ne 'Class::Date' ) {
    #     $date = Class::Date->new( $date );
    # }
    $date = Class::Date->new( $date );
    my $d = $now - $date;
    my $v = 
        $d <= -$__day ? _loc('in %1 days', - int $d/$__day )
      : $d <= -$__day && $d > 2*-$__day ? _loc('in 1 day' )
      : $d < 0 ? _loc('today')
      : $d >= 0 && $d <= 1 ? _loc('just now')
      : $d < 60 ? _loc('%1 seconds ago', int $d )
      : $d < 120 ? _loc('1 minute ago' )
      : $d < 3600 ? _loc('%1 minutes ago', int $d->minute )
      : $d < 7200 ? _loc('1 hour ago' )
      : $date > $now-'1D' ? _loc('%1 hours ago', int $d->hour )
      : $date > $now-'2D' ? _loc('1 day ago')
      : $date > $now-'7D' ? _loc('%1 days ago', int $d->day )
      : $date > $now-'14D' ? _loc('1 week ago' )
      : $date > $now-'1M' ? _loc('%1 weeks ago', sprintf '%.01d', $d/$__week )
      : $date > $now-'2M' ? _loc('1 month ago' )
      : $date > $now-'1Y' ? _loc('%1 months ago', int $d->month )
      : $date > $now-'2Y' ? _loc('1 year ago')
      : _loc('%1 years ago', int $d/$__year )
    ;
    $v;
}

=head2

Make an async request to myself.

    async_request( '/service/test.run', { key1=>value... } );
    async_request( '/service/test.run', json => { key1=>value... } );
    async_request( '/service/test.run', yaml => { key1=>value... } );

=cut
sub async_request {
    my ( @req ) = @_;
    #require HTTP::Async;
    # object needs to be alive, although no responses are needed
    #  XXX consider checking the object on later requests, if there is data, include on json for retrieve by ajaxEval()
    #my $as = $Baseliner::_http_as // ( $Baseliner::_http_as = HTTP::Async->new );
    #my $req = HTTP::Request->new( @req );
    #$as->add( $req ); #GET => 'http://localhost:3000/sleepme' ) );

    require Net::HTTP::NB;
    my $request = ref $_[0] eq 'HTTP::Request' ? $_[0] : do {
        if( $_[1] eq 'json' ) {
            my $r = HTTP::Request->new( POST=>$_[0]);
            $r->header( 'Content-Type' => 'application/json' );
            $r->content( _to_json( $_[2] ) );
            $r;
        } 
        elsif( $_[1] eq 'yaml' ) {
            my $r = HTTP::Request->new( POST=>$_[0] );
            $r->header( 'Content-Type' => 'application/yaml' );
            $r->content( _dump( $_[2] ) );
            $r;
        }
        else {
            require HTTP::Request::Common;
            HTTP::Request::Common::POST( @req );
        }
    };
    # make sure the offline request is with this same user
    my $cookie = Baseliner->app->req->headers->{cookie};
    $request->header( 'cookie' => $cookie );  
    my $uri = $request->uri;
    my $cf = Baseliner->config;
    my $host = $cf->{web_queue} // $ENV{BALI_WEB_QUEUE};
    $host //= $cf->{web_host} && $cf->{web_port} 
        ? sprintf('%s:%s', $cf->{web_host}, $cf->{web_port} ) 
        : _throw(_loc("async_request: missing or invalid queue configuration: either configure web_queue to 'host:port', or web_host and web_port"));
        
    my $s = Net::HTTP::NB->new( Host=>$host ) or _throw $!;
    my %headers = map { $_ => $request->header( $_ ) } $request->{_headers}->header_field_names;
    # create run token, put it in headers, put it in session
    my $run_token = 'run_token='. _md5( int(rand($$)) . int(rand(9999999)) . _nowstamp . $$ );
    $headers{'run-token'} = $run_token;
    Baseliner->app->session->{$run_token} = 1;
    $s->write_request( $request->method, "$uri", %headers, $request->content );
}

=head2 _get_dotted_keys

Identify keys with '.' in a structure recursively

Use:
    _get_dotted_keys( $struct, '$struct' );

Returns ARRAY:

    - key: Eliminar .gitkeep
      parent: $stash->{job}->{service_levels}->{PRE}
    - key: Entorno_ultima_actuacion.X
      parent: $stash

In your code after that you can remove those keys

    my @keys = _get_dotted_keys( $stash, '$stash');

    for my $key ( @keys ) {
        my $parent = eval($key->{parent});
        delete $parent->{$key->{key}};
    }

=cut

sub _get_dotted_keys {
    my $var = shift;
    my $parent = shift;
    my @keys;

    for my $key ( keys %$var ) {
        if ( $key && $key =~ /\./ ) {  
            push @keys, { parent => $parent, key => $key};
        };
        my $ref = ref $var->{$key};
        if ( $ref && ($ref eq 'HASH' || $ref eq 'HASHREF' || $ref =~ /Baseliner/) ) {
            my @new_keys = _get_dotted_keys( $var->{$key}, $parent."->{".$key."}" );
            push @keys, @new_keys if @new_keys;
        }
    }

    return @keys;
}

=head2 package_and_instance

Little finder of packages not loaded. Lists and loads them temporarily from root
and features. 
    
Just a list of files and package names (deduced from filename):

    package_and_instance( 'lib/Baseliner/Parser/Grammar' ) 

A instance + method call, with params, if any 

    package_and_instance( 'lib/Baseliner/Parser/Grammar','grammar', [ param1=>val1 ... ], [  meth param1... ] ) 

If method name is "new", only the instance created with C<new> is returned. 

Returns HASHREF:

    $file => { package=>Package::Name, file=>$file, instance=>$self, ret=>$return_value_from_method }

TODO 

    - recursivity

=cut
sub package_and_instance {
    my ($path,$method, $new_params, $method_params) = @_;
    local %INC = %INC; 
    my $root = Baseliner->path_to('/')->stringify;
    +{ map {
        my $f = $_;
        s{^.*lib/}{}g;
        s{/}{::}g;
        s{\.pm$}{}g;
        if( $method ) {
            do $f;
            my $ins = $_->new( Util->_array( $new_params) );
            my $ret = $_->new->$method( Util->_array( $method_params) ) unless $method eq 'new';
            $f => { package => $_, file => $f, instance=>$ins, ret=>$ret };
        } else {
            $f => { package => $_, file => $f };
        }
    } <$root/$path/* $root/features/*/lib/$path/*> }
}

=head2 tar_dir 

Tar a directory

    source_dir => directory to tar
    tarfile    => full path to tar file
    files      => [] 
    include    => []
    exclude    => []
    attributes => [
        { regex=>'.*', type=>'f|d', mode=>'octal', mtime=>'epoch', uname=>'owner', gname=>'group' }
    ]

=cut
sub tar_dir {
    my (%p) =@_;
    my $source_dir = $p{source_dir} // _fail _loc 'Missing parameter source_dir'; 
    my $tarfile = $p{tarfile} // _fail _loc 'Missing parameter tarfile';
    my $verbose = $p{verbose};
    my %files = map { $_ => 1 } _array $p{files};
    my @include = _array $p{include};
    my @exclude = _array $p{exclude};
    my %attributes = map { $_->{regex} => $_ } _array( $p{attributes} );
    # open and close to reset file and attempt write
    open my $ff, '>', $tarfile 
       or _fail _loc 'Could not create tar file `%1`: %2', $tarfile, $!;
    close $ff;
    
    require Archive::Tar; 
    
    _fail _loc 'Could not find dir `%1` to tar', $source_dir 
        unless -e $source_dir;
    
    # build local tar
    my $tar = Archive::Tar->new or _throw $!;
    my $dir = Util->_dir( $source_dir );
    $dir->recurse( callback=>sub{
        my $f = shift;
        return if _file($tarfile) eq $f;
        my $rel = $f->relative( $dir );
        return if %files && !exists $files{$rel}; # check if file is in list
        my $stat = $f->stat;
        my $type = $f->is_dir ? 'd' : 'f';
        my %attr = $type eq 'f' 
            ? ( mtime=>$stat->mtime, mode=>$stat->mode )
            : ( mtime => $stat->mtime, mode=>$stat->mode );
        # look for attributes
        while( my($re,$re_attr) = each %attributes ){
            if( "$f" =~ $re && $type =~ $type && ref $re_attr eq 'HASH' ) {
                say "tar_dir: found attributes for file `$f`" if $verbose;
                %attr = ( %attr, %$re_attr ); 
                $attr{mode} = oct( $attr{mode} ) if length $re_attr->{mode};
            }
        }
        
        for my $in ( @include ) {
            return if "$f" !~ $in;
        }
        for my $ex ( @exclude ) {
            return if "$f" =~ $ex;
        }
        
        if( $f->is_dir ) {
            # directory with empty data
            say "tar_dir: add dir: `$f`: " . _to_json(\%attr) if $verbose;
            my $tf = Archive::Tar::File->new(
                data => "$rel", '', { # type 5=DIR, type 0=FILE
                    type  => 5, %attr
                });
            $tar->add_files($tf);
        } else {
            # file
            say "tar_dir: add file `$f`: " . _to_json(\%attr) if $verbose;
            my $tf = Archive::Tar::File->new( 
                data=>"$rel", scalar($f->slurp), 
                { type=>0, %attr }
            );
            $tar->add_files( $tf );
        }
    });
    say "tar_dir: writing tar file `$tarfile`" if $verbose;
    $tar->write( $tarfile );
    return 1;
}

=head2 zip_dir 

Zip a directory

    source_dir => directory to zip
    zipfile    => full path to zip file
    files      => [] 
    include    => []
    exclude    => []

=cut
sub zip_dir {
    my ($self, %p) =@_;
    my $source_dir = $p{source_dir} // _fail _loc 'Missing parameter source_dir'; 
    my $zipfile = $p{zipfile} // _fail _loc 'Missing parameter tarfile';
    my $verbose = $p{verbose};
    my %files = map { $_ => 1 } _array $p{files};
    my @include = _array $p{include};
    my @exclude = _array $p{exclude};

    # open and close to reset file and attempt write
    open my $ff, '>', $zipfile 
       or _fail _loc 'Could not create zip file `%1`: %2', $zipfile, $!;
    close $ff;
    
    
    _fail _loc 'Could not find dir `%1` to zip', $source_dir 
        unless -e $source_dir;
    
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS ); 
    # build local tar
    my $zip = Archive::Zip->new or _throw $!;
    my $dir = Util->_dir( $source_dir );
    $dir->recurse( callback=>sub{
        my $f = shift;
        return if _file($zipfile) eq $f;
        my $rel = $f->relative( $dir );
        return if %files && !exists $files{$rel}; # check if file is in list
        my $stat = $f->stat;
        my $type = $f->is_dir ? 'd' : 'f';
        for my $in ( @include ) {
            return if "$f" !~ $in;
        }
        for my $ex ( @exclude ) {
            return if "$f" =~ $ex;
        }
        
        if( $f->is_dir ) {
            # directory with empty data
            my $dir_member = $zip->addDirectory( ''.$rel );
        } else {
            # file
            $zip->addFile( ''.$f, ''.$rel, COMPRESSION_LEVEL_BEST_COMPRESSION  );
            
        }
    });
    say "zip_dir: writing zip file `$zipfile`" if $verbose;
    unless ( $zip->writeToFileNamed( $zipfile ) == AZ_OK ) {
        _fail 'Error writing file '.$zipfile;
    }
    return 1;
}

=head2 foreach_block

Calls a code block for each group
of N elements from an array:

    my @xx = map { "N$_" } 1..34;
    Util->foreach_block( 10, sub {
        # will be called 4 times
        my $ix = shift;
        _log \@_;   
    }, @xx );

Useful for limiting a call to a function to N 
elements in an array (ie DBIC IN clauses).

=cut
sub foreach_block {
    my ($blk,$code,@arr) = @_;
    
    require POSIX;
    my $top = POSIX::ceil(@arr/$blk-1);
    for( 0..$top ) {
       my $i = $blk * $_;
       my $j = $i+$blk-1;
       $code->($_, @arr[ $i..($j>@arr ? $#arr : $j) ] );
    }
}

=head2 in_range

Checks if number is withing a range string,
typically used by return code matches
in the run_remote/local task.

    Util->in_range( 7, '1,2,3,10-');  # returns false
    Util->in_range( 11, '1,2,3,10-'); # returns true
    Util->in_range( 999999, '1,2,3,10-'); # returns true
    Util->in_range( 0, '1,2,3,10-'); # returns false
    Util->in_range( 0, '0-');        # returns true

=cut
sub in_range {
   my ($v,$range) = @_;
   return 0 if !length $v || !length $range;
   #$range =~ s/-+/../g;
   #my @rg = map { $_ =~ s/-+./../g ? eval $_ : $_ } grep { length } split /,+/, $range;
   my @rg = grep { length } split /,+/, $range;
   List::MoreUtils::any { 
   		/^(.+)-+$/ ? $v >= $1 :
   		/^-+(.+)$/ ? $v <= $1 :
   		/^(.+)-+(.+)$/ ? ($v >= $1 && $v <= $2) : 
        $v == $_ 
   } @rg;
}

sub compress {
    require Compress::Zlib;
    Compress::Zlib::compress( @_ );
}

sub uncompress {
    require Compress::Zlib;
    Compress::Zlib::uncompress( @_ );
}

{
    package Util;
    our $AUTOLOAD;
    sub AUTOLOAD {
        shift if $_[0] eq 'Util';# allows for Util::method
        my $name = $AUTOLOAD;
        my @a = reverse(split(/::/, $name));
        my $method = 'Baseliner::Utils::' . $a[0];
        goto &$method;
    }
}

sub properties {
    my ($body) = @_;
    my %ret;
    my $re = qr/^
                  \s*
                  ((?:[^\s:=\\]|\\.)+)
                  \s*
                  [:=\s]
                  \s*
                  (.*)
                  $
                  /x;  # SALVA's, see Config::Properties
    my $cnt=0;
    for my $lin ( split/\r*\n/, $body ) {
        $cnt++;
        next if $lin =~ /^\s*#/;
        if( my ($k,$v) = $lin =~ $re ) {
            $ret{ $k } = $v;
        } else { _warn "Incorrect property (line=$cnt): $lin" }
    }
    %ret;
}

sub split_with_quotes {
    my ($str, %p)=@_;
    my @arr = $str =~ /(".+"|\S+)/g;
    @arr = map { s/^"//g; s/"$//g; $_ } @arr if $p{unquote};
    return @arr;
}

sub to_dur {
    my $secs = shift;
    my $rel = ref $secs eq 'Class::Date::Rel' ? $secs : new Class::Date::Rel int($secs).'s';
    my ($y,$M,$d,$h,$m,$s) = map{ int } ($rel->year,$rel->month,$rel->day,$rel->hour,$rel->minute,$rel->second);
    my $M2=$M-($y*12);
    my $d2=int($d-($M*30.436851851851844));
    my $h2=$h-($d*24);
    my $m2=$m-($h*60);
    my $s2=$s-($m*60);
    # localze the time letters (english: y d h m s, french: a j h m s, spanish: a d h m s, ...)
    my @letters = map { '%d'.substr(_loc($_),0,1) } qw(Year Month Day hour minute second);
    my $tot = 
          $y ? sprintf(join(' ',@letters),$y,$M2,$d2,$h2,$m2,$s2)
        : $M ? sprintf(join(' ',@letters[-5..-1]),$M2,$d2,$h2,$m2,$s2)
        : $d ? sprintf(join(' ',@letters[-4..-1]),$d2,$h2,$m2,$s2)
        : $h ? sprintf(join(' ',@letters[-3..-1]),$h2,$m2,$s2)
        : $m ? sprintf(join(' ',@letters[-2..-1]),$m2,$s2)
        : sprintf('%ds',$secs);
    return $tot;
}


sub average {
    my @data = @_;
    if ( not @data ) {
        _fail("Empty array");
    }
    my $total = 0;
    foreach (@data) {
        $total += $_;
    }
    my $average = $total / @data;
    return $average;
}

sub stdev {
    my @data = @_;
    if ( @data == 1 ) {
        return 0;
    }
    my $average = average(@data);
    my $sqtotal = 0;
    foreach (@data) {
        $sqtotal += ( $average - $_ )**2;
    }
    my $std = ( $sqtotal / ( @data - 1 ) )**0.5;
    return $std;
}

sub stat_mode {
    my $mode = 0;
    my $occurances = 0;

    my %count;

    foreach my $item (@_) {
        my $count = ++$count{$item};
        if ($count > $occurances)
        {
            $mode = $item;
            $occurances = $count;
        }
    }
 
    return $mode; 
}

sub hide_passwords {
    my ($string) = @_;

    my @patterns = split "\n", Baseliner->model('ConfigStore')->get('config.global')->{password_patterns};
    for my $line ( @patterns ) {
        my ($pattern,$replace) = split /\|\|/,$line;
        my $regex = eval { qr[$pattern] };
        if (!$@ ) {
            eval('$string'." =~ s[$pattern][$replace]gm");
        } else {
            _debug(_loc("Incorrect regexp in config.global.password_patterns: $pattern"));
        }
    }
    return $string;
}


1;

__END__

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

