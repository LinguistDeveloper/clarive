---
title: YAML
---

YAML es un formato tipado legible por personas usado para la serialización de datos

YAML es el acrónimo recursivo para "Ain't Markup Language".

El siguiente es un ejemplo de YAML para Clarive (de un CI Proyecto):

```yaml
    ---
    active: 1
    assets: []
    created_by: root
    description: ''
    folders:
    -
      active: '1'
      mid: '1495'
      moniker: ~
      name: Old Projects
      ts: 2015-09-22 10:15:41
      versionid: '1'
    mid: '932'
    modified_by: root
    moniker: APLICACION_PRINCIPAL
    name: ComplexApp
    repositories:
    -
      active: 1
      bl: '*'
      created_by: root
      default_branch: HEAD
      description: 'another repository'
      exclude: []
      include: []
      mid: '1220'
      modified_by: root
      moniker: ''
      name: acmebank_cpp
      rel_path: /cpp
      repo_dir: /opt/repo/myrepo.git
      revision_mode: diff
      tags_mode: bl
      ts: 2015-02-15 20:35:17
      versionid: '1'
    ts: 2014-10-16 11:56:04
    variables:
      '*':
        c_compiler_server: '1118'
        files_server: '103'
        files_servers: '1118'
        jboss_server: '103'
        maven_server: '103'
        ruta_despliegue_ficheros: /opt/files
        staging_c_path: /tmp/${project}/cpp
        staging_path: /tmp/${project}/war
        tar_path: /tmp/clarivetar
      DEV:
        jboss_server: '1118'
        var2: optCommon
      TEST:
        c_servers: 1182,1183
        tar_path: /tmp/clarive2
      PREP:
        c_servers: 1184,1185
      PROD:
        c_servers: 1182,1183,1184,1185,1195,1196,1198,1197,1199,1200,1201
      SPECIAL:
        agents_b: '1407'
    versionid: '1'
```

YAML se usa de forma extensiva en Clarive porque permite expresar el
contenido de los datos en formato legible para usuarios técnicos.

YAML también se usa porque permite al sistema el versionado del contenido
de los datos, especialmente CIs, en un fichero del sistema.

Lee más acerca del formato en:

- https://en.wikipedia.org/wiki/YAML
- http://yaml.org/

También, puedes jugar con YAML en el (REPL)[devel/repl] de Clarive o en
esta herramienta online:

http://yaml-online-parser.appspot.com/

### Indentación

En YAML la indentación es importante, YAML usa un esquema de indentación fijada
que representa las diferentes relaciones entre elementos.

```yaml
parent:
   child:
      grandchild: 10
```

En JavaScript, los mapas de debajdo se usan pra el siguiente objeto:

```json
{ parent: { child: { grandchild: 10 } } }
```

En Clarive, la indentación requiere al menos 1 espacio.

### Dos Puntos

Los Dos Puntos representa pares cd clave-valor, que son usados para definir objetos
(Hashes o diccionarios en otros lenguajes).

```yaml
key1: value1
key2: value2
```

Lo que en JavaScript se traduce a:

```js
{ key1: 'value1', key2: 'value2' }
```

### Dashes

Los Dashes son usados para crear listas, o Arrays en Javascript.

```yaml
parent:
   - child1
   - child2
```

En JavaScript, el mapa de debajo muestra el objecto:

```json
{ parent: [ 'child1', 'child2' ] }
```

### Datos Multi-línea

Las cadenas multi-línea se pueden escribir usando la `|` (barra vertical) YAML
operator. Indentation is necessary, so use leading spaces.

```yaml
---
mytext: |
  Long, long,
  multiline text that is
  nicely indented everywhere
  and may start with spaces.
age: 20
```