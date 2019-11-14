# Liquid CLI

This is a alpha project spiraling towards beta.

The user interface is working towards conformance with the [target 1.0 ontology](./docs/ontology.md).

## Installation

## Usage

* **Create a workspace**: `liq meta init`
* **Create (or join) to an org**: `liq org create --activate` or `liq org join --activate`
* **Identify projects to work on**: `liq projects import @liquid-labs/liquid-cli`
* **Do some work**: `liq work start @liquid-labs/liquid-cli`
* **Dev workflow**:
  * `liq work edit`
  * `liq work review`
  * `liq work stage`
  * `liq work test`
  * `liq work commit`
  * `liq work push`
  * `liq work publish`
* **Environment management**: `liq environments create`
* **Data management**: `liq data rebuild`
* **Straightforward runtime management**: `liq services start`

## CI/CD flow

Liquid Projects offer greatly simplified and entirely optional integration with a full CI/CD process supporting:

* **Workflow and process best-practices come built in.**
* **Fully automated static analysis and CI/CD pipelines; free QA!** (For "most" projects.)
* **Built in change control management, complete with badges and trend reports.**
* **Plug-in, largely automated compliance conformance (currently supporting PCI DSS and SOC 2 standards).
