# Catalyst CLI

## Audience & scope

This document defines the command line interface for the Catalyst CLI tool and is aimed at tool users.

## General concepts

### Modules & actions

All commands are broken into two parts: the Module and Action.

Each Module is essentially a group of related Actions dealing with a particular aspect of development and/or operations. Collectively, the Modules cover the entire scope of the development+deploy+production lifecycle.

* [`project`](#project-module) : Used to create and manage Catalyst projects. This includes managing remote repositories and project dependencies.
* [`work`](#work-module) : A development-only module managing the set of projects currently under active, local development.
* [`services`](#services-module) : Manages services defined by the current in-scope projects.

### Projects

Organize code and other artifacts.

### Services

A Service is a runtime process, which may be either local or remote. Key Services include web servers and database servers.

### Environments

A running Service exists within an Environment. Environments are defined orthogonal to Projects and Services.

## Global actions

* `help` : prints a list of available Modules.

## Specification

### `project` module

### `work` module

* `entry-info` : Displays the current entry-point project.
* `entry-set` : Sets the current entry-point project.

### `services` module

### `data` module

Manage schema defined by projects and data sets.

### `environment` module

Manage the target deploy environment.
