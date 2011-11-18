package Baseliner::Utils;

=head1 NAME

Baseliner::Utils 

=head1 DESCRIPTION

Some utilities shared by different Baseliner modules and plugins.

=head1 METHODS

=cut 

use Exporter::Tidy default => [
    qw/_loc _loc_raw _cut _log _debug _utf8 _tz slashFwd slashBack slashSingle
	_loc_ansi _utf8_to_ansi _guess_utf8 _loc_unaccented _loc_decoded
    _unique _throw _say _dt _now _now_ora _nowstamp parse_date parse_dt
	_unac _whereami _throw_stack _parse_template _get_options _decode_json
    _check_parameters _mkpath _mktmp _tmp_dir _tmp_file _damn _parameters
    _notify_address _replace_tags is_oracle is_number _dump _load _trim _array
    ns_match ns_split domain_match to_pages to_base64 rs_hashref
    packages_that_do query_array _db_setup query_sql_build _file _dir _slurp
    _fail _mason _textile _pathxs _uacc unique inc bool
    /
];

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
		for( map { $_->lib } Baseliner->features->list ) {
			my $dir = File::Spec->catfile($_, 'Baseliner', 'I18N');
			next unless -d "$dir";
			$pattern = File::Spec->catfile($dir, '*.[pm]o');
			push @patterns, "Gettext => '$pattern'";
		} 
		$patterns = join',', @patterns;
	};  # may fail when Baseliner is not "use" - ignore then
}

use Locale::Maketext::Simple (
			Style => 'gettext',
			Path => $i18n_path,
			Decode => 1,
		);

#use Carp::Clan qw(^Baseliner:: ^BaselinerX::);
use Carp::Tidy -clan=>['Baseliner']; #,'Catalyst'];
use DateTime;
use YAML::Syck;
use List::MoreUtils qw(:all);
use Try::Tiny;
use MIME::Lite;
use Class::MOP;
use Sys::Hostname;
use PadWalker qw(peek_my peek_our peek_sub closed_over);
use Text::Unaccent::PurePerl qw/unac_string/;
use Path::Class;
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
    return YAML::Syck::Load( @_ );
}

sub _dump {
    return YAML::Syck::Dump( @_ );
}

use Encode qw( decode_utf8 encode_utf8 is_utf8 );
use Encode::Guess qw/utf8/;
sub _loc {
    return unless $_[0];
    #return loc( @_ );
	my @args = @_;
    my $context={};
	for my $level (1..2) {## try to get $c with PadWalker
		$context = try { peek_my($level); } catch { last }; 
		last if( $context->{'$c'} && ref ${ $context->{'$c'} } );
	}
    if( $context->{'$c'} && ref ${ $context->{'$c'} } ) {
		return try {
			my $c = ${ $context->{'$c'} };
			return loc(@args) if $c->commandline_mode;
			return loc(@args) unless defined $c->request;
			if( ref $c->session->{user} ) {
				$c->languages( $c->session->{user}->languages );
			}
			$c->localize( @args );
		} catch {
			loc(@args);
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

sub _log_lev {
	my $lev = shift;
	return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller($lev);
    $cl =~ s{^Baseliner}{B};
    my $pid = sprintf('%s', $$);
	print STDERR ( _now()."[$pid] [$cl:$li] ", @_, "\n" );
}

sub _log {
	return unless any { $_ } @_;
    my ($cl,$fi,$li) = caller(0);
	_log_me( $cl, $fi, $li, @_ );
}

#TODO check that global DEBUG flag is active
sub _debug {
    my ($cl,$fi,$li) = caller(0);
	return unless $ENV{BASELINER_DEBUG};
	_log_me($cl,$fi,$li,@_);
}

# internal log engine used by _log and _debug
sub _log_me {
    my ($cl,$fi,$li) = (shift,shift,shift);
	my $logger = Baseliner->app->{_logger};
	if( ref $logger eq 'CODE' ) { # logger override
		$logger->($cl,$fi,$li, @_);
	} else {
		$cl =~ s{^Baseliner}{B};
		my $pid = sprintf('%s', $$);
		print STDERR ( _now()."[$pid] [$cl:$li] ", @_, "\n" );
	}
}

use JSON::XS;
sub _decode_json {
    my $data = shift;
    $data = encode_utf8($data) if is_utf8($data);
    return decode_json($data); 
}

sub _throw {
	#Carp::confess(@_);
	#die join('', @_ , "\n");
    #Catalyst::Exception->throw( @_ );
	#Carp::Clan::croak @_;
	##Baseliner->{last_err} = { err=>$_[0], stack=>_whereami };
	#   Carp::croak @_, Carp::longmess();

	my $thower = Baseliner->app->{_thrower};
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
    return Baseliner->config->{time_zone} || 'CET';
}

sub _dt { DateTime->now(time_zone=>_tz);  }

sub _now {
    my $now = DateTime->now(time_zone=>_tz);
    $now=~s{T}{ }g;
    return $now;
}

sub _nowstamp {
    (my $t = _now )=~ s{\:|\/|\\|\s}{}g;
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
    my $parser = DateTime::Format::Strptime->new( pattern => $format, on_error=>'croak' );
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
			$opt = 	Encode::encode_utf8($opt) if Encode::is_utf8($opt);
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

sub _check_parameters {
	my $p = shift;
	for my $param ( @_ ) {
		exists($p->{$param}) or _throw _loc('Missing parameter %1', $param);
	}
}

sub _mkpath {
	my $dir = File::Spec->catfile( @_ );
    
	return if( -e $dir );
	use File::Path;
    
    File::Path::make_path( $dir ) or _throw "Error creating directory $dir: $!";
}

# returns the official tmp dir
sub _tmp_dir {
    Baseliner->config->{tempdir} || $ENV{BASELINER_TEMP} || File::Spec->tmpdir || $ENV{TEMP};
}

=head2 _mktmp( suffix=>$str )

Creates a random tempdir inside the official temp dir.

=cut
sub _mktmp {
   my %p = @_;
   my $suffix = [ _array($p{suffix}) ] || [];
   return _dir( _tmp_dir(), join( '_', _nowstamp, $$, int( rand( 100000 ) ), @$suffix ) );
}

# returns a temp file name 
sub _tmp_file {
	my $p = _parameters(@_);
	_check_parameters( $p, qw/prefix/ );
    my $tempdir = $p->{tempdir} || _tmp_dir();
	$p->{dir}||='';
	my $dir  = File::Spec->catdir($tempdir, $p->{dir} );
	warn "Creating temp dir $tempdir";
	_mkpath( $tempdir );
	my $file = File::Spec->catfile($dir, $p->{prefix} . "_" . _nowstamp() . "_$$.log" );
	warn "Returning tempfile $file";
	return $file;
}

sub _damn {
	my $blessed = shift;
	my $damned = $blessed;
	try {
		$damned = { %$blessed };
		try {
			# recurse
			if( ref($damned) eq 'HASH' ) {
				for my $k ( keys %$damned ) {
					next unless ref($k) eq 'HASH'; 
					$damned->{$k} = _damn( $damned->{$k} );
				}
			}
		} catch {
			my $err = shift;
			warn 'DAMN1=' . $err;
			exit;
		};
	} catch {
		my $err = shift;
		warn 'DAMN1=' . $err;
		exit;
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

sub rs_hashref {
    my $rs = shift;
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
}

=head2 _fail

Die without line number info.

=cut
sub _fail {
    die join(' ',@_) . "\n";
}

sub query_sql_build {
    my %p = @_;
    return {} unless $p{query};
    return {} unless ref $p{fields} eq 'HASH';
    my @terms;
    my $where = {};
    # build columns   -----    TODO use field:lala
    my $col = join '||', values %{ $p{fields} };
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

sub unique {
  my @ls = keys %{{map { $_ => 1 } @_}};
  wantarray ? @ls : \@ls;
}

sub inc { $_[0] + 1 }

sub bool { !!$_[0] } # Any -> Bool

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
