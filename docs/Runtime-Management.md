# Catalyst Runtime Management

## Audience & scope

This document addresses Catalyst conventions and tools for managing runtime and runtime environments. This is aimed both at system operations managers as well as developers. In the case of sysops, the primary concern with production and pre-production runtimes and environments. With regards to developers, the primary concern is test runtimes and environments.

General concepts and common concerns are addressed first. Issues particular to production and testing environments are addressed separately and aimed primarily at the sysop and developer audience respectively.

## General Concepts

* Projects may provide runtime *services* which are described in the `package.json` under `_catServices`.
* Projects may declare compatible service *providers*.
* Compatible services are composed into a runtime *environment*.

For example, package `mysql-runtime` might provide two services `mysql-gcp` and `mysql-local-hybrid`. These would both support interface class `mysql`. Package `foo-api` requires a `mysql` provider. We could create then create a dev environment using `mysql-local-hybrid` and a production environment using `mysql-gcp`.
