package BaselinerX::Changeman::Provider::Nature;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Sugar;
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
sub domain    { 'changeman.nature' }
sub icon      { '/static/images/icon/nature.gif' }
sub name      { 'Natures' }

register 'config.changeman.natures' => {
   name => 'Changeman Natures',
   metadata => [
            { id=>'changeman', label=>'Natures to process', type=>'hash', 
              default=>qq{ZOS=>_loc('ZOS'),'ZOS-Linklist'=>_loc('ZOS-Linklist'),'ZOS-Linklist-DB2'=>_loc('ZOS-Linklist-DB2'),'ZOS-DB2'=>_loc('ZOS-DB2') } }
      ]
};

sub find {
    my ($self, $item ) = @_;
	$self->not_implemented;
    #my $package = Baseliner->model('Harvest::Harpackage')->search({ packagename=>$item })->first;
    #return BaselinerX::CA::Harvest::Namespace::Package->new({ row => $package }) if( ref $package );
}

sub list {
    my ($self, $c, $p) = @_;
	_log "provider list started...";
	my @ns;
    my $natures=config_get('config.changeman.natures');

    foreach ( keys %{ $natures->{changeman} || {} } ) {
        push @ns, BaselinerX::CA::Harvest::Namespace::Nature->new({
            ns      => 'nature/' . $_,
            ns_name => $natures->{changeman}{$_},
            ns_type => _loc('Changeman Nature'),
            ns_id   => 0,
            ns_data => { },
            provider=> 'namespace.changeman.nature',
        });
    }

	_log "provider list finished.";
	return \@ns;
}
1;

