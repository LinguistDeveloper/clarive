my $cycle = $c->model('ConfigStore')->get('config.approval', bl=>'PREP');
#$cycle->{cycle}->{start}
__END__
--- 
active: ''
cycle: 
  action.approve.pruebas_aceptacion: 
    action: action.approve.pruebas_sistemas
    bl: PREP
  action.approve.pruebas_integradas: 
    action: action.approve.pruebas_aceptacion
    bl: PREP
  start: 
    action: action.approve.pruebas_integradas
    bl: PREP
frequency: 10

