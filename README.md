# Liquid CLI

This is a alpha project spiraling towards beta. **_Not all features listed her are currently implemented._**

The user interface is working towards conformance with the [target 1.0 ontology](./docs/Ontology.md).

* [Installation](#installation)
* [Usage](#usage)
* [CI/CD](#ci-cd)
* [Supported platforms](#supported-platforms)
* [Contributions and bounties](#contributions-and-bounties)

## Installation

`npm inistall -g @liquid-labs/liq-cli`

## Usage

* **Create a workspace**: `liq meta init-workspace`
* **Create (or join) to an org**: `liq orgs create --activate` or `liq orgs join --activate`
* **Identify projects to work on**: `liq projects import @liquid-labs/liquid-cli`
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

* [Search for available bounties.](https://github.com/Liquid-Labs/liq-cli/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+no%3Aassignee+label%3Abounty)
* Refer to [Bounty Terms and Conditions](./docs/Bounty%20Terms%and%20Conditions.md).
* Claim a bounty!

Non-bounty contributions are also welcome. You may also refer to open, non-bountied issues and make an offer.
