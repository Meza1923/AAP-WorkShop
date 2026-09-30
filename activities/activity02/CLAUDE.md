# Activity 2: Configuration as Code (CaC)

## Scope
Participants take the AAP objects they created by hand in Activity 1 (both Part A
webapp-vm and Part B webapp-openshift) and manage them from Git. A push to their fork
triggers a GitHub webhook, which runs a CaC job template that applies the configuration.
Build everything in `activities/activity02/`.
Out of scope for this task: the DR session content. Do not write anything about DR.

## Learning design (must be preserved)
- Configuration lives in Git; AAP is updated to match it. Git history is the audit trail.
- Credentials are NEVER in Git. CaC references credentials by name only. They were
  created by hand in Activity 1 and stay manual. The fork is public, so this is critical.
- Bootstrap: a few objects must exist before CaC can manage anything. Participants
  create them by hand: an AAP credential, a CaC project pointing to their fork, and a
  CaC job template with webhook enabled. CaC does not manage these bootstrap objects.
- Participants write almost no YAML from scratch:
  - The skeleton contains ONE example of each object kind, modeled on Part A: an
    inventory, a host with the `nginx_port` host variable, a project, and a job template
    with the `page_title` survey. Values use obvious placeholders such as `<username>`.
    Participants replace the values to match their own Part A objects.
  - For Part B, participants copy the examples and adapt them: an inventory with
    `localhost` and the `app_namespace` host variable, and a job template with no survey
    that uses the OpenShift credential instead of the Machine credential.
- Object names in YAML must match the Activity 1 objects EXACTLY (including the username
  prefix). Otherwise CaC creates duplicates instead of managing the existing objects.
- Drift test: participants change a managed field by hand in the UI, run CaC, and see it revert.
- Recovery test: participants delete the Part B job template in the UI, run CaC, see it
  restored, then launch it and see the Automation Receipt show a new job.

## Technical requirements
- Use the configuration collection appropriate for {AAP_VERSION}
  (`infra.aap_configuration` for AAP 2.5+). Verify variable names and structure against
  the collection's official documentation. Do not guess them.
- The collection must be available at run time: either it exists in {EE_NAME}, or add
  `collections/requirements.yml` in the CaC folder so AAP installs it on project sync.
  Confirm which applies and report it.
- The CaC playbook runs on `localhost`, authenticates to AAP only through the AAP
  credential attached to the job template (environment variables injected by AAP).
  No URLs, usernames, passwords, or tokens in the repo.
- Only create or update objects. NEVER delete objects that are not in the configuration.
  Do not use any "object diff" or cleanup functionality that removes unmanaged objects;
  it would delete participants' credentials and bootstrap objects.
- All managed objects belong to the participant's organization (placeholder `<organization>`).
- Suggested layout (adapt to repo conventions):
  - `activities/activity02/cac/apply-config.yml` (the playbook)
  - `activities/activity02/cac/config/` with one file per object kind
    (inventories, hosts, projects, job templates)
- YAML must pass `yamllint`; the playbook must pass `ansible-lint` and `--syntax-check`.

## Webhook requirements (these are the usual failure points)
- The CaC job template uses GitHub as webhook service. Participants copy its webhook URL
  and webhook key into their fork's GitHub webhook settings: content type
  `application/json`, push events only.
- The CaC project MUST have "update revision on launch" enabled. Otherwise the webhook
  job runs the previous commit and participants think their push had no effect.

## README requirements
Follow the root writing style. Estimated time: about 110 minutes. For each step: what to
do, why it matters (one or two sentences), expected result.
1. Goal: what CaC gives you (consistent, auditable, recoverable) in three short sentences.
2. Warning box near the top: your fork is public. Never commit passwords, keys, or tokens.
3. Steps:
   1. Fork the repo and look at the skeleton. Explain what each file describes. (10 min)
   2. Create the bootstrap objects: AAP credential, CaC project (with update revision on
      launch), CaC job template with GitHub webhook enabled. Explain why these stay manual. (20 min)
   3. Configure the webhook in the fork's GitHub settings. Show how to check
      "Recent Deliveries" in GitHub. (15 min)
   4. Replace the example values to match your Part A objects. Place the exact-name
      warning right here. Commit, push, confirm the webhook job ran and AAP matches. (20 min)
   5. Add Part B by copying and adapting the examples. Push and verify. (20 min)
   6. Drift test: change a managed field (e.g. a job template description) in the UI,
      run the CaC job, confirm it reverted. (10 min)
   7. Recovery test: delete your Part B job template, run the CaC job, confirm it's back,
      launch it, check the Automation Receipt. Note that a deleted credential could NOT be
      restored this way, and why. (15 min)
   8. Show where the audit trail is: the fork's commit history.
4. Troubleshooting: webhook shows failed delivery in GitHub; signature or 403 errors
   (wrong webhook key); job ran but nothing changed (update revision on launch disabled);
   duplicate objects appeared (name mismatch); "credential not found" (credential name
   mismatch); authentication to AAP failed; YAML syntax errors.
5. Recap: what CaC restores, and what it does not (credentials, job history).