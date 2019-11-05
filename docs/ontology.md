# Liquid CLI Ontology

liq provides comprehensive development and operational support for
managing, testing, and deploying Catalyst projects.

## Audience & scope

This document describes the key concepts and high level features embodied in Liquid CLI.

## CLI conformance

Commands are organized by 'resources', which correspond to the ontology discussed here. The general command form is:

  liq <resource> <action> [<target>...]

## Core resources

There are three core Liquid Development resources (Core Resources). Core Resources are:

* _meta_
* _orgs_
* _projects_
* _work_

### Meta ~= self-control.

### Orgs ~= "where" we're working.

Org(anization)s define who "owns" the work we do and the policies that control that work.

### Projects ~= stuff we're working on and could work on.

TODO: break out and reference 'liq-npm package spec'

* Note, "liq" was originally called "catalyst".
* A 'Liquid Project' is manifest as a NPM package associated to a Github project.
* `liq project create` will configure each of either a new or existing NPM package and Github project.
  * Future versions may encode to multiple package formats.
  * Future versions may integrate with other version control protocols and issues/project management platforms.
* A liq-npm `package.json`:
  * must include a `catalyst` (and later `liq`) entry.
  * must specify a GitHub hosted `repository`.
  * defines build and other file-type dependencies via the standard NPM mechanisms.
  * defines run time through the `liq.runtime` block.
* The current implementation does not do much in the way of checking for conformance to requirements.
* The behavior of non-conforming packages blessed as Liquid Projects is generally undefined.
* Projects define both build and runtime dependencies.
* In the liq ontology, the concept of "packages" is subsumed into the "project" concept.
  * Packages are the typical method by which projects are distributed. I.e., a "package" is a "packaged project version".
  * Packages are used/manipulated by the `liq project import`, `create`, `audit`, and other commands

### Work ~= outstanding changes.

* Work represents units of outstanding change.
* Work is managed through logical, git-based workflows.
* The workflow ensures a basic (and configurable) level of quality control and security.

## DevOps resources

There are three DevOps Resources:

* _environments_
* _data_
* _services_

### Environments ~= where stuff lives.

* Environments serve one of three basic "purposes":
  * `dev` environments are used to test speculative changes. They use small datasets, minimally scaled, and ephemeral.
  * `test` environments simulate the 'real environment'.
     * 'User' test environments are generally moderately scaled, but otherwise fully implement a production environment right down to user involvement (a dress rehearsal).
     * 'Performance' test environments are fully automated, but simulate large scale over a short-period of time.
  * `production` environments are where regular users live.

### Data ~= data in an environment.

### Services ~= runtime management.

* Services, running in an Environment, create a runtime.
