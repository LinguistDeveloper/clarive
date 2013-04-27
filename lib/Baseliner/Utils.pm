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
    _loc_raw
    _cut
    _log
    _debug
    _error
    _utf8
    _tz
    slashFwd
    slashBack
    slashSingle
    _loc_ansi
    _utf8_to_ansi
    _guess_utf8
    _loc_unaccented
    _loc_decoded
    _unique
    _throw
    _say
    _dt
    _now
    _now_ora
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
    _mkpath
    _rmpath
    _mktmp
    _tmp_dir
    _tmp_file
    _damn
    _parameters
    _notify_address
    _replace_tags
    _strip_html
    is_oracle
    is_number
    _dump
    _load
    _trim
    _array
    ns_match
    ns_split
    domain_match
    to_pages
    to_base64
    from_base64
    rs_hashref
    packages_that_do
    query_array
    _db_setup
    query_sql_build
    _file
    _dir
    _slurp
    _fail
    _mason
    _textile
    _pathxs
    _uacc
    _markup
    _markdown
    zip_files
    hash_flatten
    parse_vars
    _to_json
    _from_json
    _repl
    _md5
    _html_escape
    _join_quoted
    case
    _utf8_on_all
    _to_utf8
    _size_unit
    _dbis
    _hook
    _read_password
    _load_features
    _ci
    _any
    _package_is_loaded
)],
other => [qw(
    _load_yaml_from_comment
)];

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

#use Carp::Clan qw(^Baseliner:: ^BaselinerX::);
use utf8;
use v5.10;
use Carp::Tidy -clan=>['Baseliner']; #,'Catalyst'];
use DateTime;
use Class::Date;
use YAML::XS;
use List::MoreUtils qw(:all);
use Try::Tiny;
use MIME::Lite;
use Class::MOP;
use Sys::Hostname;
use PadWalker qw(peek_my peek_our peek_sub closed_over);
use Text::Unaccent::PurePerl qw/unac_string/;
use Path::Class;
use Term::ANSIColor;
use strict;

BEGIN {
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

# check if the first ns string contains the second
sub ns_match {
    my ( $ns, $search ) = @_;

    my ( $domain, $item ) = ns_split( $ns );
    my ( $search_domain, $search_item ) = ns_split( $search );
    return 1 if domain_match( $domain , $search_domain ) && !$search_item;
    return 1 if domain_match( $domain , $search_domain ) && $item eq $search_item;
    return 1 if !$search_domain && $item eq $search_item;
}

# check if search is part of domain
sub domain_match {
    my ( $domain, $search ) = @_;
    return 1 if $domain eq $search;
    return $domain =~ m{\.\Q$search\E$}; 
}

## base standard utilities subs
sub slashFwd {
    (my $path = $_[0]) =~ s{\\}{/}g ;
    return $path;
}

sub slashBack {
    (my $path = $_[0]) =~ s{/}{\\}g ;
    return $path;
}

sub slashSingle {
    (my $path = $_[0]) =~ s{//}{/}g ;
    $path =~ s{\\\\}{\\}g ;
    return $path;
}

sub _unique {
    return () unless @_ > 0;
    keys %{{ map {$_=>1} grep { defined } @_ }};
}

sub _load {
    my @args = @_;
    return try {
        utf8::encode( $args[0] ) if utf8::valid( $args[0] );  # TODO consider using _to_utf8 - a decode may be needed before
        YAML::XS::Load( @args )
    } catch { 
        my $err = shift;
        _error( "_load error: " . $err );
        _fail( $err ) if $Baseliner::Utils::YAML_LOAD_FAIL; 
        require YAML::Syck;
        YAML::Syck::Load( @args );
    };
}

sub _dump {
    my @args = @_;
    return try { 
        YAML::XS::Dump( @args );
    } catch { 
        _error( "_dump error: " . shift() );
        require YAML::Syck;
        YAML::Syck::Dump( @args );
    };
}

use Encode qw( decode_utf8 encode_utf8 is_utf8 );
use Encode::Guess qw/utf8/;
sub _loc {
    return unless $_[0];
    #return loc( @_ );
    my @args = @_;
    my $context={};
    for my $level (2..3) {## try to get $c with PadWalker
        $context = try { peek_my($level); } catch { last }; 
        last if ref $context->{'$c'};
        #last if( $context->{'$c'} && ref ${ $context->{'$c'} } );
    }
    if( ref $context->{'$c'} ) {
        my $c = ${ $context->{'$c'} };
        return try {
            return _loc_decoded(@args) if $ENV{BALI_CMD};
            return _loc_decoded(@args) unless defined $c->request;
            if( ref $c->session->{user} ) {
                $c->languages( $c->session->{user}->languages );
            }
            $c->localize( @args );
        } catch {
            _loc_decoded(@args);
        };
    } else {
        return loc( @args );
    }
}

sub _loc_raw { return loc( @_ ) }
sub _loc_decoded { return _utf8( _loc(@_) ) }
sub _loc_ansi { return _utf8_to_ansi( _loc(@_) ) }
sub _loc_unaccented { unac_string( _loc_ansi(@_) ) }

sub _utf8 {
    my $msg = shift;
    is_utf8($msg) ? $msg : decode_utf8($msg);
}

sub _unac { my $s = "$_[0]"; $s = unac_string( $s ); return $s }

sub _guess_utf8 { ref guess_encoding( $_[0] ) }

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
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller($lev);
    $cl =~ s{^Baseliner}{B};
    my $pid = sprintf('%s', $$);
    print STDERR ( _now()."[$pid] [$cl:$li] ", @_, "\n" );
}

sub isatty { no autodie; return open(my $tty, '+<', '/dev/tty'); }

# internal log engine used by _log and _debug
sub _log_me {
    my ($lev, $cl,$fi,$li, @msgs ) = @_;
    my $logger = Baseliner->app ? Baseliner->app->{_logger} : '';
    if( ref $logger eq 'CODE' ) { # logger override
        $logger->($cl,$fi,$li, @msgs );
    } else {
        my $first = shift @msgs;
        if( my $rf = ref $first ) {
            $first = sprintf '[DUMP ref=%s]%s', $rf , "\n" . _dump( $first );
        }
        $cl =~ s{^Baseliner}{B};
        my $pid = sprintf('%s', $$);
        my $msg = join '', _now_log(), "[$pid] [$cl:$li] ", $first, @msgs ;
        #if( !$ENV{BALI_CMD} && ( my $cat_log = Baseliner->log ) ) {
            #$cat_log->$lev( $msg );
        if( $^O ne 'Win32' && -t STDOUT ) { 
            if( $lev eq 'error' ) {
                print STDERR color('red') , $msg , color('reset'), "\n"; 
            } elsif( $lev eq 'debug' ) {
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
    my ($cl,$fi,$li) = caller(0);
    _log_me( 'info', $cl, $fi, $li, @_ );
}

sub _error {
    return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller(0);
    _log_me( 'error', $cl, $fi, $li, @_ );
}

#TODO check that global DEBUG flag is active
sub _debug {
    my ($cl,$fi,$li) = caller(0);
    return unless Baseliner->debug;
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


use JSON::XS;
sub _decode_json {
    my $data = shift;
    $data = encode_utf8($data) if is_utf8($data);
    return decode_json($data); 
}

sub _encode_json {
    my $data = shift;
    #$data = encode_utf8($data) if is_utf8($data);
    return decode_utf8( encode_json($data) ); 
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
    Carp::longmess @_;
}

sub _say {
    print @_,"\n" if( $Baseliner::DEBUG );
} 

sub _tz {
    my $tz = try { Baseliner->config->{time_zone} } catch {''};
    $tz || 'CET';
}

sub _dt { DateTime->now(time_zone=>_tz);  }

# same as _now, but with hi res in debug mode
sub _now_log {
    if( Baseliner->debug ) {
        my @t=split /\./, Time::HiRes::time(); 
        return sprintf "%s.%03d", Class::Date::date( $t[0]), substr $t[1], 0, 3;
    } else {
        return _now();
    }
}

sub _now {
    my $now = DateTime->now(time_zone=>_tz);
    $now=~s{T}{ }g;
    return $now;
}

sub _nowstamp {
    (my $t = _now )=~ s{-|\:|\/|\\|\s}{}g;
    return $t;
}

sub _now_ora {
    return DateTime->now(time_zone=>_tz);
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
    use DateTime::Format::Strptime;
    my $parser = DateTime::Format::Strptime->new( pattern => $format, on_error=>'croak', time_zone=>_tz() );
    return $parser->parse_datetime( $date );
}

# return an array with hashes of data from a resultset
sub rs_data {
    my $rs = shift;
    my @data;
    while( my $row = $rs->next ) {
        push @data, { $row->get_columns };
    }
    return @data;
}

sub query_array {
    my $query = shift;
    {
        no warnings;  # may be empty strings, unitialized
        my $txt = join ',', @_;    ##TODO check for "and", "or", etc. with text::query
        return $txt =~ m/$query/i;
    }
}

# setup some data standards at a lower level
sub _db_setup {
    my $dbh = Baseliner->model('Baseliner')->storage->dbh;
    return unless $dbh;
    if( $dbh->{Driver}->{Name} eq 'Oracle' ) {
        $dbh->do("alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'");
        $dbh->{LongReadLen} =  Baseliner->config->{LongReadLen} || 100000000; #64 * 1024;
        $dbh->{LongTruncOk} = Baseliner->config->{LongTruncOk}; # do not accept truncated LOBs
    }
}

sub packages_that_do {
    my @roles = @_;
    my @packages;
    my %cl=Class::MOP::get_all_metaclasses;
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
sub _array {
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

sub is_oracle {
    return Baseliner->model('Baseliner')->storage->dbh->{Driver}->{Name} =~ m/oracle/i;
}

sub is_number {
    return $_[0] =~ /^(?=[-+.]*\d)[-+]?\d*\.?\d*(?:e[-+ ]?\d+)?$/i;
}

sub _trim {
    my $str = shift;
    $str =~ s{^\s*}{}g;
    $str =~ s{\s*$}{}g;
    return $str;
}

sub _parse_template {
    my ( $template, %vars ) = @_;
    my $type = $vars{text_template_type} || 'FILE'; # could use STRING
    use Text::Template;
    my $tt = Text::Template->new( 
                    TYPE => "FILE",
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
    use HTML::Mason::Interp;
    my $comp_root = "". Baseliner->config->{root};
    my $data_dir = File::Spec->catdir(
        File::Spec->tmpdir, sprintf('Baseliner_%d_mason_data_dir', $<));
    my $m = HTML::Mason::Interp->new(
        comp_root  => $comp_root,
        data_dir   => $data_dir,
        out_method => \$body,
    );
    $m->exec( "/$template", %vars );
    return $body;
}

sub _notify_address {
    my $host = Baseliner->config->{web_host} || Baseliner->config->{host} || lc(Sys::Hostname::hostname);
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
    require HTML::Strip;
    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($d);
    $clean_text;
}

sub _check_parameters {
    my $p = shift;
    for my $param ( @_ ) {
        exists($p->{$param}) or _throw _loc('Missing parameter %1', $param);
    }
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
    return $name;
}

# returns the official tmp dir
sub _tmp_dir {
    my $tmp_dir = try { Baseliner->config->{tempdir} } catch {};
    $tmp_dir || $ENV{BASELINER_TEMP} || File::Spec->tmpdir || $ENV{TEMP};
}

=head2 _mktmp( suffix=>$str )

Creates a random tempdir inside the official temp dir.

=cut
sub _mktmp {
   my %p = @_;
   my $suffix = [ _array($p{suffix}) ] || [];
   return _dir( _tmp_dir(), join( '_', _nowstamp, $$, int( rand( 100000 ) ), @$suffix ) );
}

=head2 _tmp_file( prefix=>'myprefix', extension=>'zip' )

Returns a temp file name, creating the temp directory if needed. 

=cut
sub _tmp_file {
    my $p = _parameters(@_);
    $p->{prefix} ||= [ caller(0) ]->[2];  # get the subname
    $p->{prefix} =~ s/\W/_/g;
    my $tempdir = $p->{tempdir} || _tmp_dir();
    $p->{dir}||='';
    $p->{extension} ||='log';
    my $dir  = File::Spec->catdir($tempdir, $p->{dir} );
    unless( -d $tempdir ) {
    warn "Creating temp dir $tempdir";
    _mkpath( $tempdir );
    }
    my $file = File::Spec->catfile($dir, $p->{prefix} . "_" . _nowstamp() . "_$$." . $p->{extension} );
    ( $ENV{BASELINER_DEBUG} || $ENV{CATALYST_DEBUG} ) and warn "Created tempfile $file\n";
    return $file;
}

sub _damn {
    my $blessed = shift;
    my $damned;
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
        elsif( ref $blessed ) {
            $damned = _damn( { %$blessed } );
        }
        else {
            $damned = $blessed;
        }
    } catch {
        my $err = shift;
        $damned = $blessed;
        _error( 'DAMN1=' . $err );
    };
    return $damned;
}

sub to_pages {
    my %p = @_;
    return 1 unless $p{start} && $p{limit};
    return int( $p{start} / $p{limit} ) + 1;
}

sub to_base64 {
    return MIME::Lite::encode_base64( shift );
}

sub from_base64 {
    return  MIME::Base64::decode_base64( shift() );
}

sub rs_hashref {
    my $rs = shift;
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
}

=head2 _fail

Die without line number info.

=cut
sub _fail {
    my ($cl,$fi,$li) = caller();
    _error( "_fail($cl;$li): @_" );
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
        items    =>"bali_job_items.item",
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
    use File::Spec;
    use HTML::Mason::Interp;
    my $comp_root = [ [ root=>"". Baseliner->config->{root} ], @mason_features ];
    my $data_dir = File::Spec->catdir( File::Spec->tmpdir, sprintf('Baseliner_%d_mason_data_dir', $<));
    my $m = HTML::Mason::Interp->new(
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
    my $txt = Text::Markdown::markdown( shift );
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

=head2 _markup

Baseliner flavored markup.

=cut
sub _markup {
    my $txt = shift;
    $txt =~ s{\*\*(.*?)\*\*}{<span><b>$1</b></span>}g;
    $txt =~ s{\*(.*?)\*}{<b>$1</b>}g;
    $txt =~ s{\`(.*?)\`}{<code>$1</code>}g;
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
        $zip->addFile( $file, $filepath );
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
sub hash_flatten {
    my ( $stash, $prefix ) = @_;
    ref $stash eq 'HASH' or _throw "Missing stash hashref parameter";
    $prefix ||= '';
    my %flat;
    while( my ($k,$v) = each %$stash ) {
        my $ref = ref $v;
        if( $ref eq 'HASH') {
            $flat{$prefix . $k} = _dump( $v ); # used to represent complex variables as text
            my %flat_sub = hash_flatten( $v, "$prefix$k." );
            %flat = ( %flat, %flat_sub );
        } elsif( $ref eq 'ARRAY') {
            $flat{$prefix . $k} = join ',', @$v;
        } elsif( $ref ) {
            $flat{$prefix . $k} = _dump( $v ); # used to represent complex variables as text TODO consider JSON or something that shows in oneline
            $v = _damn( $v );
            my %flat_sub = hash_flatten( $v, "$prefix$k." );
            %flat = ( %flat, %flat_sub );
        } else {
            $flat{$prefix . $k} = $v;
        }
    }
    return wantarray ? %flat : \%flat;
}

=head2 parse_vars

Parse vars in a string. Replace them if we can. Return
the replaced string.

Options:

    throw    => die on missing variables
    cleanup  => remove unresolved variables

Default action for unresolved variables is to leave them in.

=cut
sub parse_vars {
    my ( $data, $vars, %args ) = @_;

    # flatten keys
    $vars = hash_flatten( $vars );

    parse_vars_raw( data=>$data, vars=>$vars, throw=>$args{throw} );
}

sub parse_vars_raw {
    my %args = @_;
    my ( $data, $vars, $throw, $cleanup ) = @args{ qw/data vars throw cleanup/ };
    my $ref = ref $data;
    if( $ref eq 'HASH' ) {
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw );
        }
        return \%ret;
    } elsif( $ref =~ /Baseliner/ ) {
        my $class = $ref;
        my %ret;
        for my $k ( keys %$data ) {
            my $v = $data->{$k};
            $ret{$k} = parse_vars_raw( data=>$v, vars=>$vars, throw=>$throw );
        }
        return bless \%ret => $class;
    } elsif( $ref eq 'ARRAY' ) {
        my @tmp;
        for my $i ( @$data ) {
            push @tmp, parse_vars_raw( data=>$i, vars=>$vars, throw=>$throw );
        }
        return \@tmp;
    } elsif($ref) {
        return parse_vars_raw( data=>_damn( $data ), vars=>$vars, throw=>$throw );
    } else {
        # string
        return $data unless $data && $data =~ m/\$\{.+\}/;
        my $str = "$data";
        for my $k ( keys %$vars ) {
            my $v = $vars->{$k};
            $str =~ s/\$\{$k\}/$v/g;
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

sub _md5 {
    require Digest::MD5;
    my $str = @_ ? join '#',@_ : _now . rand() . $$ ;
    Digest::MD5::md5_hex( $str );
}

sub _html_escape {
    my $data = shift;
    $data =~ s/\&/&amp;/gs;
    $data =~ s/</&lt;/gs;
    $data =~ s/>/&gt;/gs;
    $data
}

sub _join_quoted {
    return '' unless @_;
    return '"' . join( '" "', @_ ) . '"';
}


sub case {
    my ($val, %opts) = @_;
    for my $key ( keys %opts ) {
        if( $key ~~ $val ) {
           ref $opts{$key} eq 'CODE' and return $opts{$key}->();
           return $opts{$key};
        }
    }
    return;
}

sub _utf8_on_all {
    #return map { _to_utf8( $_ ) } @_;
    #map { _log "SSSSSSSSSSSSSS=".  utf8::valid( $_) } @_;
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
    require DBIx::Simple;
    return DBIx::Simple->connect( Baseliner->model('Baseliner')->storage->dbh );
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

sub _load_features {
    my $dir = shift;
    my %p = @_;
    my $features = Path::Class::dir('./features');
    my @dirs;
    if( -d $features ) {
        for my $dir ( map { Path::Class::dir( $_, $dir ) } $features->children ) {
            next unless -d $dir;
            push @dirs, $dir;
            # if its lib, we load it
            if( $p{use_lib} ) {
                eval "use lib '$dir'";
                die $@ if $@;
            }
        }
    }
    return @dirs;
}

sub _ci {
    return Baseliner::CI->new( @_ );
}

*_any = \&List::MoreUtils::any;

sub _package_is_loaded {
    my $cl = shift;
    $cl =~ s/::/\//g;
    $cl = $cl . '.pm';
    exists $INC{ $cl };
}

sub _load_yaml_from_comment {
    my ($y) = $_[0] =~ m{(?:--+|/\*)(.*?)(?:--+|\*/)}gs;
    return $y;
}

{
    package Util;
    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $name = $AUTOLOAD;
        my @a = reverse(split(/::/, $name));
        my $method = 'Baseliner::Utils::' . $a[0];
        goto &$method;
    }
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

