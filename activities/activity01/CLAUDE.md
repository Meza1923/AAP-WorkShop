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