# Catalist CLI

This is a pre-alpha project.

[Target CLI](./docs/cli.md)

# Installation

# Usage

To use Catalyst CLI, you must:

1. Initialize your Workspace.
2. Import at least one Project into the Workspace.
3. Define your current development entry-point project.
4. Define your current target Environment.

You're now ready to start developing.

# TODO Notes

The current interface is highly idiomatic. The ontological model has developed
as we added features, while we were also actively using the tool in daily
development.

The following changes need to be made:
* individual service controls should be unified under a 'services' component
  * a project may define multiple services
  * each service defines:
    * build <env, def: local>: transpile and check syntax
    * deploy <env, def: local> : deploy and start service for indicated
      environment
    * stop <env, def: local> : stop running service for indicated environment
  * a library is just another service
