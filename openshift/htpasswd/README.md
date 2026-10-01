# htpasswd login for workshop users

Lets each participant log in to the OpenShift console as `user1` .. `userN`, with the
same password they use for AAP.

| File | What it does |
|---|---|
| `oauth.yaml` | Adds an identity provider named `workshop` of type HTPasswd to the cluster OAuth configuration. It reads users from the Secret `htpass-secret` in `openshift-config`. |

The Secret itself is not in the repository: it contains password hashes, and participants
fork this repository publicly. `lab/create_users.sh` generates it from `PASSWORD_OF_USERS`
and applies it together with `oauth.yaml`.

## Notes

- `oauth.yaml` replaces the cluster's whole identity provider list. It was empty when this
  was written; if you add another provider later, add it to this file too.
- The script rewrites `htpass-secret` on every run with exactly the users it creates. Users
  added to the Secret by hand are removed.
- After the first apply, the authentication operator rolls out the change. Logins work once
  `oc get co authentication` shows `PROGRESSING=False` (usually a few minutes).
- Each user gets the `admin`, `monitoring-rules-edit` and `alert-routing-edit` roles in
  their own namespace `<N>user-aap`, the same as their service account.
