---
title: Developing with liq
description: Development workflow, conventions, and commands.
permalink: /docs/usage/Developing with liq
prev_url: /docs/usage/Setup
prev_name: liq setup
next_url: /docs/usage/Runtime management
next_name: Runtime management
---

# Audience & scope

This document discusses the liq development workflow conventions and tools. This process may be broadly divided into 'change control' and 'deploy':

* change control,
  * development workflows,
  * implementing changes,
  * testing and quality assurance,
* deploy,
  * pre-deploy testing,
  * production deploy,
  * post-deploy verification and certification.

# Overview

The following flow diagram gives a high level overview of the "golden path" development and deploy workflow. Of course, not all projects are "deployed" (e.g., a library would be "published", but not directly deployed) and, of course, there are many branches and options not shown which would deal with updating code based on feedback, failed verification tests, etc.

![High level, "golden path" development, testing, and deploy workflow. The "work setup" phase starts with the developer creating or importing projects into the local playground with `liq projects create` and `liq projects import`. The primary project (or first if it's all the same) project is used to create the unit of work with `liq work start`. Additional projects are added to the work unit with `liq work involve`. The "work in main" phase involves local changes to the project code, saving those changes, and local QA checks with `liq work status`, `liq work save`, and `liq work qa`. The "deploy prep" phase begins with `liq work submit`, at which point the developer may use `liq work close` to close the local work unit. The submitted changes are then queued for automated testing. After passing the automated tests, the changes are reviewed by one or more humans and, after approval, merged to the `master` branch of the respective projects. When all the changes for a release are present, the main application project is published and depoyled to testing with `liq projects publish` and `liq projects deploy`. This kicks off automated pre-deploy testing and, optionally and depending on the nature of the changes, RC user testing. Once the necessary pre-deploy testing has been completed, the changes are deployed to production with `liq projects deploy`, which kicks off automated deploy verification checks and also manual checks. Once these have passed, the deploy is fully certified with `liq projects deploy --certify`.](./liq%20Change%20Control%20Flow.svg)

Source: https://docs.google.com/drawings/d/1dlhK32qiEcLBg2jzwnHXRRujJajHpV8Hty_LRYPUQiA/; Version: "2019-11-18 updated flow - fix phase grouping"

# Change control

liq change control processes are primarily organized around "work units". A work unit involves one or more issues and one or more projects.

## Preparing a work unit

```js
// The interface as defined here is ahead of and differs in some aspects from the interface as implemented at the time of writing. Refer to `liq work help` for current state.
```

* A unit of work is created with
  `liq work start -i 24 "implement feature foo`
* A work unit may be associated with multiple issues.
* Associated issues may be 'cured' or 'related' by the associated unit of work.
  ```js
  // 'related' issues not implemented at time of writing.
  ```
* Issues are managed through the `liq work issues` sub-resource interface.
* A work unit may involve one or more projects.
  * `liq work start` is executed against the 'primary' project involved in a work unit.
  * Additional projects may be involved with `liq work involve`.
  * Projects may be dropped, without affecting the work unit, with `liq work drop`.
    ```js
    // Not currently implemented.
    ```

## Implementing changes

Developers:

* Make and test changes locally.
* Use `liq work status` to check the status of changes and available updates across all work units.
* Use `liq work save` (along with `liq work stage`) to save local changes to remote workspace repos on the workbranch.
* Use `liq work test` and `liq work qa` to test and audit local changes.

# Release and deploy

## Deploy prep

The "deploy prep" phase is all about verifying a new product version prior to production deploy/release.

* Changes from work units are submitted for inclusion into master (and thereby, to the next production release), with `liq work submit`.
* After submitting their work, developers will generally close the local unit of work with `liq work close`.
* Once submitted, changes the full battery of integration tests are run against the updates for each project.
* All changes are also manually reviewed by at least one qualified human reviewer (who, if at all possible, did not contirbute to the changes themselves).
* Once changes are approved and pass the automated tests, they are merged onto their projects respective `master` branches.
* When all target changes have been collected on, or as otherwise determined by the stakeholders, products are published (internally or publicly) and deployed to a test environment for final comprehensive testing that combines all the changes in one place and verifies schema or other "system upgrade" processes associated with the release.
* The pre-deploy testing may, as determined by Company policy, also include end-user testing in either a contrived or live-data environment.

## Deploy

* After passing all necessary pre-deploy testing, the product is deployed via `liq work deploy` (or by other means depending on process particulars).
* After deploying, the deploy itself is verified through a series of simple automated and manual checks that include simple version checks and an end-user test script.
* After these checks, the deploy is certified with `liq projects deploy --certify`.
