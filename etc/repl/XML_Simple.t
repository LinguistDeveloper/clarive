use Data::Dumper;
use XML::Simple;

my $VAR1 = {
          'version' => '2441',
          'cpt' => {
                   'first' => {
                              'nom' => '',
                              'type' => '0',
                              'cpt' => {
                                       '99000' => {
                                                  'nom' => 'Teleproceso',
                                                  'type' => '0',
                                                  'cpt' => {
                                                           '80001' => {
                                                                      'nom' => "Administraci\x{f3}n TP",
                                                                      'trans' => {
                                                                                 '80002' => {
                                                                                            'text' => [
                                                                                                      'Cambio de oficina'
                                                                                                    ],
                                                                                            'cont' => [
                                                                                                    ],
                                                                                            'tp' => '0',
                                                                                            'offline' => [
                                                                                                         'False'
                                                                                                       ],
                                                                                            'v' => [
                                                                                                   '11'
                                                                                                 ],
                                                                                            'cint' => [
                                                                                                      'T80002'
                                                                                                    ]
                                                                                          },
                                                                                 '80004' => {
                                                                                            'text' => [
                                                                                                      'Datos de la oficina'
                                                                                                    ],
                                                                                            'cont' => [
                                                                                                      {}
                                                                                                    ],
                                                                                            'tp' => '0',
                                                                                            'offline' => [
                                                                                                         'False'
                                                                                                       ],
                                                                                            'v' => [
                                                                                                   '19'
                                                                                                 ],
                                                                                            'cint' => [
                                                                                                      'T00301'
                                                                                                    ]
                                                                                          }
                                                                               },
                                                                      'type' => '0',
                                                                      'cpt' => {
                                                                               '80100' => {
                                                                                          'nom' => 'Radiado',
                                                                                          'trans' => {
                                                                                                     '98005' => {
                                                                                                                'text' => [
                                                                                                                          "Oficinas asignadas a un c\x{f3}digo postal"
                                                                                                                        ],
                                                                                                                'cont' => [
                                                                                                                          {}
                                                                                                                        ],
                                                                                                                'tp' => '0',
                                                                                                                'offline' => [
                                                                                                                             'False'
                                                                                                                           ],
                                                                                                                'v' => [
                                                                                                                       '11'
                                                                                                                     ],
                                                                                                                'cint' => [
                                                                                                                          'T00113'
                                                                                                                        ]
                                                                                                              }
                                                                                                   },
                                                                                          'type' => '0'
                                                                                        }
                                                                             }
                                                                    }
                                                         }
                                                },
                                       '99001' => {
                                                  'nom' => 'Favoritos',
                                                  'type' => '2'
                                                },
                                       '99007' => {
                                                  'nom' => 'TPnet',
                                                  'type' => '0',
                                                  'cpt' => {
                                                           '60000' => {
                                                                      'nom' => 'Operaciones internas',
                                                                      'trans' => {
                                                                                 '25002' => {
                                                                                            'visible' => [
                                                                                                         'False'
                                                                                                       ],
                                                                                            'tp' => '4',
                                                                                            'v' => [
                                                                                                   '1'
                                                                                                 ],
                                                                                            'cint' => [
                                                                                                      'COFOP'
                                                                                                    ],
                                                                                            'allowed' => 'true',
                                                                                            'text' => [
                                                                                                      'Cambio oficina java'
                                                                                                    ],
                                                                                            'cont' => [
                                                                                                      {}
                                                                                                    ],
                                                                                            'offline' => [
                                                                                                         'False'
                                                                                                       ]
                                                                                          },
                                                                                 '25001' => {
                                                                                            'visible' => [
                                                                                                         'False'
                                                                                                       ],
                                                                                            'tp' => '4',
                                                                                            'v' => [
                                                                                                   '1'
                                                                                                 ],
                                                                                            'cint' => [
                                                                                                      'INITOP'
                                                                                                    ],
                                                                                            'allowed' => 'true',
                                                                                            'text' => [
                                                                                                      'Inicio Java'
                                                                                                    ],
                                                                                            'cont' => [
                                                                                                      {}
                                                                                                    ],
                                                                                            'offline' => [
                                                                                                         'False'
                                                                                                       ]
                                                                                          }
                                                                               },
                                                                      'allowed' => 'true',
                                                                      'type' => '0'
                                                                    }
                                                         }
                                                }
                                     }
                            }
                 }
        };
my $XML1 = new XML::Simple ( ForceArray => [ qw(text cint cont offline v visible) ], 'KeyAttr'=>{'cpt'=>'id','trans'=>'id'}, SuppressEmpty => undef);
my $XML2 = new XML::Simple ( ForceArray => [ qw(text cint cont offline v visible) ], 'KeyAttr'=>{'cpt'=>'id','trans'=>'id'}, SuppressEmpty => 1);

my $order = {"cpt"=>{"id", "nom", "allowed", "type", "cpt", "trans"}, "trans"=>{"id", "tp", "allowed", "text", "cint", "cont", "offline", "v", "visible", "param"}};
print Dumper($order);

my $data1 = $XML1->XMLout($VAR1, XMLDecl=>'<?xml version="1.0" encoding="utf-8"?>', KeepRoot=>'true');
print Dumper($data1);

my $data2 = $XML2->XMLout($VAR1, XMLDecl=>'<?xml version="1.0" encoding="utf-8"?>', KeepRoot=>'true');
print Dumper($data2);

__END__
$VAR1 = {
          'trans' => {
                       'visible' => 'param',
                       'allowed' => 'text',
                       'offline' => 'v',
                       'id' => 'tp',
                       'cint' => 'cont'
                     },
          'cpt' => {
                     'allowed' => 'type',
                     'cpt' => 'trans',
                     'id' => 'nom'
                   }
        };
$VAR1 = '<?xml version="1.0" encoding="utf-8"?>
<opt version="2441">
  <cpt id="first" nom="" type="0">
    <cpt id="99000" nom="Teleproceso" type="0">
      <cpt id="80001" nom="AdministraciÃ³n TP" type="0">
        <cpt id="80100" nom="Radiado" type="0">
          <trans id="98005" tp="0">
            <cint>T00113</cint>
            <cont></cont>
            <offline>False</offline>
            <text>Oficinas asignadas a un cÃ³digo postal</text>
            <v>11</v>
          </trans>
        </cpt>
        <trans id="80002" tp="0">
          <cint>T80002</cint>
          <offline>False</offline>
          <text>Cambio de oficina</text>
          <v>11</v>
        </trans>
        <trans id="80004" tp="0">
          <cint>T00301</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Datos de la oficina</text>
          <v>19</v>
        </trans>
      </cpt>
    </cpt>
    <cpt id="99001" nom="Favoritos" type="2" />
    <cpt id="99007" nom="TPnet" type="0">
      <cpt id="60000" allowed="true" nom="Operaciones internas" type="0">
        <trans id="25001" allowed="true" tp="4">
          <cint>INITOP</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Inicio Java</text>
          <v>1</v>
          <visible>False</visible>
        </trans>
        <trans id="25002" allowed="true" tp="4">
          <cint>COFOP</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Cambio oficina java</text>
          <v>1</v>
          <visible>False</visible>
        </trans>
      </cpt>
    </cpt>
  </cpt>
</opt>
';
$VAR1 = '<?xml version="1.0" encoding="utf-8"?>
<opt version="2441">
  <cpt id="first" nom="" type="0">
    <cpt id="99000" nom="Teleproceso" type="0">
      <cpt id="80001" nom="AdministraciÃ³n TP" type="0">
        <cpt id="80100" nom="Radiado" type="0">
          <trans id="98005" tp="0">
            <cint>T00113</cint>
            <cont></cont>
            <offline>False</offline>
            <text>Oficinas asignadas a un cÃ³digo postal</text>
            <v>11</v>
          </trans>
        </cpt>
        <trans id="80002" tp="0">
          <cint>T80002</cint>
          <offline>False</offline>
          <text>Cambio de oficina</text>
          <v>11</v>
        </trans>
        <trans id="80004" tp="0">
          <cint>T00301</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Datos de la oficina</text>
          <v>19</v>
        </trans>
      </cpt>
    </cpt>
    <cpt id="99001" nom="Favoritos" type="2" />
    <cpt id="99007" nom="TPnet" type="0">
      <cpt id="60000" allowed="true" nom="Operaciones internas" type="0">
        <trans id="25001" allowed="true" tp="4">
          <cint>INITOP</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Inicio Java</text>
          <v>1</v>
          <visible>False</visible>
        </trans>
        <trans id="25002" allowed="true" tp="4">
          <cint>COFOP</cint>
          <cont></cont>
          <offline>False</offline>
          <text>Cambio oficina java</text>
          <v>1</v>
          <visible>False</visible>
        </trans>
      </cpt>
    </cpt>
  </cpt>
</opt>
';

1
