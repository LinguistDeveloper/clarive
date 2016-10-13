---
title: MongoDB
index: 250
icon: page
---

## Recommendations

As highlighted in the architecture
considerations document, we recommend
MongoDB to be installed in a separate
machine from the Clarive Server, as
that helps improve overall performance
and better share the available resources
in between machines.

## Installation

The steps needed to install MongoDB are:

- Download the archive for your operating system
- Untar/uncompress files and move them to their definitive location
- Edit the configuration file
- Start the database

### Download

First, download the MongoDB installation binaries for
your operating system from the following locations:

#### Windows

[Windows 64-bit](https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-3.2.4-signed.msi)

#### Mac OS X

[Mac OS X](https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-3.2.4.tgz)

#### Linux

- [RHEL 5 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel55-3.2.4.tgz)
- [RHEL 6 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.4.tgz)
- [RHEL 7 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.4.tgz)
- [SUSE 11 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-suse11-3.2.4.tgz)
- [SUSE 12 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-suse12-3.2.4.tgz)
- [Debian 7 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian71-3.2.4.tgz)
- [Ubuntu 12.04 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1204-3.2.4.tgz)
- [Ubuntu 14.04 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1404-3.2.4.tgz)
- [Ubuntu 14.04 Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1404-3.2.4.tgz)
- [Ubuntu 14.10 Clang 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1410-clang-3.2.4.tgz)
- [Legacy Linux 64-bit](https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-3.2.4.tgz)

## Mongo Server Configuration

To configure MongoDB, open the `mongod.conf`
file located in your `CLARIVE_BASE/config` directory.

This file contains the standard product configuration,
please do not change any parameters not mentioned in this
documentation as that may void your service/maintenance contract
or unless requested by your Clarive Support Representative.

Contents of the `mongod.conf` file:

```
dbpath=/opt/clarive/data/mongo
logpath=/opt/clarive/logs/mongod.log
pidfilepath=/opt/clarive/logs/mongod.pid
fork=true
bindIp=127.0.0.1
port=27017
logappend=true
setParameter=failIndexKeyTooLong=false
storageEngine=wiredTiger
```

### `bindIp`

This is the IP address the MongoDB database daemon will
listen for incoming connections. If this is a MongoDB
instance that has been installed exclusively for use
with Clarive, either:

- **do not** bind to IP addresses that are accessible by
your corporate network or the internet at large! If possible, choose
an IP address that is only available at the cluster level.
- setup a firewall that limits access to the Mongo Server


### `port`

The port is the network port the Mongo database daemon
listens for connections from the Clarive Server.

Remember, if you change the port here, you need to
modify the Clarive Server configuration file port.

### `dbpath`

This is the path to the directory where
the Mongo database files will reside.

The files in this directory can require extensive disk
space as your Clarive usage grows. Disk use and file sizes
depend highly on system usage, number of jobs, artifacts
generated and other factors, but can reach many GB quickly.

Please plan accordingly as lack of database disk space
**may disrupt Clarive Server service and could cause severe
data loss**.

By default, this value is set to `CLARIVE_BASE/data/mongo`.

### `logpath`

This is the path to the directory where
all Mongo log files are stored.

Plan for moderate space requirements, typically
around 1GB.

### `pidfilepath`

Path to the file that indicates if the database
is started or not.

You may change this to any location on the server
to fit your installation needs, but we recommend
setting it to either the `CLARIVE_BASE/logs/` or
`CLARIVE_HOME/data/` directories.

## Clarive Mongo Configuration

Here are the Clarive `[env].yml` file
configuration entries that control
the connection from Clarive to MongoDB.

```yaml
mongo:
    dbname: acmebank
    retry_frequency: 5
    max_retries: 60
    client:
        host: 'localhost:27017'
        username: myuser
        password: mypassword
        auto_reconnect: 1
        query_timeout: -1
        #auto_connect: 1
        #host: 'mongodb://localhost:27017,localhost2:27018'
        #w
        #wtimeout
        #j
        #timeout: 20000
        #db_name
        #max_bson_size
        #find_master: 1
        #ssl
        #sasl
        #sasl_mechanism
        #dt_type
        #inflate_dbrefs: 1
```

Options:

#### `dbname`

The database name.

#### `host`

The host attribute specifies either a single server to connect to (as hostname
or hostname:port), or else a connection string URI with a seed list of one or
more servers plus connection options.

Defaults to the connection string URI mongodb://localhost:27017.

#### `auth_mechanism`

This attribute determines how the client authenticates with the server. Valid values are:

    NONE
    DEFAULT
    MONGODB-CR
    MONGODB-X509
    GSSAPI
    PLAIN
    SCRAM-SHA-1

If not specified, then if no username is provided, it defaults to NONE. If a
username is provided, it is set to DEFAULT, which chooses SCRAM-SHA-1 if
available or MONGODB-CR otherwise.

This may be set in a connection string with the authMechanism option.

#### `auth_mechanism_properties`

This is an optional hash reference of authentication mechanism specific
properties. See "AUTHENTICATION" for details.

This may be set in a connection string with the authMechanismProperties option.
If given, the value must be key/value pairs joined with a ":". Multiple pairs
must be separated by a comma. If ": or "," appear in a key or value, they must
be URL encoded.

#### `connect_timeout_ms`

This attribute specifies the amount of time in milliseconds to wait for a new
connection to a server.

The default is 10,000 ms.

If set to a negative value, connection operations will block indefinitely until
the server replies or until the operating system TCP/IP stack gives up (e.g. if
the name can't resolve or there is no process listening on the target
host/port).

A zero value polls the socket during connection and is thus likely to fail
except when talking to a local process (and perhaps even then).

This may be set in a connection string with the connectTimeoutMS option.

#### `db_name`

Optional. If an "auth_mechanism" requires a database for authentication, this
attribute will be used. Otherwise, it will be ignored. Defaults to "admin".

This may be provided in the connection string URI as a path between the
authority and option parameter sections. For example, to authenticate against
the "admin" database (showing a configuration option only for illustration):

    mongodb://localhost/admin?readPreference=primary

#### `heartbeat_frequency_ms`

The time in milliseconds (non-negative) between scans of all servers to check
if they are up and update their latency. Defaults to 60,000 ms.

This may be set in a connection string with the heartbeatFrequencyMS option.

#### `j`

If true, the client will block until write operations have been committed to
the server's journal. Prior to MongoDB 2.6, this option was ignored if the
server was running without journaling. Starting with MongoDB 2.6, write
operations will fail if this option is used when the server is running without
journaling.

This may be set in a connection string with the journal option as the strings
'true' or 'false'.

#### `local_threshold_ms`

The width of the 'latency window': when choosing between multiple suitable
servers for an operation, the acceptable delta in milliseconds (non-negative)
between shortest and longest average round-trip times. Servers within the
latency window are selected randomly.

Set this to "0" to always select the server with the shortest average round
trip time. Set this to a very high value to always randomly choose any known
server.

Defaults to 15 ms.

This may be set in a connection string with the localThresholdMS option.

#### `max_time_ms`

Specifies the maximum amount of time in (non-negative) milliseconds that the
server should use for working on a database command. Defaults to 0, which
disables this feature. Make sure this value is shorter than socket_timeout_ms.

Note: this will only be used for server versions 2.6 or greater, as that was
when the $maxTimeMS meta-operator was introduced.

You are strongly encouraged to set this variable if you know your environment
has MongoDB 2.6 or later, as getting a definitive error response from the
server is vastly preferred over a getting a network socket timeout.

This may be set in a connection string with the maxTimeMS option.

#### `password`

If an "auth_mechanism" requires a password, this attribute will be used.
Otherwise, it will be ignored.

This may be provided in the connection string URI as a username:password pair
in the leading portion of the authority section before a @ character. For
example, to authenticate as user "mulder" with password "trustno1":

    mongodb://mulder:trustno1@localhost If the username or password have a ":"
    or "@" in it, they must be URL encoded. An empty password still requires a
    ":" character.

#### `port`

If a network port is not specified as part of the host attribute, this
attribute provides the port to use. It defaults to 27107.

#### `read_pref_mode`

The read preference mode determines which server types are candidates for a
read operation. Valid values are:

    primary
    primaryPreferred
    secondary
    secondaryPreferred
    nearest

For core documentation on read preference see
http://docs.mongodb.org/manual/core/read-preference/.

This may be set in a connection string with the readPreference option.

#### `read_pref_tag_sets`

The read_pref_tag_sets parameter is an ordered list of tag sets used to
restrict the eligibility of servers, such as for data center awareness. It must
be an array reference of hash references.

The application of read_pref_tag_sets varies depending on the read_pref_mode
parameter. If the read_pref_mode is 'primary', then read_pref_tag_sets must not
be supplied.

For core documentation on read preference see
http://docs.mongodb.org/manual/core/read-preference/.

This may be set in a connection string with the readPreferenceTags option. If
given, the value must be key/value pairs joined with a ":". Multiple pairs must
be separated by a comma. If ": or "," appear in a key or value, they must be
URL encoded. The readPreferenceTags option may appear more than once, in which
case each document will be added to the tag set list.

#### `replica_set_name`

Specifies the replica set name to connect to. If this string is non-empty, then
the topology is treated as a replica set and all server replica set names must
match this or they will be removed from the topology.

This may be set in a connection string with the replicaSet option.

#### `server_selection_timeout_ms`

This attribute specifies the amount of time in milliseconds to wait for a
suitable server to be available for a read or write operation. If no server is
available within this time period, an exception will be thrown.

The default is 30,000 ms.


This may be set in a connection string with the serverSelectionTimeoutMS
option.

#### `server_selection_try_once`

This attribute controls whether the client will make only a single attempt to
find a suitable server for a read or write operation. The default is true.

When true, the client will not use the server_selection_timeout_ms. Instead, if
the topology information is stale and needs to be checked or if no suitable
server is available, the client will make a single scan of all known servers to
try to find a suitable one.

When false, the client will continually scan known servers until a suitable
server is found or the serverSelectionTimeoutMS is reached.

This may be set in a connection string with the serverSelectionTryOnce option.

#### `socket_check_interval_ms`

If a socket to a server has not been used in this many milliseconds, an
ismaster command will be issued to check the status of the server before
issuing any reads or writes. Must be non-negative.

The default is 5,000 ms.

This may be set in a connection string with the socketCheckIntervalMS option.

#### `socket_timeout_ms`

This attribute specifies the amount of time in milliseconds to wait for a reply
from the server before issuing a network exception.

The default is 30,000 ms.

If set to a negative value, socket operations will block indefinitely until the
server replies or until the operating system TCP/IP stack gives up.

A zero value polls the socket for available data and is thus likely to fail
except when talking to a local process (and perhaps even then).

This may be set in a connection string with the socketTimeoutMS option.

#### `ssl`

This tells the driver that you are connecting to an SSL mongodb instance.

If SSL_ca_file is not provided, server certificates are verified against a
default list of CAs, ie. operating-system-specific default
CA file. To disable verification, you can use SSL_verify_mode => 0x00.

You are strongly encouraged to use your own CA file for increased security.

Server hostnames are also validated against the CN name in the server
certificate using SSL_verifycn_scheme => 'http'. You can use the scheme 'none'
to disable this check.

Disabling certificate or hostname verification is a security risk and is not
recommended.

This may be set to the string 'true' or 'false' in a connection string with the
ssl option, which will enable ssl with default configuration. (A future version
of the driver may support customizing ssl via the connection string.)

#### `username`

Optional username for this client connection. If this field is set, the client
will attempt to authenticate when connecting to servers. Depending on the
"auth_mechanism", the "password" field or other attributes will need to be set
for authentication to succeed.

This may be provided in the connection string URI as a username:password pair
in the leading portion of the authority section before a @ character. For
example, to authenticate as user "mulder" with password "trustno1":

    mongodb://mulder:trustno1@localhost If the username or password have a ":"
    or "@" in it, they must be URL encoded. An empty password still requires a
    ":" character.

#### `w`

The client write concern.

- 0 Unacknowledged. MongoClient will NOT wait for an acknowledgment that the
server has received and processed the request. Older documentation may refer to
this as "fire-and-forget" mode. This option is not recommended.

- 1 Acknowledged. This is the default. MongoClient will wait until the primary
MongoDB acknowledges the write.

- 2 Replica acknowledged. MongoClient will wait
until at least two replicas (primary and one secondary) acknowledge the write.
You can set a higher number for more replicas.  all All replicas acknowledged.
majority A majority of replicas acknowledged.  In MongoDB v2.0+, you can "tag"
replica members. With "tagging" you can specify a custom write concern For more
information see Data Center Awareness

This may be set in a connection string with the w option.

#### `wtimeout`

The number of milliseconds an operation should wait for w secondaries to
replicate it.

Defaults to 1000 (1 second).

See w above for more information.

This may be set in a connection string with the wTimeoutMS option.

#### `read_concern_level`

The read concern level determines the consistency level required of data being
read.

The default level is undef, which means the server will use its configured
default.

If the level is set to "local", reads will return the latest data a server has
locally.

Additional levels are storage engine specific. See Read Concern in the MongoDB
documentation for more details.

This may be set in a connection string with the the readConcernLevel option.

#### `query_timeout (DEPRECATED)`

This value is in milliseconds and defaults to 30000.

#### `timeout (DEPRECATED AND READ-ONLY)`

This option has been renamed as "connect_timeout_ms". If this option is set and
that one is not, this will be used.

Connection timeout is in milliseconds. Defaults to 10000.

## Support & Maintenance Notice

MongoDB is maintained as part of the Clarive software contract. Patches and any
service advisory to Mongo are distributed as any other patches to the core
Clarive Server and related products (like the ClaX agent) included in your
service agreement.

We do not support MongoDB with outside network access, such as having other
users connecting to it with a database client of any type.
Access to MongoDB must be restricted by either binding
MongoDB to local cluster network controller addresses, by firewall rules or a
combination of both. By doing that, only the Clarive Server IP and its
processes can access the database network port. The configuration
recommendation is described in our installation and configuration guide for
MongoDB. This is done not just as a best practice recommendation, but as a
service clause: if you use the MongoDB database outside of Clarive in any
manner, that may limit our ability to support your installation and may void
any service guarantees.


