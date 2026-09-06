# agent-devcontainer

A devcontainer base image for agent-assisted development. Coding agents (e.g. Claude Code) run through the IDE, not inside this image — this just provides the OS tooling a devcontainer needs.

## What's in it

| Tool | Why |
|---|---|
| `jq` | JSON handling |
| `yq` (mikefarah/yq, the Go binary — not apt's Python one) | YAML handling |
| `gh` | GitHub CLI |
| `kubectl` | Talk to a Kubernetes cluster |
| `kind` | Local Kubernetes cluster |
| `openssh-client` | `ssh-keygen` and general SSH usage |
| `unzip`, `bzip2`, `less`, `vim`, `ca-certificates`, `gnupg` | General sandbox hygiene |
| Python 3.12 | Added via a devcontainer feature, not baked into the image (see below) |

Base image: `mcr.microsoft.com/devcontainers/javascript-node:22`, for devcontainer-spec compatibility (non-root `node` user, sudo, features).

**Deliberately excluded:** `sbx`, gVisor/Kata, cloud provider CLIs.

## Build & publish

```bash
# from this directory
docker buildx build --platform linux/amd64,linux/arm64 \
  -t julieio/agent-devcontainer:latest \
  --push .
```

To test locally before pushing:

```bash
docker buildx build --platform linux/arm64 -t julieio/agent-devcontainer:test --load .
docker run --rm -it julieio/agent-devcontainer:test bash
```

## Python

Python is **not** baked into the image. It's added declaratively via the official `ghcr.io/devcontainers/features/python:1` feature in `devcontainer.json` (pinned to `3.12`), keeping the version visible and diffable in `devcontainer.json` rather than buried in a Dockerfile `RUN` step.

## Using image in `devcontainer.json`

### Copy sample file

Copy `devcontainer.sample.json` to your project's `.devcontainer/devcontainer.json` 

### Adjust paths/mounts to load Claude memories

- Mounting `~/.claude` carries over its config into the container.
- Adjusting `workspaceMount` / `workspaceFolder` allow for local mapping to  memories folder via Claude naming conventions.



## Maintenance notes

- `kubectl` installs from `dl.k8s.io/release/stable.txt` at build time — rebuilding the image (not just restarting a container) picks up new kubectl versions. Pin explicitly if cluster-version skew becomes a problem.
- `yq` and `kind` versions are pinned explicitly in the Dockerfile (`v4.44.3`, `v0.24.0`) — bump these manually; they don't auto-track latest.
