---
title: YAML
---

YAML is a human-readable markup format
used for data serialization.

YAML is a recursive acronym for
"YAML Ain't Markup Language".

The following is an example of a YAML from Clarive (from a Project CI):

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

YAML is used extensively in Clarive
because it allows for expressing
data contents in a human-readable format
that is familiar to the technical user.

YAML is also used because it allows the
system to version data contents,
specially CIs, in a file system.

Read more about the format here:

- https://en.wikipedia.org/wiki/YAML
- http://yaml.org/

Also, you can play with YAML in Clarive's (REPL)[devel/repl]
or at this online tool:

http://yaml-online-parser.appspot.com/

### Indentation

In YAML indentation is important, YAML uses a
fixed indentation scheme which represents different relationship
between elements.

```yaml
parent:
   child:
      grandchild: 10
```

In JavaScript, the above maps to the following Object:

```json
{ parent: { child: { grandchild: 10 } } }
```

In Clarive, indentation requires at least 1 space.

### Colons

Colons represent key-value pairs, which are used
to define Objects (Hashes or Dictionaries in other languages).

```yaml
key1: value1
key2: value2
```

Which in JavaScript translates to:

```js
{ key1: 'value1', key2: 'value2' }
```

### Dashes

Dashes are used for creating lists, or Arrays in Javascript.

```yaml
parent:
   - child1
   - child2
```

In JavaScript, the above maps to the following Object:

```json
{ parent: [ 'child1', 'child2' ] }
```

### Multi-line data

Multi-line strings can be written using the `|` (pipe)
YAML operator. Indentation is necessary, so use leading spaces.

```yaml
---
mytext: |
  Long, long,
  multiline text that is
  nicely indented everywhere
  and may start with spaces.
age: 20
```


