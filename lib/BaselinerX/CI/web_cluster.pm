package BaselinerX::CI::web_cluster;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);

sub icon { '/static/images/icons/webservice.png' }

has_ci server  => qw(is rw isa Baseliner::Role::CI::Server required 1),
            handles => [qw(connect hostname remote_temp ping)];
has url 	=> qw(is rw isa Str), default => '';
has doc_root => qw(is rw isa Str), default => '';
has user 	=> qw(is rw isa Str), default => '';
has_cis 'instances';

with 'Baseliner::Role::CI::ApplicationServer';
#with 'Baseliner::Role::HasAgent';

sub rel_type { 
	+{
           instances => [ from_mid => 'cluster_instance' ],
           server    => [ from_mid => 'cluster_server' ],
	};
}

1;