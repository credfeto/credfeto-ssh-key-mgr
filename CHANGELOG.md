# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
- Pin GitHub Actions uses: references to commit SHA instead of tag (#41)
### Added
- PKGBUILD for Arch Linux packaging via makepkg
- upload subcommand to push an existing key to the key server with challenge-response authentication
- Auto-upload new key to credfeto-ssh-key-server on create
- Remove old key from credfeto-ssh-key-server on rotate or revoke
- Add --user flag to rotate and revoke subcommands for key server integration
- Bats unit tests covering all subcommands
- CI workflow to run bats tests on every push and pull request
- GitHub Actions workflow to build Arch Linux package using makepkg in an archlinux:latest container
- Automated PKGBUILD version and sha256sums update in CI via update-pkgbuild composite action
### Fixed
- Corrected broken cross-reference in github-workflows.instructions.md — anchor #visual-indicators updated to #output-helpers to match actual section name in shell-scripts.instructions.md
- shell.firewall.examples.md open_port_for_private_networks no longer calls firewall-cmd --reload internally; added explicit caller-reload rule to shell.firewall.instructions.md
- die() now correctly writes to stderr so error messages are not captured by stdout pipelines
- removed spurious debug echo in create subcommand that printed the ssh-keygen command line to stdout
- IFS='\\n' no-op assignments in alias and revoke subcommands replaced with correct IFS handling
- removed unused BASEDIR variable
- import subcommand was copying the public key to the private key path
- audit subcommand incorrectly exited non-zero when no default SSH key files existed
- upload/rotate/revoke error messages now include the HTTP status code and response body from the key server instead of a bare failure message, making failures diagnosable without server log access
- upload and remove now pass the request body to the key server via a temp file instead of piping into http_request; piping made http_request run as the last stage of a pipeline, which executes in a subshell in sh/dash, silently discarding the HTTP_STATUS/HTTP_BODY it set and leaving the caller with stale values from the previous request
### Changed
- die() must output to stderr so error messages are not swallowed by stdout pipelines
- Replaced bare echo/printf calls with die/success/info output helpers throughout script for consistent user-facing output
### Deprecated
### Removed
### Deployment Changes
<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->
## [0.0.0] - Project created