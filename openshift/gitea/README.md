# Gitea

A Git server on the cluster, reachable through a Route. Each participant logs in as
`user1` .. `userN` with the same password they use for OpenShift and AAP.

| File | What it does |
|---|---|
| `gitea.yaml` | Namespace `gitea`, a 10Gi PVC, the Gitea Deployment (SQLite, rootless image), its Service and an HTTPS edge Route. |
| `deploy_gitea.sh` | Applies `gitea.yaml`, sets Gitea's `ROOT_URL` to the Route host, waits for the pod, and creates or updates the users. |

## Deploy

Log in with `oc` as a cluster admin, then run:

```bash
openshift/gitea/deploy_gitea.sh
```

To also create `manager` as a Gitea administrator, pass the password of the OpenShift
login `manager`:

```bash
MANAGER_PASSWORD='<password>' openshift/gitea/deploy_gitea.sh
```

The script prints the Gitea URL at the end.

## Notes

- Users and password come from `PASSWORD_OF_USERS` and `NUM_USERS` in
  `lab/create_users.sh`, so all three systems stay in sync. Set `GITEA_USERS_PASSWORD`
  or `GITEA_NUM_USERS` to override them for one run.
- The script is safe to re-run. Existing users get their password reset to the current
  value; users are never deleted.
- Users are local Gitea accounts with the same name and password, not a login through
  OpenShift. If you change the password later, run the script again.
- Self-registration is off and SSH is off. Clone over HTTPS with the Route URL.
- Repositories, the database and `app.ini` live on the PVC. Deleting the namespace deletes
  them.
- Webhooks may call any host (`ALLOWED_HOST_LIST = *`), so a push can reach AAP even if its
  Route resolves to a private address.
- Each user's email is `<username>@example.com`. Gitea requires one; nothing is sent to it.
