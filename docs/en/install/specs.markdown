---
title: Architecture and Requirements
index: 200
---

# Components

Clarive's architecture consists of the following general elements:

* Automation Server(s)
* Web Server
* Web Client
* Staging-Build server(s)
* Communication agent(s)

<img src="/static/images/docs/arch1.png" />

## Automation Server

Clarive has at least one automation server. This server is responsible for the following tasks:

* Planning and execution of jobs and integration with schedulers.
* Build management and deployment. Communication with agents.
* Batch processes, such as purging or backup.
* Integration with external tools: Source code management, Incident management, cmdb, etc.
* Export and Import of data.

## Web Server

The primary user interface of Clarive is Web-based.

Clarive features an application server that provides the web interface of Clarive and the SOAP
and REST WebServices. The web server is based on the Catalyst framework and runs standalone or under compatible servers like Apache, Nginx or Lighttpd.

## Web Client

Clarive Web client uses the latest Web 2.0 technology to deliver a dynamic and natural user experience,
similar to that of a client application, but from any system on the network.

## Agents

Realising the process of building and deploying applications, Clarive needs
to communicate with servers on the network: with proprietary agents or via SSH.

<img src="/static/images/docs/arch2.png" />

Clarive agents are compatible with any UNIX, Linux or Windows technology.

## Interfaces

The product includes the following interfaces for customization and integration within the company.

* Web-services SOAP and REST
* Command line
* JavaScript DSL and API for the implementation of plugins and automation logic

### Authentication and authorisation

The user can authenticate to Clarive using the most common standards in the company:

* LDAP, Active Directory
* Proprietary Authentication
* Integration with external authentication and authorization
SSO (Single Sign-On), such as BMC Atrium, CAS, SAML,  by use key generation.

Through the tool's API the load of users
and granting permissions to roles, groups and applications can be handled.

# SYSTEM REQUIREMENTS

Clarive requires a server with 64-bit processor. The machine can be
virtualized or not. Other requirements depend on machine usage requirements, measured considering the following variables:

* Number of users
* Size of the application
* Version freqeuncy of the application
* Number of daily deployments

## Supported Operating systems (Server)

### Linux 2.6 or higher, 64 bits

* SUSE, OpenSUSE
* CentOS 5.x, 6.x, 7.x
* RedHat Linux 5.x, 6.x, 7x
* Oracle Linux 6.x
* Debian 5 or higher (or Ubuntu)

### Unix or BSD 64 bits

* OSX 10.6 or higher
* Solaris 11 / OpenSolaris (SmartOS) 64-bit

### Microsoft Windows

* Microsoft Windows 7 (64-bit edition).
* Microsoft Windows Vista (64-bit edition).
* Microsoft Windows Server 2008 R2 (64-bit editions)

## Supported Databases

* MongoDB 2.6 or higher

## Supported web browsers

* Microsoft Internet Explorer 11
* Google Chrome 13 or higher.
* Mozilla Firefox 3.x or higher.
* Safari 5 or higher.

### Mainframe (Agent and Clarive ZSCM)

* z/OS zLinux (Agent only)
* z/OS 1.7 or higher (Agent, Clarive ZSCM)

## Recommended system requirements

### Clarive Server

There are 2 server proceeses
required to execute Clarive processes: the web server and the dispatcher.

* Operating system: Linux 64 bits
* Cores: 8
* RAM: 32 GB
* Disk:
    - $CLARIVE_BASE (software): 5 GB
    - $CLARIVE_BASE/tmp: 50 GB (depending on the number of jobs and size of applications)  Recommended to share between the two machines (NFS, SAN, etc?)
    - $CLARIVE_BASE/logs: 20 GB
    - $GIT_BASE/repo: 500 GB (depending on the size of the application repositories)  Recommended to share between the two machines (NFS, SAN, etc?)

### Database Server

2 servers to execute the MongoDB database server processes. The servers will be configured as a replication set got the

* MongoDB.Operating system: Linux 64 bits
* Cores: 8
* RAM: 16 GB
* Disk:
    - $MONGO_BASE/data: 200 GB
    - $MONGO_BASE/logs: 20 GB

## Agents Support

### Operating systems

* Linux 2.4 or higher: Red Hat, Centos, Debian, OpenSUSE
* IBM AIX 4 or higher
* HP-UX
* Oracle Sun Solaris / SunOS
* IBM ZOS (OS-390) / IBM USS (OMVS)
* Windows Server 2000 or higher
* OSX, BSD or compatible
