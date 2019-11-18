# Developing with liq

## Audience & scope

This document discusses the liq development workflow conventions and tools. This process may be broadly divided into 'change control' and 'deploy':

* change control,
  * development workflows,
  * implementing changes,
  * testing and quality assurance,
* deploy,
  * pre-deploy testing,
  * production deploy,
  * post-deploy verification and certification.

## Overview

![High level, "golden path" development, testing, and deploy workflow. The "work setup" phase starts with the developer creating or importing projects into the local playground with `liq projects create` and `liq projects import`. The primary project (or first if it's all the same) project is used to create the unit of work with `liq work start`. Additional projects are added to the work unit with `liq work involve`. The "work in main" phase involves local changes to the project code, saving those changes, and local QA checks with `liq work status`, `liq work save`, and `liq work qa`. The "deploy prep" phase begins with `liq work submit`, at which point the developer may use `liq work close` to close the local work unit. The submitted changes are then queued for automated testing. After passing the automated tests, the changes are reviewed by one or more humans and, after approval, merged to the `master` branch of the respective projects. When all the changes for a release are present, the main application project is published and depoyled to testing with `liq project publish` and `liq project deploy`. This kicks off automated pre-deploy testing and, optionally and depending on the nature of the changes, RC user testing. Once the necessary pre-deploy testing has been completed, the changes are deployed to production with `liq projects deploy`, which kicks off automated deploy verification checks and also manual checks. Once these have passed, the deploy is fully certified with `liq projects deploy --certify`.](./liq%20Change%20Control%20Flow.svg)

Source: https://docs.google.com/drawings/d/1dlhK32qiEcLBg2jzwnHXRRujJajHpV8Hty_LRYPUQiA/; Version: "2019-11-18 updated flow - fix phase grouping"

## Change control

liq change control processes are primarily organized around "work units". A work unit involves one or more issues and one or more projects.

### Preparing a work unit

<span style="color: red">*ALERT*</span>: The interface as defined here is ahead of and differs in some aspects from the interface as implemented at the time of writing. Refer to `liq work help` for current state.

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

### Implementing changes
