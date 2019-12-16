---
title: liq setup
description: How to set up your local liq environment and Projects.
permalink: /docs/usage/Setup
prev_url: /docs/Ontology
prev_name: liq Ontology
next_url: /docs/usage/Developing with liq
next_name: Developing with liq
---

# TL;DR:
```bash
eval $(liq meta bash-config)
liq meta init
liq import @liquid-labs/liq-cli
```

You can also create new Projects and (if necessary) Orgs with:
```bash
liq orgs create
liq projects create @new-org/new-project
```

It's also possible to duplicate and convert non-Liquid Projects with:
```bash
liq projects create --source ssh://foo.com/some-project-repo.git @acme/new-project
```

# Walkthrough

## Setup your local work environment.

### Configure your bash compatible shell.
```bash
eval "$(liq meta bash-config)"
```

This should only be necessary after first installing liq. As part of the liq installation, your `$HOME/.bash_profile` should have been updated, and your shell will be automatically configured for subsequent logins.

### Initialize your Playground
```bash
liq meta init
```

This will setup your local Playground directory. Later, we'll create and/or import projects into the Playground where we can work on them.

## (optional) Establish an Org affiliation.

Each Project is owned by an Org. If you're working on an existing project(s), you can simply import the Projects and the Org settings will be imported as well. If you're starting a Project from scratch, you'll need to affiliate with an existing Org or create your own.

### Affiliate with an existing Org.
```bash
liq orgs affiliate liquid-labs # for example
```

This will attempt to load the Org's settings directly without importing a specific project. This is useful if creating new projects under an existing, but un-affiliated Org.

### Create a new Org.
```bash
liq orgs create
```

This will start an interactive wizard to gather your Org details. This is typically used when first setting up your own personal projects (you are your own Org) or when first setting up a company, department, or team. Liquid Orgs map directly to GitHub organizations.

## Add Projects to the Playground.

To work on a Project, you first add it to the Playground. Existing Projects may be imported or new Projects created. Create is also used to convert existing, non-Liquid projects to Liquid projects.

### Import an existing Liquid Project.
```bash
liq projects import @liquid-labs/liq-cli # for example
```

This will add the named Project to the Playground.

### Create a project from scratch.
```bash
liq projects create --new @liquid-labs/lib-js @some-org/new-project # for example
```

This will initialize a new project using `@liquid-labs/create-lib-js`.

TODO: provide link to supported 'create' options.

### Copy and convert a non-Liquid Project.
```bash
liq projects create --source ssh://foo.com/some-project-repo.git @acme/new-project
```

This will use the 'source' repo as a starting point, and then attempt to add or convert `package.json` in order to make the project a proper Liquid Project.

# References

For further details and options, refer to:

* `liq help bash-config`
* `liq help meta init`
* `liq help projects import`
* `liq help projects create`
