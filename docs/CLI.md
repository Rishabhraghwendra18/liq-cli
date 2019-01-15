# Catalyst CLI

Catalyst CLI provides (more or less) complete support for managing, testing, and deploying Catalyst projects. The goal is to (more or less) cover the entire development and sysops lifecycles.

## Audience & scope

This document defines the command line interface for the Catalyst CLI tool and is aimed at tool users.

## General concepts

The Catalyst CLI tool is used to:

* Manage project and package configuration through the [`project` commands](#project-commands).
* Manage services and environment through the [`runtime` commands](#runtime-commands).
* Manage the workflow through the [`work` commands](#work-commands).
* Manage data through the [`data` commands](#data-commands).

### Projects

Organize code and other artifacts.

### Runtimes

A package may require all needed services by referring to service "interface classes". Here, services are primarily network services and the interface class describes both the method and general syntax provided by the service.

Any given project may both require and provide services.

## Global actions

* `help` : prints a list of available Modules.

## Command spec

### `project` commands

-- TODO: can we push the 'usage' output into the document?

### `runtime` commands

### `work` commands

### `data` commands

Manage schema defined by projects and data sets.
