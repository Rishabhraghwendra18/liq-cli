---
title: liq Ontology
description: On how liq is defined.
permalink: /docs/Ontology
next_url: /docs/usage/Setup
next_name: liq Setup
---

# Core resources

There core resources are:

* `orgs`
* `projects`
* `work`
* `data`
* `services`
* `environments`
* `policies`
* (and `meta`)

## Orgs own projects and define policy.

* Each project is owned by a logical `org`.
* Operational policy is defined at the `org` level.

## Projects are the building blocks of applications, environments, and policies.

* A 'Liquid Project' is manifest as a NPM package associated to a Github project.
* `liq projects create` will configure each of either a new or existing NPM package and Github project.
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
  * Packages are used/manipulated by the `liq projects import`, `create`, `audit`, and other commands

## Work a set of changes to a project.

* Work represents an atomic unit of change.
* Work is managed through logical, git-based workflows and via interaction with policy touchpoints.
* The workflow ensures a basic (and configurable) level of quality control and security.

## Environments define the purpose and configuration of a runtime.

* There are three basic Environment (or Runtime) types:
  * `dev` Environments are used to test speculative changes. They use small datasets, minimally scaled, and ephemeral.
  * `test` Environments simulate the 'real environment'.
     * 'User' test environments are generally moderately scaled, but otherwise fully implement a production environment right down to user involvement (a dress rehearsal).
     * 'Performance' test Environments are fully automated, but simulate large scale over a short-period of time.
  * `production` Environments are where regular users live.
* User identity and credentials passed through the Environment for use in the Runtime.

## Data deals the bits in each runtime, as well as the underlying schema.

## Services create a runtime. (TODO: rename this resource 'runtime'.)

* Services, running in an Environment, create a runtime.

## Meta ~= self-control.

Additionally, there is a `meta` resource which handles some basic setup tasks.
