---
title: Policy management
description: Manage development and organizational policies and evidence.
permalink: /docs/usage/Policy management
prev_url: /docs/usage/Runtime management
prev_name: Runtime management
next_url: /docs/Contributions and Bounties
next_name: Contributions and Bounties
---

# General concepts

A "Policy" may be understood as a set of organizational, departmental, and/or project goals, standards, and controls. In concrete terms, liq policies are implemented as Liquid Projects providing both textual documentation as well as scripted, automated controls and related components. For policy agents, see [Policy Concepts](/docs/topics/Policy Concepts.md) for a more detailed discussion of the ontology of the Policy.

"Compliance" simply means that the Company is doing everything it says it's going to do, especially as relates to security and protecting user data. As workers go about sensitive tasks, evidence must be gathered to prove that the task was executed properly. With liq, much of this evidence gathering is automated so that each user and thereby the Company as a whole can achieve compliance for the most part by simply utilizing the tool to mediate the tasks they're already performing.

In other words, liq eliminates much of the burden of evidence gathering and organization.

# Policy walkthrough

## Subscribing to a Policies
```bash
liq policies subscribe @liquid-labs/orgs-policies-oss
```
Policies are installed just like packages. The only difference being that as an enforced convention, policy Projects are kept separate from code projects so the process will check the project type prior to acting.

## Creating a policy
```bash
liq projects create --new liquid-policy @my-company/orgs-policies-hiring
```
A policy really is just a kind of Project. Change control is very similar, differing mostly in the human actors.

## Update policy subscriptions
```bash
liq policies update
```
Creates a PR of upstream policy updates. The changes are then reviewed and may be cherry-picked.

## See the policy
```bash
liq policies document
```
(Re-)generates the Company Policy as a whole and customized for each staff member.

## Policy tools
```bash
liq policies document --for-review
```
Can also generate individualized "for review" collections for each staff member, essentially consisting of a spreadsheets of the portion of the policies they are obligated to review according to their role and the policy review requirements.

## Other touchpoints

There are policy hooks and touchpoints all throughout liq. Policy ties directly into the 'staff' resource and all throughout the development workflow.
