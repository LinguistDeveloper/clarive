<%init>
use Encode qw( decode_utf8 encode_utf8 is_utf8 );
my $id = $c->stash->{id};
my $id_cal = $c->stash->{id_cal};
my $panel = $c->stash->{panel};
my $dia = $c->stash->{dia};
my $activa = $c->stash->{activa};
my $inicio = $c->stash->{inicio};
my $fin = $c->stash->{fin};
my $tipo = $c->stash->{tipo};
my $date = $c->stash->{date};
my $title = 'Editar ventana';
$title = 'Editar ventana para el ' . $date if($date);

my $loc = DateTime::Locale->load("es_ES"); 
my $day_wide = $loc->day_format_wide;
my $from_to_1 = _loc("From %1 to %2", $day_wide->[0], $day_wide->[4]);
my $from_to_2 = _loc("From %1 to %2", $day_wide->[0], $day_wide->[6]);

sub capitalize { return uc(substr($_[0],0,1)).substr($_[0],1) }

my @ven_dia;
my @ven_ini;
my @ven_fin;

# ven_dia
foreach my $dd ( 0..6 ) {
    my $day_name = capitalize( $day_wide->[ $dd ] );
    push @ven_dia, [ $dd , $day_name  ];
}

# Eric -- Calculamos hh y mm de las fechas de inicio y fin. Hay que evitar que el
# usuario pueda crear ventanas más fuera del rango actual.
#  rgo - we dont care about that anymore - thanks to slot merging

# ven_ini
for(my $hh=0; $hh<=23; $hh++) {
    for(my $mm=0; $mm<59; $mm+=30) {
        my $hora = sprintf("%02d:%02d", $hh, $mm);
        my $hora_corta = sprintf("%d:%02d", $hh, $mm);
        push @ven_ini, [ $hora, $hora_corta  ];
    }
}

# ven_fin
for(my $hh=0; $hh<=24; $hh++) {
    for(my $mm=0; $mm<59; $mm+=30) {
        last if( $hh==24 && $mm==30 );
        my $hora = sprintf("%02d:%02d", $hh, $mm);
        my $hora_corta = sprintf("%d:%02d", $hh, $mm);
        push @ven_fin, [ $hora, $hora_corta  ];
    }
}

</%init>
(function(){

    var modify_window = function(cmd) {
        var form = fpanel.getForm();
        //alert( cmd + "=" + form.findField('ven_ini').getValue() );
        var ini = form.findField('ven_ini').getValue().substring(0,2) + form.findField('ven_ini').getValue().substring(3,5);
        var fin = form.findField('ven_fin').getValue().substring(0,2) + form.findField('ven_fin').getValue().substring(3,5);
        if( ini >= fin ) {
            Ext.Msg.alert("Error", "La hora fin es igual o superior a la hora de inicio (" +ini+ " < " +fin+ ")" ); // ">
            return false;
        }
        /* if( cmd=="B" && form.findField('ven_tipo').getValue()=="X" ) {
            Ext.Msg.alert("Aviso", "Las ventanas cerradas no necesitan borrarse")
            return false;
        } */
        form.findField('cmd').setValue(cmd);
        form.submit({
            clientValidation: true,
            success: function(form, action) {
                //Ext.Msg.alert("Success", action.result.msg);
                var pan = Ext.get('<% $panel %>');
                var upd = pan.getUpdater();
                upd.update( { 
                    url: '/job/calendar_slots', params: { id_cal: '<% $id_cal %>', panel: '<% $panel %>'  }, scripts: true ,
                    callback: function(el,success,res,opt){
                        // Eric -- Esto peta y no parece muy importante. No encuentra el método .setTitle
                        // pan.setTitle(_loc('Calendar Windows'));
                    }
                });
                win.close();
            },
            failure: function(form, action) {
                //var upd = Ext.get('<% $panel %>').getUpdater() ;
                //upd.update( { url: '/job/calendar_slots',  params: { id_cal: '<% $id_cal %>', panel: '<% $panel %>' }, scripts: true });
                //Ext.get('<% $panel %>').doLayout();
                Ext.Msg.show({ title: "<% _loc('Failure') %>", msg: action.result.msg, width: 500, buttons: { ok: true } });
            }
        });
    }
    var ven_dia_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( [ @ven_dia ] ) %>
    }); 
    var tpl_type = new Ext.XTemplate(
        '<tpl for=".">',
            '<div class="search-item"><table><tr><td class="slot_{value}" width="20" height="20">&nbsp</td><td style="font-size:13px">{name}</td></tr></table></div>',
        '</tpl>'
    );
    var ven_tipo_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( [ ['N', _loc('Normal') ],[ 'U', _loc('Urgent') ] ,[ 'X', _loc('No Job') ] ] ) %>
    }); 
    var ven_ini_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( [ @ven_ini ] ) %>
    }); 
    var ven_fin_store = new Ext.data.SimpleStore({ 
       fields: ['value', 'name'], 
       data : <% js_dumper( [ @ven_fin ] ) %>
    }); 
    
% if ( $c->stash->{not_found} ) {
     //   Ext.get("calform").createChild({tag: 'h2', html: 'Ventana con ID=<% $id %> no existe.'});
% } else {
    var fpanel = new Ext.FormPanel({
        frame: true,
        url: '/job/calendar_submit', 
        buttons: [
%if($c->stash->{create}){		
            {  icon:'/static/images/icons/calendar_add.png', text: 'Crear Ventana', handler: function(){ modify_window('A') } }
            ,{ icon:'/static/images/icons/cerrar.png', text: 'Crear Inactiva', handler: function(){ modify_window('AD') } }
%} else {
            {  icon:'/static/images/icons/calendar_edit.png', text: 'Modificar Ventana', handler: function(){ modify_window('A') } }

%}
% unless( $c->stash->{create} ) { #las ventanas cerradas no se borran 
            ,{  icon:'/static/images/icons/calendar_delete.png', text: 'Borrar', handler: function(){ modify_window('B') } }
%   if( $activa ) {
            ,{ icon:'/static/images/icons/cerrar.png', text: 'Desactivar (No pase)', handler: function(){  modify_window('C0')   } }
%   } else {
            ,{ icon:'/static/images/icons/checkbox.png', text: 'Activar (Ventana)', handler: function(){  modify_window('C1')   } }
% 	}
% }
            ,{ icon:'/static/images/icons/clear.png',  text: 'Cancelar', handler: function(){ win.close(); } }
        ],
        items: [
            {  xtype: 'hidden', name: 'id', value: '<% $id %>' },
            {  xtype: 'hidden', name: 'id_cal', value: '<% $id_cal %>' },
            {  xtype: 'hidden', name: 'cmd' },
            {  xtype: 'combo', 
                       name: 'ven_dia', 
                       hiddenName: 'ven_dia',
                       fieldLabel: 'Dia', 
                       mode: 'local', 
                       editable: false,
                       //disabled: true,
                       forceSelection: true,
                       triggerAction: 'all',
                       store: ven_dia_store, 
                       valueField: 'value',
                       displayField:'name', 
                       value: '<% $dia %>',					   
                       allowBlank: false,
                       width: 150 
            },
            {  xtype: 'combo', 
                       name: 'ven_tipo', 
                       hiddenName: 'ven_tipo',
                       fieldLabel: _loc('Type'), 
                       mode: 'local', 
                       editable: false,
                       forceSelection: true,
                       triggerAction: 'all',
                       store: ven_tipo_store, 
                       tpl: tpl_type,
                       itemSelector: 'div.search-item',
                       valueField: 'value',
                       displayField:'name', 
                       value: '<% $tipo %>',
                       allowBlank: false,
                       width: 150 
            },
            {  xtype: 'combo', 
                       name: 'ven_ini', 
                       hiddenName: 'ven_ini',
                       fieldLabel: _loc('Starts at'), 
                       mode: 'local', 
                       editable: false,
                       forceSelection: true,
                       triggerAction: 'all',
                       store: ven_ini_store, 
                       valueField: 'value',
                       displayField:'name', 
                       value: '<% $inicio %>',
                       allowBlank: false,
                       width: 150 
            },
            {  xtype: 'combo', 
                       name: 'ven_fin', 
                       hiddenName: 'ven_fin',
                       fieldLabel: _loc('Ends at'), 
                       mode: 'local', 
                       editable: false,
                       forceSelection: true,
                       triggerAction: 'all',
                       store: ven_fin_store, 
                       valueField: 'value',
                       displayField:'name', 
                       value: '<% $fin %>',
                       allowBlank: false,
                       width: 150 
           },
            {  xtype: 'textfield', 
                       name: 'date', 
                       fieldLabel: _loc('Date'), 
                       readOnly: true,
                       style: { 'color' : '#ccc' },
                       hidden: <% length $date ? 'false' : 'true' %>,
                       value: '<% $date %>',
                       displayField:'date', 
                       width: 150 
           }		   
        ]
    });
    var win = new Ext.Window({
        layout: 'fit',
        height: 230, width: 500,
        title: '<% $title %>',
        items: fpanel
    });
    return win;
% }
})();

