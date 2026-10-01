# Activity 3: Event-Driven Ansible (EDA)

## Scope
When a participant's Automation Receipt webapp (Activity 1 Part B) is scaled to zero,
the alert `AutomationReceiptDown` fires, Alertmanager sends it to the participant's EDA
event stream, and a rulebook launches the Part B job template, which restores the app.
Build participant content in `activities/activity03/` and the rulebook in `{RULEBOOK_DIR}`.

Already in place from earlier activities (do not rebuild):
- The Deployment `automation-receipt` and the PrometheusRule with alert
  `AutomationReceiptDown` (`for: 1m`), created by the Activity 1 Part B playbook.
- The participant's OpenShift credential, Part B inventory (`localhost`, no host
  variables), Activity 1 project, and Part B job template (its survey asks the namespace
  as `AAP_NAMESPACE`; the optional `WEBAPP_IMAGE` has a default). The remediation action
  must pass `AAP_NAMESPACE` in `job_args.extra_vars`, because nobody answers the survey
  when EDA launches the job.
- The participant's CaC fork and webhook pipeline from Activity 2.

## Learning design (must be preserved)
- Rules match on event data. Participants first SEE a real event, then write a rule for it.
- Participants write BOTH the condition and the action of the remediation rule.
  The throttle is provided ready: it's a guardrail to discuss, not something to discover.
- The remediation action is the participant's existing Part B job template. No new
  remediation playbook. The Automation Receipt then shows a job not launched by a person.
- The "connect Alertmanager" job template is created through CaC (Activity 2), not by hand.
  The README gives its full YAML; participants paste it into their fork and push.
- EDA objects (credential, project, event stream, activation) are created by hand.
  The README acknowledges in one sentence that in real life these could also be managed as code.

## Deliverable 1: Rulebook (in {RULEBOOK_DIR})
- File name: `automation-receipt-remediation.yml`.
- Starter version (what participants receive) must be valid and runnable as-is:
  - One rule that prints every received event (debug action).
  - The remediation rule present but COMMENTED OUT, with the throttle filled in and
    the condition and action marked as `TODO` for participants to write.
- Throttle on the remediation rule: act at most once within 5 minutes, grouped by
  alert name.
- Rule ordering: verify how ansible-rulebook handles multiple matching rules. If only
  the first matching rule fires per event, the print-everything rule would block the
  remediation rule. Design the starter and the README so the final rulebook works
  (e.g. remediation rule first). Explain the chosen approach in the final report.
- Verify for AAP 2.7: how event streams attach to a rulebook source, and exactly which
  folder EDA projects discover rulebooks in.
- The rulebook must not contain any secrets, URLs, or tokens.

## Deliverable 2: Sample alert
- `activities/activity03/sample-alert.json`: a realistic Alertmanager webhook payload
  (current webhook format) for one firing `AutomationReceiptDown` alert, with labels
  `alertname`, `namespace` (placeholder), `deployment: automation-receipt`,
  `severity: warning`, and populated `commonLabels`.
- README shows how to send it to the event stream with the correct auth header, in two
  versions: bash (`curl`) and Windows PowerShell.

## Deliverable 3: "Connect Alertmanager" playbook
Location: `activities/activity03/connect-alertmanager/`. It is reached through the
Activity 1 project (main repo), not through the CaC fork.
- `hosts: localhost`, `connection: local`, `gather_facts: false`, interpreter set to
  `{{ ansible_playbook_python }}`, `kubernetes.core` modules, auth only through the
  attached OpenShift credential.
- Inputs:
  - `AAP_NAMESPACE`, `event_stream_url` and `event_stream_token` from the survey
    (the playbook maps `AAP_NAMESPACE` to `app_namespace` internally)
- Assert all three are defined, with clear messages.
- In `app_namespace`, create:
  1. A Secret holding the event stream token
  2. An `AlertmanagerConfig` that routes `AutomationReceiptDown` to a webhook receiver
     at `event_stream_url`, authenticating with the Secret. `sendResolved: false`.
     Short grouping delay so the demo is quick.
- Verify which auth method AAP 2.7 event stream credentials accept, and make the
  Alertmanager side send exactly that (header name and format, e.g. whether a
  "Bearer " prefix is expected). This is a likely silent failure point. Document the
  choice in the README so participants pick the matching credential type.
- `no_log: true` on every task that handles the token.
- Idempotent, ansible-lint clean.

## Deliverable 4: CaC job template definition (shown in the README, not committed)
Read `activities/activity02/` first and match its config structure exactly.
- Name: `<username>-connect-alertmanager`
- Inventory: the participant's Part B inventory. Project: the Activity 1 project.
  Credential: the participant's OpenShift credential. Use the exact naming from Activity 1.
- Survey enabled with three required questions:
  - `AAP_NAMESPACE`: text
  - `event_stream_url`: text
  - `event_stream_token`: password type, NO default value
- Never include any token or URL value in this YAML.

## README requirements
Follow the root writing style. Estimated time: about 120 minutes. For each step: what
to do, why it matters (one or two sentences), expected result.
1. Goal: what EDA adds (automation that reacts to events, not to people) in a few sentences.
2. Steps:
   1. Look at the starter rulebook in your fork: source, rules, actions. (5 min)
   2. Create the EDA objects: AAP credential for EDA, EDA project pointing to your fork,
      event stream credential, event stream named `<username>-alerts`, and a rulebook
      activation using the starter rulebook. (30 min)
   3. Send the sample alert and read the event in the activation output. Point out where
      the alert name is in the event. (15 min)
   4. Write the condition and the action, using what you saw in the event. Tiered help:
      Hint 1 (conceptual), Hint 2 (docs link), full solution in a collapsed `<details>`
      block. Then push, resync the EDA project, and restart the activation. (20 min)
   5. Send the sample alert again. Confirm your Part B job ran and the Automation
      Receipt shows it was not launched by you. (10 min)
   6. Add the connect-alertmanager job template to your CaC config: full YAML given,
      exact file to paste into, warning about indentation. Push, confirm the job
      template appears, launch it, fill in the survey. (15 min)
   7. Scale the `automation-receipt` deployment to zero in the OpenShift console.
      Watch: alert fires (about 1 minute), event arrives, job runs, app returns,
      receipt updates. (15 min)
   8. Guardrails: what the throttle does (first event acts immediately, repeats within
      5 minutes are ignored), what happens if remediation fails, when to require human
      approval instead. Short, no lecture. (10 min)
3. Troubleshooting: activation won't start (rulebook syntax, decision environment);
   401/403 when sending the sample (token or header format); no event in the output
   (wrong URL, event stream not attached to the activation); condition never matches
   (wrong field path, rule ordering); job not launched (EDA's AAP credential, job
   template name or organization mismatch); alert not firing (wait for the 1-minute
   delay, check the alert in the console); alert firing but no event (AlertmanagerConfig,
   auth format); indentation errors in the pasted CaC YAML.
4. Recap: the full loop, from scaled to zero to restored, and which object does what.