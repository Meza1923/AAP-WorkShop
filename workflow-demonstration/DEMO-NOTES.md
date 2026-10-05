# Workflow demo: instructor notes

End of day 1, about 20 minutes. You present, participants watch. The demo stress tests nginx on your own Part A VM. If it is fast enough, the workflow reports success. If not, it reloads nginx and reports that the server needs more capacity.

```
Load test ──success──> Check results ──success──> Notify passed
                              │
                              └──failure──> Reload nginx ──always──> Notify capacity
```

## 1. Setup (before the session)

You need your own Part A objects from Activity 1: `admin-nginx-inventory` (your VM, with `nginx_port: 8080` as a host variable), `admin-nginx-credential`, and `admin-nginx-project`. nginx must be running on the VM. Nothing new is created except the five job templates and the workflow.

1. Make sure the `workflow-demonstration/` folder is in the repo your Part A project points to, then sync `admin-nginx-project`. AAP refuses a job template whose playbook is not in the synced project.
2. In your CaC fork from Activity 2, open `activities/activity02/aap_config_as_code/roles/deploy_job_templates/vars/main.yml`. Copy the five entries from [cac/job_templates.yml](cac/job_templates.yml) (everything under `controller_job_templates:`) to the end of the list. They already use your `admin` user and the `admin` organization. Keep the indentation of the existing entries.
3. Commit and push. The webhook runs your CaC job template, which creates all five job templates in one run.
4. Rehearse once: build the workflow (section 2) and run it with the defaults. The first run installs `httpd-tools` on the VM, so the live run doesn't wait on a package install. Then run the Reload nginx path once with the strict limit (section 4), so you know your VM's real numbers.

You can keep the rehearsed workflow and only show it during the session, or delete it and build it live. Building it live takes about 5 minutes and shows the logic better.

## 2. Building the workflow live

Create a workflow job template named `Workflow demo - Stress test` in your organization. Leave inventory empty: each job template brings its own. Open the workflow visualizer and add the nodes in this order:

| # | Node (job template) | Added after | Run on |
|---|---|---|---|
| 1 | `Workflow demo - Load test` | Start | (root) |
| 2 | `Workflow demo - Check results` | Load test | Success |
| 3 | `Workflow demo - Notify passed` | Check results | Success |
| 4 | `Workflow demo - Reload nginx` | Check results | Failure |
| 5 | `Workflow demo - Notify capacity` | Reload nginx | Always |

Say why node 5 is "Always": the capacity message must go out even if the reload itself fails.

Save the workflow, then add a survey to the workflow job template and enable it. Four questions, all required, answer type Integer:

| Question | Answer variable name | Default |
|---|---|---|
| Number of requests | `requests` | 2000 |
| Concurrent requests | `concurrency` | 50 |
| Max average response time (ms) | `max_avg_response_ms` | 200 |
| Max error rate (%) | `max_error_percent` | 1 |

The answer variable names must match exactly; the playbooks read them by name.

## 3. Demo run 1: default limits

Launch the workflow and accept the defaults.

Expected result: Load test, Check results and Notify passed turn green. Reload nginx and Notify capacity don't run.

Show, in this order:
- The Load test job output: `Show the results` prints the numbers, then `Publish the results to the workflow` hands them on with `set_stats`.
- The Check results job output: the table of results against limits. This job never ran `ab`. It received the numbers from the Load test job, and the limits from the workflow survey. Its extra variables show both.
- The Notify passed job output: the message and the same numbers.

## 4. Demo run 2: strict limit

Launch again and set `max_avg_response_ms` to `1`. Keep the other defaults.

Expected result: Check results fails with a message like `Average response time 3.42 ms exceeds the limit of 1 ms by 2.42 ms.` The workflow follows the failure link: Reload nginx runs, then Notify capacity prints "Stress test failed, nginx reloaded, the server should be extended."

Point out that the workflow ends as **Successful**, although one node is red. A failure that has a failure or always link is handled, so it doesn't fail the workflow. Without that link, the workflow would end as **Failed**.

## 5. Talking points

- Each job works alone. Launch `Workflow demo - Reload nginx` by itself: it reloads nginx and checks the page. None of the five job templates knows the others exist.
- The workflow adds the logic: the order, and what happens on success and on failure. Changing the process means changing links, not playbooks.
- Data passes between jobs. The load test publishes `stress_results` with `set_stats`, and AAP passes it as an extra variable to every later node, on both branches. The survey is asked once, and its answers reach every node too.
- Reloading recovers the service, but it doesn't make the server faster. That's why the capacity message asks a person to extend the server: automation handles the first response, and people make the capacity decision.
- In production, the notify jobs would be AAP notification templates (email, Teams, Slack) attached to the workflow. Printed messages keep the demo self-contained.

## 6. What can go wrong

- **CaC job fails with "playbook not found" or similar:** the project hasn't synced the `workflow-demonstration/` folder. Sync `admin-nginx-project`, then rerun the CaC job.
- **Check results fails with "stress_results is not defined":** it was launched on its own, or the link from Load test is missing. Launch the workflow, not the job template.
- **Check results fails with "Missing limit":** the workflow survey isn't enabled, or an answer variable name has a typo.
- **Load test fails with "Connection refused":** nginx is down on the VM. Launch `Workflow demo - Reload nginx` on its own (it starts nginx if needed), then relaunch the workflow.
- **Load test fails installing httpd-tools:** the VM can't reach its package repositories. Fix it before the session; that's what the rehearsal is for.
- **Host unreachable:** the VM is stopped or its address changed. Check the host in `admin-nginx-inventory`.
- **Run 1 fails:** the VM is slower than 200 ms average under this load. Lower `concurrency` or raise `max_avg_response_ms`. You can also turn it into the failure demo and skip run 2.
- **Run 2 passes:** the average stayed under 1 ms. Relaunch with `concurrency` at 200.
- **The passing run also reloads nginx:** a link type is wrong. Check that Check results → Reload nginx is "Failure" and Check results → Notify passed is "Success".
