(function(){

    /*!
    * Ext JS Library 3.3.1
    * Copyright(c) 2006-2010 Sencha Inc.
    * licensing@sencha.com
    * http://www.sencha.com/license
    */

    Ext.ns('Ext.ux.form');

    Ext.ux.form.SearchField = Ext.extend(Ext.form.TwinTriggerField, {
        initComponent : function(){
            Ext.ux.form.SearchField.superclass.initComponent.call(this);
            this.on('specialkey', function(f, e){
                if(e.getKey() == e.ENTER){
                    this.onTrigger2Click();
                }
            }, this);
        },

        validationEvent:false,
        validateOnBlur:false,
        trigger1Class:'x-form-clear-trigger',
        trigger2Class:'x-form-search-trigger',
        hideTrigger1:true,
        width:180,
        hasSearch : false,
        paramName : 'query',

        onTrigger1Click : function(){
            if(this.hasSearch){
                this.el.dom.value = '';
                var o = {start: 0};
                this.store.baseParams = this.store.baseParams || {};
                this.store.baseParams[this.paramName] = '';
                this.store.reload({params:o});
                this.triggers[0].hide();
                this.hasSearch = false;
            }
        },

        onTrigger2Click : function(){
            var v = this.getRawValue();
            if(v.length < 1){
                this.onTrigger1Click();
                return;
            }
            var o = {start: 0};
            this.store.baseParams = this.store.baseParams || {};
            this.store.baseParams[this.paramName] = v;
            this.store.reload({params:o});
            this.hasSearch = true;
            this.triggers[0].show();
        }
    });

    function change(val){
        if(val > 0){
            return '<span style="color:green;">' + val + '</span>';
        }else if(val < 0){
            return '<span style="color:red;">' + val + '</span>';
        }
        return val;
    }

    function change_red(val){
		return '<span style="color:red;">' + val + '</span>';
    }

	var densidad = function(v,m,r,i,col,store) {
 		return Ext.util.Format.number( v, '0.000,00/i');
    };
	var kb_rend = function(v,m,r,i,col,store) {
		var mkb = 1024;
		var kb  = v < mkb ? '< 1 KB' : Ext.util.Format.number( v/mkb, '0.000,00/i');
		return kb;
	};

	var mb_rend = function(v,m,r,i,col,store) {
		var mkb = 1024 * 1024;
		var mb  = v < mkb ? '< 1 MB' : Ext.util.Format.number( v/mkb, '0.000,00/i') + ' MB';
		return mb;
	};

	var mistore=new Ext.data.JsonStore({
		root:          'data' , 
		remoteSort:    true,
		totalProperty: "totalCount", 
		id:            'id', 
		url:           '/espacio/load',
		fields: [ 
		    { name : 'versions_test'   },
            { name : 'versions_ante'   },
            { name : 'repsize'         },
            { name : 'versions_r'      },
            { name : 'versions'        },
            { name : 'envisactive'     },
            { name : 'ts2'             },
            { name : 'envobjid'        },
            { name : 'ts'              },
            { name : 'cam'             },
            { name : 'versions_prod'   },
            { name : 'densidad'        },
            { name : 'isarchive'       },
            { name : 'versions_high'   },
            { name : 'environmentname' },
            { name : 'items'           }
		]
	});
	
	var grid = new Ext.grid.GridPanel({
        title           : 'Informe de Espacio',
        header          : false,
        stripeRows      : true,
        autoScroll      : true,
        autoWidth       : true,
        store           : mistore,
        autoSizeColumns : true,
        deferredRender  : true,
        height          : 300,
        selModel        : new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask        : 'true',
        wait            : 'Loading...',
        columns: [
            { header : _('Proyecto'),        width : 150, dataIndex : 'environmentname', sortable : true                                         },
            { header : _('Espacio Ocupado'), width : 150, dataIndex : 'repsize',         sortable : true, renderer : mb_rend                     },
            { header : _('Actualizado'),     width : 75,  dataIndex : 'ts2',             sortable : true                                         },
            { header : _('Items'),           width : 75,  dataIndex : 'items',           sortable : true, renderer : change                      },
            { header : _('Densidad'),        width : 80,  dataIndex : 'densidad',        sortable : true, renderer : change, renderer : densidad },
            { header : _('Vers. >50'),       width : 75,  dataIndex : 'versions_high',   sortable : true, renderer : change                      },
            { header : _('V. TEST'),         width : 75,  dataIndex : 'versions_test',   sortable : true, renderer : change                      },
            { header : _('V. ANTE'),         width : 75,  dataIndex : 'versions_ante',   sortable : true, renderer : change                      },
            { header : _('V. PROD'),         width : 75,  dataIndex : 'versions_prod',   sortable : true, renderer : change                      },
            { header : _('Reservados'),      width : 75,  dataIndex : 'versions_r',      sortable : true, renderer : change_red                  },
            { header : _('Versiones Total'), width : 99,  dataIndex : 'versions',        sortable : true, renderer : change                      }
        ],
        tbar: [ 
            new Ext.ux.form.SearchField ({
                store: mistore,
                params: {start: 0, limit: 100},
                emptyText: 'Filtro por proyecto...'
            }),
          	new Ext.Toolbar.Button({
                text: 'Ver Historico',
                enableToggle: true,
                pressed: false,
                toggleHandler: function(item,pressed) {
                    ver_historico = pressed;
                    mistore.load({  params: { hist: ver_historico } });
                }
            }),
            new Ext.Toolbar.Button({
                text: 'Ver Totales',
                handler: function() {
                    var win = new Ext.Window({
                        title: 'Totales',
                        width: 500,
                        height: 200,
                        autoScroll: true,
                        closeAction: "close",
                        resizable: true,
                        layout: "fit",
                        autoLoad: "espacio/load_total"
                    });
                    win.show();
                }
            })
        ],
        bbar: new Ext.PagingToolbar({
            store:       mistore,
            pageSize:    9999999,
            displayInfo: true,
            displayMsg:  'Rows {0} - {1} of {2}',
            emptyMsg:    "No hay registros disponibles"
        })
	});

    var store_path = new Ext.data.JsonStore({
		root          : 'data',
		remoteSort    : true,
		totalProperty : "totalCount",
		id            : "rownum",
		url           : "espacio/load_path",
        fields: [
           { name : 'path'    },
           { name : 'espacio' }
        ]
    });
	store_path.on("exception", function(proxy,type,action,options,res,arg) {
		try { Ext.Msg.alert('Error en la carga', res.raw.message ); } 
		catch(e) {  Ext.Msg.alert( "Error desconocido", res.responseText ) }
	});    

    // Cuando haglo click llamo a store_path y le paso el project
	grid.on("rowdblclick", function(grid, rowIndex, e ) {
		var row = grid.getStore().getAt( rowIndex );
		var project = row.get("environmentname");
		var grid_path = new Ext.grid.GridPanel({
			store: store_path,
			columns: [
				{id: 'path',    header: 'Path',                 width: 150, sortable: true,                dataIndex: 'path'                       },
				{id: 'espacio', header: 'Espacio Ocupado (KB)', width: 150, sortable: true, align:'right', dataIndex: 'espacio', renderer: kb_rend }
			],
			bbar: new Ext.PagingToolbar({
				store       : store_path,
				pageSize    : 9999999,
				displayInfo : true, 
				displayMsg  : "Registros {0} - {1} de {2}",
				emptyMsg    : "No hay registros disponibles"
			}),
			stripeRows       : true,
			autoExpandColumn : 'path',
			autoSizeColumns  : true,
			loadMask         : true,
			wait             : 'Cargando...',
			height           : 650,
			width            : 1100,
			stateful         : true,
			stateId          : 'grid-path'        
		});
		var win_path = new Ext.Window({
			title       : 'Informe de Espacio por Path (' + project + ')',
			width       : 1000,
			height      : 400,
			autoScroll  : true,
			closeAction : "close",
			resizable   : true,
			maximizable : true,
			layout      : "fit",
			items       : grid_path
		});
		win_path.show();
		store_path.load({ params: { project: project } });
	});
		
	mistore.load();

	return grid;
})()
