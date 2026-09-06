# agent-devcontainer

A devcontainer base image for agent-assisted development. Coding agents (e.g. Claude Code) run through the IDE, not inside this image — this `docker.io/julieio/agent-devcontainer` just provides the OS tooling a devcontainer needs.

> [!IMPORTANT] 
> This is **very large image at 8.5GB** due to the [Mermaid CLI](https://www.npmjs.com/package/@mermaid-js/mermaid-cli) dependency that Claude Code needs to verify the mermaid code it generates. This is a known issue and because the container is only for me, I will move `mmdc` to `devcontainer.json` at later time.

## Included Tools

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

### Python

Python is **not** baked into the image. It's added declaratively via the official `ghcr.io/devcontainers/features/python:1` feature in `devcontainer.json` (pinned to `3.12`), keeping the version visible and diffable in `devcontainer.json` rather than buried in a Dockerfile `RUN` step.

## Example `devcontainer.json`

Copy [`devcontainer.sample.json`](./.devcontainer/devcontainer.sample.json) to your project's `.devcontainer/devcontainer.json` and adjust paths/mounts as needed.

```json
{
  "name": "Agent Devcontainer",
  "image": "docker.io/julieio/agent-devcontainer:latest",
  "workspaceMount": "source=${localWorkspaceFolder},target=/Users/<user>/path/to/project,type=bind,consistency=cached",
  "workspaceFolder": "/Users/<user>/path/to/project",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.12"
    }
  },
  "mounts": [
    "source=${localEnv:HOME}/.claude,target=/home/node/.claude,type=bind,consistency=cached"
  ],
  "postCreateCommand": "npm install",
  "dotfiles": {
    "repository": "https://github.com/<USERNAME>/dotfiles.git",
    "targetPath": "~/dotfiles",
    "installCommand": "~/dotfiles/setup.sh"
  }
}
```

### Claude Code Setup

The `agent-devcontainer` itself is agnostic. But the `devcontainer.json` file contains Claude code specific setup.

#### Map this project's memories

In order for Claude to pull the project specific memories, the container needs to work in a directory path that matches the host path:

| | Path |
|---|---|
| Project Path | `/Users/alice/workspace/my-project` |
| Claude memory path | `~/.claude/projects/-Users-alice-workspace-my-project` |

#### Mount all memories

Mounting `~/.claude` carries over its config into the container and _memorials from **all** claude projects_.  This intentional I can ask Claude to check how project X handled problem Y, etc.

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

## Maintenance notes

- `kubectl` installs from `dl.k8s.io/release/stable.txt` at build time — rebuilding the image (not just restarting a container) picks up new kubectl versions. Pin explicitly if cluster-version skew becomes a problem.
- `yq` and `kind` versions are pinned explicitly in the Dockerfile (`v4.44.3`, `v0.24.0`) — bump these manually; they don't auto-track latest.
