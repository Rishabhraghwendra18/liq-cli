<span style="color:red">This is a alpha project.</span> **_Documentation and implementation may not be entirely in-sync._**

* [Installation](#installation)
* [Usage](#usage)
* [CI/CD](#cicd)
* [Supported platforms](#supported-platforms)
* [Contributions and bounties](#contributions-and-bounties)

# Installation

`npm inistall -g @liquid-labs/liq-cli`

# Usage

1. Setup your local environment. See [Usage: Setup A](/docs/usage/Setup.md) [Usage: Setup B](docs/usage/Setup.md) [Usage: Setup C](./docs/usage/Setup.md) [Usage D: Setup](docs/usage/Setup) for details.
   ```bash
   liq meta init
   liq projects import @liquid-labs/liquid-cli # or whatever
  ```
2. Do work. See...


* **Do some work**: `liq work start @liquid-labs/liquid-cli`
* **Dev workflow**:
  * `liq work edit`
  * `liq work review`
  * `liq work stage`
  * `liq work test`
  * `liq work qa`
  * `liq work save`
  * `liq work publish`
* **Environment management**:
  * `liq environments create`
  * `liq environments select`
* **Data management**:
  * `liq data rebuild`
  * `liq data snapshot`
  * `liq data restore`
* **Straightforward runtime management**:
  * `liq services start`
  * `liq services stop`

## CI/CD

Liquid Projects offer greatly simplified and entirely optional integration with a full CI/CD process supporting:

* **Workflow and process best-practices come built in.**
* **Fully automated static analysis and CI/CD pipelines; free QA!** (TODO: list supported languages.)
* **Built in change control management, complete with badges and trend reports.**
* **Plug-in, largely automated compliance conformance (currently supporting PCI DSS and SOC 2 standards).**

## Supported platforms

Support for target distros is currently limited. Full support for additional distros will be rolled out once we reach a stable beta.

* MacOS is the primary/lead platform.
* Some testing is done on Ubuntu.
* Most Linux or BSD based distros should work, perhaps with some tweaks.
* At this point, Windows is entirely out of scope, though in theory Windows with CygWin or similar may work.

## Contributions and bounties

This project offers bounties on many issues.

* [Search for available bounty tasks in this project](https://github.com/Liquid-Labs/liq-cli/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+no%3Aassignee+label%3Abounty) or [all Liquid Labs bounty tasks](https://github.com/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+org%3ALiquid-Labs+archived%3Afalse+label%3Abounty).
* Refer to [Bounty Terms and Conditions](./docs/Bounty%20Terms%20and%20Conditions.md).
* Claim a bounty!

Non-bounty contributions are also welcome. You may also refer to open, non-bountied issues and make an offer.

The user interface is working towards conformance with the [target 1.0 ontology](./docs/Ontology.md).
