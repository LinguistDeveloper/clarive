my $jobname = 'N.DESA-00001168';
my $com = 'porfa, apruebame';
my $app = (ns_split('GBP.0001'))[1];
Baseliner->model('Request')->request(
                    name         => 'Aprobar pruebas integradas',
                    action       => 'action.approve.pruebas_integradas',
                    requested_by => 'ROG2833Z',
                    data         => {
                        rfc     => 'S0912919',
                        project => '0083',
                        app     =>  $app,
                        state   => 'PREP',
                        reason  => 'Porfa, apruebame',
                        ts      => _now(),
                    },
                    template    => '/email/approval.html',
                    template_engine => 'mason',
                    ns          => 'harvest.package/H0083S0912919@11',
                    bl          => 'PREP',
                );

__END__
2010-05-18 20:44:31[31305] [BX::CA::Harvest::Namespace::Environment:11] Creating namespace GBP.0083_DESA
2010-05-18 20:44:31 [Baseliner::Model::Request 31305] - Notifying users: SLG2093A,JRF5355T
2010-05-18 20:44:31[31305] [B::Model::Messaging:161] Creating message for username=SLG2093A, carrier=email
2010-05-18 20:44:31[31305] [B::Model::Messaging:161] Creating message for username=JRF5355T, carrier=email

Baseliner::Model::Baseliner::BaliRequest=HASH(0xec3a300)
