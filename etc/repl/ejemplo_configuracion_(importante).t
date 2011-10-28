# package BaselinerX::BDE /features/bde/lib/BaselinerX/BDE.pm


register 'config.bde' => {
    metadata => [
         { id=>'whoami', default=>'vtscm', label=>'Usuario UNIX', description=>'User' },
    ]
};


my $config =  Baseliner->model('ConfigStore')->get('config.bde', ns=>'project/SCR' );
#my $whoami = Baseliner->model('ConfigStore')->search('config.bde.whoami', ns=>'project/CT' );


register 'service.bde.carga_ldif' => {
     config=>'config.bde',
     handler=>sub{
          my ($self,$c,$config)=@_;
          print 'hola ' . $config->{whoami};
     }
};

#Baseliner->launch('service.bde.carga_ldif', data=>{ whoami=>'pepe' });

#$config;
__END__
--- 
whoami: ''

