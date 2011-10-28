package BaselinerX::Changeman::Provider::Nature;
use Baseliner::Plug;
use Baseliner::Utils;
use BaselinerX::Changeman::Namespace::Nature;
use Baseliner::Core::DBI;

with 'Baseliner::Role::Provider';

register 'namespace.changeman.nature' => {
	name	=>_loc('Changeman Nature'),
	domain  => domain(),
	can_job => 1,
    finder =>  \&find,
	handler =>  \&list,
};

sub namespace { 'BaselinerX::Changeman::Namespace::Nature' }
sub domain    { 'chaneman.nature' }
sub icon      { '/static/images/icon/nature.gif' }
sub name      { 'Natures' }

sub find {
    my ($self, $item ) = @_;
	$self->not_implemented;
}

sub list {
    my ($self, $c, $p) = @_;
	my @ns;
	_log "provider list started...";
	_log "provider list finished.";
	return [
		BaselinerX::Changeman::Namespace::Nature->new({
			ns      => 'changeman.nature/changeman_batch',
			ns_name => _loc('Changeman Batch'),
			ns_type => _loc('Changeman Nature'),
			ns_id   => 0,
			ns_data => { },
			provider=> 'namespace.changeman.nature',
		}),
		BaselinerX::Changeman::Namespace::Nature->new({
			ns      => 'changeman.nature/changeman_batch_db2',
			ns_name => _loc('Changeman Batch-DB2'),
			ns_type => _loc('Changeman Nature'),
			ns_id   => 0,
			ns_data => { },
			provider=> 'namespace.changeman.nature',
		}),
		BaselinerX::Changeman::Namespace::Nature->new({
			ns      => 'changeman.nature/changeman_batch_linklist',
			ns_name => _loc('Changeman Batch-LinkList'),
			ns_type => _loc('Changeman Nature'),
			ns_id   => 0,
			ns_data => { },
			provider=> 'namespace.changeman.nature',
		}),
		BaselinerX::Changeman::Namespace::Nature->new({
			ns      => 'changeman.nature/changeman_online',
			ns_name => _loc('Changeman Online'),
			ns_type => _loc('Changeman Nature'),
			ns_id   => 0,
			ns_data => { },
			provider=> 'namespace.changeman.nature',
		})],
}
1;

