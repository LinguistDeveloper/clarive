my $jobname = 'N.DESA-00001168';
my $com = 'porfa, apruebame';
 Baseliner->model('Request')->request(
            name   => _loc("Aprobación del Pase %1", $jobname),
            action => 'action.job.approve',
            template_engine => 'mason',
            template => '/email/approval_job.html',
            username     => 'ROG2833Z',
            comments_job => $com,
            ns           => 'job/' . $jobname,
            bl           => 'PREP',
            vars         => {
                jobname  => $jobname,
                comments => $com,
            },
        );

__END__
2010-05-18 20:31:03[31036] [BX::Job::Namespace::JobNamespace:11] Creating namespace N.DESA-00001168
2010-05-18 20:31:03[31036] [BX::Job::Namespace::JobNamespace:11] Creating namespace N.DESA-00001168
2010-05-18 20:31:03[31036] [BX::Job::Namespace::JobNamespace:11] Creating namespace N.DESA-00001168
2010-05-18 20:31:03 [Baseliner::Model::Request 31036] - Notifying users: SLG2093A,OAM7315R,JRL2168P,ROG2833Z,JVR3651A,oper,BCL0524V,JBGL304T,RPM0900D,JRF5355T
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=SLG2093A, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=OAM7315R, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=JRL2168P, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=ROG2833Z, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=JVR3651A, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=oper, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=BCL0524V, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=JBGL304T, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=JRF5355T, carrier=email
2010-05-18 20:31:04[31036] [B::Model::Messaging:161] Creating message for username=RPM0900D, carrier=email

Baseliner::Model::Baseliner::BaliRequest=HASH(0xec3db08)
