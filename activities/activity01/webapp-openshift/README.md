# Activity 1, Part B: a webapp on OpenShift

## 1. Goal

You'll deploy a small web page, the Automation Receipt, into your own OpenShift namespace. Three things are different from Part A:

- AAP talks to an API instead of logging in to a server over SSH.
- You reuse the project you created in Part A.
- AAP passes information about the job to the playbook by itself, and the page shows it.

Time: 45-60 minutes.

## 2. What you were given

| | |
|---|---|
| OpenShift API URL | `<ocp-api-url>` |
| Namespace | `<namespace>` |
| Service account token | `<token>` |
| AAP URL and login | the same as Part A |

## 3. Naming

Same rule as Part A, start every new object with your username:

- `<username>-ocp-credential`
- `<username>-ocp-inventory`
- `<username>-ocp-template`

## 4. Steps

### Step 1: OpenShift credential

Create a credential of type **OpenShift or Kubernetes API Bearer Token** named `<username>-ocp-credential`. Enter the API URL and the token from section 2. (TODO: verify menu path)

Why: there is no server to log in to this time. The job calls the OpenShift API, and the token is how it proves who it is. Like the SSH key, it stays encrypted in AAP and never goes in Git.

### Step 2: Inventory with localhost

Create `<username>-ocp-inventory` and add one host named `localhost`. In its **Variables** field, set your namespace:

```yaml
app_namespace: <namespace>
```

(TODO: verify menu path)

Why: same lesson as Part A. The namespace describes where the app lives, so it belongs in the inventory, on the host. The job runs on `localhost` inside the execution environment and sends its requests from there.

### Step 3: Reuse your project

Open `<username>-nginx-project` from Part A. Sync it again and check it finishes with **Successful**. (TODO: verify menu path)

Why: one project holds all your playbooks. You point at a different playbook in the same repo, so you don't create a second project.

### Step 4: Job template

Create `<username>-ocp-template`:

- Inventory: `<username>-ocp-inventory`
- Project: `<username>-nginx-project`
- Playbook: `activities/activity01/webapp-openshift/receipt.yml`
- Credential: `<username>-ocp-credential`
- Execution environment: Default

Add only the OpenShift credential. This job needs no Machine credential, because nothing here uses SSH. (TODO: verify menu path)

### Step 5: Run it

Launch the template. When the job finishes, look for the last task in the output. It prints the URL of your app. Open it in your browser.

Why: the playbook creates a ConfigMap, a Deployment, a Service and a Route in your namespace. The page you see is served from the ConfigMap.

### Step 6: Where did these values come from?

You set none of the job details on the page. AAP passed them to the playbook.

| On the page | Where it came from |
|---|---|
| Job number | AAP, automatically |
| Job template name | AAP, automatically |
| Launched by and launch type | AAP, automatically |
| Project revision (Git commit) | AAP, automatically |
| Namespace | Your inventory (`app_namespace`) |
| Deployed at | The time the playbook ran |

### Step 7: Run it again

Launch the template a second time and reload the page.

The job number on the page changes, and the job reports changes. That doesn't contradict Part A. Idempotency means nothing changes when the desired state is the same. Here the desired state includes the job number, so each run is a different state.

## 5. Troubleshooting

- **Unauthorized or invalid token:** the token is wrong or has expired. Check the credential, and ask the instructor for a new one if needed.
- **Certificate errors:** the cluster certificate is not trusted by the job. Ask the instructor.
- **Forbidden:** your token can only work in your own namespace. Check that `app_namespace` in the host variables matches `<namespace>` exactly.
- **Missing required variable `app_namespace`:** the variable is missing or misspelled on the `localhost` host.
- **Pod does not start:** check the pod events in the OpenShift console for image or permission errors, and tell the instructor.
- **Route does not load:** wait a minute and try again. If it still fails, check that the pod shows as ready.

## 6. Recap

| | Part A | Part B |
|---|---|---|
| Target | A Linux VM | The OpenShift API |
| Credential | Machine (SSH key) | OpenShift or Kubernetes API Bearer Token |
| Inventory | Your VM | `localhost` |
| Host variable | `nginx_port` | `app_namespace` |
| Run-time input | `page_title` from a survey | none, AAP supplies the job details |
| Project | Created | Reused |
