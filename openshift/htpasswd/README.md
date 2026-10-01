# htpasswd login for workshop users

Lets each participant log in to the OpenShift console as `user1` .. `userN`, with the
same password they use for AAP.

| File | What it does |
|---|---|
| `oauth.yaml` | Adds an identity provider named `workshop` of type HTPasswd to the cluster OAuth configuration. It reads users from the Secret `htpass-secret` in `openshift-config`. |
| `htpass-secret.yaml` | That Secret, empty. Paste htpasswd lines into it (for example for `manager`) and apply it. Don't commit it once it has data. |
| `cluster-admin-manager.yaml` | Gives the user `manager` the `cluster-admin` role on the whole cluster. |

The committed Secret has no data: real entries are password hashes, and participants fork
this repository publicly. `lab/create_users.sh` adds `user1` .. `userN` from
`PASSWORD_OF_USERS` and applies the Secret together with `oauth.yaml`.

## Notes

- `oauth.yaml` replaces the cluster's whole identity provider list. It was empty when this
  was written; if you add another provider later, add it to this file too.
- The script rewrites `htpass-secret` on every run. It keeps every existing entry that is
  not `user<number>` (such as `manager`) and replaces the `user<number>` entries.
- To create `manager`: generate a line with `htpasswd -nbB manager <password>`, paste it into
  `htpass-secret.yaml`, then apply it and `cluster-admin-manager.yaml`. Applying
  `htpass-secret.yaml` replaces the whole Secret, so run `lab/create_users.sh` afterwards
  (or before, and add the users to the file) to keep the participant logins.
- After the first apply, the authentication operator rolls out the change. Logins work once
  `oc get co authentication` shows `PROGRESSING=False` (usually a few minutes).
- Each user gets the `admin`, `monitoring-rules-edit` and `alert-routing-edit` roles in
  their own namespace `<N>user-aap`, the same as their service account.
