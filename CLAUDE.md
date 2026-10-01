# AAP Workshop Repository

## Purpose
Materials for a two-day Ansible Automation Platform (AAP) workshop for an IT department.
Format: short lecture, then a hands-on activity, for each topic.

## Audience
IT staff who already know Ansible basics (YAML, playbooks, modules) and Git basics.
They are new to AAP. Materials teach the platform, not playbook writing.

## Workshop storyline
All activities build on the same scenario, so each one continues the previous:
- Activity 1 (AAP basics): Part A deploys nginx on a Linux VM. Part B deploys a webapp on OpenShift.
- Activity 2 (CaC): participants define the AAP objects from Activity 1 in Git and sync them via webhook. Includes the DR design.
- Activity 3 (EDA): a rulebook receives Alertmanager webhooks for each participant's webapp and triggers remediation.

## Environment facts
- AAP version: 2.7
- VM operating system: RHEL9
- SSH username on VMs: ec2-user
- Execution environment: Default
- Git repo URL used by participants: will be provide in the future
- Every participant has their own VM and shares one AAP instance with everyone else.
- nginx port is always 8080 (already allowed by SELinux on RHEL; no SELinux handling needed).
- OpenShift API URL: {OCP_API_URL}
- OpenShift version: {OCP_VERSION}
- Webapp container image (non-root, listens on 8080): `docker.io/nginxinc/nginx-unprivileged:latest`.
  Participants supply it through the Part B survey (`WEBAPP_IMAGE`, optional, this as default).
- HTML directory served by that image: `/usr/share/nginx/html`
- Every participant has their own OpenShift namespace and a service account with
  edit rights limited to that namespace. Participants receive the namespace name and token.
- AAP public URL (reachable from the internet, used for GitHub webhooks): {AAP_URL}
- In Activity 2, participants fork {GIT_URL} into their own GitHub account.
  Forks are public: nothing secret may ever be committed.
- OpenShift user workload monitoring is enabled, including the user workload
  Alertmanager with user-defined alert routing (`AlertmanagerConfig`) allowed.

## Repository layout
Repo root: `/root/github/AAP-WorkShop`

- `activities/`: all participant-facing activity folders, one per activity, named
  `activityNN` with a two-digit number:
  - `activities/activity01` (AAP basics)
  - `activities/activity02` (CaC)
  - `activities/activity03` (EDA)
  Each activity folder has its own CLAUDE.md. Read it before working in that folder.
- `terraform/`: deploys the workshop VMs on AWS. Do NOT modify anything here unless
  explicitly asked. Reading it for context (e.g. VM OS, usernames) is allowed.
- `lab/`: instructor maintenance scripts (e.g. creating participant users in AAP).
  Not participant-facing. Do not modify unless explicitly asked. Reading it for context
  is allowed, e.g. to match the username format used in naming conventions.
- `playbooks/`: the instructor's personal test area. Ignore it completely. Never put
  activity playbooks here; activity playbooks always live in their activity folder.
- `{RULEBOOK_DIR}` (at the repo root, e.g. `extensions/eda/rulebooks/`): EDA rulebooks.
  EDA projects only discover rulebooks in specific root folders, so this is the ONE
  exception to the rule that activity content lives in its activity folder.
  Only Activity 3 uses it.

## Activity folder conventions
- Each activity folder contains: playbooks, supporting files (templates etc.), and a
  README.md with step-by-step instructions for participants.
- An activity with multiple parts uses one subfolder per part inside its activity folder
  (e.g. `activities/activity01/webapp-vm`).
- Participant AAP objects are prefixed with the participant's username, e.g. `<username>-nginx-inventory`.
- Playbooks must pass `ansible-lint` (production profile if feasible) and `ansible-playbook --syntax-check`.
- Prefer `ansible.builtin` modules. Any 
other collection must exist in {EE_NAME}, or be listed in `collections/requirements.yml`.

## Writing style for participant READMEs
Participants read these during a live workshop, with the instructor in the room.
Write detailed but human: like an experienced colleague walking someone through it.
- Give every detail needed to complete a step, and nothing beyond that.
- Explain "why" in one or two plain sentences. Do not turn steps into lectures;
  the instructor covers theory in the session.
- Use short sentences and address the reader as "you".
- No marketing or hype words ("powerful", "seamless", "robust", "unlock", "leverage").
- No filler openings ("In this section we will explore..."). Start with what to do.
- No emojis, no exclamation marks, no excessive bold. Bold only UI element names
  the participant must click or find.
- Do not repeat the same explanation in several places. Say it once, where it's needed.

Example of the right tone:
  Bad:  "Credentials are a powerful and essential feature of AAP that seamlessly
         enable secure authentication across your entire automation estate!"
  Good: "AAP stores your SSH key encrypted, so it never appears in your playbook or
         in Git. The job uses it to log in to your VM."

## Global rules
- Never invent documentation URLs. If an exact link can't be confirmed, write `TODO: link to <topic> docs`.
- Never guess AAP UI menu paths. Name the object type and its fields instead; do not add
  "verify menu path" notes, participants manage without them.
- Only work inside the activity folder you were asked to work on.
- Do not add content belonging to a later activity (e.g. no CaC in Activity 1).
- At the end of every task, report: files created or changed, assumptions made, and all TODOs.
- Only work inside the activity folder you were asked to work on (plus `{RULEBOOK_DIR}`
  when working on Activity 3).