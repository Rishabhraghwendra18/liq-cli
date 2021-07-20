---
title: Contributions and Bounties
description: How to contribute to this project and claim bounties.
permalink: /docs/Contributions and Bounties
prev_url: /docs/usage/Runtime management
prev_name: Runtime management
---

# Contributions

`@liquid-labs/liq-cli` is a Liquid Project. Refer to {{ site.homepage }} for installation instructions and further details. The use of the liq CLI tool will speed development and ensure compliance to all development and contribution policies.

# Bounty Terms and Conditions

## Summary

This summary is provided as a good-faith overview of the terms and conditions and is meant to provide an overall understanding of the scope and purpose of the terms. Anyone considering requesting assignment to a bounty task under these terms will do so under the [Terms and conditions](#terms-and-conditions) section of this document.

Liquid Labs, LLC offers bounties on certain issues. The amount of the bounty will be listed in the issue, which will also reference these terms and conditions. The basic bounty process is:

* Review [Developing with liq](./usage/Developing with liq.md)
* [Search for available bounty tasks in this project.](https://github.com/Liquid-Labs/liq-cli/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+no%3Aassignee+label%3Abounty) You can also search for [all Liquid Labs bounty tasks](https://github.com/issues?utf8=%E2%9C%93&q=is%3Aopen+is%3Aissue+org%3ALiquid-Labs+archived%3Afalse+label%3Abounty).
* Request assignment to the a task. Task will remain assigned for a specified Lock-In Period and the Assignee shall have exclusive rights to complete the task and receive the bounty payment.
* Complete work and submit a PR.
* Address any feedback.
* After PR is accepted, get paid via Venmo.

## Terms and Conditions

### Task assignment and lock-in

* Tasks (GitHub issues) are assigned to an individual user for a specific period of time, known as the 'Lock-In Period'. The default Lock-In Period is specified in the task description but may be modified by request. When requesting assignment to an issue, please provide a justification for a different Lock-In Period.
* Liquid Labs reserves the sole right to make assignments.
* Prior to assignment, the requesting party must provide an email address to be used for certain notifications and payment discussions per these terms.
* For the purposes of this agreement, Liquid Labs may be reached at: bounties@liquid-labs.com.
* Discussions regarding the work task itself should generally be held as comments on the task, however either party may utilize the counter-party's indicated email address as they deem appropriate and necessary.
* Once assigned, the final date of the current lock in will be added in the task comments.
* While a task is assigned, PRs from other users will not be accepted.
* If a significantly correct PR is submitted within the Lock-In Period, an additional 5 working days grace period will be tacked onto the Lock-In Period to allow for the identification and address of any minor issues.
* If the Lock-In Period (including any grace period) should expire, then Liquid Labs may, at their sole discretion, either extend the Lock-In Period or un-assign the issue, at which point it is available to be claimed by another user. Any previous Assignee may submit a [Speculative PR](#speculative-prs) within this period or re-apply for another Lock-In Period.
* Assignments are always made to a single individual. Multiple individuals contribute to a project, but a single contact individual shall serve as contact point and be responsible to Liquid Labs under these terms and conditions.

### Acceptance and rejection

* To be accepted, a PR must implement all deliverables stated in the 'Deliverables' section of the task.
* Deliverables must conform to and be consistent with the entire task description. E.g., the text of any "Overview", "Notes", or other sections in the task are part of the task specification and may inform, provide context for, or otherwise have bearing on the deliverables.
* All PRs must pass unit test and other qa checks as implemented by `liq` and the [development flow](./usage/Developing with liq.md).
* In addition, PRs may need to be modified for clarity or to conform general or project specific coding standards. Such standards may or may not be explicitly stated.
* Liquid Labs will provide reasonable feedback on any significantly correct PR.
* PRs with significant issues may, at Liquid Labs sole discretion, be rejected with instructions to refer back to the task description for guidance.
* A PR is considered "accepted" once it is merged into the source project, or in such a case where Liquid Labs decides not to merge the changes but finds no significant fault with the work provided.

### Task errors and omissions

* By requesting and accepting an assignment, the Assignee accepts responsibility for ensuring that the task specification, as written, is clear and complete with regards to the goals of the task as laid out in the task title and description.
* Changes made to the task to cure clearly incomplete or erroneous statements, even after assignment and/or submission, shall not be held against Liquid Labs. Liquid Labs may, but is under no obligation, to increase the bounty in light of any additional work created by such changes.
* The Assignee, as a professional familiar with and having sufficient skills in the field and technologies implied by the task, is expected to suggest modifications to the task specification where such would improve the quality of the final product. Liquid Labs may also suggest modifications at any time.
  * The Assignee is free to suggest an additional bounty to reflect additional work and/or recognize the contribution made by such suggestions.
  * Any upward modification to the bounty amount shall be at the sole discretion of Liquid Labs.
  * In the event that an agreement cannot be reached regarding a bounty amount modification, then the original task, as described, shall remain in effect.
* So long as a PR reflects fully satisfies task specifications, Liquid Lab shall be liable for payment under these terms and conditions even if a PR is ultimately rejected for technical reason, due to changes in product specification, or for any reason.

### Payment

* Clear and obvious typos or bounty payments which are far out of bounds for the work described and the historical amount offered for similar work shall be deemed invalid. Each party shall have an obligation to note and seek correction of any such "outsized bounties" immediately.
* Once an issue is accepted, Liquid Labs shall request the Assignee to provide instructions for receiving payment.
* Payments are only distributed via Venmo at this time and the Assignee must have a Venmo account to recieve payment.
* All payments will be sent as "commercial/business" payments.
* At least one "fee-less" option will be provided, and any fees associated with the Assignees chosen option will be the responsibility and may be deducted from the "base" pay such that the gross payment is equivalent to the bounty amount.
* Payment instructions will be received either through an issue comment or via email. If email is preferred, the Assignee must provide an email via either their public github profile or in the task comments.
* Once instructions are received, Liquid Lab shall remit payment within 5 business days unless additional information is required as defined by these terms and conditions.
* Payments may be split in two. Any additional splitting of payments must be handled by the receiving party.
* Payment is considered remitted and received when sent per-instructions. Liquid Labs shall only be liable for refund and/or additional payments if payment is not sent per the recipients instructions. Liquid Labs may, at their sole discretion, make reasonable efforts or participate in recovery of funds in other instances, but in no case shall Liquid Labs make additional payments or in anyway be liable for errors in instructions or for failure to deliver payments by the payment network for any reason.
* Individuals receiving payment for multiple bounties or from Liquid Labs through other channels must use the same identifying information and contact addresses or notify Liquid Labs of any change in such.
* Liquid Labs may need to collect additional information for tax purposes. In particular, Liquid Labs may need to submit a '1099 Misc' income report for individuals earning more than a specific amount in a given calendar year. In this case, or in any case where Liquid Labs is required by applicable laws to gather additional information prior to remitting payments, payments shall be sent within 5 business days after all necessary information has been received.

### Speculative PRs

* There's nothing stopping users from submitting PRs for bounty tasks without first establishing assignment. Such submissions are termed "Speculative PRs".
* **_It is generally recommended to request and receive assignment to a bounty issue before submitting a PR._**
* The contents of a Speculative PR may be referenced and even copied by a task Assignee. In such a case, the Assignee shall receive the bounty, though the Assignee may, at their sole discretion, choose to share a portion or all of the bounty with the Speculative PR author.
* If there is no current Assignee for the issue(s) related to a Speculative PR an the PR is accepted, then Liquid Lab shall offer the bounty the primary Speculative PR author, who will be assigned the issue for the purposes of ironing out any issues, final acceptance, and payment.

### Construction

* In the first instance, Liquid Labs shall have the sole right to make a determination of the meaning of the terms "significantly" and "minor" as regards to these terms and conditions. The Assignee has the right to dispute such a judgement under these terms and conditions.
* These terms and conditions should be understood as a "plain language" offer and do not rely on any legal terms or precedent for their meaning. In the case of any dispute over the meaning or implementation of these terms, such "strict construction" shall not be held against the interests of any party.
* In the instance of any typographical or grammatical error or ambiguity in these terms and conditions, the "clearly intended" or "common sense" meaning of a phrase shall take precedence over a strict reading.

### Choice of law

* The parties agree these terms and conditions are to be understood with regard to the laws and regulations of the United States and the state of Texas.

### Disputes

* Due to the generally limited amount of work and payments, the Assignee and Liquid Labs agree that any disputes arising under these terms and conditions will be settled by arbitration under the following terms.
* As Liquid Labs has the option to simply reject work and re-assign a task after the end of any Lock-In Period, Liquid Labs shall not generally have cause to dispute performance or raise a case under these terms and conditions except in the case which Liquid Labs alleges outright fraud and or malevolent action on the part of the Assignee, such as the introduction of intentional flaws, security holes, backdoors, or similar in submitted code, wether intentionally or through gross negligence.
* Only the Liquid Labs and the Assignee shall have rights to dispute performance under these terms and conditions and neither may assign their rights to a third. party.
* The Assignee may claim compensation only for any balance on the last offered and accepted bounty payment.
* The complaining party shall give notice to the counter-party at the email address provided. To be valid, the complaint must clearly state the claims at issue on the basis these terms and conditions and propose one or more cures which would be acceptable to the complaining party.
* The counter-party shall have 10 business days to either accept a proposed cure or refute the claims in whole or in part. The counter party may propose an alternate cure or compromise without necessarily conceding the original claims.
* The complaining party shall have 10 days to either accept the response, continue dialog, or refer the claims to arbitration.
* So long as dialog continues, each party shall have 10 business days to respond in a like manner with further discussion of the claims and potential cures, acceptance of a proposed cure, or by referring the matter to arbitration.
* Once the matter is referred to arbitration, the parties shall have up to 30 days to select a mutually agreeable arbitrator, or they may agree at any time to submit the case to an arbitrator selected by the Better Business Bureau (or its natural successor) and each agrees to undertake whatever steps are necessary to secure such services in a timely manner. If no agreement can be reached by the end of the 30 day period, then they must submit the case to arbitration through the Better Business Bureau.
* Each party shall provide the arbitrator with their own summary of the case, a copy of the email discussion, the a copy of these terms and conditions in effect at the commencement of the work, and any supporting documentation they deem relevant to the case.
* Each party agrees and affirms that it is their intent and desire to conduct the arbitration via email and, if necessary, remote video or telephonic sessions with the arbitrator to set the schedule and deadlines relating thereto.
* Each party agrees and affirms that it desires that no more than 1 hour of each party's time be spent in conference per $100 at issue.
* The arbitrator shall have the option to reduce any damages awarded to either party based on a theory of actual harm, mutual responsibility, and/or to account for an "outsized" bounty payment as defined by these terms and conditions.
* In addition to any reward of damages, the arbitrator shall direct the payment or compensation of arbitration fees according to the English Rule convention that the "loser pays". The arbitrator is free to apportion such payment on a theory of mutual responsibility where applicable and need not hold one party entirely liable for all fees.
* Only arbitration fees and no other costs incurred by either party shall be awarded under these terms.
* Barring any conflicts, the judgement of a duly appointed and qualified arbitrator under these terms and conditions shall be binding on both parties and the prevailing party may seek court judgement and enforcement, if necessary, and the prevailing party may submit a tally of all fees and reasonable expenses to the court, and any such additional costs approved by the court shall be added to the sum due to the prevailing party in any final judgement.
