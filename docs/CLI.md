# Catalyst CLI

Catalyst CLI provides comprehensive development and operational support for
managing, testing, and deploying Catalyst projects.

## Audience & scope

This document describes the Catalyst Command Line Interface (CLI) tool. The
primary audience is developers and system operations personnel.

## Command organization

Commands are specified by selecting a resource (or group) and an action. The
general form is:

  catalyst <resource/group> <action> [<option>...] [<target>...]

There are ten command groups in all. Three of these deal primarily with
[project configuration and management](#project-configuration-and-management):

* project
* packages
* remotes

Five command groups deal with runtime configuration and management:

* provided-services
* required-services
* environments
* services
* data

The final two command groups deal with workflow:

* work
* playground

## Basic concepts

"Plain" NPM packages are turned into catalyst packages with:

`catalyst packages init`

### Static components

A Catalyst _project_ is a regular NPM package that can also conforms to Catalyst
standards and can be managed by the Catalyst tools. A number of bootstrap
projects are maintained as part of the Catalyst core for the express purpose
of kickstarting new projects.

Each project is identified with a primary repository. The project may
be mirrored to any number of 'mirror repositories'. Primary and mirror
repositories are managed through the [`remotes` commands](#remotes-commands)

A project may  contain multiple _packages_. **ALPHA NOTE**: The current alpha
version only supports a single package per-repository.

### Runtime components

A _service_ is a runtime process. Services are classified by their _interface
class_. A _primary interface class_ is a general category which is usually
defined as a broad industry standard, like `sql`. A _secondary interface class_
denotes a sub-class which varies somewhat but is largely compatible with the
primary class. E.g., `sql-mysql`. Secondary classes are always written in the
form of '<primary class>-<secondary designation>'.

A _required service_ is simply a declaration that a package requires a service
of a particular interface class at runtime. A _provided service_ declares that
a package provides a service of a particular interface class. When creating a
runtime environment, Catalyst will inspect a packages dependencies to find
suitable providers for all required services.

A _service_ is an actual runtime process or processes. Services may be either
remote or local.

An _environment_ is essentially a collection of services along with a particular
configuration. A user may create any number of environments for many purposes.
A developer for example will commonly create a developer environment, which is
isolated to their own work, and configure a shared test environment which will
be used for final verification.

### Workflow components

The Catalyst workflow provides a thin abstraction over standard git and QA
flows to ensure consistent branching, merging, logging, etc. The workflow also
helps enforce certain minimum quality standards.

## Command spec

-- TODO: can we push the 'help' output into the document?

### Global commands

#### `help` command

### Static configuration command groups

#### `project` commands

#### `packages` commands

#### `remotes` commands

### Runtime command groups

#### `required-sevices` commands

#### `provided-sevices` commands

#### `environments` commands

#### `required-sevices` commands

#### `data` commands

### Workflow command groups

#### `work` commands

#### `workflow` commands
