# CaC execution environment (instructor setup)

The Activity 2 CaC job template runs in the execution environment `cac-image` (image
`aap/cac-image`). Build this image once before the workshop and register it in AAP.
Participants only select it. Activities 1 and 3 use the Default execution environment.

What the image contains:

| | |
|---|---|
| Base image | `registry.redhat.io/ansible-automation-platform-27/ee-supported-rhel9:latest` (same image as the **Default execution environment**) |
| Added collection | `infra.aap_configuration` 4.10.0 from galaxy.ansible.com |
| Already in the base image | `ansible.controller`, `ansible.platform`, `ansible.hub`, `ansible.eda`, the dependencies of `infra.aap_configuration` |

Why not a `collections/requirements.yml` in the project instead: AAP only reads that file at
the root of the project, and every `infra.aap_configuration` release since 3.4.0 declares
hard dependencies on the four certified collections above. Those are not on
galaxy.ansible.com, so a project sync with only the Galaxy credential fails. Building on top
of `ee-supported-rhel9` avoids this, because the dependencies are already installed there.

## 1. Build

You need `podman`, `ansible-builder` 3.x, and a Red Hat login for `registry.redhat.io`.

```bash
cd Execution-environment
podman login registry.redhat.io
ansible-builder build -f execution-environment.yml -t aap/cac-image:latest
```

Check that the collection is in the image:

```bash
podman run --rm aap/cac-image:latest ansible-galaxy collection list infra.aap_configuration
```

Expected: `infra.aap_configuration 4.10.0`.

## 2. Push

Push the image to the private automation hub that comes with AAP. Its container registry is
served on the AAP host name, so `<registry>` is the host part of the AAP URL (for example
`aap-aap.apps.<cluster-domain>`, without `https://`). Log in with an AAP admin account:

```bash
podman tag aap/cac-image:latest <registry>/aap/cac-image:latest
podman login <registry>
podman push <registry>/aap/cac-image:latest
```

## 3. Register it in AAP

Create an execution environment:

- Name: `cac-image` (the Activity 2 README uses this exact name)
- Image: `<registry>/aap/cac-image:latest`
- Pull: always pull the image before running
- Organization: leave empty, so every participant organization can use it
- Registry credential: only if the registry needs a login to pull

## 4. Test it

Before the workshop, run Activity 2 once with a test user. The CaC job of
`<username>-cac-template` must run in `cac-image` and finish **Successful**.

## Updating the collection

Change the version in `requirements.yml`, rebuild with a new tag, and update the image in
the AAP execution environment. Re-check your variable names against the new version's role
documentation.
