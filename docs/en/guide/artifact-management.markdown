---
title: Artifact Management
index: 2000
---

A repository stores two types of artifacts: releases and snapshots. Release
repositories are for stable, static release artifacts and snapshot repositories
are frequently updated repositories that store binary software artifacts from
projects under constant development. While it is possible to create a
repository which serves both release and snapshot artifacts, repositories are
usually segmented into release or snapshot repositories serving different
consumers and maintaining different standards and procedures for deploying
artifacts.

Much like the difference between a production network and a staging
network, a release repository is considered a production network and a snapshot
repository is more like a development or a testing network. While there is a
higher level of procedure and ceremony associated with deploying to a release
repository, snapshot artifacts can be deployed and changed frequently without
regard for stability and repeatability concerns.

### Release Artifacts

A release artifact is an artifact which was created by a specific, versioned
release. For example, consider the 1.2.0 release of the commons-lang library
stored in the central Clarive repository. This release artifact,
commons-lang-1.2.0.jar, and the associated POM, commons-lang-1.2.0.pom, are
static objects which will never change in the central Clarive repository.
Released artifacts are consider to be solid, stable, and perpetual in order to
guarantee that builds which depend upon them are solid and repeatable over
time. The released JAR artifact is associated with a PGP signature, an MD5 and
SHA checksum which can be used to verify both the authenticity and integrity of
the binary software artifact.

### Snapshot Artifacts

Snapshot artifacts are artifacts generated during the development of a software
project. A Snapshot artifact has both a version number such as "1.3.0" or "1.3"
and a timestamp in its name. For example, a snapshot artifact for commons-lang
1.3.0 might have the name commons-lang-1.3.0-20090314.182342-1.jar the
associated POM, MD5 and SHA hashes would also have a similar name. To
facilitate collaboration during the development of software components, Clarive
and other clients which know how to consume snapshot artifacts from a
repository know how to interrogate the metadata associated with a Snapshot
artifact and always retrieve the latest version of a Snapshot dependency from a
repository.

### Groups

Groups can bundle different repositories in one.

That way, to the user, a single URL can be used to access artifacts.
Then Clarive, automatically, will look through the artifact repositories
that make up the group and attempt to find an artifact, *in the order
the artifact repositories are in a group*.

### Remote Repositories and Proxying

Clarive can have local and remote repositories.
Remote repositories are URLs that will be tried against
when the user requests Clarive for an artifact.

    USER ===> CLARIVE LOCAL REPOSITORY ===> REMOTE REPOSITORY

Remote repositories can be used to proxy and cache remote artifacts.

#### Caching Remote Artifacts

Once an artifact is requested, Clarive fetches the artifact and stores it
locally.

Everytime a user requests the artifact, if Clarive already has the filed cached
locally, it will just check if the remote artifact has the same timestamp and
size.  If they match, then Clarive will serve the local file, thus reducing the
remote fetch overhead.

### Publishing Artifacts

To include new artifacts into the Clarive repository, use the rule op
`Publish Artifact`.

This will publish *and index* the artifact.

If you don't use the op, and chose to copy the file directly to the repository
path, then it won't be indexed for searches.

### Searching

Artifacts added to the repository using the rule op `Publish Artifact`
force a index update, which means fast searches through the `Artifacts`
interface.

### Repository as Change Provider

Artifact repositories can be used as change providers.

Just add any Artifact repository to the Project repository list
(in the Project CI) to have it work.

### Identifiers

Artifacts can be identified by a combination of 3 data points:

#### Group Identifier (groupId)

A group identifier groups a set of artifacts into a logical group. Groups are
often designed to reflect the organization under which a particular software
component is being produced. For example, software components being produced by
the Maven project at the Apache Software Foundation are available under the
groupId org.apache.maven.

#### Artifact Identifier (artifactId)

An artifact is an identifier for a software component. An artifact can
represent an application or a library; for example, if you were creating a
simple web application your project might have the artifactId “simple-webapp”,
and if you were creating a simple library, your artifact might be
“simple-library”. The combination of groupId and artifactId must be unique for
a project.

#### Version (version)

The version of a project follows the established convention of Major, Minor,
and Point release versions. For example, if your simple-library artifact has a
Major release version of 1, a minor release version of 2, and point release
version of 3, your version would be 1.2.3. Versions can also have alphanumeric
qualifiers which are often used to denote release status. An example of such a
qualifier would be a version like “1.2.3-BETA” where BETA signals a stage of
testing meaningful to consumers of a software component.

### Origin

A Clarive artifact repository is
completely agnostic where it comes to the type of artifact it is managing.
Packaging can be anything that describes any binary software format including
ZIP, SWC, SWF, NAR, WAR, EAR, SAR.

