# Activity 1: AAP Basics

## Scope
Activity 1 has two parts:
- Part A: deploy nginx on the participant's Linux VM. Designed below. Build it in
  `activities/activity01/webapp-vm/`.
- Part B: deploy a webapp on OpenShift. Not designed yet. Do not create anything for it.
  It will be added later in its own subfolder next to Part A.

## Part A learning design (must be preserved)
Participants build every AAP object by hand in the UI. They do NOT write the playbook.
- SSH authentication uses a Machine credential with an SSH private key.
  Lesson: secrets live encrypted in AAP, never in playbooks, inventory, or Git.
- The playbook requires two variables with NO defaults anywhere:
  - `nginx_port`: set by participants as a HOST variable in the inventory.
    Lesson: values that describe the host belong in the inventory.
  - `page_title`: provided through a SURVEY on the job template.
    Lesson: values chosen at run time belong in a survey.
- The first run fails on purpose. The playbook reports only the FIRST missing variable,
  so participants fix one, re-run, hit the second, fix it, re-run. This is intended.

## Part A playbook requirements
- `hosts: all`, `become: true`.
- First tasks: separate assert tasks for `nginx_port`, then `page_title`, so the play stops
  at the first missing one. Failure message names the variable and points to the README
  section "Fix the missing variables", but does NOT say where to set it.
- Validate that `nginx_port` is an integer.
- Install nginx; deploy a server config template listening on `nginx_port`; deploy an
  index.html template showing `page_title` (HTML-escaped) and the host's name.
- Handlers reload/restart nginx only when config changes. nginx started and enabled.
- Open the port in firewalld if firewalld is running.
- Final tasks: verify the page responds locally with the uri module, then print the URL
  to open in the browser.
- Fully idempotent: a second run with the same values reports changed=0.
- NEVER define `nginx_port` or `page_title` in defaults, vars, group_vars, host_vars, or
  anywhere in the repo. Doing so silently breaks the exercise.

## Part A README requirements
For each step: what to do, why it matters (one or two sentences), expected result.
1. Goal and estimated time (75-90 minutes).
2. What you were given: VM address, SSH username, SSH key, AAP URL and login (placeholders).
3. Naming convention reminder.
4. Steps:
   1. Create a Machine credential with the SSH key.
   2. Create an inventory and add the VM as a host.
   3. Create a project pointing to the Git repo, sync it, verify success.
   4. Create a job template and run it. Expected: it FAILS on purpose. Add the note:
      "You may need more than one fix before the job succeeds."
   5. "Fix the missing variables" (title must match the playbook's failure message).
      Per variable, tiered help: Hint 1 (conceptual nudge), Hint 2 (official docs link),
      Solution in a collapsed `<details>` block. Survey answer variable name must be
      exactly `page_title`, and the solution must mention enabling the survey.
   6. Run again, enter a title, open http://<vm-address>:8080, confirm the title appears.
   7. Run again with the same values, confirm changed=0, explain idempotency briefly.
5. Troubleshooting: project sync fails; host unreachable (IP/user/key); privilege
   escalation errors; survey not enabled; variable name typo in the survey.
6. Recap: each AAP object and its purpose.

---
## Part B: webapp-openshift

### Learning design (must be preserved)
Part B must not repeat Part A. It teaches three new things:
1. Automating an API instead of a server. The inventory contains only `localhost`, and
   the credential is an OpenShift API bearer token, not an SSH key. No Machine credential
   is attached to this job template.
2. Reuse. Participants reuse the SAME project from Part A (same repo, different playbook
   path). They do not create a new project.
3. AAP-provided variables. AAP automatically passes job metadata to every playbook
   (e.g. job ID, job template name, launching user, launch type, project revision).
   Participants set none of these; the webapp displays them.
Namespace: participants enter it at launch through a SURVEY question with answer
variable `AAP_NAMESPACE` (Text, required). The playbook maps it to `app_namespace`
internally. The inventory holds only `localhost`, with no host variables.
Image: a second survey question, `WEBAPP_IMAGE` (Text, NOT required, default
`docker.io/nginxinc/nginx-unprivileged:latest`). The README gives the image. It must not be
required: API launches (EDA in Activity 3) get the default only for optional questions.
Preparation for Activity 3: the playbook also deploys an alert rule that fires when the
webapp has zero available replicas. Participants do nothing with it in Activity 1.

### The webapp: "Automation Receipt"
A single static page, dark dashboard style, visually polished, little content. It shows:
- Deployed by AAP job #<job id>
- Job template name
- Launched by <user> and launch type
- Project revision (Git commit)
- Namespace and deployment time
- A small visual "workshop journey" strip: VM deployed (done), OpenShift deployed (done),
  CaC (next), EDA (next)
Rules:
- Fully self-contained: inline CSS and JS, no external fonts, scripts, or images.
- Responsive, good contrast. HTML-escape every injected value.
- No personal greeting or participant name beyond what the job metadata shows.

### Playbook requirements
- `hosts: localhost`, `connection: local`, `gather_facts: false`, and set
  `ansible_python_interpreter` to `{{ ansible_playbook_python }}` so the execution
  environment's Python (with the Kubernetes libraries) is used.
- Use `kubernetes.core` modules. Confirm the collection exists in {EE_NAME}.
- Authenticate only through the AAP OpenShift/Kubernetes credential (it injects the API
  host and token as environment variables). Never put the API URL or token in the repo.
- First task: assert `AAP_NAMESPACE` is defined, with a clear message pointing to the survey
  step in the README.
- Read AAP job metadata variables (verify exact names against official AAP 2.7 docs).
  Give each a fallback such as "not run from AAP" so the playbook still works outside AAP.
  (Fallbacks are allowed here; the no-defaults rule applies only to Part A's variables
  and `AAP_NAMESPACE`.)
- Deployment time comes from the time the playbook runs, not gathered facts.
- Resources, all in `app_namespace`, all with fixed names and a consistent label
  (e.g. `app: automation-receipt`), because Activity 3 depends on them:
  1. ConfigMap containing the rendered index.html
  2. Deployment named `automation-receipt` using the `WEBAPP_IMAGE` survey answer, mounting
     the ConfigMap at `/usr/share/nginx/html`, port 8080, 1 replica, small CPU/memory requests and limits,
     readiness and liveness probes
  3. Service on port 8080
  4. Route with edge TLS
  5. PrometheusRule named `automation-receipt-alerts` with one alert,
     `AutomationReceiptDown`:
     - fires when the `automation-receipt` deployment in `app_namespace` has zero
       available replicas (kube-state-metrics, e.g. `kube_deployment_status_replicas_available`)
     - `for: 1m`, so the Activity 3 demo doesn't take long
     - labels: `severity: warning`, `app: automation-receipt`
     - annotations: a short summary and description naming the namespace and deployment
     - must be evaluated where kube-state-metrics are visible: do NOT restrict it to
       the `leaf-prometheus` evaluation scope
- Add a checksum of the ConfigMap content as a pod template annotation so a new receipt
  triggers a rollout.
- Wait for the rollout to complete, verify the Route URL responds with the uri module,
  then print the URL.
- Idempotency note: the receipt contains the job ID, so every run legitimately changes
  the ConfigMap. This is expected; the README explains it (see step 7 below).
- Do NOT create Alertmanager routing, receivers, webhooks, or any EDA-related objects.
  Only the PrometheusRule is in scope for Activity 1.

### README requirements
Same style as Part A. Estimated time: 45-60 minutes.
1. Goal: what's new compared to Part A (API instead of SSH, reuse, AAP-provided variables).
2. What you were given: OpenShift API URL, namespace name, service account token (placeholders).
3. Steps:
   1. Create an "OpenShift or Kubernetes API Bearer Token" credential with the API URL
      and token. Explain why this replaces the SSH key.
   2. Create a new inventory with host `localhost` and no host variables.
   3. Reuse the project from Part A. Sync it and confirm the new playbook is available.
   4. Create a job template: new inventory, SAME project, the Part B playbook, and only
      the OpenShift credential. Point out that no Machine credential is needed. Add and
      enable a survey with two Text questions: `AAP_NAMESPACE` (required, no default) and
      `WEBAPP_IMAGE` (optional, default `docker.io/nginxinc/nginx-unprivileged:latest`).
   5. Run it, open the Route URL, and view your Automation Receipt. Mention in one
      sentence that the job also created an alert rule, which is used in Activity 3.
   6. "Where did these values come from?": a table mapping each value on the page to its
      source (AAP automatically vs. your survey answer).
   7. Run again. The job ID on the receipt changes, and the job reports changes. Explain
      why this doesn't contradict Part A: idempotency means no change when the desired
      state is the same, and here the desired state includes the job ID.
4. Troubleshooting: invalid or expired token; TLS/certificate errors; "forbidden" errors
   from a wrong namespace; "forbidden" when creating the alert rule (missing monitoring
   permissions); pod not starting (image or permission issue); Route not reachable.
5. Recap: comparison table of Part A vs Part B (target, credential type, inventory, variables).