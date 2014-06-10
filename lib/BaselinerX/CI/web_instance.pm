package BaselinerX::CI::web_instance;
use Baseliner::Moose;
use Baseliner::Utils qw(:logging);
with 'Baseliner::Role::CI';

sub icon { '/static/images/icons/webservice.png' }

has_ci server  => qw(is rw isa Baseliner::Role::CI::Server required 1),
            handles => [qw(connect hostname remote_temp ping)];
has ip 	=> qw(is rw isa Str), default => '';
has web_port => qw(is rw isa Str), default => '';
has stop_script => qw(is rw isa Str), default => '';
has start_script => qw(is rw isa Str), default => '';
has install => qw(is rw isa Str), default => '';
has contingency => qw(is rw isa Str), default => '';
has doc_root_dynamic_fixed => qw(is rw isa Str), default => '';
has doc_root_static_fixed => qw(is rw isa Str), default => '';
has server0 => qw(is rw isa Str), default => '';
has server1 => qw(is rw isa Str), default => '';
has server2 => qw(is rw isa Str), default => '';
has server3 => qw(is rw isa Str), default => '';
has server4 => qw(is rw isa Str), default => '';
has server5 => qw(is rw isa Str), default => '';
has server6 => qw(is rw isa Str), default => '';

sub rel_type { 
	+{
           server    => [ from_mid => 'instances_server' ],
	};
}


sub store {

	my ($self, $p) = @_;
    
	my @cis = ci->search_cis(collection=>'web_instance');

	my $total = scalar (@cis);
	
	return { totalCount => $total, data => \@cis };
}

1;
