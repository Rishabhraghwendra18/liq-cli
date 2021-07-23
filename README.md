**_<span style="color:red">This is a alpha project.</span> Documentation and implementation may not be entirely in-sync._**

liq is user-friendly development and process management framework. liq provides:
* clear project specification guidelines,
* a straightforward, well-defined development workflow
* extensible libraries of (mostly) automatically enforced change and submission policies, and
* built in CI/CD.

___

* [Installation](#installation)
* [Basic usage](#basic-usage)
   * [Setup](#setup)
   * [Doing work](#doing-work)
   * [Runtime management](#runtime-management)
* [Policies](#policies)
* [CI/CD](#cicd)
* [Supported platforms](#supported-platforms)
* [Contributions and bounties](#contributions-and-bounties)
* [Further reading](#further-reading)

# Installation

`npm inistall -g @liquid-labs/liq-cli`

# Basic usage

## Setup

Setup your local environment. See [Usage: Setup](/docs/usage/Setup.md) for details.
 ```bash
 liq meta init
 liq projects import @liquid-labs/liquid-cli # or whatever
```

## Developing

Do work; make changes. See [Usage: Developing with liq](/docs/usage/Developing with liq.md) for details.
 ```bash
 cd "$(liq projects dir @liquid-labs/liq-cli)"
 # cd ~/playground/\@liquid-labs/liq-cli
 liq work start -i 100 "adding golang support"
 # make changes
 liq work test
 liq work qa
 liq work save -am "golang support added"
 liq work submit
 liq work close
 ```

## Runtime management

Manage your local development, test, and production environments. See [Usage: Runtime management](/docs/usage/Runtime management.md) for details.
```bash
liq environments create
liq data rebuild
liq services start
```

# Policies

liq has built in support for (optional) development and organizational policies:

* Prebuilt policies libraries can be easily installed; Liquid Labs offers standard open source policies as well as PCI and SOC 2 compliant policies.
* All policies are fully cutomizable.
* Policies are subject to the same change controls as code.

See [Usage: Policy management](/docs/usage/Policy management.md) for details.

# CI/CD

Liquid Projects offer greatly simplified (and entirely optional) integration with a full CI/CD process supporting:

* Built in CI/CD workflow best-practices.
* Fully automated static code analysis (for supported languages).
* Configurable automated or manual deploy.
* Automated project badging and trend reports.

# Supported platforms

Support for target distros is currently limited. Full support for additional distros will be rolled out once we reach a stable beta.

* MacOS is the primary/lead platform.
* Some testing is done on Ubuntu.
* Most Linux or BSD based distros should work (perhaps with some tweaks).
* At this point, Windows is entirely out of scope, though in theory Windows with CygWin or similar may work.

# Contributions and bounties

This project offers bounties on many issues.

* [Search for available bounty tasks in this project](https://github.com/liquid-labs/liq-cli/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+no%3Aassignee+label%3Abounty) or [all Liquid Labs bounty tasks](https://github.com/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+org%3Aliquid-labs+archived%3Afalse+label%3Abounty).
* Refer to [Contributions and Bounties](/docs/Contributions%20and%20Bounties.md).
* Claim a bounty!

Non-bounty contributions are also welcome. You may also refer to open, non-bountied issues and make an offer.

# Further reading

For a more detailed look at liq, please refer to the [project documentation](/docs/toc.md).
