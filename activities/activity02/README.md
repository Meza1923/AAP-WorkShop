# Activity 2: Configuration as Code

## 1. Goal

In Activity 1 you built your AAP objects by hand. Now you describe them in Git, and every push makes AAP match that description. That keeps AAP consistent with Git, gives you an audit trail of every change, and lets you restore a deleted object with one job run.

Time: about 110 minutes.

> [!WARNING]
> Your fork is public. Never commit passwords, SSH keys, tokens or any other secret to it. Anyone on the internet can read it, including its full history, so a secret that was committed once stays exposed even after you delete it.

## 2. What you need

| | |
|---|---|
| Workshop repo to fork | `<git-repo-url>` (TODO: instructor to provide the repository URL) |
| Your GitHub account | `<github-user>` |
| AAP URL and login | the same as Activity 1 |
| Your organization | `<organization>`, the organization your Activity 1 objects belong to |
| Your Activity 1 objects | Part A and Part B, both working |

## 3. Naming

You create three new objects by hand in this activity:

- `<username>-aap-credential`
- `<username>-cac-project`
- `<username>-cac-template`

## 4. Steps

### Step 1: Fork the repo and look at the skeleton (10 min)

Fork `<git-repo-url>` into your GitHub account, then clone your fork:

```bash
git clone https://github.com/<github-user>/<repo>.git
cd <repo>/activities/activity02/aap_config_as_code
```

This folder holds everything CaC uses:

```text
aap_config_as_code/
├── deploy_main.yaml
├── controller_vars.yml
└── roles/
    ├── deploy_projects/
    │   ├── tasks/main.yml
    │   └── vars/main.yml
    ├── deploy_inventories/
    │   ├── tasks/main.yml
    │   └── vars/main.yml
    ├── deploy_hosts/
    │   ├── tasks/main.yml
    │   └── vars/main.yml
    └── deploy_job_templates/
        ├── tasks/main.yml
        └── vars/main.yml
```

Each role separates logic from data:

- `vars/main.yml` is the data: a list of the objects that must exist. This is the only kind of file you edit.
- `tasks/main.yml` is the logic: one task that loops over that list and creates or updates each object in AAP. You don't edit it.

| File | What it describes |
|---|---|
| `deploy_main.yaml` | The playbook. It logs in to AAP, runs the four roles in order, and logs out. You don't edit it. |
| `controller_vars.yml` | Connection settings. They are filled in at run time from the credential you create in step 2, so this file holds no URL and no secret. |
| `roles/deploy_projects/vars/main.yml` | Projects: name, organization, Git URL. |
| `roles/deploy_inventories/vars/main.yml` | Inventories: name and organization. |
| `roles/deploy_hosts/vars/main.yml` | Hosts: name, the inventory they belong to, and their host variables. |
| `roles/deploy_job_templates/vars/main.yml` | Job templates: inventory, project, playbook, execution environment, credentials, privilege escalation and survey. |

Each `vars/main.yml` contains one example, modeled on your Part A objects. Values in angle brackets, like `<username>`, are placeholders you replace in step 4. Every entry also has a `state` line: `present` creates or updates the object, `absent` deletes it (see step 5). Don't rename the top-level names (`controller_projects`, `controller_inventories`, `controller_hosts`, `controller_job_templates`): the task files loop over exactly these names.

There is no role for credentials. Credentials stay in AAP, and job templates refer to them by name only.

Expected result: your fork exists on GitHub, and you have the four `vars/main.yml` files open in front of you.

### Step 2: Create the bootstrap objects (20 min)

CaC needs a way in before it can manage anything: a login for AAP, a project that reads your fork, and a job template that runs the playbook. You create these three by hand. They are not in any `vars/main.yml`, so CaC never changes them. If CaC managed its own job template, one bad push could break the job you need to fix it.

#### 2a. AAP credential

Create a credential of type **Red Hat Ansible Automation Platform** named `<username>-aap-credential` (TODO: verify menu path):

- **Red Hat Ansible Automation Platform**: `<aap-url>`
- **Username** and **Password**: your AAP login
- **Verify SSL**: on

Why: AAP hands this credential to the CaC job at run time, so the URL and password never go in Git. The job uses it to create a temporary token, does all its work with that token, and deletes the token at the end. The job can do exactly what you can do in the UI, nothing more.

#### 2b. CaC project

Create `<username>-cac-project` (TODO: verify menu path):

- Organization: `<organization>`
- **Source control type**: Git
- **Source control URL**: your fork, `https://github.com/<github-user>/<repo>.git`
- **Update revision on launch**: on

Save it and wait until the sync shows **Successful**.

Why: this project reads your fork, not the workshop repo. **Update revision on launch** makes every CaC job fetch the latest commit first. Without it, the job runs whatever commit the project synced last, and your push seems to have no effect.

Your Part A project, `<username>-nginx-project`, stays as it is and keeps pointing to the workshop repo.

#### 2c. CaC job template

Create `<username>-cac-template` (TODO: verify menu path):

- Inventory: `<username>-ocp-inventory` (your Part B inventory; the CaC playbook also runs on `localhost`)
- Project: `<username>-cac-project`
- Playbook: `activities/activity02/aap_config_as_code/deploy_main.yaml`
- Execution environment: Default execution environment
- Credential: `<username>-aap-credential`
- **Enable webhook**: on
- **Webhook service**: GitHub

Save it. The template now shows a **Webhook URL** and a **Webhook key**. Keep this page open for step 3.

Expected result: three new objects, and the project sync shows **Successful**.

### Step 3: Connect GitHub to AAP (15 min)

In your fork on GitHub, open **Settings**, then **Webhooks**, then **Add webhook**, and fill in:

- **Payload URL**: the **Webhook URL** from your job template
- **Content type**: `application/json`
- **Secret**: the **Webhook key** from your job template
- **Which events would you like to trigger this webhook?**: **Just the push event.**
- **Active**: on

Click **Add webhook**.

Why: from now on GitHub calls AAP on every push. GitHub signs each call with the secret, and AAP rejects calls with a wrong signature. That way only your fork can start your job.

GitHub sends a test event right away, and AAP starts your CaC job for it. That job fails at the task **Check that no example placeholders are left**. This is expected, because you haven't replaced the placeholders yet. It proves the webhook works.

To check a delivery, open the webhook in GitHub and go to the **Recent Deliveries** tab. Click a delivery to see the request and AAP's response:

- Response `202` with `{"message": "Job queued."}`: AAP accepted it and started a job.
- Any other code, or a red warning icon: see Troubleshooting.

Expected result: one delivery with response `202`, and in AAP a failed job of `<username>-cac-template` that complains about placeholders.

### Step 4: Describe your Part A objects (20 min)

Open the four `roles/*/vars/main.yml` files and replace every placeholder:

| Placeholder | Replace with |
|---|---|
| `<username>` | Your AAP username, for example `user7` |
| `<organization>` | Your organization |
| `<git-repo-url>` | The **Source control URL** of `<username>-nginx-project`, copied from AAP |
| `<vm-address>` | Your VM's host name, exactly as it appears in `<username>-nginx-inventory` |

> [!IMPORTANT]
> Every name must match your Activity 1 object exactly: the username prefix, upper and lower case, dashes, everything. CaC finds objects by name. If the name in Git differs, CaC creates a second object next to yours instead of managing it. Open each object in AAP and copy its name from there. The same goes for the credential name in `roles/deploy_job_templates/vars/main.yml`: it must match the credential in AAP exactly.

The example job template also sets a description and a survey question text. They probably differ from what you typed in Activity 1. That's fine: after the run, AAP shows what Git says.

Commit and push:

```bash
git add roles/
git commit -m "Manage my Part A objects with CaC"
git push
```

Why: from now on Git is the description of your objects, and each push applies it.

Expected result:

- A new delivery with response `202` in **Recent Deliveries**.
- A new job of `<username>-cac-template` with status **Successful**. Near the top of its output, **Project revision used by this job** is the commit you just pushed (`git log -1 --format=%H` shows it).
- `<username>-nginx-template` now has the description `Deploys nginx on my VM. Managed by CaC.`
- Each of your Part A objects exists once. If you see two with similar names, see "Duplicate objects appeared" in Troubleshooting.

Launch `<username>-nginx-template` once to confirm it still works.

### Step 5: Add Part B (20 min)

Now describe your Part B objects. Copy each example entry, paste it below the existing one in the same file, and change the values. Part B needs:

- `roles/deploy_inventories/vars/main.yml`: `<username>-ocp-inventory`.
- `roles/deploy_hosts/vars/main.yml`: host `localhost` in `<username>-ocp-inventory`, with the host variable `app_namespace` set to your namespace.
- `roles/deploy_job_templates/vars/main.yml`: `<username>-ocp-template`, with the Part B inventory, the SAME project as Part A, the playbook `activities/activity01/webapp-openshift/receipt.yml`, and only `<username>-ocp-credential`. Remove the `become_enabled`, `survey_enabled` and `survey_spec` lines: Part B has no survey and needs no privilege escalation.
- `roles/deploy_projects/vars/main.yml`: nothing to add. Part B reuses the Part A project.

Keep the indentation: each new entry starts with `  - name:`, aligned with the example above it.

If you leave out a field such as a survey, CaC doesn't change it. It only sets the fields you write down.

To delete an object through Git, keep its entry and change its `state` to `absent`. A delete entry needs only the name and the organization (for a host: the name and the inventory):

```yaml
  - name: <username>-old-template
    state: absent
    organization: <organization>
```

Removing an entry from the file does NOT delete the object. CaC only deletes what you explicitly mark, so the deletion shows up in your commit history like any other change. Two things to watch:

- Deleting an inventory also deletes its hosts. Remove those hosts' entries from `roles/deploy_hosts/vars/main.yml` in the same commit, or the next run fails looking for the inventory.
- Never mark `<username>-ocp-inventory` as absent. Your CaC job template runs with it.

<details>
<summary>Solution</summary>

Add to `roles/deploy_inventories/vars/main.yml`:

```yaml
  - name: <username>-ocp-inventory
    state: present
    organization: <organization>
```

Add to `roles/deploy_hosts/vars/main.yml`:

```yaml
  - name: localhost
    state: present
    inventory: <username>-ocp-inventory
    variables:
      app_namespace: <namespace>
```

Add to `roles/deploy_job_templates/vars/main.yml`:

```yaml
  - name: <username>-ocp-template
    state: present
    organization: <organization>
    description: Deploys the Automation Receipt on OpenShift. Managed by CaC.
    inventory: <username>-ocp-inventory
    project: <username>-nginx-project
    playbook: activities/activity01/webapp-openshift/receipt.yml
    execution_environment: Default execution environment
    credentials:
      - <username>-ocp-credential
```

Replace the placeholders with your own values, as in step 4.

</details>

Commit and push, the same way as in step 4.

Expected result: a new CaC job with status **Successful**, and `<username>-ocp-template` now has the description you set. Your Part B objects each exist once.

### Step 6: Drift test (10 min)

Open `<username>-nginx-template` in AAP, change its description to something else, and save. Then launch `<username>-cac-template` from AAP. You don't need a push for this.

When the job finishes, open `<username>-nginx-template` again.

Why: a change made by hand is called drift. AAP no longer matches Git. Every CaC run puts back what Git says, so a manual change lasts only until the next run. To change something for good, change it in Git.

Expected result: the description is back to `Deploys nginx on my VM. Managed by CaC.` The job output shows **Commit sent by the webhook: none**, because you launched it by hand.

### Step 7: Recovery test (15 min)

Delete `<username>-ocp-template` in AAP. Then launch `<username>-cac-template` and wait for it to finish.

Open the template list: `<username>-ocp-template` is back. Launch it, and when it finishes, open your Route URL.

Why: Git holds the full description of the template, so CaC can rebuild it from scratch.

Expected result: the Automation Receipt shows a new job number and the job template name `<username>-ocp-template`. The restored template is a new object, so its job history starts empty.

A deleted credential could NOT be restored this way. Git only holds its name, never the token or SSH key behind it, and it must stay that way because your fork is public. If a credential is deleted, the CaC job fails because it can't find the credential by name, and you recreate the credential by hand from the key or token you were given. Don't try this; just keep it in mind.

### Step 8: Find the audit trail

On GitHub, open your fork and click the commit count (or **Commits**) to see its history. Or run:

```bash
git log --oneline -- roles/
```

Every change to your AAP objects is a commit: who made it, when, and exactly which lines changed. Each CaC job also records which commit it applied (**Project revision used by this job**), so you can match any job to a commit.

Your manual change from step 6 appears nowhere in Git. Changes made in the UI leave no trace there, which is one more reason to make changes through Git.

## 5. Troubleshooting

- **Webhook shows a failed delivery in GitHub:** open the delivery and read the response. If there is no response or a timeout, check that the **Payload URL** is exactly the **Webhook URL** from AAP. If it is, tell the instructor: AAP may not be reachable from the internet.
- **Response 403, or signature errors:** the **Secret** in GitHub must be exactly the **Webhook key** from AAP, the **Content type** must be `application/json`, and the job template must have **Enable webhook** on with **Webhook service** GitHub. If you generated a new webhook key in AAP, paste it into GitHub again. After fixing, click **Redeliver** on the failed delivery.
- **Redeliver doesn't start a new job:** if AAP already ran a job for that delivery, it answers `Webhook previously received, aborting.` and starts nothing. Push a new commit or launch the job template in AAP instead.
- **Job ran but nothing changed:** compare **Project revision used by this job** in the job output with your latest commit. If they differ, or the output shows a WARNING about the commit, turn on **Update revision on launch** on `<username>-cac-project`. Also check that you pushed to the branch the project uses.
- **Duplicate objects appeared:** a name in Git doesn't match the original object. Fix the name in Git, and add a second entry with the wrong name and `state: absent` to remove the extra object. Push, and CaC deletes the duplicate while keeping your original.
- **"Credential not found":** the job fails with an error like `Request to /api/controller/v2/credentials/?name=... returned 0 items, expected 1`. The credential name in `roles/deploy_job_templates/vars/main.yml` doesn't match the credential in AAP. The same message with `projects`, `inventories` or `organizations` in the path means that name doesn't match.
- **Authentication to AAP failed:** the job fails at **Generate a temporary token for this run**. That task hides its output, because it handles your password. Check `<username>-aap-credential`: the URL is `<aap-url>`, and the username and password are the ones you log in to AAP with. Check that the credential is attached to `<username>-cac-template`. For certificate errors, ask the instructor.
- **Placeholders left:** the job fails at **Check that no example placeholders are left** and lists them. Replace them and push again.
- **YAML syntax errors:** the job fails at one of the **Deploy** tasks, and the error names the file and line. Common causes are tabs instead of spaces, a new entry indented differently from the one above it, and a missing space after a colon. Fix it and push again.

## 6. Recap

CaC restores everything described in the `vars/main.yml` files: projects, inventories, hosts with their host variables, and job templates with their credentials (by name), execution environment, privilege escalation and survey.

It does not restore:

- Credentials. Their secrets are never in Git, so you recreate them by hand.
- Job history. A restored object is new, and its past jobs are not in Git.
- Anything not in a `vars/main.yml` file, such as the three bootstrap objects.

Manual changes in the UI are not kept either. The next CaC run replaces them with what Git says.

CaC deletes an object only when its entry says `state: absent`. An object that is simply missing from the files stays in AAP.
