# credfeto-ssh-key-mgr

SSH Key Manager — a POSIX shell script that manages per-host SSH keys and their entries in `~/.ssh/config`.

Each host gets its own ed25519 key pair named `id_<host>` stored in `~/.ssh/`. The script keeps `~/.ssh/config` in sync so SSH automatically uses the correct identity file for each host.

## Build Status

| Branch  | Status                                                                                                                                                                                                                                        |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| main    | [![Build: Pre-Release](https://github.com/credfeto/credfeto-ssh-key-mgr/actions/workflows/build-and-publish-pre-release.yml/badge.svg)](https://github.com/credfeto/credfeto-ssh-key-mgr/actions/workflows/build-and-publish-pre-release.yml) |
| release | [![Build: Release](https://github.com/credfeto/credfeto-ssh-key-mgr/actions/workflows/build-and-publish-release.yml/badge.svg)](https://github.com/credfeto/credfeto-ssh-key-mgr/actions/workflows/build-and-publish-release.yml)             |

## Prerequisites

- A POSIX-compatible shell (`/bin/sh`)
- `ssh-keygen` at `/bin/ssh-keygen`
- `cut` at `/bin/cut`
- `grep` at `/bin/grep`
- `ssh-add` (only required for the `use` subcommand)
- A running `ssh-agent` (only required for the `use` subcommand)

## Installation

Copy or symlink `ssh-key-mgr` to a directory on your `PATH`, for example:

```sh
cp ssh-key-mgr ~/.local/bin/ssh-key-mgr
chmod +x ~/.local/bin/ssh-key-mgr
```

On first run the script creates `~/.ssh/` (mode `700`) and a default `~/.ssh/config` (mode `600`) if either does not already exist. The generated config disables password authentication, enables public key authentication, and sets `IdentitiesOnly yes` so only the host-specific key is offered.

## Usage

```text
ssh-key-mgr <subcommand> [options]
```

### create

Generate a new ed25519 SSH key pair for a host and add it to `~/.ssh/config`.

```sh
ssh-key-mgr create --host <host> --comment <comment> [--no-password]
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname to create the key for. The key is stored as `~/.ssh/id_<host>`. |
| `--comment <comment>` | No | Key comment embedded in the public key. Defaults to `<host> for <user>@<hostname>`. |
| `--no-password` | No | Generate the key without a passphrase. Omitting this flag prompts for a passphrase. |

After generation the public key is printed to stdout.

### alias

Add an additional hostname to an existing host's `~/.ssh/config` entry so that it reuses the same key.

```sh
ssh-key-mgr alias --host <host> --additional-host <additional-host>
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | The existing host whose key will be reused. |
| `--additional-host <additional-host>` | Yes | The new hostname to associate with that key. |

### revoke

Revoke an SSH key by moving both key files into `~/.ssh/old/` with a `.revoked` suffix and removing the host entry from `~/.ssh/config`.

```sh
ssh-key-mgr revoke --host <host>
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname whose key is to be revoked. |

The old key files are retained in `~/.ssh/old/` so they can be recovered if needed, though they should not be reused.

### rotate

Replace an existing host key with a freshly generated one. The old key pair is moved to `~/.ssh/old/` before the new key is written.

```sh
ssh-key-mgr rotate --host <host> --comment <comment> [--no-password]
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname whose key is to be rotated. |
| `--comment <comment>` | Yes | Key comment for the new public key. |
| `--no-password` | No | Generate the replacement key without a passphrase. Omitting this flag prompts for a passphrase. |

After rotation the new public key is printed to stdout.

### show

Print the public key for a host to stdout.

```sh
ssh-key-mgr show --host <host>
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname whose public key to display. |

### use

Unlock a host's private key and add it to the running `ssh-agent`.

```sh
ssh-key-mgr use --host <host>
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname whose key to load into the agent. |

The `SSH_AUTH_SOCK` environment variable must be set and an `ssh-agent` must be running. To enable the user-level agent on systemd systems:

```sh
systemctl enable --now --user ssh-agent.service
```

After loading, the public key and the full list of keys currently held by the agent are printed.

### import

Import an existing key pair for a host. Both the private key and its `.pub` companion must exist at the source path.

```sh
ssh-key-mgr import --host <host> --source <path-to-private-key>
```

| Option | Required | Description |
| --- | --- | --- |
| `--host <host>` | Yes | Hostname to associate with the imported key. |
| `--source <path>` | Yes | Path to the existing private key file. The public key is expected at `<path>.pub`. |

The key pair is copied to `~/.ssh/id_<host>` and a host entry is added to `~/.ssh/config`.

### audit

Report the algorithm and fingerprint of every key pair currently installed in `~/.ssh/`.

```sh
ssh-key-mgr audit
```

No options. The command also warns if a default `id_rsa` or `id_ed25519` key is present, since those are not managed by `ssh-key-mgr`.

## Key Storage

| Path | Purpose |
| --- | --- |
| `~/.ssh/id_<host>` | Private key for `<host>` |
| `~/.ssh/id_<host>.pub` | Public key for `<host>` |
| `~/.ssh/old/id_<host>.old` | Superseded private key after `rotate` |
| `~/.ssh/old/id_<host>.old.pub` | Superseded public key after `rotate` |
| `~/.ssh/old/id_<host>.revoked` | Revoked private key after `revoke` |
| `~/.ssh/old/id_<host>.revoked.pub` | Revoked public key after `revoke` |

## Key Algorithm

All keys are generated using **ed25519** with **1500 bcrypt KDF rounds** for passphrase-protected keys.

## Changelog

View [changelog](CHANGELOG.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## Security

See [SECURITY.md](SECURITY.md)

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
