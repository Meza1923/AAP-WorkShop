# Workflow Demonstration (instructor only)

## Purpose
A live demo at the end of day 1 showing that a workflow combines independent job
templates into one process with logic. Presented by the instructor; participants only watch.
Scenario: stress test the nginx webapp on the instructor's Part A VM. If it meets the
performance limits, report success. If not, reload nginx and report that the server
needs more capacity.

## Key concepts the demo must show
- Each job template is useful on its own and knows nothing about the others.
- The workflow adds the logic: order, success and failure branches.
- Data passes between jobs in a workflow (the load test results reach the check job
  and the notify jobs through `set_stats`).
- A workflow survey asks once and its answers reach every job.
- The failure branch can be triggered on demand with a strict survey limit.

## Reused from Activity 1 (instructor's own Part A objects)
The Part A inventory (VM with `nginx_port`), Machine credential, and project.
No new inventories or credentials.

## Playbooks
All in `workflow-demonstration/`. ansible-lint clean, idempotent where it makes sense.
1. `load-test.yml`
   - `hosts: all`, `become: true`.
   - Ensure the load tool is installed on the VM (e.g. `ab` from `httpd-tools`).
   - Run it on the VM against `http://localhost:{{ nginx_port }}/`, with `requests` and
     `concurrency` from the workflow survey. The load stays on the VM itself; it must
     never run from the execution environment.
   - Parse: total requests, failed and non-2xx responses, requests per second, average
     response time in ms.
   - Publish results with `set_stats` as one structured variable (e.g. `stress_results`).
   - The load command itself reports `changed_when: false`.
2. `check-results.yml`
   - `hosts: localhost`, `connection: local`, `gather_facts: false`.
   - Assert `stress_results` exists, with a clear message if it doesn't (e.g. run outside the workflow).
   - Compare against survey limits `max_avg_response_ms` and `max_error_percent`.
   - Print a readable summary table of results vs. limits.
   - FAIL the job if any limit is exceeded, with a message naming which limit and by how much.
     The failure is what sends the workflow down the failure branch.
3. `reload-nginx.yml`
   - `hosts: all`, `become: true`. Reload nginx, then verify the page responds.
4. `notify.yml`
   - `hosts: localhost`, `connection: local`.
   - Prints a clear, well-formatted summary including the `stress_results` numbers.
   - Message depends on `notify_outcome`: `passed` or `capacity`
     ("stress test failed, nginx reloaded, the server should be extended").
   - Used by TWO job templates with fixed extra vars, one per outcome.
   - Include a comment noting that in production this would be an AAP notification
     template (email, Teams, Slack) instead of a printed message.

## Job templates (5)
- `Workflow demo - Load test`
- `Workflow demo - Check results`
- `Workflow demo - Reload nginx`
- `Workflow demo - Notify passed` (extra vars: `notify_outcome: passed`)
- `Workflow demo - Notify capacity` (extra vars: `notify_outcome: capacity`)
Provide `cac/job_templates.yml` defining these five, using the same configuration
collection and structure as Activity 2, so the instructor can create them in one run.
Do NOT define the workflow in CaC; the instructor builds it live in the visual editor.

## Workflow (built live by the instructor; describe it in the notes)
```
Load test ──success──> Check results ──success──> Notify passed
                              │
                              └──failure──> Reload nginx ──always──> Notify capacity
```
Workflow survey questions, with defaults:
- `requests` (integer, e.g. 2000)
- `concurrency` (integer, e.g. 50)
- `max_avg_response_ms` (integer, e.g. 200)
- `max_error_percent` (integer, e.g. 1)
Verify for AAP 2.7: that workflow survey answers and `set_stats` data reach every node,
including nodes on the failure branch. Report the findings.

## Deliverable: DEMO-NOTES.md (for the instructor only)
Short and practical, following the root writing style:
1. Setup: what to create before the session and how (CaC file for the job templates).
2. Building the workflow live: node by node, which link type (success, failure, always),
   and the survey questions.
3. Demo run 1: default limits, expected result: passes.
4. Demo run 2: strict limit (e.g. `max_avg_response_ms: 1`), expected result: failure
   branch, nginx reloaded, capacity message.
5. Talking points, one or two sentences each: each job works alone; the workflow adds the
   logic; data passed between jobs; reloading recovers the service but does not fix
   capacity, which is why the notification asks to extend the server.
6. What can go wrong during the demo and the quick fix for each.