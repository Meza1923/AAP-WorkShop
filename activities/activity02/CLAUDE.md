# Activity 2: Configuration as Code (CaC)

## Scope
Participants take the AAP objects they created by hand in Activity 1 (both Part A
webapp-vm and Part B webapp-openshift) and manage them from Git. A push to their fork
triggers a webhook, which runs a CaC job template that applies the configuration.

## Git server: GitHub or Gitea
The workshop runs with either one; the instructor decides per workshop. Wherever the steps
differ, the README gives two options: "Option A: GitHub" and "Option B: Gitea".
- GitHub: participants fork `https://github.com/Meza1923/AAP-WorkShop` into their own
  GitHub account (`<github-user>`).
- Gitea: runs on the cluster (`openshift/gitea/`). The instructor imports the workshop
  repo as a public repo; participants fork it there. Gitea logins are the same username
  and password as AAP. Gitea address placeholder: `<gitea-host>`.
- The README calls the participant's fork URL `<fork-url>` (defined in step 1, also used
  by Activity 3).
- Forks are public on both. Nothing secret may ever be committed.
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
    `localhost` (no host variables), and a job template whose survey asks the namespace
    (`AAP_NAMESPACE`, required) and the image (`WEBAPP_IMAGE`, optional, default
    `docker.io/nginxinc/nginx-unprivileged:latest`), and that uses the OpenShift credential
    instead of the Machine credential.
- Object names in YAML must match the Activity 1 objects EXACTLY (including the username
  prefix). Otherwise CaC creates duplicates instead of managing the existing objects.
- Drift test: participants change a managed field by hand in the UI, run CaC, and see it revert.
- Recovery test: participants delete the Part B job template in the UI, run CaC, see it
  restored, then launch it and see the Automation Receipt show a new job.

## Technical requirements
- Use only `ansible.controller` and `ansible.platform` modules. Both are in the Default
  execution environment of AAP 2.7, so no extra collection or custom execution
  environment is needed. Do not switch to `infra.aap_configuration`: it is not in the
  Default execution environment (see `Execution-environment/README.md`).
- The CaC playbook runs on `localhost`, authenticates to AAP only through the AAP
  credential attached to the job template (environment variables injected by AAP).
  No URLs, usernames, passwords, or tokens in the repo.
- Only create or update objects. NEVER delete objects that are not in the configuration.
  Do not use any "object diff" or cleanup functionality that removes unmanaged objects;
  it would delete participants' credentials and bootstrap objects.
- All managed objects belong to the participant's organization (placeholder `<organization>`).
- Layout, in `activities/activity02/aap_config_as_code/`:
  - `deploy_main.yaml`: the playbook
  - `controller_vars.yml`: connection settings, filled from the AAP credential at run time
  - `roles/deploy_<kind>/` for projects, inventories, hosts and job templates. Each has
    `vars/main.yml` (data, the only files participants edit) and `tasks/main.yml` (logic)
- YAML must pass `yamllint`; the playbook must pass `ansible-lint` and `--syntax-check`.

## Webhook requirements (these are the usual failure points)
- The CaC job template uses GitHub as webhook service, for both Git servers. Gitea's
  webhook (type "Gitea") sends GitHub-compatible headers (`X-GitHub-Event`,
  `X-GitHub-Delivery`, `X-Hub-Signature`) and a GitHub-style push payload (`ref`,
  `after`). Verified against Gitea 1.27.3 only, not yet end to end with AAP.
- Participants copy the job template's webhook URL and webhook key into their fork's
  webhook settings: content type `application/json`, push events only.
  - GitHub: sends a test event as soon as the webhook is saved.
  - Gitea: sends nothing by itself; participants click **Test Delivery**.
- The CaC project MUST have "update revision on launch" enabled. Otherwise the webhook
  job runs the previous commit and participants think their push had no effect.

## README requirements
Follow the root writing style. Estimated time: about 110 minutes. For each step: what to
do, why it matters (one or two sentences), expected result.
1. Goal: what CaC gives you (consistent, auditable, recoverable) in three short sentences.
2. Warning box near the top: your fork is public. Never commit passwords, keys, or tokens.
3. Steps:
   1. Fork the repo (GitHub or Gitea option) and look at the skeleton. Explain what each
      file describes. (10 min)
   2. Create the bootstrap objects: AAP credential, CaC project (with update revision on
      launch), CaC job template with webhook enabled (service GitHub, also for Gitea).
      Explain why these stay manual. (20 min)
   3. Configure the webhook in the fork's settings (GitHub or Gitea option). Show how to
      check "Recent Deliveries". (15 min)
   4. Replace the example values to match your Part A objects. Place the exact-name
      warning right here. Commit, push, confirm the webhook job ran and AAP matches. (20 min)
   5. Add Part B by copying and adapting the examples. Push and verify. (20 min)
   6. Drift test: change a managed field (e.g. a job template description) in the UI,
      run the CaC job, confirm it reverted. (10 min)
   7. Recovery test: delete your Part B job template, run the CaC job, confirm it's back,
      launch it, check the Automation Receipt. Note that a deleted credential could NOT be
      restored this way, and why. (15 min)
   8. Show where the audit trail is: the fork's commit history.
4. Troubleshooting: webhook shows failed delivery (GitHub or Gitea); signature or 403 errors
   (wrong webhook key); job ran but nothing changed (update revision on launch disabled);
   duplicate objects appeared (name mismatch); "credential not found" (credential name
   mismatch); authentication to AAP failed; YAML syntax errors.
5. Recap: what CaC restores, and what it does not (credentials, job history).