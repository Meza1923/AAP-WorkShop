# Activity 1, Part A: nginx on your Linux VM

## 1. Goal

You'll set up everything AAP needs to run a playbook on your own VM, then use it to put nginx on that VM. The playbook is already written (`nginx.yml`). Your job is the AAP side.


## 2. What you were given

| | |
|---|---|
| VM address | `<vm-address>` |
| SSH user | `lab-user` |
| SSH private key | `<ssh-private-key>` |
| AAP URL | `<aap-url>` |
| AAP login | `<username>` / `<password>` |
| Git repo | `<git-repo-url>` (TODO: instructor to provide the repository URL) |

## 3. Naming

Everyone shares this AAP, so start every object name with your username:

- `<username>-nginx-credential`
- `<username>-nginx-inventory`
- `<username>-nginx-project`
- `<username>-nginx-template`

## 4. Steps

### Step 1: Machine credential

Create a **Machine** credential named `<username>-nginx-credential`. Username `lab-user`, paste in the SSH private key. (TODO: verify menu path)

Why: the key lives encrypted in AAP. It never goes in a playbook, an inventory or Git.


### Step 2: Inventory and host

Create `<username>-nginx-inventory` and add your VM as a host, using `<vm-address>` as the host name. (TODO: verify menu path)

Why: the inventory is the list of machines AAP is allowed to touch.


### Step 3: Project

Create `<username>-nginx-project` (source control type Git) with the repo URL from section 2. Save it and let it sync. (TODO: verify menu path)

Why: this is how playbooks get from Git into AAP.


### Step 4: Job template

Create `<username>-nginx-template`:

- Inventory: your inventory
- Project: your project
- Playbook: `activities/activity01/webapp-vm/nginx.yml`
- Credential: your credential
- Execution environment: Default
- Privilege escalation: on (nginx needs root)

Save it and launch it.


### Step 5: Fix the missing variables

Your job failed. Good. Read the error in the job output. It tells you what is missing, and it points you back to this section.

Work out where the missing value should live, fix it, and run the job again. Don't open a hint until you've tried something. If the next run fails on something else, that's expected: repeat the same routine.

#### If the job complained about `nginx_port`

Use port 8080.

<details>
<summary>Hint 1</summary>

This value describes one particular machine, not the job and not the playbook. Where does AAP keep things it knows about a single host?

</details>

<details>
<summary>Hint 2</summary>

TODO: link to AAP 2.7 docs on inventory host variables.

</details>

<details>
<summary>Solution</summary>

Open your inventory, open the host, and put this in its **Variables** field:

```yaml
nginx_port: 8080
```

Save. (TODO: verify menu path)

</details>

#### If the job complained about `page_title`

Pick any title you like.

<details>
<summary>Hint 1</summary>

Nobody can decide this value in advance. The person launching the job chooses it every time. How can a job template ask for input at launch?

</details>

<details>
<summary>Hint 2</summary>

See the [AAP 2.7 docs on surveys](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/develop-ref_controller_job_template_variables#controller-create-survey).

</details>

<details>
<summary>Solution</summary>

On your job template, add a survey with one question:

- Answer variable name: exactly `page_title`
- Type: Text
- Required: yes

Then make sure the survey is **enabled**. A survey that isn't enabled never shows up. (TODO: verify menu path)

</details>

Why: values that describe a host go in the inventory. Values chosen at run time go in a survey.

### Step 6: Run it and open the page

Launch the template and type a title, like `Hello from <username>`. When it finishes, open `http://<vm-address>:8080`.

Why: it proves the whole chain works.


### Step 7: Run it again

Launch again with the same title.

Why: running a playbook twice shouldn't change anything the second time. That's idempotency, and it's what makes re-running safe.


## 5. Troubleshooting

- **Project sync fails:** check the Git URL, and that AAP can reach the repo.
- **Host unreachable:** check the host name is your `<vm-address>`, the user is `lab-user`, and you pasted the whole key, BEGIN and END lines included.
- **Privilege escalation error:** turn on privilege escalation in the job template.
- **No survey when launching:** it's probably saved but not enabled.
- **Still asking for `page_title`:** check the survey variable name for typos. It must be exactly `page_title`. Same goes for `nginx_port` in the host variables.
- **Job succeeded but the page won't load:** tell the instructor. Port 8080 may be blocked on the cloud network.

## 6. Recap

- **Credential:** holds the SSH key, encrypted.
- **Inventory:** the machines, plus variables that describe them.
- **Project:** brings playbooks in from Git.
- **Job template:** combines the above into something you can run.
- **Survey:** asks for run-time values when you launch.
