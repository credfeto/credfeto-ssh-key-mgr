# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
### Added
- PKGBUILD for Arch Linux packaging via makepkg
- upload subcommand to push an existing key to the key server with challenge-response authentication
- Auto-upload new key to credfeto-ssh-key-server on create
- Remove old key from credfeto-ssh-key-server on rotate or revoke
- Add --user flag to rotate and revoke subcommands for key server integration
- Bats unit tests covering all subcommands
- CI workflow to run bats tests on every push and pull request
- GitHub Actions workflow to build Arch Linux package using makepkg in an archlinux:latest container
### Fixed
- Corrected broken cross-reference in github-workflows.instructions.md — anchor #visual-indicators updated to #output-helpers to match actual section name in shell-scripts.instructions.md
- shell.firewall.examples.md open_port_for_private_networks no longer calls firewall-cmd --reload internally; added explicit caller-reload rule to shell.firewall.instructions.md
- die() now correctly writes to stderr so error messages are not captured by stdout pipelines
- removed spurious debug echo in create subcommand that printed the ssh-keygen command line to stdout
- IFS='\\n' no-op assignments in alias and revoke subcommands replaced with correct IFS handling
- removed unused BASEDIR variable
- import subcommand was copying the public key to the private key path
- audit subcommand incorrectly exited non-zero when no default SSH key files existed
### Changed
- die() must output to stderr so error messages are not swallowed by stdout pipelines
### Deprecated
### Removed
### Deployment Changes
<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->
## [0.0.0] - Project created