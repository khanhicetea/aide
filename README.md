# AIDE

A small, repeatable bootstrap for an AI development environment on Linux
(`arm64` and `amd64`).

## Quick start

```bash
curl -fsSL https://github.com/khanhicetea/aide/archive/refs/heads/main.tar.gz \
  | tar -xz
cd aide-main
./aide
```

Or clone the repository and run `./aide`. The default setup:

1. installs basic prerequisites using the detected Linux package manager;
2. installs `mise` at `/usr/local/bin/mise` (using `sudo` when needed);
3. installs Node.js LTS as the current user's global mise version;
4. configures `~/.local/bin` as the user npm global bin directory and adds it to `PATH`;
5. generates `~/.ssh/id_ed25519` if it does not exist;
6. adds keys from `https://github.com/khanhicetea.keys` to `authorized_keys`;
7. installs pi and the configured pi packages;
8. merges this repository's `.agents/` into `~/.agents/`.

Existing SSH keys and `authorized_keys` entries are preserved. Agent files with the
same names are replaced; unrelated files in `~/.agents` are preserved.

## Commands

```bash
./aide setup                         # everything (default)
./aide tools                         # mise + Node.js
./aide user                          # npm PATH + SSH/GitHub keys
./aide agents                        # install pi/packages + sync .agents
./aide user --github-user USER       # use another GitHub account
AIDE_NODE_VERSION=22 ./aide tools    # select a Node version
```

Supported package managers: `apt`, `dnf`, `yum`, `pacman`, and `apk`.

The agents step installs:

- `@earendil-works/pi-coding-agent`
- `npm:@juicesharp/rpiv-ask-user-question`
- `npm:pi-powerline-footer`
- `npm:pi-xai-oauth`

## Repository layout

```text
aide                 entry point
lib/                 bootstrap modules
.agents/             files copied into ~/.agents
dotfiles/            user configuration tracked by AIDE
```
