package BaselinerX::CA::Harvest::Test;
use Baseliner::Plug;
use Baseliner::Utils;

with 'Baseliner::Role::Service';

register 'service.harvest.test' => {
	handler => sub{
		$?=0;
		my @RET=`hsv -i /opt/ca/tmp/harvestparam2595-2010-08-03124311.in 2>&1`;
		_log "RC=$?";
		_log "RET=@RET";
		#_log _whereami();
	}
};

1;
