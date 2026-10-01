# Activity 3: Event-Driven Ansible

## 1. Goal

So far, every job ran because a person clicked **Launch** or pushed a commit. In this activity, an event starts the job. When your Automation Receipt goes down, OpenShift raises an alert, Event-Driven Ansible (EDA) receives it, and a rulebook launches your Part B job template, which brings the app back. Nobody has to notice the outage first.


## 2. What you need

| | |
|---|---|
| From Activity 1 Part B | `<username>-ocp-credential`, `<username>-ocp-inventory`, `<username>-ocp-template`, and your app running in `<namespace>` |
| From Activity 1 Part A | `<username>-nginx-project` (it holds the playbook for step 6) |
| From Activity 2 | Your fork `https://github.com/<github-user>/<repo>` and your working CaC webhook |
| AAP URL and login | the same as before |
| Decision environment | `Default decision environment` |

New objects in this activity:

- `<username>-eda-aap-credential`
- `<username>-eda-project`
- `<username>-event-stream-credential`
- `<username>-alerts` (the event stream)
- `<username>-remediation` (the rulebook activation)
- `<username>-connect-alertmanager` (created through CaC in step 6)

## 3. Steps

### Step 1: Look at the starter rulebook (5 min)

Your fork must contain the file `extensions/eda/rulebooks/automation-receipt-remediation.yml`. If it doesn't, open your fork on GitHub, click **Sync fork**, then **Update branch**. Then pull the change:

```bash
git pull
```

Open the file. A rulebook has three parts:

- `sources`: where events come from. The `alertmanager` source is a placeholder. When you start the rulebook in AAP, EDA replaces it with your event stream.
- `rules`: each rule has a `condition`, checked against every event, and an `action`, run when the condition matches.
- The two rules: the first, `Print every event`, prints each event it receives. The second rule, the one that will restart your app, is commented out. You write its condition and action in step 4. Its `throttle` is already filled in; step 8 explains it.

`match_multiple_rules: true` lets more than one rule act on the same event. Without it, only the first matching rule acts, and the print rule would block the remediation rule. Keep the print rule first: then it keeps showing every event after the remediation rule is active.

Why: EDA only finds rulebooks in `extensions/eda/rulebooks/` at the root of the repository. That is why this file does not live in the `activities/` folder.

Expected result: the file is in your fork, and you know which part is the source, which are the rules, and which are the actions.

### Step 2: Create the EDA objects (30 min)

You create these objects by hand. In real life they could be managed as code too, just like your Activity 2 objects.

#### 2a. AAP credential for EDA

In the EDA part of AAP, create a credential of type **Red Hat Ansible Automation Platform** named `<username>-eda-aap-credential`:

- **Red Hat Ansible Automation Platform**: `<aap-url>/api/controller/` (with `/api/controller/` at the end)
- **Username** and **Password**: your AAP login
- **Verify SSL**: on

Why: when a rule fires, the rulebook launches your job template through the AAP API, and it logs in with this credential.

#### 2b. EDA project

Create an EDA project named `<username>-eda-project`:

- **Source control type**: Git
- **Source control URL**: your fork, `https://github.com/<github-user>/<repo>.git`

Save it and wait until the sync finishes.

Why: EDA reads rulebooks from Git, just like AAP reads playbooks from a project.

Expected result: the project status is **Completed**. The project page doesn't list rulebooks.

#### 2c. Event stream credential

Create a credential of type **Token Event Stream** named `<username>-event-stream-credential`:

- **Token**: a long random value you choose. To generate one, run `openssl rand -hex 24` (bash) or `[guid]::NewGuid().ToString("N")` (PowerShell).
- **HTTP Header Key**: `Authorization` (the default)

Keep the token at hand for steps 3 and 6. Never commit it to your fork.

Why: Alertmanager sends the token as `Authorization: Bearer <token>`. The **Token Event Stream** type accepts exactly that: it reads the `Authorization` header and accepts the token with or without the `Bearer ` prefix. Other types, such as **Basic Event Stream** or **HMAC Event Stream**, expect a different format and would reject every alert.

#### 2d. Event stream

Create an event stream named `<username>-alerts`:

- **Event stream type**: Token Event Stream
- **Credential**: `<username>-event-stream-credential`

Save it. The event stream now shows a URL. Copy it: you need it in steps 3 and 6. If you see a test mode option, leave it off. In test mode, events are not passed to the rulebook.

Why: the event stream gives your rulebook a URL that the outside world can send events to.

#### 2e. Rulebook activation

Create a rulebook activation named `<username>-remediation`:

- **Project**: `<username>-eda-project`
- **Rulebook**: `automation-receipt-remediation.yml`
- **Decision environment**: `Default decision environment`
- **Credential**: `<username>-eda-aap-credential`
- **Event streams**: map the rulebook source `alertmanager` to the event stream `<username>-alerts`

Save it.

Why: the activation runs the rulebook. The mapping tells EDA to feed your event stream into the rulebook's `alertmanager` source.

Expected result: the activation status changes to **Running** within a minute or two.

### Step 3: Send the sample alert and read the event (15 min)

`activities/activity03/sample-alert.json` is an alert exactly as Alertmanager would send it. Send it to your event stream. Replace `<event-stream-url>` and `<token>` with your values.

Bash:

```bash
curl -i -X POST "<event-stream-url>" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  --data @activities/activity03/sample-alert.json
```

Windows PowerShell:

```powershell
Invoke-RestMethod -Method Post -Uri "<event-stream-url>" `
  -Headers @{ Authorization = "Bearer <token>" } `
  -ContentType "application/json" `
  -InFile "activities\activity03\sample-alert.json"
```

Expected result: curl shows `HTTP/1.1 200 OK`. PowerShell returns without an error.

Now open your activation and look at its output. The `Print every event` rule printed a line that starts with `event:`. The alert you sent is under `payload`, and EDA added `meta` (where and when the event arrived). Find the alert name:

```text
event: {'payload': {..., 'commonLabels': {'alertname': 'AutomationReceiptDown', ...}, ...}, 'meta': {...}}
```

So the alert name is at `event.payload.commonLabels.alertname`.

Why: you can only write a rule for data you have seen. The printed event shows you the exact field names to use.

### Step 4: Write the condition and the action (20 min)

In your fork, open `extensions/eda/rulebooks/automation-receipt-remediation.yml`. Remove the leading `# ` from every line of the `Restart the Automation Receipt` rule, keeping the indentation. Then replace the two `TODO` lines:

- The **condition** must match when the alert name is `AutomationReceiptDown`.
- The **action** must launch your job template `<username>-ocp-template` in `<organization>`, and pass your namespace as `AAP_NAMESPACE`.

<details>
<summary>Hint 1</summary>

The condition compares the field you found in step 3 with the alert name. The action is not a playbook: you already have a job template that restores the app, so launch that. Nobody is there to answer its survey, so the rule must hand over the answer itself, as an extra variable.

</details>

<details>
<summary>Hint 2</summary>

See [Conditions: navigate structured data](https://ansible.readthedocs.io/projects/rulebook/en/latest/conditions.html#navigate-structured-data) and the [run_job_template action](https://ansible.readthedocs.io/projects/rulebook/en/latest/actions.html#run-job-template) in the ansible-rulebook documentation.

</details>

<details>
<summary>Solution</summary>

```yaml
    - name: Restart the Automation Receipt
      condition: event.payload.commonLabels.alertname == "AutomationReceiptDown"
      throttle:
        once_within: 5 minutes
        group_by_attributes:
          - event.payload.commonLabels.alertname
      action:
        run_job_template:
          name: <username>-ocp-template
          organization: <organization>
          job_args:
            extra_vars:
              AAP_NAMESPACE: <namespace>
```

Replace `<username>`, `<organization>` and `<namespace>` with your values. The rule stays below `Print every event`.

</details>

Don't change the `sources` section. EDA keeps your event stream mapping only as long as the sources stay the same.

Commit and push:

```bash
git add extensions/eda/rulebooks/automation-receipt-remediation.yml
git commit -m "Add the remediation rule"
git push
```

Then sync `<username>-eda-project` and restart `<username>-remediation`.

Why: EDA works from a copy of your repository. The sync fetches your new rule, and the restart loads it into the running rulebook.

Expected result: the activation is **Running** again.

### Step 5: Trigger the remediation (10 min)

Send the sample alert again, with the same command as in step 3.

Expected result:

- The activation output prints the event, as before.
- A new job of `<username>-ocp-template` appears in the job list and finishes with **Successful**.
- The activation's rule audit shows that `Restart the Automation Receipt` fired, and links to that job.
- Reload your Automation Receipt: it shows the new job number and a new deployment time.

You didn't launch this job. The rulebook did, after reading an event. The receipt's "Launched by" line still shows your username, because EDA launches the job with your credential from step 2a. The rule audit is where you see that the rulebook started it.

Why: this is the whole idea of EDA. The same job template you used by hand now runs as a reaction to an event.

### Step 6: Add the connect-alertmanager job template through CaC (15 min)

So far you sent a fake alert by hand. To let OpenShift send the real one, a playbook configures Alertmanager in your namespace. It lives in the workshop repository, so it is reached through `<username>-nginx-project`. Sync that project first, so AAP finds the new playbook.

In your fork, open `activities/activity02/aap_config_as_code/roles/deploy_job_templates/vars/main.yml` and paste this entry at the end of the file:

```yaml
  - name: <username>-connect-alertmanager
    state: present  # present = create or update (default), absent = delete
    organization: <organization>
    description: Routes my AutomationReceiptDown alert to my EDA event stream.
    inventory: <username>-ocp-inventory
    project: <username>-nginx-project
    playbook: activities/activity03/connect-alertmanager/connect.yml
    execution_environment: Default execution environment
    credentials:
      - <username>-ocp-credential
    survey_enabled: true
    survey_spec:
      name: ""
      description: ""
      spec:
        - question_name: Namespace
          question_description: The OpenShift namespace of your app
          required: true
          type: text
          variable: AAP_NAMESPACE
          min: 0
          max: 1024
          default: ""
        - question_name: Event stream URL
          question_description: The URL shown on your event stream in AAP
          required: true
          type: text
          variable: event_stream_url
          min: 0
          max: 1024
          default: ""
        - question_name: Event stream token
          question_description: The token in your Token Event Stream credential
          required: true
          type: password
          variable: event_stream_token
          min: 0
          max: 1024
```

Replace `<username>` and `<organization>` with your values.

> [!IMPORTANT]
> Indentation matters. `  - name:` must start with exactly two spaces, aligned with the `- name:` of the entry above it. Use spaces, never tabs.

The URL and the token are not in this file. You type them into the survey when you launch, and AAP keeps the token encrypted.

Commit and push:

```bash
git add activities/activity02/aap_config_as_code/roles/deploy_job_templates/vars/main.yml
git commit -m "Add the connect-alertmanager job template"
git push
```

Your CaC job runs, as in Activity 2. When it finishes, launch `<username>-connect-alertmanager` and fill in the survey:

- **Namespace**: `<namespace>`
- **Event stream URL**: the URL you copied in step 2d
- **Event stream token**: the token from step 2c

Why: the playbook stores the token in a Secret in your namespace and creates an `AlertmanagerConfig`. It tells Alertmanager to send `AutomationReceiptDown` to your event stream, with the token in the `Authorization` header.

Expected result: `<username>-connect-alertmanager` appears in AAP, and its job finishes with **Successful**.

### Step 7: Break the app and watch it heal (15 min)

In the OpenShift console, open the `automation-receipt` deployment in `<namespace>` and scale it down to 0 pods. With the `oc` CLI, the same is:

```bash
oc scale deployment/automation-receipt --replicas=0 -n <namespace>
```

Then watch:

1. Your Automation Receipt page stops loading.
2. After about 1 minute, the alert `AutomationReceiptDown` fires. You can see it in the OpenShift console under **Observe**.
3. A few seconds later, the event appears in your activation output.
4. A new `<username>-ocp-template` job runs.
5. The deployment is back at 1 pod, and the receipt shows the new job number.

Why: this is the full loop, with no person involved between the outage and the fix.

Expected result: the app is back within a few minutes, without you launching anything.

### Step 8: Guardrails (10 min)

- The throttle: the first matching event acts immediately. Further events for the same alert within 5 minutes are ignored by the remediation rule; the print rule still shows them. Without the throttle, an alert that repeats would launch a new job every time.
- If the remediation fails: the app stays down, the alert keeps firing, and Alertmanager sends it again every 5 minutes. After the throttle window, the rule launches the job again. A broken fix can loop like this, so watch failed jobs and alert a person when the same fix fails repeatedly.
- When to require a human: restarting a stateless web page is safe to automate. For risky actions, such as touching data, production databases, or anything hard to undo, let the rule open a ticket or launch a workflow with an approval step instead of acting directly.

## 4. Troubleshooting

- **Activation won't start:** open the activation output. A YAML or rulebook error points to a line in the rulebook; compare it with the solution in step 4. If the error mentions the decision environment or pulling an image, tell the instructor.
- **401 or 403 when sending the sample:** the token in your command must match the token in `<username>-event-stream-credential`, and the header must be `Authorization: Bearer <token>`. Check that the event stream uses the **Token Event Stream** credential.
- **No event in the activation output:** check the URL in your command against the URL of `<username>-alerts`. Check that the activation maps the source `alertmanager` to `<username>-alerts`, and that test mode is off on the event stream.
- **Condition never matches:** compare your field path with the printed event: `event.payload.commonLabels.alertname`. Check that `Print every event` is still the first rule and `match_multiple_rules: true` is still there. If you changed the `sources` section, the mapping was dropped: edit the activation and map the source again.
- **Job not launched:** the activation output shows the error. Check `<username>-eda-aap-credential`: the URL must end with `/api/controller/`. Check that `name` and `organization` in your action match `<username>-ocp-template` and `<organization>` exactly. If the error mentions `variables_needed_to_start`, the action does not pass `AAP_NAMESPACE`, or misspells it.
- **Alert not firing:** the alert waits 1 minute before it fires. Check the deployment really shows 0 pods, and look for `AutomationReceiptDown` under **Observe** in the OpenShift console.
- **Alert firing but no event:** run `<username>-connect-alertmanager` again and check it succeeds. Check that you typed the event stream URL and token exactly. If it still fails, tell the instructor.
- **CaC job fails after pasting the YAML:** usually indentation. The entry must start with `  - name:`, aligned with the entry above it, with spaces only. The job output names the line.

## 5. Recap

From scaled to zero to restored:

| Step in the loop | Object that does it |
|---|---|
| Deployment drops to 0 available pods | OpenShift |
| `AutomationReceiptDown` fires after 1 minute | PrometheusRule from Activity 1 Part B |
| Alert is sent to your event stream with a token | `AlertmanagerConfig` and Secret, created by `<username>-connect-alertmanager` |
| Event is accepted and checked | Event stream `<username>-alerts` with `<username>-event-stream-credential` |
| Rule matches and launches a job | Rulebook activation `<username>-remediation` |
| Job logs in to AAP | `<username>-eda-aap-credential` |
| App is redeployed and the receipt updated | `<username>-ocp-template` from Activity 1 Part B |

Want to learn more about rulebooks? Start with the [ansible-rulebook introduction](https://docs.ansible.com/projects/rulebook/en/v1.3.1/introduction.html).
