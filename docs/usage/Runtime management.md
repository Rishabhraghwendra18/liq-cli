---
title: Runtime management
description: Manage environments, services, and data with liq.
permalink: /docs/usage/Runtime management
prev_url: /docs/usage/Developing with liq
prev_name: Developing with liq
next_url: /docs/usage/Policy management
next_name: Policy management
---

# General concepts

* *Services* enable runtime capabilities such as data access, REST-ful request handling, etc.
* Services are provided by Projects. E.g., an application requiring a relational database may depend on a project which provides Postgres as a runtime Service.
* An *Environment* defines a set of service providers and associated Service and Project defined configuration parameters.
* liq runtime management encompasses both local (developer and QA) Environments as well as remote test and production Environments.

For example, suppose:

* Project `postgres-runtime` provides two Services `postgres-gcp` and `postgres-local-hybrid`.
* Both services support interface class `postgresql`.
* Project `foo-api` requires a `postgresql` provider.
* Running `liq environments create` from the `foo-api` Project would discover the Service providers and we would select `mysql-local-hybrid` when creating a local "dev" environment and `mysql-gcp` when creating a "production" (or "beta" test) environent.
