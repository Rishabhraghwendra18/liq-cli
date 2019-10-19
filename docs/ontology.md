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
* _projects_
* _work_

### Meta ~= self-control.

### Projects ~= stuff we're working on and could work on.

* A 'Liquid Project' is an NPM package blessed with: `liq packages init`.
* The current implementation does not do much in the way of checking for conformance to requirements.
* The behavior of non-conforming packages blessed as Liquid Projects is generally undefined.
* The Liquid Project is uniquely identified with a Github repository.
* A package is identified as conforming by the presence of `catalyst` and later `liquidDev` field in `package.json`. (`catalyst` was the projects original name.)
* Projects define both build and runtime dependencies.

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
