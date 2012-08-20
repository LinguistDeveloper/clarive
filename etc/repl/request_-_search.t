my $req = $c->model('Baseliner::BaliRequest')->search(
{ 'id_project.ns' => 'application/GBP.0188' },
{ join=>{ 'projects' => 'id_project' } }
);
print _dump $req->as_query;
rs_hashref( $req );
[ $req->all ]
__END__
--- !!perl/ref 
=: 
  - (SELECT me.id, me.ns, me.bl, me.requested_on, me.finished_on, me.status, me.finished_by, me.requested_by, me.action, me.id_parent, me.key, me.name, me.type, me.id_wiki, me.id_job, me.data, me.callback, me.id_message FROM bali_request me LEFT JOIN bali_project_items projects ON projects.ns = me.ns LEFT JOIN bali_project id_project ON id_project.id = projects.id_project WHERE ( id_project.ns = ? ))
  - 
    - id_project.ns
    - application/GBP.0188

--- 
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-05-24 11:37:57\n"
  finished_by: ~
  finished_on: ~
  id: 321
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 66d7fc7caf5e1b5ba6d268093e4a76f9
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/PG.0188.Version 8.46
  requested_by: CRG4739J
  requested_on: 2010-05-24 11:37:57
  status: cancelled
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: Ficheros Comunes PREP\nstate: PREP\nts: 2010-06-25 12:59:53\n"
  finished_by: ~
  finished_on: ~
  id: 386
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 466a5df70525e94cb80901ba28f419f2
  name: Aprobar Pruebas Integradas
  ns: harvest.package/Ficheros Comunes PREP
  requested_by: JRF5355T
  requested_on: 2010-06-25 12:59:53
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: S1001446\nstate: PREP\nts: 2010-06-25 12:59:56\n"
  finished_by: ~
  finished_on: ~
  id: 387
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 267a48c46370e3b2a071387e99866d77
  name: Aprobar Pruebas Integradas
  ns: harvest.package/H0188S1001446@01 - VMM7190Q 2010-06-09
  requested_by: VMM7190Q
  requested_on: 2010-06-25 12:59:56
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: S1000583\nstate: PREP\nts: 2010-06-25 12:59:56\n"
  finished_by: ~
  finished_on: ~
  id: 388
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 370235edadbc8df4db6d86ec3686d1b4
  name: Aprobar Pruebas Integradas
  ns: harvest.package/H0188S1000583@04 Tarea 30 P1000583PRTP99800003
  requested_by: JMBG427Q
  requested_on: 2010-06-25 12:59:56
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-06-25 14:43:45\n"
  finished_by: ROG2833Z
  finished_on: 2010-06-28 19:14:36
  id: 390
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 4e06e409443111e6b6b480cfa562bf2e
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/Pruebas2
  requested_by: ROG2833Z
  requested_on: 2010-06-25 14:43:45
  status: cancelled
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: Ficheros Comunes DESA\nstate: PREP\nts: 2010-06-25 15:26:58\n"
  finished_by: ~
  finished_on: ~
  id: 391
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: b17712f8177653db15c4b2905fae064d
  name: Aprobar Pruebas Integradas
  ns: harvest.package/Ficheros Comunes DESA
  requested_by: ROG2833Z
  requested_on: 2010-06-25 15:26:58
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: I01515878\nstate: PREP\nts: 2010-06-28 20:22:30\n"
  finished_by: ~
  finished_on: ~
  id: 398
  id_job: ~
  id_message: 9914
  id_parent: ~
  id_wiki: ~
  key: cfa13893a60d4294a871a6b54936230c
  name: Aprobar Pruebas Integradas
  ns: harvest.package/H0188I01515878@2 - SCG1531L 2010-06-23
  requested_by: SCG1531L
  requested_on: 2010-06-28 20:22:30
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-06-09 09:37:26\n"
  finished_by: ~
  finished_on: ~
  id: 344
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: e6fb8a75be86b3ec9be2c45c57e42286
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/PG.0188.Version 8.47
  requested_by: AMGM336X
  requested_on: 2010-06-09 09:37:26
  status: cancelled
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-06-28 19:14:36\n"
  finished_by: ~
  finished_on: ~
  id: 396
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 71aadb4afe283d1ecb50f6b677e0de1b
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/Pruebas2
  requested_by: ROG2833Z
  requested_on: 2010-06-28 19:14:36
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-06-25 16:04:46\n"
  finished_by: ROG2833Z
  finished_on: 2010-06-28 19:14:36
  id: 392
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: f12bb3cbf892ba3e2544e7f3bb0e862f
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/Pruebas2
  requested_by: ROG2833Z
  requested_on: 2010-06-25 16:04:46
  status: cancelled
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: S1000067\nstate: PREP\nts: 2010-06-28 18:07:32\n"
  finished_by: ~
  finished_on: ~
  id: 393
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: fc92aa4c75e9a2820b2468dd36a71b3c
  name: Aprobar Pruebas Integradas
  ns: harvest.package/H0188S1000067@06 TAREA 32 P1000067PRTP22000001
  requested_by: JMBG427Q
  requested_on: 2010-06-28 18:07:33
  status: pending
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ruta configu.ini H0188S1000958\nstate: PREP\nts: 2010-06-28 18:36:17\n"
  finished_by: ~
  finished_on: ~
  id: 394
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: db00fb04c977763f8b53cb5b83139589
  name: Aprobar Pruebas Integradas
  ns: harvest.package/ruta configu.ini H0188S1000958
  requested_by: AMGM336X
  requested_on: 2010-06-28 18:36:18
  status: cancelled
  type: approval
- 
  action: action.approve.pruebas_integradas
  bl: "*"
  callback: ~
  data: "--- \napp: GBP.0188\nproject: GBP.0188\nreason: Aprobar Pruebas Integradas\nrfc: ''\nstate: PREP\nts: 2010-06-28 19:03:11\n"
  finished_by: ROG2833Z
  finished_on: 2010-06-28 19:14:36
  id: 395
  id_job: ~
  id_message: ~
  id_parent: ~
  id_wiki: ~
  key: 702c800394653fdaf5faf779b0e461a3
  name: Aprobar Pruebas Integradas
  ns: harvest.packagegroup/Pruebas2
  requested_by: ROG2833Z
  requested_on: 2010-06-28 19:03:12
  status: cancelled
  type: approval

