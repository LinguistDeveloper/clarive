Baseliner->model('SQA')->send_analisys_mail( 
	subject => "Analisis de calidad",
	message => "Analisis de calidad finalizado correctamente",
	bl => 'TEST',
	project => 'AIA',
	subproject => 'aiamain',
	nature => 'J2EE',
	qualification => '44,56',
	indicators => '<li>Mantenibilidad:77,34</li><li>Fiabilidad:89,23</li><li>Eficiencia:65,23</li><li>IAS:43,20</li>',
	result => 'OK',
	project_id => '74',
	status => 'OK'
);

__END__
2011-07-08 14:13:48[5784] [BX::Model::SQA:1261] Enviando correo para: 
proyecto: 74
result:OK
subject:Analisis de calidad
2011-07-08 14:13:48[5784] [B::Model::Messaging:164] Creating message for username=q74612x, carrier=email

--- !!perl/hash:Baseliner::Model::Baseliner::BaliMessage 
_column_data: 
  attach: ~
  body: "<head>\n    <meta http-equiv=\"Content-Language\" content=\"en\" />\n    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\" />\n    <title>Accion</title>\n\t    <style type=\"text/css\">\n        body {\n            font-family: \"Bitstream Vera Sans\", \"Trebuchet MS\", Verdana,\n                         Tahoma, Arial, helvetica, sans-serif;\n            color: #333;\n            background-color: #eee;\n            margin: 0px;\n            padding: 0px;\n        }\n        :link, :link:hover, :visited, :visited:hover {\n            color: #000;\n        }\n        div.box {\n            position: relative;\n            background-color: #ccc;\n            border: 1px solid #aaa;\n            padding: 4px;\n            margin: 10px;\n        }\n        div.error {\n            background-color: #cce;\n            border: 1px solid #755;\n            padding: 8px;\n            margin: 4px;\n            margin-bottom: 10px;\n        }\n        div.infos {\n            background-color: #eee;\n            border: 1px solid #575;\n            padding: 8px;\n            margin: 4px;\n            margin-bottom: 10px;\n        }\n        div.name {\n            background-color: #cce;\n            border: 1px solid #557;\n            padding: 8px;\n            margin: 4px;\n        }\n        code.error {\n            display: block;\n            margin: 1em 0;\n            overflow: auto;\n        }\n        div.name h1, div.error p {\n            margin: 0;\n        }\n        h2 {\n            margin-top: 0;\n            margin-bottom: 10px;\n            font-size: medium;\n            font-weight: bold;\n            text-decoration: underline;\n        }\n        h1 {\n            font-size: medium;\n            font-weight: normal;\n        }\n        pre {\n            white-space: pre-wrap;       /* css-3 */\n            white-space: -moz-pre-wrap;  /* Mozilla, since 1999 */\n            white-space: -pre-wrap;      /* Opera 4-6 */\n            white-space: -o-pre-wrap;    /* Opera 7 */\n            word-wrap: break-word;       /* Internet Explorer 5.5+ */\n        }\n\n        div.trace {\n            background-color: #eee;\n            border: 1px solid #575;\n        }\n        div#stacktrace table {\n            width: 100%;\n        }\n        div#stacktrace th, td {\n            padding-right: 1.5em;\n            text-align: left;\n        }\n        div#stacktrace .line {\n            color: #000;\n            font-weight: strong;\n        }\n    </style>\n\n\n</head>\n\n<style>\nbody {\n\tfont-family: arial;\n\tfont-size: 10pt;\n}\n.backGroundPrimeraFila {\n\tfont-family: Verdana;\n\tfont-size: 8pt;\n\tfont-weight: bold;\n\tcolor: #CCCCCC;\n\tbackground-color: #666666\n}\n.backGroundFilaDatos {\n\tfont-family: Verdana;\n\tfont-size: 8pt;\n\tcolor: #111111;\n\tbackground-color: #ffffff\n}\n</style>\n<body> \n<div id=\"tablaContenedor_div\">\n<TABLE cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n<TR style=\"height:54px\">\n\t\t<TD align=\"right\" colspan=\"2\" nowrap=\"nowrap\"\n\t\t\tstyle=\"background-image:url(/email/img/fondocab_base.gif);\" height=\"54\"><img\n\t\t\tid=\"form:imagen0\" border=0 height=54 src=\"/email/img/pastillas.gif\" /></TD>\n\t</TR>\n<TR height=\"20\">\n\t<TD class=\"backGroundPrimeraFila\" nowrap=\"nowrap\" height=\"14\">\n\t\t&nbsp;SCM/SQA\n\t</TD>\n\t<TD align=\"right\" class=\"backGroundPrimeraFila\" nowrap=\"nowrap\" height=\"14\">\n\t\t<table width=\"80\" height=\"23\" \"cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr>\n\t\t<td id=\"tdAyudaNavegacionDeSoporte\" class=\"navSopColorDefecto\">\n\t\t</td>\n\t\t<td id=\"tdMapaNavegacionDeSoporte\" class=\"navSopColorDefecto\"></td>\n\t\t<td id=\"tdSalirNavegacionDeSoporte\" class=\"navSopColorDefecto\"></td></tr>\n\t\t</table>\n\t</TD>\n</TR>\n</TABLE>\n</div>\n<table border=0 cellspacing=2>\n\n\t<tr>\n\t\t<td>\n\t\t\t<h3>Analisis de calidad finalizado correctamente: AIA</h3>\n\t\t</td>\n\t</tr>\n</table>\n\n<table border=1 cellspacing=1 cellpadding=\"2\">\n\n\t<tr>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Entorno</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Proyecto</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Subaplicaci&oacute;n</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Naturaleza</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Indicadores</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Indicador global</h4></td>\n\t\t<td class=\"backGroundPrimeraFila\"><h4>Auditor&iacute;a</h4></td>\n\t</tr>\n\t<tr>\n\t\t<td class=\"backGroundFilaDatos\">TEST</td>\n\t\t<td class=\"backGroundFilaDatos\">AIA</td>\n\t\t<td class=\"backGroundFilaDatos\">aiamain</td>\n\t\t<td class=\"backGroundFilaDatos\">J2EE</td>\n\t\t<td class=\"backGroundFilaDatos\"><li>Mantenibilidad:77,34</li><li>Fiabilidad:89,23</li><li>Eficiencia:65,23</li><li>IAS:43,20</li></td>\n\t\t<td class=\"backGroundFilaDatos\">44,56</td>\n\t\t<td class=\"backGroundFilaDatos\">OK</td>\n\t</tr>\n\n</table>\n\n\n<p>\n<A HREF=\"/raw/sqa/grid\" TARGET=_blank>Consulte el portal de calidad aqu&iacute;</A>.\n</body>\n\n\n"
  id: 637
  sender: SCM
  subject: Analisis de calidad
_dirty_columns: {}

_in_storage: 1
_inflated_column: {}

_source_handle: !!perl/hash:DBIx::Class::ResultSourceHandle 
  schema: &1 !!perl/hash:Baseliner::Schema::Baseliner 
    class_mappings: 
      Baseliner::Model::Baseliner::BaliBaseline: BaliBaseline
      Baseliner::Model::Baseliner::BaliCalendar: BaliCalendar
      Baseliner::Model::Baseliner::BaliCalendarWindow: BaliCalendarWindow
      Baseliner::Model::Baseliner::BaliChain: BaliChain
      Baseliner::Model::Baseliner::BaliChainedService: BaliChainedService
      Baseliner::Model::Baseliner::BaliConfig: BaliConfig
      Baseliner::Model::Baseliner::BaliConfigRel: BaliConfigRel
      Baseliner::Model::Baseliner::BaliConfigset: BaliConfigset
      Baseliner::Model::Baseliner::BaliDaemon: BaliDaemon
      Baseliner::Model::Baseliner::BaliFileDist: BaliFileDist
      Baseliner::Model::Baseliner::BaliJob: BaliJob
      Baseliner::Model::Baseliner::BaliJobItems: BaliJobItems
      Baseliner::Model::Baseliner::BaliJobStash: BaliJobStash
      Baseliner::Model::Baseliner::BaliLog: BaliLog
      Baseliner::Model::Baseliner::BaliLogData: BaliLogData
      Baseliner::Model::Baseliner::BaliMessage: BaliMessage
      Baseliner::Model::Baseliner::BaliMessageQueue: BaliMessageQueue
      Baseliner::Model::Baseliner::BaliNamespace: BaliNamespace
      Baseliner::Model::Baseliner::BaliPlugin: BaliPlugin
      Baseliner::Model::Baseliner::BaliProject: BaliProject
      Baseliner::Model::Baseliner::BaliProjectItems: BaliProjectItems
      Baseliner::Model::Baseliner::BaliProvider: BaliProvider
      Baseliner::Model::Baseliner::BaliRelationship: BaliRelationship
      Baseliner::Model::Baseliner::BaliRelease: BaliRelease
      Baseliner::Model::Baseliner::BaliReleaseItems: BaliReleaseItems
      Baseliner::Model::Baseliner::BaliRepo: BaliRepo
      Baseliner::Model::Baseliner::BaliRepoKeys: BaliRepoKeys
      Baseliner::Model::Baseliner::BaliRequest: BaliRequest
      Baseliner::Model::Baseliner::BaliRole: BaliRole
      Baseliner::Model::Baseliner::BaliRoleaction: BaliRoleaction
      Baseliner::Model::Baseliner::BaliRoleuser: BaliRoleuser
      Baseliner::Model::Baseliner::BaliScriptsInFileDist: BaliScriptsInFileDist
      Baseliner::Model::Baseliner::BaliSem: BaliSem
      Baseliner::Model::Baseliner::BaliSemQueue: BaliSemQueue
      Baseliner::Model::Baseliner::BaliService: BaliService
      Baseliner::Model::Baseliner::BaliSession: BaliSession
      Baseliner::Model::Baseliner::BaliSqa: BaliSqa
      Baseliner::Model::Baseliner::BaliSshScript: BaliSshScript
      Baseliner::Model::Baseliner::BaliUser: BaliUser
      Baseliner::Model::Baseliner::BaliWiki: BaliWiki
      Baseliner::Schema::Baseliner::Result::BaliBaseline: BaliBaseline
      Baseliner::Schema::Baseliner::Result::BaliCalendar: BaliCalendar
      Baseliner::Schema::Baseliner::Result::BaliCalendarWindow: BaliCalendarWindow
      Baseliner::Schema::Baseliner::Result::BaliChain: BaliChain
      Baseliner::Schema::Baseliner::Result::BaliChainedService: BaliChainedService
      Baseliner::Schema::Baseliner::Result::BaliConfig: BaliConfig
      Baseliner::Schema::Baseliner::Result::BaliConfigRel: BaliConfigRel
      Baseliner::Schema::Baseliner::Result::BaliConfigset: BaliConfigset
      Baseliner::Schema::Baseliner::Result::BaliDaemon: BaliDaemon
      Baseliner::Schema::Baseliner::Result::BaliFileDist: BaliFileDist
      Baseliner::Schema::Baseliner::Result::BaliJob: BaliJob
      Baseliner::Schema::Baseliner::Result::BaliJobItems: BaliJobItems
      Baseliner::Schema::Baseliner::Result::BaliJobStash: BaliJobStash
      Baseliner::Schema::Baseliner::Result::BaliLog: BaliLog
      Baseliner::Schema::Baseliner::Result::BaliLogData: BaliLogData
      Baseliner::Schema::Baseliner::Result::BaliMessage: BaliMessage
      Baseliner::Schema::Baseliner::Result::BaliMessageQueue: BaliMessageQueue
      Baseliner::Schema::Baseliner::Result::BaliNamespace: BaliNamespace
      Baseliner::Schema::Baseliner::Result::BaliPlugin: BaliPlugin
      Baseliner::Schema::Baseliner::Result::BaliProject: BaliProject
      Baseliner::Schema::Baseliner::Result::BaliProjectItems: BaliProjectItems
      Baseliner::Schema::Baseliner::Result::BaliProvider: BaliProvider
      Baseliner::Schema::Baseliner::Result::BaliRelationship: BaliRelationship
      Baseliner::Schema::Baseliner::Result::BaliRelease: BaliRelease
      Baseliner::Schema::Baseliner::Result::BaliReleaseItems: BaliReleaseItems
      Baseliner::Schema::Baseliner::Result::BaliRepo: BaliRepo
      Baseliner::Schema::Baseliner::Result::BaliRepoKeys: BaliRepoKeys
      Baseliner::Schema::Baseliner::Result::BaliRequest: BaliRequest
      Baseliner::Schema::Baseliner::Result::BaliRole: BaliRole
      Baseliner::Schema::Baseliner::Result::BaliRoleaction: BaliRoleaction
      Baseliner::Schema::Baseliner::Result::BaliRoleuser: BaliRoleuser
      Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist: BaliScriptsInFileDist
      Baseliner::Schema::Baseliner::Result::BaliSem: BaliSem
      Baseliner::Schema::Baseliner::Result::BaliSemQueue: BaliSemQueue
      Baseliner::Schema::Baseliner::Result::BaliService: BaliService
      Baseliner::Schema::Baseliner::Result::BaliSession: BaliSession
      Baseliner::Schema::Baseliner::Result::BaliSqa: BaliSqa
      Baseliner::Schema::Baseliner::Result::BaliSshScript: BaliSshScript
      Baseliner::Schema::Baseliner::Result::BaliUser: BaliUser
      Baseliner::Schema::Baseliner::Result::BaliWiki: BaliWiki
    source_registrations: 
      BaliBaseline: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 100
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_baseline_seq
            size: 126
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - bl
          - name
          - description
        _primaries: &2 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *2
        name: bali_baseline
        result_class: Baseliner::Model::Baseliner::BaliBaseline
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliBaseline
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliCalendar: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 100
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_calendar_seq
            size: 126
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 100
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 0
            size: 100
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: HI
            is_nullable: 1
            size: 2
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - ns
          - bl
          - description
          - type
        _primaries: &7 
          - id
        _relationships: 
          bali_calendar_windows: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliCalendarWindow
            cond: 
              foreign.id_cal: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliCalendarWindow
        _unique_constraints: 
          primary: *7
        name: bali_calendar
        result_class: Baseliner::Model::Baseliner::BaliCalendar
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliCalendar
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliCalendarWindow: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: 1
            is_nullable: 1
            size: 1
          day: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 20
          end_date: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          end_time: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 20
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 0
            sequence: bali_calendar_window_seq
            size: 126
          id_cal: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: 1
            is_nullable: 0
            size: 126
          start_date: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          start_time: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 20
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - start_time
          - end_time
          - day
          - type
          - active
          - id_cal
          - start_date
          - end_date
        _primaries: &30 
          - id
        _relationships: 
          id_cal: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliCalendar
            cond: 
              foreign.id: self.id_cal
            source: Baseliner::Schema::Baseliner::Result::BaliCalendar
        _unique_constraints: 
          primary: *30
        name: bali_calendar_window
        result_class: Baseliner::Model::Baseliner::BaliCalendarWindow
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliCalendarWindow
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliChain: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          action: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 50
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 2000
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_chain_seq
            size: 38
          job_type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 1
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - description
          - job_type
          - active
          - action
          - ns
          - bl
        _primaries: &36 
          - id
        _relationships: 
          bali_chained_services: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliChainedService
            cond: 
              foreign.chain_id: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliChainedService
        _unique_constraints: 
          primary: *36
        name: bali_chain
        result_class: Baseliner::Model::Baseliner::BaliChain
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliChain
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliChainedService: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          chain_id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 2000
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_chained_service_seq
            size: 126
          key: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
          seq: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          step: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: RUN
            is_nullable: 1
            size: 50
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - chain_id
          - seq
          - key
          - description
          - step
          - active
        _primaries: &28 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *28
        name: bali_chained_service
        result_class: Baseliner::Model::Baseliner::BaliChainedService
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliChainedService
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliConfig: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 100
          data: 
            _ic_dt_method: blob
            data_type: BLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_config_seq
            size: 126
          key: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 100
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 0
            size: 1000
          parent_id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: '0                     '
            is_nullable: 0
            size: 126
          ref: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          reftable: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 100
          ts: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 0
            size: 19
          value: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: 'NULL'
            is_nullable: 1
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - bl
          - key
          - value
          - ts
          - ref
          - reftable
          - data
          - parent_id
        _primaries: &17 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *17
        name: bali_config
        result_class: Baseliner::Model::Baseliner::BaliConfig
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliConfig
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliConfigRel: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id: 
            _ic_dt_method: integer
            data_type: INTEGER
            is_nullable: 0
            size: ~
          namespace_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
          plugin_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - namespace_id
          - plugin_id
        _primaries: &26 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *26
        name: bali_config_rel
        result_class: Baseliner::Model::Baseliner::BaliConfigRel
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliConfigRel
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliConfigset: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          baseline_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
          created_on: 
            _ic_dt_method: datetime
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATETIME
            is_nullable: 0
            size: 19
          id: 
            _ic_dt_method: integer
            data_type: INTEGER
            is_nullable: 0
            size: ~
          namespace_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
          wiki_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - namespace_id
          - baseline_id
          - wiki_id
          - created_on
        _primaries: &10 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *10
        name: bali_configset
        result_class: Baseliner::Model::Baseliner::BaliConfigset
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliConfigset
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliDaemon: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          config: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          hostname: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: localhost
            is_nullable: 1
            size: 255
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          params: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          pid: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          service: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - service
          - active
          - config
          - pid
          - params
          - hostname
        _primaries: &22 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *22
        name: bali_daemon
        result_class: Baseliner::Model::Baseliner::BaliDaemon
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliDaemon
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliFileDist: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'*'                 "
            is_nullable: 0
            size: 100
          dest_dir: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          exclussions: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          filter: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'*.*'    "
            is_nullable: 1
            size: 1024
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          isrecursive: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: '0    '
            is_nullable: 1
            size: 1
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'/'                 "
            is_nullable: 0
            size: 1000
          src_dir: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'.'     "
            is_nullable: 0
            size: 1024
          ssh_host: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          sys: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: AIX
            is_nullable: 0
            size: 20
          xtype: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 16
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - bl
          - filter
          - isrecursive
          - src_dir
          - dest_dir
          - ssh_host
          - xtype
          - sys
          - exclussions
        _primaries: &15 
          - id
        _relationships: 
          bali_scripts_in_file_dists: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist
            cond: 
              foreign.file_dist_id: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist
        _unique_constraints: 
          primary: *15
        name: bali_file_dist
        result_class: Baseliner::Model::Baseliner::BaliFileDist
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliFileDist
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliJob: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 45
          comments: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          endtime: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          exec: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          host: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: localhost
            is_nullable: 1
            size: 255
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_job_seq
            size: 38
          id_stash: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 1
            size: 38
          maxstarttime: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 0
            size: 19
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 45
          now: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 0
            size: 45
          owner: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          pid: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 38
          request_status: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          rollback: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          runner: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          schedtime: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: sysdate
            is_nullable: 1
            size: 19
          starttime: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 0
            size: 19
          status: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: READY
            is_nullable: 0
            size: 45
          step: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: PRE
            is_nullable: 1
            size: 50
          ts: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 100
          username: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - starttime
          - maxstarttime
          - endtime
          - status
          - ns
          - bl
          - runner
          - pid
          - comments
          - type
          - username
          - ts
          - host
          - owner
          - step
          - id_stash
          - rollback
          - now
          - schedtime
          - exec
          - request_status
        _primaries: &16 
          - id
        _relationships: 
          bali_job_items: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliJobItems
            cond: 
              foreign.id_job: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliJobItems
          bali_job_stashes: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliJobStash
            cond: 
              foreign.id_job: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliJobStash
          bali_log: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliLog
            cond: 
              foreign.id_job: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliLog
          id_stash: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJobStash
            cond: 
              foreign.id: self.id_stash
            source: Baseliner::Schema::Baseliner::Result::BaliJobStash
          job_stash: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJobStash
            cond: 
              foreign.id: self.id_stash
            source: Baseliner::Schema::Baseliner::Result::BaliJobStash
        _unique_constraints: 
          primary: *16
        name: bali_job
        result_class: Baseliner::Model::Baseliner::BaliJob
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliJob
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliJobItems: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          application: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          data: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_job_items_seq
            size: 38
          id_job: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 0
            size: 38
          item: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          provider: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          rfc: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          service: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - data
          - item
          - provider
          - id_job
          - service
          - application
          - rfc
        _primaries: &13 
          - id
        _relationships: 
          id_job: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              foreign.id: self.id_job
            source: Baseliner::Schema::Baseliner::Result::BaliJob
        _unique_constraints: 
          primary: *13
        name: bali_job_items
        result_class: Baseliner::Model::Baseliner::BaliJobItems
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliJobItems
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliJobStash: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_job_stash_seq
            size: 38
          id_job: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 1
            size: 38
          stash: 
            _ic_dt_method: blob
            data_type: BLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - stash
          - id_job
        _primaries: &4 
          - id
        _relationships: 
          bali_jobs: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              foreign.id_stash: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliJob
          id_job: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              foreign.id: self.id_job
            source: Baseliner::Schema::Baseliner::Result::BaliJob
        _unique_constraints: 
          primary: *4
        name: bali_job_stash
        result_class: Baseliner::Model::Baseliner::BaliJobStash
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliJobStash
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliLog: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          data: 
            _ic_dt_method: blob
            data_type: BLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          data_length: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 38
          data_name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          exec: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_log_seq
            size: 38
          id_job: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 0
            size: 38
          lev: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 10
          milestone: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          module: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          more: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 10
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 1
            size: 255
          prefix: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          provider: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          section: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: general
            is_nullable: 1
            size: 255
          step: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          text: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 2048
          timestamp: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - text
          - lev
          - id_job
          - more
          - timestamp
          - ns
          - provider
          - data
          - data_name
          - data_length
          - module
          - section
          - step
          - exec
          - prefix
          - milestone
        _primaries: &23 
          - id
        _relationships: 
          bali_log_datas: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliLogData
            cond: 
              foreign.id_log: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliLogData
          job: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              foreign.id: self.id_job
            source: Baseliner::Schema::Baseliner::Result::BaliJob
          jobexec: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              foreign.exec: self.exec
              foreign.id: self.id_job
            source: Baseliner::Schema::Baseliner::Result::BaliJob
        _unique_constraints: 
          primary: *23
        name: bali_log
        result_class: Baseliner::Model::Baseliner::BaliLog
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliLog
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliLogData: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          data: 
            _ic_dt_method: blob
            data_type: BLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            size: 38
          id_log: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 0
            size: 38
          len: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 38
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 2048
          timestamp: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - id_log
          - data
          - timestamp
          - name
          - type
          - len
        _primaries: &24 
          - id
        _relationships: 
          id_log: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliLog
            cond: 
              foreign.id: self.id_log
            source: Baseliner::Schema::Baseliner::Result::BaliLog
        _unique_constraints: 
          primary: *24
        name: bali_log_data
        result_class: Baseliner::Model::Baseliner::BaliLogData
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliLogData
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliMessage: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          attach: 
            _ic_dt_method: blob
            data_type: BLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          attach_content_type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          attach_filename: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          body: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          content_type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          created: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_message_seq
            size: 126
          sender: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          subject: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - subject
          - body
          - created
          - active
          - attach
          - sender
          - content_type
          - attach_content_type
          - attach_filename
        _primaries: &40 
          - id
        _relationships: 
          bali_message_queues: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliMessageQueue
            cond: 
              foreign.id_message: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliMessageQueue
        _unique_constraints: 
          primary: *40
        name: bali_message
        result_class: Baseliner::Model::Baseliner::BaliMessage
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliMessage
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliMessageQueue: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          attempts: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          carrier: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: instant
            is_nullable: 1
            size: 50
          carrier_param: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          destination: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 50
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_message_queue_seq
            size: 126
          id_message: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          received: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          result: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          sent: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          username: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - id_message
          - username
          - destination
          - sent
          - received
          - active
          - carrier
          - carrier_param
          - result
          - attempts
        _primaries: &5 
          - id
        _relationships: 
          id_message: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliMessage
            cond: 
              foreign.id: self.id_message
            source: Baseliner::Schema::Baseliner::Result::BaliMessage
        _unique_constraints: 
          primary: *5
        name: bali_message_queue
        result_class: Baseliner::Model::Baseliner::BaliMessageQueue
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliMessageQueue
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliNamespace: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_namespace_seq
            size: 126
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 100
          provider: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 500
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - provider
        _primaries: &29 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *29
        name: bali_namespace
        result_class: Baseliner::Model::Baseliner::BaliNamespace
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliNamespace
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliPlugin: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          desc: 
            _ic_dt_method: varchar
            data_type: VARCHAR
            is_nullable: 0
            size: 500
          id: 
            _ic_dt_method: integer
            data_type: INTEGER
            is_nullable: 0
            size: ~
          plugin: 
            _ic_dt_method: varchar
            data_type: VARCHAR
            is_nullable: 0
            size: 250
          wiki_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - plugin
          - desc
          - wiki_id
        _primaries: &37 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *37
        name: bali_plugin
        result_class: Baseliner::Model::Baseliner::BaliPlugin
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliPlugin
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliProject: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: varchar2
            default_value: "*"
            is_nullable: 1
            size: 1024
          data: 
            _ic_dt_method: clob
            data_type: clob
            is_nullable: 1
          description: 
            _ic_dt_method: clob
            data_type: clob
            is_nullable: 1
          domain: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1
          id: 
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_project_seq
          id_parent: 
            _ic_dt_method: numeric
            data_type: numeric
            is_nullable: 1
            original: 
              data_type: number
            size: 126
          name: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 0
            size: 1024
          nature: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          ns: 
            _ic_dt_method: varchar2
            data_type: varchar2
            default_value: /
            is_nullable: 1
            size: 1024
          ts: 
            _ic_dt_method: datetime
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: datetime
            default_value: !!perl/ref 
              =: current_timestamp
            is_nullable: 1
            original: 
              data_type: date
              default_value: !!perl/ref 
                =: sysdate
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - data
          - ns
          - bl
          - ts
          - domain
          - description
          - id_parent
          - nature
        _primaries: &25 
          - id
        _relationships: 
          bali_project_items: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliProjectItems
            cond: 
              foreign.id_project: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliProjectItems
          parent: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              join_type: LEFT OUTER
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliProject
            cond: 
              foreign.id: self.id_parent
            source: Baseliner::Schema::Baseliner::Result::BaliProject
        _unique_constraints: 
          primary: *25
        name: bali_project
        result_class: Baseliner::Model::Baseliner::BaliProject
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliProject
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliProjectItems: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id: 
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_project_items_seq
          id_project: 
            _ic_dt_method: numeric
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: numeric
            is_foreign_key: 1
            is_nullable: 0
            original: 
              data_type: number
            size: 126
          ns: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - id_project
          - ns
        _primaries: &35 
          - id
        _relationships: 
          id_project: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliProject
            cond: 
              foreign.id: self.id_project
            source: Baseliner::Schema::Baseliner::Result::BaliProject
        _unique_constraints: 
          primary: *35
        name: bali_project_items
        result_class: Baseliner::Model::Baseliner::BaliProjectItems
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliProjectItems
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliProvider: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id: 
            _ic_dt_method: integer
            data_type: INTEGER
            is_nullable: 0
            size: ~
          plugin: 
            _ic_dt_method: varchar
            data_type: VARCHAR
            is_nullable: 0
            size: 250
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - plugin
        _primaries: &27 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *27
        name: bali_provider
        result_class: Baseliner::Model::Baseliner::BaliProvider
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliProvider
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRelationship: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          from_id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 38
          from_ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          to_id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 38
          to_ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 45
        _columns_info_loaded: 0
        _ordered_columns: 
          - from_ns
          - to_ns
          - from_id
          - to_id
          - type
        _primaries: &18 
          - to_ns
          - from_ns
        _relationships: {}

        _unique_constraints: 
          primary: *18
        name: bali_relationship
        result_class: Baseliner::Model::Baseliner::BaliRelationship
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRelationship
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRelease: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: char
            data_type: CHAR
            default_value: 1
            is_nullable: 0
            size: 1
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 100
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 2000
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_release_seq
            size: 38
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 1
            size: 1024
          ts: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          username: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - description
          - active
          - ts
          - bl
          - username
          - ns
        _primaries: &12 
          - id
        _relationships: 
          bali_release_items: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliReleaseItems
            cond: 
              foreign.id_rel: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliReleaseItems
        _unique_constraints: 
          primary: *12
        name: bali_release
        result_class: Baseliner::Model::Baseliner::BaliRelease
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRelease
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliReleaseItems: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          data: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_release_items_seq
            size: 38
          id_rel: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 38
          item: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          provider: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - id_rel
          - item
          - provider
          - data
          - ns
        _primaries: &33 
          - id
        _relationships: 
          id_rel: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRelease
            cond: 
              foreign.id: self.id_rel
            source: Baseliner::Schema::Baseliner::Result::BaliRelease
          release: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRelease
            cond: 
              foreign.id: self.id_rel
            source: Baseliner::Schema::Baseliner::Result::BaliRelease
        _unique_constraints: 
          primary: *33
        name: bali_release_items
        result_class: Baseliner::Model::Baseliner::BaliReleaseItems
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliReleaseItems
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRepo: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          backend: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: default
            is_nullable: 1
            size: 1024
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 255
          class: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          data: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          item: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          provider: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          ts: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
        _columns_info_loaded: 0
        _ordered_columns: 
          - ns
          - backend
          - ts
          - bl
          - provider
          - item
          - class
          - data
        _primaries: &6 
          - ns
        _relationships: 
          keys: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRepoKeys
            cond: 
              foreign.ns: self.ns
            source: Baseliner::Schema::Baseliner::Result::BaliRepoKeys
        _unique_constraints: 
          primary: *6
        name: bali_repo
        result_class: Baseliner::Model::Baseliner::BaliRepo
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRepo
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRepoKeys: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 255
          k: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          ts: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          v: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 0
            size: '2147483647'
          version: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 38
        _columns_info_loaded: 0
        _ordered_columns: 
          - ns
          - ts
          - bl
          - version
          - k
          - v
        _primaries: &38 
          - ns
          - bl
          - k
          - version
        _relationships: 
          repo: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRepo
            cond: 
              foreign.ns: self.ns
            source: Baseliner::Schema::Baseliner::Result::BaliRepo
        _unique_constraints: 
          primary: *38
        name: bali_repokeys
        result_class: Baseliner::Model::Baseliner::BaliRepoKeys
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRepoKeys
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRequest: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          action: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 50
          callback: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          data: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          finished_by: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          finished_on: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_request_seq
            size: 38
          id_job: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 1
            size: 126
          id_message: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          id_parent: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 38
          id_wiki: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 1
            size: 126
          key: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          name: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          requested_by: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          requested_on: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          status: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: pending
            is_nullable: 1
            size: 50
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: approval
            is_nullable: 1
            size: 100
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - bl
          - requested_on
          - finished_on
          - status
          - finished_by
          - requested_by
          - action
          - id_parent
          - key
          - name
          - type
          - id_wiki
          - id_job
          - data
          - callback
          - id_message
        _primaries: &9 
          - id
        _relationships: 
          projects: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliProjectItems
            cond: 
              foreign.ns: self.ns
            source: Baseliner::Schema::Baseliner::Result::BaliProjectItems
        _unique_constraints: 
          primary: *9
        name: bali_request
        result_class: Baseliner::Model::Baseliner::BaliRequest
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRequest
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRole: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 2048
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_role_seq
            size: 38
          mailbox: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
          role: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - role
          - description
          - mailbox
        _primaries: &8 
          - id
        _relationships: 
          bali_roleactions: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRoleaction
            cond: 
              foreign.id_role: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliRoleaction
          bali_roleusers: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRoleuser
            cond: 
              foreign.id_role: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliRoleuser
        _unique_constraints: 
          primary: *8
        name: bali_role
        result_class: Baseliner::Model::Baseliner::BaliRole
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRole
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRoleaction: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          action: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 50
          id_role: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 0
            size: 38
        _columns_info_loaded: 0
        _ordered_columns: 
          - id_role
          - action
          - bl
        _primaries: &19 
          - action
          - id_role
          - bl
        _relationships: 
          id_role: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRole
            cond: 
              foreign.id: self.id_role
            source: Baseliner::Schema::Baseliner::Result::BaliRole
        _unique_constraints: 
          primary: *19
        name: bali_roleaction
        result_class: Baseliner::Model::Baseliner::BaliRoleaction
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRoleaction
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliRoleuser: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          id_role: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_foreign_key: 1
            is_nullable: 0
            size: 38
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: /
            is_nullable: 0
            size: 100
          username: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - username
          - id_role
          - ns
        _primaries: &20 
          - ns
          - id_role
          - username
        _relationships: 
          actions: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRoleaction
            cond: 
              foreign.id_role: self.id_role
            source: Baseliner::Schema::Baseliner::Result::BaliRoleaction
          bali_user: 
            attrs: 
              accessor: single
              cascade_delete: 1
              cascade_update: 1
            class: Baseliner::Schema::Baseliner::Result::BaliUser
            cond: 
              foreign.username: self.username
            source: Baseliner::Schema::Baseliner::Result::BaliUser
          id_role: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRole
            cond: 
              foreign.id: self.id_role
            source: Baseliner::Schema::Baseliner::Result::BaliRole
          requests: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRequest
            cond: 
              - 
                foreign.ns: self.ns
              - 
                foreign.bl: actions.bl
              - 
                foreign.action: actions.action
            source: Baseliner::Schema::Baseliner::Result::BaliRequest
          role: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliRole
            cond: 
              foreign.id: self.id_role
            source: Baseliner::Schema::Baseliner::Result::BaliRole
        _unique_constraints: 
          primary: *20
        name: bali_roleuser
        result_class: Baseliner::Model::Baseliner::BaliRoleuser
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliRoleuser
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliScriptsInFileDist: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          file_dist_id: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          script_id: 
            _ic_dt_method: number
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - file_dist_id
          - script_id
        _primaries: &31 
          - id
        _relationships: 
          file_dist_id: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliFileDist
            cond: 
              foreign.id: self.file_dist_id
            source: Baseliner::Schema::Baseliner::Result::BaliFileDist
          script_id: 
            attrs: 
              accessor: filter
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliSshScript
            cond: 
              foreign.id: self.script_id
            source: Baseliner::Schema::Baseliner::Result::BaliSshScript
        _unique_constraints: 
          primary: *31
        name: bali_scripts_in_file_dist
        result_class: Baseliner::Model::Baseliner::BaliScriptsInFileDist
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliScriptsInFileDist
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliSem: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 0
            size: 255
          description: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          queue_mode: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: slot
            is_nullable: 0
            size: 255
          sem: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          slots: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
        _columns_info_loaded: 0
        _ordered_columns: 
          - sem
          - description
          - slots
          - active
          - bl
          - queue_mode
        _primaries: &34 
          - sem
          - bl
        _relationships: 
          queue: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliSemQueue
            cond: 
              foreign.sem: self.sem
            source: Baseliner::Schema::Baseliner::Result::BaliSemQueue
        _unique_constraints: 
          primary: *34
        name: bali_sem
        result_class: Baseliner::Model::Baseliner::BaliSem
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliSem
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliSemQueue: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          active: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 126
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 50
          busy_secs: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          caller: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          expire_on: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          host: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: localhost
            is_nullable: 1
            size: 255
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_sem_queue_seq
            size: 126
          id_job: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          pid: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          run_now: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          sem: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          seq: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          status: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: idle
            is_nullable: 1
            size: 50
          ts_grant: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          ts_release: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: ~
            is_nullable: 1
            size: 19
          ts_request: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: sysdate
            is_nullable: 1
            size: 19
          wait_secs: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 0
            is_nullable: 1
            size: 126
          who: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 1024
          who_id: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - sem
          - who
          - who_id
          - host
          - pid
          - status
          - active
          - seq
          - id_job
          - run_now
          - wait_secs
          - busy_secs
          - ts_request
          - ts_grant
          - ts_release
          - bl
          - caller
          - expire_on
        _primaries: &3 
          - id
        _relationships: 
          job: 
            attrs: 
              accessor: single
              cascade_delete: 1
              cascade_update: 1
            class: Baseliner::Schema::Baseliner::Result::BaliJob
            cond: 
              id: id_job
            source: Baseliner::Schema::Baseliner::Result::BaliJob
        _unique_constraints: 
          primary: *3
        name: bali_sem_queue
        result_class: Baseliner::Model::Baseliner::BaliSemQueue
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliSemQueue
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliService: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          desc: 
            _ic_dt_method: varchar
            data_type: VARCHAR
            is_nullable: 0
            size: 100
          id: 
            _ic_dt_method: integer
            data_type: INTEGER
            is_nullable: 0
            size: ~
          name: 
            _ic_dt_method: varchar
            data_type: VARCHAR
            is_nullable: 0
            size: 100
          wiki_id: 
            _ic_dt_method: int
            data_type: INT
            is_nullable: 0
            size: 10
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - name
          - desc
          - wiki_id
        _primaries: &41 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *41
        name: bali_service
        result_class: Baseliner::Model::Baseliner::BaliService
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliService
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliSession: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          expires: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            is_numeric: 0
            size: 126
          id: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 72
          session_data: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - session_data
          - expires
        _primaries: &21 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *21
        name: bali_session
        result_class: Baseliner::Model::Baseliner::BaliSession
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliSession
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliSqa: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          data: 
            _ic_dt_method: clob
            data_type: clob
            is_nullable: 1
          id: 
            is_auto_increment: 1
            is_nullable: 0
            sequence: bali_sqa_seq
          id_prj: 
            _ic_dt_method: numeric
            data_type: numeric
            is_foreign_key: 1
            is_nullable: 1
            original: 
              data_type: number
            size: 126
          nature: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          ns: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          qualification: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          status: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
          tsend: 
            _ic_dt_method: datetime
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: datetime
            is_nullable: 1
            original: 
              data_type: date
          tsstart: 
            _ic_dt_method: datetime
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: datetime
            default_value: !!perl/ref 
              =: current_timestamp
            is_nullable: 1
            original: 
              data_type: date
              default_value: !!perl/ref 
                =: sysdate
          type: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 1024
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - bl
          - id_prj
          - nature
          - qualification
          - status
          - data
          - tsstart
          - tsend
          - type
        _primaries: &39 
          - id
        _relationships: 
          project: 
            attrs: 
              accessor: single
              is_foreign_key_constraint: 1
              undef_on_null_fk: 1
            class: Baseliner::Schema::Baseliner::Result::BaliProject
            cond: 
              foreign.id: self.id_prj
            source: Baseliner::Schema::Baseliner::Result::BaliProject
        _unique_constraints: 
          primary: *39
        name: bali_sqa
        result_class: Baseliner::Model::Baseliner::BaliSqa
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliSqa
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliSshScript: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          bl: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'*'                 "
            is_nullable: 0
            size: 100
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            size: 126
          ns: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "'/'                 "
            is_nullable: 0
            size: 1000
          params: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          script: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          ssh_host: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 0
            size: 1024
          type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: POST
            is_nullable: 1
            size: 4
          xorder: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: 1
            is_nullable: 1
            size: 1
          xtype: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: "*"
            is_nullable: 1
            size: 16
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - ns
          - bl
          - script
          - params
          - ssh_host
          - xorder
          - type
          - xtype
        _primaries: &11 
          - id
        _relationships: 
          bali_scripts_in_file_dists: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist
            cond: 
              foreign.script_id: self.id
            source: Baseliner::Schema::Baseliner::Result::BaliScriptsInFileDist
        _unique_constraints: 
          primary: *11
        name: bali_ssh_script
        result_class: Baseliner::Model::Baseliner::BaliSshScript
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliSshScript
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliUser: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          alias: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 512
          avatar: 
            _ic_dt_method: blob
            data_type: blob
            is_nullable: 1
          data: 
            _ic_dt_method: clob
            data_type: clob
            is_nullable: 1
          id: 
            _ic_dt_method: integer
            data_type: integer
            is_auto_increment: 1
            is_nullable: 0
            original: 
              data_type: number
            sequence: bali_user_seq
            size: 126
          password: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 0
            size: 45
          realname: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 1
            size: 4000
          username: 
            _ic_dt_method: varchar2
            data_type: varchar2
            is_nullable: 0
            size: 45
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - username
          - password
          - realname
          - avatar
          - data
          - alias
        _primaries: &14 
          - id
        _relationships: 
          roles: 
            attrs: 
              accessor: multi
              cascade_copy: 1
              cascade_delete: 1
              join_type: LEFT
            class: Baseliner::Schema::Baseliner::Result::BaliRoleuser
            cond: 
              foreign.username: self.username
            source: Baseliner::Schema::Baseliner::Result::BaliRoleuser
        _unique_constraints: 
          primary: *14
        name: bali_user
        result_class: Baseliner::Model::Baseliner::BaliUser
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliUser
        sqlt_deploy_callback: default_sqlt_deploy_hook
      BaliWiki: !!perl/hash:DBIx::Class::ResultSource::Table 
        _columns: 
          content_type: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: text/plain
            is_nullable: 1
            size: 255
          id: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 0
            sequence: bali_wiki_seq
            size: 126
          id_wiki: 
            _ic_dt_method: number
            data_type: NUMBER
            default_value: ~
            is_nullable: 1
            size: 126
          modified_on: 
            _ic_dt_method: date
            _inflate_info: 
              deflate: !!perl/code: '{ "DUMMY" }'
              inflate: !!perl/code: '{ "DUMMY" }'
            data_type: DATE
            default_value: !!perl/ref 
              =: SYSDATE
            is_nullable: 1
            size: 19
          text: 
            _ic_dt_method: clob
            data_type: CLOB
            default_value: ~
            is_nullable: 1
            size: '2147483647'
          username: 
            _ic_dt_method: varchar2
            data_type: VARCHAR2
            default_value: ~
            is_nullable: 1
            size: 255
        _columns_info_loaded: 0
        _ordered_columns: 
          - id
          - text
          - username
          - modified_on
          - content_type
          - id_wiki
        _primaries: &32 
          - id
        _relationships: {}

        _unique_constraints: 
          primary: *32
        name: bali_wiki
        result_class: Baseliner::Model::Baseliner::BaliWiki
        resultset_attributes: {}

        resultset_class: Baseliner::Schema::Baseliner::Base::ResultSet
        schema: *1
        source_name: BaliWiki
        sqlt_deploy_callback: default_sqlt_deploy_hook
    storage: !!perl/hash:DBIx::Class::Storage::DBI::Oracle::Generic 
      _conn_pid: 5784
      _connect_info: 
        - 
          LongReadLen: 100000000
          LongTruncOk: 1
          dsn: dbi:Oracle:host=prusv059;sid=TISH;port=1522
          password: wtscm4
          user: wtscm4
      _dbh: !!perl/hash:DBI::db {}

      _dbh_autocommit: 1
      _dbh_details: 
        capability: 
          _supports_insert_returning: 0
      _dbh_gen: 0
      _dbi_connect_info: 
        - dbi:Oracle:host=prusv059;sid=TISH;port=1522
        - wtscm4
        - wtscm4
        - &42 
          AutoCommit: 1
          LongReadLen: 100000000
          LongTruncOk: 1
          PrintError: 0
          RaiseError: 1
      _dbic_connect_attributes: *42
      _driver_determined: 1
      _in_dbh_do: 0
      _sql_maker: !!perl/hash:DBIx::Class::SQLMaker::Oracle 
        array_datatypes: 1
        bindtype: columns
        cmp: =
        equality_op: !!perl/regexp (?i-xsm:^(\=|is|(is\s+)?like)$)
        inequality_op: !!perl/regexp (?i-xsm:^(!=|<>|(is\s+)?not(\s+like)?)$)
        injection_guard: !!perl/regexp "(?mix-s:\n    \\;\n      |\n    ^ \\s* go \\s\n  )"
        limit_dialect: RowNum
        logic: OR
        name_sep: .
        special_ops: 
          - 
            handler: _where_field_PRIOR
            regex: !!perl/regexp (?i-xsm:^prior$)
          - 
            handler: _where_field_BETWEEN
            regex: !!perl/regexp "(?ix-sm:^ (?: not \\s )? between $)"
          - 
            handler: _where_field_IN
            regex: !!perl/regexp "(?ix-sm:^ (?: not \\s )? in      $)"
          - 
            handler: _where_op_IDENT
            regex: !!perl/regexp (?ix-sm:^ ident $)
        sqlfalse: 0=1
        sqltrue: 1=1
        unary_ops: 
          - 
            handler: _where_op_ANDOR
            regex: !!perl/regexp "(?ix-sm:^ and  (?: [_\\s]? \\d+ )? $)"
          - 
            handler: _where_op_ANDOR
            regex: !!perl/regexp "(?ix-sm:^ or   (?: [_\\s]? \\d+ )? $)"
          - 
            handler: _where_op_NEST
            regex: !!perl/regexp "(?ix-sm:^ nest (?: [_\\s]? \\d+ )? $)"
          - 
            handler: _where_op_BOOL
            regex: !!perl/regexp "(?ix-sm:^ (?: not \\s )? bool     $)"
          - 
            handler: _where_op_IDENT
            regex: !!perl/regexp (?ix-sm:^ ident $)
      _sql_maker_opts: {}

      debugobj: !!perl/hash:DBIx::Class::Storage::Statistics {}

      savepoints: []

      schema: *1
      transaction_depth: 0
  source_moniker: BaliMessage
related_resultsets: 
  bali_message_queues: !!perl/hash:Baseliner::Schema::Baseliner::Base::ResultSet 
    _result_class: Baseliner::Model::Baseliner::BaliMessageQueue
    _source_handle: !!perl/hash:DBIx::Class::ResultSourceHandle 
      schema: *1
      source_moniker: BaliMessageQueue
    attrs: 
      accessor: multi
      alias: me
      cascade_copy: 1
      cascade_delete: 1
      join_type: LEFT
      where: &43 
        me.id_message: 637
    cond: *43
    pager: ~

